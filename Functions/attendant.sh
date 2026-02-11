
function tb_list_functions() {
    if command -v declare >/dev/null 2>&1; then
        declare -F 2>/dev/null | awk '{print $3}'
        return 0
    fi

    if command -v typeset >/dev/null 2>&1; then
        typeset -f 2>/dev/null | awk '/^[a-zA-Z_][a-zA-Z0-9_]* *\\(\\)/{print $1}'
        return 0
    fi
}

function tb_run() {
    local file="$1"
    local func="$2"
    local before after
    local tmp_before tmp_after

    if [[ -z "$TECNO_BASH_FILES" ]]; then
        print_error "TECNO_BASH_FILES não definido."
        return 1
    fi

    before=$(tb_list_functions)

    if [[ -f "$TECNO_BASH_FILES/$file" ]]; then
        source "$TECNO_BASH_FILES/$file"
    else
        print_error "Arquivo não encontrado: $file"
        return 1
    fi

    if ! declare -F "$func" >/dev/null; then
        print_error "Função não encontrada: $func"
        return 1
    fi

    "$func"

    after=$(tb_list_functions)
    tmp_before=$(mktemp)
    tmp_after=$(mktemp)

    printf "%s\n" $before | sort > "$tmp_before"
    printf "%s\n" $after | sort > "$tmp_after"

    comm -13 "$tmp_before" "$tmp_after" | while read -r fn; do
        unset -f "$fn"
    done

    rm -f "$tmp_before" "$tmp_after"
}

