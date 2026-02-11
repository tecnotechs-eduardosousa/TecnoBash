
function getPatternizedBranchByTicketNumber() {
    local TICKET_NUMBER="$1"
    local PATTERNIZED_BRANCH="ticket-$TICKET_NUMBER"

    echo "$PATTERNIZED_BRANCH"
}

function getVersionedBranch() {
    local PATTERNIZED_BRANCH="$1"
    local EXISTENT_BRANCHES=$(git branch --list "$PATTERNIZED_BRANCH*")
    local VERSIONED_BRANCH=""

    if [[ -z "$EXISTENT_BRANCHES" ]]; then
        VERSIONED_BRANCH="$PATTERNIZED_BRANCH"
    else 
        MAX_SUFFIX=1
        while read -r b; do
            b=$(echo "$b" | sed 's/^[* ]*//')

            SUFFIX=$(echo "$b" | sed -n "s/^ticket-$TICKET_NUMBER-\([0-9]\+\)$/\1/p")

            if [[ -n "$SUFFIX" ]] && (( SUFFIX >= MAX_SUFFIX )); then
                MAX_SUFFIX=$((SUFFIX + 1))
            fi
        done <<< "$EXISTING_BRANCHES"

        if [[ $MAX_SUFFIX -eq 1 ]]; then
            # Existe apenas a branch ticket-NUMBER
            VERSIONED_BRANCH="$PATTERNIZED_BRANCH-2"
        else
            VERSIONED_BRANCH="$PATTERNIZED_BRANCH-$MAX_SUFFIX"
        fi
    fi

    echo "$VERSIONED_BRANCH"
}

# Função para criar um ticket e entrar nele!
function crtkt() {
    while true; do
        print_prompt "Digite o número do Ticket:"
        read TICKET_NUMBER

        if [[ -z "$TICKET_NUMBER" ]]; then
            print_error "Nenhum número de ticket foi fornecido..."
            sleep 0.7
            clear
            continue
        fi

        local PATTERNIZED_BRANCH=$(getPatternizedBranchByTicketNumber "$TICKET_NUMBER")
        local BRANCH=$(getVersionedBranch "$PATTERNIZED_BRANCH")

        show_loading "Criando branch" 1
        
        if git switch -c "$BRANCH" 2>/dev/null; then
            print_success "Branch ${bold}${BRANCH}${reset}${verde} criada com sucesso!${reset}"
            print_info "Você está agora em: ${ciano}${BRANCH}${reset}"
        else
            print_error "Não foi possível criar/entrar na branch ${bold}${BRANCH}${reset}"
            sleep 2
            clear
            return 1
        fi

        break
    done
}

# Função para passar de um ticket para outro!
function tkt() {
    local BRANCH
    
    print_info "Buscando tickets disponíveis..."
    
    BRANCH=$(git branch --list 'ticket-*' | sed 's/^..//' | \
      tb_fzf --prompt="▶ Selecione um ticket: " \
      --pointer="→" \
      --border=rounded \
      --color="prompt:magenta,pointer:cyan,marker:green")
    
    if [[ -z "$BRANCH" ]]; then
        print_warning "Nenhuma branch selecionada"
        return 1
    fi
    
    show_loading "Mudando para ${BRANCH}" 1
    
    if git switch "$BRANCH" 2>/dev/null; then
        print_success "Agora você está em: ${bold}${ciano}${BRANCH}${reset}"
    else
        print_error "Falha ao tentar mudar para a branch: ${bold}${BRANCH}${reset}"
        return 1
    fi
}
