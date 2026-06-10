
# ═══════════════════════════════════════════════════════════════
# TecnoBash - Cherry-Pick Interativo
# ═══════════════════════════════════════════════════════════════

# Apresenta seleção de modo via fzf
# stdout: "single" | "multi"
# return: 0 sucesso, 1 cancelamento
function tb__cpick_select_mode() {
    local OPTIONS="Cherry-pick único\nCherry-pick múltiplo"

    local SELECTED=$(echo "$OPTIONS" | tb_fzf \
        --prompt="❯ Selecione o modo: " \
        --height=30% \
        --border=rounded \
        --border-label=" 🍒 Modo de Cherry-Pick " \
        --border-label-pos=3 \
        --color="border:cyan,label:cyan:bold,prompt:magenta:bold" \
        --pointer="▶")

    if [[ -z "$SELECTED" ]]; then
        print_info "Operação cancelada" >&2
        return 1
    fi

    case "$SELECTED" in
        "Cherry-pick único")
            echo "single"
            ;;
        "Cherry-pick múltiplo")
            echo "multi"
            ;;
    esac

    return 0
}

# Lista branches excluindo a atual, apresenta via fzf
# stdout: nome da branch selecionada
# return: 0 sucesso, 1 sem branches ou cancelamento
function tb__cpick_select_branch() {
    local branch_atual
    branch_atual=$(git branch --show-current 2>/dev/null)

    local all_branches
    all_branches=$(git branch --format='%(refname:short)' 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        print_error "Não foi possível listar branches" >&2
        return 1
    fi

    # Filtrar para excluir a branch atual
    local branches_disponiveis
    branches_disponiveis=$(echo "$all_branches" | grep -v "^${branch_atual}$")

    if [[ -z "$branches_disponiveis" ]]; then
        print_warning "Não há outras branches disponíveis" >&2
        return 1
    fi

    local selected
    selected=$(echo "$branches_disponiveis" | tb_fzf \
        --prompt="❯ Selecione a branch de origem: " \
        --height=40% \
        --border=rounded \
        --border-label=" 🌿 Branch de Origem " \
        --border-label-pos=3 \
        --color="border:cyan,label:cyan:bold,prompt:magenta:bold" \
        --pointer="▶")

    if [[ -z "$selected" ]]; then
        print_info "Operação cancelada" >&2
        return 1
    fi

    echo "$selected"
    return 0
}

# Lista commits formatados de uma branch
# $1: nome da branch de origem
# stdout: linhas no formato "hash mensagem (data)"
function tb__cpick_list_commits() {
    local branch="$1"
    local commits
    commits=$(git log --oneline --format='%h %s (%ar)' -50 "$branch" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        print_error "Não foi possível listar commits da branch $branch" >&2
        return 1
    fi
    echo "$commits"
    return 0
}

# Fluxo Single_Mode
# $1: nome da Source_Branch
function tb__cpick_single() {
    local source_branch="$1"
    local commits
    commits=$(tb__cpick_list_commits "$source_branch")
    [[ $? -ne 0 ]] && return 1

    local selected
    selected=$(echo "$commits" | tb_fzf \
        --prompt="❯ Selecione o commit: " \
        --height=60% \
        --border=rounded \
        --border-label=" 🍒 Cherry-Pick Único " \
        --border-label-pos=3 \
        --color="border:cyan,label:cyan:bold,prompt:magenta:bold" \
        --pointer="▶")

    if [[ -z "$selected" ]]; then
        print_info "Operação cancelada"
        return 0
    fi

    local hash=$(echo "$selected" | awk '{print $1}')
    local msg=$(echo "$selected" | sed 's/^[a-f0-9]* //')

    show_loading "Aplicando cherry-pick..." &
    local pid=$!
    git cherry-pick "$hash" >/dev/null 2>&1
    local result=$?
    kill $pid 2>/dev/null; wait $pid 2>/dev/null

    if [[ $result -eq 0 ]]; then
        print_success "Cherry-pick aplicado: ${hash} - ${msg}"
    else
        print_warning "Conflito no cherry-pick do commit ${hash}"
        print_warning "Resolva os conflitos e execute: git cherry-pick --continue"
        print_warning "Para cancelar: git cherry-pick --abort"
    fi
}

# Fluxo Multi_Mode
# $1: nome da Source_Branch
function tb__cpick_multi() {
    local source_branch="$1"
    local commits
    commits=$(tb__cpick_list_commits "$source_branch")
    [[ $? -ne 0 ]] && return 1

    local selected
    selected=$(echo "$commits" | tb_fzf \
        --multi \
        --prompt="❯ TAB para marcar, ENTER para confirmar: " \
        --height=60% \
        --border=rounded \
        --border-label=" 🍒 Commits para Cherry-Pick " \
        --border-label-pos=3 \
        --color="border:cyan,label:cyan:bold,prompt:magenta:bold" \
        --pointer="▶")

    if [[ -z "$selected" ]]; then
        print_info "Operação cancelada"
        return 0
    fi

    # Inverter ordem para cronológica (mais antigo primeiro)
    local ordered
    ordered=$(echo "$selected" | tac)

    local total=$(echo "$ordered" | wc -l | tr -d ' ')
    local applied=0

    show_loading "Aplicando cherry-picks..." &
    local pid=$!

    while IFS= read -r line; do
        local hash=$(echo "$line" | awk '{print $1}')
        local msg=$(echo "$line" | sed 's/^[a-f0-9]* //')

        git cherry-pick "$hash" >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            kill $pid 2>/dev/null; wait $pid 2>/dev/null
            echo ""
            if [[ $applied -gt 0 ]]; then
                print_info "$applied de $total commits aplicados com sucesso"
            fi
            print_warning "Conflito no cherry-pick do commit: $hash - $msg"
            print_warning "Resolva os conflitos e execute: git cherry-pick --continue"
            print_warning "Para cancelar: git cherry-pick --abort"
            return 1
        fi
        ((applied++))
    done <<< "$ordered"

    kill $pid 2>/dev/null; wait $pid 2>/dev/null
    echo ""
    print_success "$applied commits aplicados com sucesso via cherry-pick"
    return 0
}

# Ponto de entrada público
function cpick() {
    local branch_atual
    branch_atual=$(git branch --show-current 2>/dev/null)

    if [[ -z "$branch_atual" ]]; then
        print_error "Não foi possível detectar a branch atual"
        return 1
    fi

    print_info "Branch destino: ${bold}${branch_atual}${reset}"
    echo ""

    # Selecionar modo (single/multi)
    local mode
    mode=$(tb__cpick_select_mode)
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo ""

    # Selecionar branch de origem
    local source_branch
    source_branch=$(tb__cpick_select_branch)
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo ""

    # Despachar para o modo selecionado
    case "$mode" in
        "single")
            tb__cpick_single "$source_branch"
            ;;
        "multi")
            tb__cpick_multi "$source_branch"
            ;;
    esac
}