function tb_build_display_items() {
    local -a items=("$@")
    local -a display_items
    local i

    for ((i = 1; i <= ${#items}; i++)); do
        local label="${items[i]%%|*}"
        display_items+=("${i}) ${label}")
    done

    printf '%s\n' "${display_items[@]}"
}

function tb_fzf_select() {
    local list_label="$1"
    local branch="$2"
    shift 2
    local -a items=("$@")
    local display_lines
    local preview_cmd
    local lion_lines
    local min_height

    display_lines="$(tb_build_display_items "${items[@]}")"
    preview_cmd="zsh -lc 'source \"${TECNO_BASH_FILES}/Design/visual.sh\"; print_mascot_lion'"
    lion_lines=$(print_mascot_lion | wc -l | tr -d ' ')
    min_height="${TB_MENU_MIN_HEIGHT:-$((lion_lines + 4))}"

    printf '%s\n' "$display_lines" \
        | tb_fzf --prompt="❯ Selecione uma opção: " \
            --height="${TB_MENU_HEIGHT:-60%}" \
            --min-height="$min_height" \
            --margin="${TB_MENU_MARGIN:-1,2}" \
            --layout=default \
            --no-sort \
            --tac \
            --border-label=" TecnoBash " \
            --border-label-pos=3  \
            --border=rounded \
            --list-label=" ${list_label} " \
            --list-label-pos=0 \
            --info=inline-right \
            --info-command="echo Branch atual: ${branch}" \
            --color="border:yellow,label:yellow:bold,prompt:yellow:bold" \
            --pointer="▶" \
            --marker="✓" \
            --preview="$preview_cmd" \
            --preview-window="${TB_MENU_PREVIEW_POS:-left}:${TB_MENU_PREVIEW_SIZE:-40%}:${TB_MENU_PREVIEW_WRAP:-wrap}:noinfo" \
            --no-mouse
}

function tecnobash(){    
    if command -v tb_ensure_dependencies >/dev/null 2>&1; then
        tb_ensure_dependencies || return 1
    fi
    local branch=$(git branch --show-current)
    local -a tb_menu_principal

    tb_menu_principal=(
        "Efetuar commit|Functions/commit.sh|commit"
        "Desfazer último commit (soft)|Functions/commit.sh|soft"
        "Trocar de CREA|Functions/crea.sh|crea"
        "Trocar para branch de Desenvolvimento|Functions/main-branches-switching.sh|dev"
        "Trocar para branch de Produção|Functions/main-branches-switching.sh|prod"
        "Pull|Functions/pulls.sh|pull"
        "Pull Corporativo e Serviços|Functions/pulls.sh|cpull"
        "Pull Diário|Functions/pulls.sh|dp"
        "Push|Functions/pushes.sh|push"
        "Criar Branch de Ticket|Functions/ticket.sh|crtkt"
        "Trocar Branch de Ticket|Functions/ticket.sh|tkt"
        "Executar Testes (phpunit)|Functions/ticket-testing.sh|test"
        "Executar Testes (interativo)|Functions/ticket-testing.sh|testi"
        "Dar Permissão a Arquivo|Functions/permission.sh|such"
        "Entrar SITAG Corporativo (sad)|Functions/folder-switching.sh|sad"
        "Entrar SITAC Corporativo (ad)|Functions/folder-switching.sh|ad"
        "Entrar SITAG Serviços (ssv)|Functions/folder-switching.sh|ssv"
        "Entrar SITAC Serviços (sv)|Functions/folder-switching.sh|sv"
        "Entrar SITAG Extras (ste)|Functions/folder-switching.sh|ste"
        "Entrar SITAC Extras (ext)|Functions/folder-switching.sh|ext"
        "Iniciar Docker e VPN|Functions/start-docker-vpn.sh|start"
    )

    if [[ -z "$branch" ]]; then
        print_error "Não foi possível verificar a branch atual."
        sleep 2
        tput reset
        return 1
    fi 

    clear
    echo ""
    local -A category_map
    category_map=(
        "Git" $'Efetuar commit|Functions/commit.sh|commit\nDesfazer último commit (soft)|Functions/commit.sh|soft\nPull|Functions/pulls.sh|pull\nPull Corporativo e Serviços|Functions/pulls.sh|cpull\nPull Diário|Functions/pulls.sh|dp\nPush|Functions/pushes.sh|push'
        "Tickets" $'Criar Branch de Ticket|Functions/ticket.sh|crtkt\nTrocar Branch de Ticket|Functions/ticket.sh|tkt'
        "Branches" $'Trocar para branch de Desenvolvimento|Functions/main-branches-switching.sh|dev\nTrocar para branch de Produção|Functions/main-branches-switching.sh|prod'
        "Testes" $'Executar Testes (phpunit)|Functions/ticket-testing.sh|test\nExecutar Testes (interativo)|Functions/ticket-testing.sh|testi'
        "Permissões" $'Dar Permissão a Arquivo|Functions/permission.sh|such'
        "Pastas" $'Entrar SITAG Corporativo (sad)|Functions/folder-switching.sh|sad\nEntrar SITAC Corporativo (ad)|Functions/folder-switching.sh|ad\nEntrar SITAG Serviços (ssv)|Functions/folder-switching.sh|ssv\nEntrar SITAC Serviços (sv)|Functions/folder-switching.sh|sv\nEntrar SITAG Extras (ste)|Functions/folder-switching.sh|ste\nEntrar SITAC Extras (ext)|Functions/folder-switching.sh|ext'
        "CREA" $'Trocar de CREA|Functions/crea.sh|crea'
        "Docker/VPN" $'Iniciar Docker e VPN|Functions/start-docker-vpn.sh|start'
    )

    local -a categories
    categories=("${(@k)category_map}")
    local cat_selection
    cat_selection="$(tb_fzf_select "Menu Principal" "$branch" "${categories[@]}")"

    if [[ -z "$cat_selection" ]]; then
        print_error "Opção inválida! O programa será encerrado."
        sleep 1
        tput reset
        return 1
    fi

    local cat_index="${cat_selection%%)*}"
    local selected_category="${categories[$cat_index]}"
    local -a category_items
    category_items=("${(@f)category_map[$selected_category]}")

    local item_selection
    item_selection="$(tb_fzf_select "$selected_category" "$branch" "${category_items[@]}")"

    if [[ -z "$item_selection" ]]; then
        print_error "Opção inválida! O programa será encerrado."
        sleep 1
        tput reset
        return 1
    fi

    local item_index="${item_selection%%)*}"
    local selected_item="${category_items[$item_index]}"

    local selected_file
    local selected_func
    selected_file="$(echo "$selected_item" | awk -F'|' '{print $2}')"
    selected_func="$(echo "$selected_item" | awk -F'|' '{print $3}')"

    tb_run "$selected_file" "$selected_func"

    echo ""
    print_success "Operação concluída com sucesso! ${icon_celebrate}"
    echo ""
    
    return 0
}
