
# Efetuar commit
function commit() {
    local BRANCH=$(git branch --show-current)
    local TICKET_NUMBER=$(grep -oP '(?<=ticket-)\d+' <<< "$BRANCH")

    if [[ -z "$TICKET_NUMBER" ]]; then
        print_warning "Branch atual não segue o padrão 'ticket-XXX'"
        return 0
    else
        print_label "Número do ticket" "#${TICKET_NUMBER}" "${cinza}" "${magenta}"
    fi
    
    echo ""

    if ! git diff --cached --quiet 2>/dev/null; then
        local STAGED_COUNT=$(git diff --cached --numstat | wc -l | xargs)
        print_info "${bold}${STAGED_COUNT}${reset} arquivo(s) preparado(s) para commit"
    else
        print_warning "Nenhum arquivo preparado para commit"
        print_prompt "Deseja adicionar todos os arquivos modificados?"
        local ADD_ALL=$(printf "Selecionar arquivos\nNão\nSim" | tb_fzf \
            --prompt="❯ " \
            --height=30% \
            --border=rounded \
            --border-label=" 📦 Preparar Arquivos " \
            --border-label-pos=3 \
            --color="border:yellow,label:yellow:bold,prompt:magenta:bold" \
            --pointer="▶")
        
        case "$ADD_ALL" in
            "Sim")
                git add -A
                print_success "Todos os arquivos adicionados"
                ;;
            "Selecionar arquivos")
                local MODIFIED_FILES=$(git status --short | awk '{print $2}')
                if [[ -z "$MODIFIED_FILES" ]]; then
                    print_error "Nenhum arquivo modificado encontrado"
                    return 1
                fi
                
                local SELECTED_FILES=$(echo "$MODIFIED_FILES" | tb_fzf \
                    --multi \
                    --prompt="❯ Selecione os arquivos (TAB para múltiplos): " \
                    --height=60% \
                    --border=rounded \
                    --border-label=" 📁 Arquivos Modificados " \
                    --border-label-pos=3 \
                    --color="border:cyan,label:cyan:bold,prompt:magenta:bold" \
                    --pointer="▶" \
                    --marker="✓")
                
                if [[ -z "$SELECTED_FILES" ]]; then
                    print_warning "Nenhum arquivo selecionado"
                    return 0
                fi
                
                echo "$SELECTED_FILES" | while read file; do
                    git add "$file"
                done
                print_success "Arquivos selecionados adicionados"
                ;;
            *)
                print_info "Operação cancelada"
                return 0
                ;;
        esac
        echo ""
    fi

    local COMMIT_OPTIONS="10) 🤖 ci
9) ⚡ perf
8) 🏗️  build
7) 🎨 style
6) 🧪 test
5) 🔧 chore
4) 📚 docs
3) ♻️  refactor
2) 🐛 fix
1) ✨ feat"

    local SELECTED=$(echo "$COMMIT_OPTIONS" | tb_fzf \
        --prompt="❯ Selecione o tipo: " \
        --height=50% \
        --border=rounded \
        --border-label=" 📝 Tipo de Commit " \
        --border-label-pos=3 \
        --color="border:cyan,label:cyan:bold,prompt:magenta:bold" \
        --pointer="▶" \
        --marker="✓")

    if [[ -z "$SELECTED" ]]; then
        print_warning "Operação cancelada"
        return 0
    fi

    local pattern=$(echo "$SELECTED" | awk '{print $3}')
    local pattern_icon=$(echo "$SELECTED" | awk '{print $2}')
    
    echo ""
    print_success "Tipo selecionado: ${pattern_icon} ${bold}${pattern}${reset}"
    echo ""
    print_prompt "Digite a mensagem do commit:"
    
    read message
    
    if [[ -z "$message" ]]; then
        print_error "Mensagem do commit não pode ser vazia"
        return 1
    fi

    LAST_COMMIT=$(git log -1 --pretty=%B | grep -oP 'Pt\.\K\d+')

    if [[ -z "$LAST_COMMIT" ]]; then
        PART_NUMBER=1
    else
        PART_NUMBER=$((LAST_COMMIT + 1))
    fi

    TICKET_PART="Pt.$PART_NUMBER"

    show_loading "Efetuando commit" 1

    if git commit -m "Ticket #$TICKET_NUMBER ($TICKET_PART) - $pattern: $message" 2>/dev/null; then
        print_success "Commit efetuado com sucesso!"
        print_info "Mensagem: ${bold}Ticket #$TICKET_NUMBER ($TICKET_PART) - $pattern: $message${reset}"
    else
        print_error "Não foi possível efetuar o commit"
        sleep 2
        tput reset
        return 1
    fi

    echo ""
    local PUSH_CHOICE=$(printf "Não\nSim" | tb_fzf \
        --prompt="❯ Efetuar push? " \
        --height=30% \
        --border=rounded \
        --border-label=" 🚀 Push " \
        --border-label-pos=3 \
        --color="border:green,label:green:bold,prompt:magenta:bold" \
        --pointer="▶")

    if [[ "$PUSH_CHOICE" == "Sim" ]]; then
        push
    else
        print_info "Push cancelado"
    fi
}

# Desfazer o commit anterior
function soft() {
    if ! git rev-parse HEAD~1 >/dev/null 2>&1; then
        print_error "Não há commits anteriores para desfazer"
        return 1
    fi

    echo ""
    print_info "Último commit:"
    print_separator 60 "${cinza}"
    git log -1 --pretty=format:"%C(yellow)%h%Creset - %s%n%C(cyan)Autor:%Creset %an%n%C(cyan)Data:%Creset %ar" HEAD
    print_separator 60 "${cinza}"
    echo ""
    
    local CONFIRM=$(printf "Não\nSim" | tb_fzf \
        --prompt="❯ Desfazer este commit? " \
        --height=30% \
        --border=rounded \
        --border-label=" ⚠️  Confirmar Ação " \
        --border-label-pos=3 \
        --color="border:yellow,label:yellow:bold,prompt:magenta:bold" \
        --pointer="▶")

    if [[ "$CONFIRM" != "Sim" ]]; then
        print_info "Operação cancelada"
        return 0
    fi

    show_loading "Desfazendo o commit" 1

    if git reset --soft HEAD~1 2>/dev/null; then
        print_success "Commit desfeito com sucesso!"
        
        local STAGED_COUNT=$(git diff --cached --numstat | wc -l | xargs)
        if [[ "$STAGED_COUNT" -gt 0 ]]; then
            print_info "${bold}${STAGED_COUNT}${reset} arquivo(s) voltaram para staged"
        fi
    else
        print_error "Não foi possível desfazer o commit"
        return 1
    fi
}
