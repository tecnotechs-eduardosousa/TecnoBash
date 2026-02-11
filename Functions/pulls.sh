# pull rápido
function pull() {

  local branch
  
  print_info "Buscando branches disponíveis..."
  
  branch=$(git branch | grep -v 'ticket-' | sed 's/^..//' | \
     tb_fzf --prompt="▶ Selecione a branch: " \
     --pointer="→" \
     --border=rounded \
     --color="prompt:magenta,pointer:cyan,marker:green")

  if [[ -z "$branch" ]]; then
      print_warning "Nenhuma branch selecionada"
      sleep 0.7
      tput reset
      return 1
  fi

  show_loading "Executando git pull em ${bold}${branch}${reset}" 1

  if git pull tecnotechs "$branch" 2>/dev/null; then
      print_success "Pull executado com sucesso em Serviços na branch ${bold}${ciano}${branch}${reset}${verde}!${reset}"
  else
      print_error "Erro ao fazer pull em Serviços na branch ${bold}${branch}${reset}"
      sleep 0.7
      tput reset
      return 1
  fi
}


# função para dar um pull mais completo
function cpull() {
    print_prompt "Em Adapt e Serviços? (S/n):"
    read both

    if [[ -z "$both" ]]; then
        print_error "Opção inválida. Encerrando operação"
        sleep 0.6
        tput reset
        return 1
    fi

    if [[ "$both" == [Yy] ]]; then
    	local branch
    
        print_info "Buscando branches disponíveis..."
        
        branch=$(git branch | grep -v 'ticket-' | sed 's/^..//' | \
           tb_fzf --prompt="▶ Selecione a branch: " \
           --pointer="→" \
           --border=rounded \
           --color="prompt:magenta,pointer:cyan,marker:green")

        # Adapt
        print_info "Entrando na pasta Adapt..."
        sleep 0.3

        cd "$ADAPT_PATH"

        sleep 0.3
        tput reset

        show_loading "Executando git pull em Adapt na branch ${bold}${branch}${reset}" 1

        if git pull tecnotechs "$branch" 2>/dev/null; then
            tput reset
            print_success "Pull executado com sucesso em Adapt na branch ${bold}${ciano}${branch}${reset}${verde}!${reset}"
        else
            print_error "Erro ao fazer pull em Adapt na branch ${bold}${branch}${reset}"
            sleep 1
            tput reset
            return 1
        fi
        # 

        # Servicos
        print_info "Entrando na pasta Servicos..."
        sleep 0.3

        cd "$SERVICOS_PATH"

        sleep 0.3
        tput reset

        show_loading "Executando git pull em Serviços na branch ${bold}${branch}${reset}" 1

        if git pull tecnotechs "$branch" 2>/dev/null; then
            tput reset
            print_success "Pull executado com sucesso em Serviços na branch ${bold}${ciano}${branch}${reset}${verde}!${reset}"
        else
            print_error "Erro ao fazer pull em Serviços na branch ${bold}${branch}${reset}"
            sleep 1
            tput reset
            return 1
        fi

        tput reset
        print_success "Pull executado em Adapt e Serviços em ${bold}${ciano}${branch}${reset}${verde} com sucesso!${reset}"
        #
        
    elif [[ "$both" == [Nn] ]]; then
        print_prompt "Qual delas seria? (a/s):"
        read folder
        
    	local branch
    
        print_info "Buscando branches disponíveis..."
        
        branch=$(git branch | grep -v 'ticket-' | sed 's/^..//' | \
           tb_fzf --prompt="▶ Selecione a branch: " \
           --pointer="→" \
           --border=rounded \
           --color="prompt:magenta,pointer:cyan,marker:green")

        if [[ "$folder" == "a" ]]; then
            # Adapt
            print_info "Entrando na pasta Adapt..."
            sleep 0.3

            cd "$ADAPT_PATH"

            sleep 0.3
            tput reset

            show_loading "Executando git pull em Adapt na branch ${bold}${branch}${reset}" 1
            
            if git pull tecnotechs "$branch" 2>/dev/null; then
                tput reset
                print_success "Pull executado com sucesso em Adapt na branch ${bold}${ciano}${branch}${reset}${verde}!${reset}"
            else
                print_error "Erro ao fazer pull em Adapt na branch ${bold}${branch}${reset}"
                sleep 1
                tput reset
                return 1
            fi
            # 
        elif [[ "$folder" == "s" ]]; then
            # Servicos
            print_info "Entrando na pasta Servicos..."
            sleep 0.3

            cd "$SERVICOS_PATH"

            sleep 0.3
            tput reset

            show_loading "Executando git pull em Serviços na branch ${bold}${branch}${reset}" 1
            
            if git pull tecnotechs "$branch" 2>/dev/null; then
                tput reset
                print_success "Pull executado com sucesso em Serviços na branch ${bold}${ciano}${branch}${reset}${verde}!${reset}"
            else
                print_error "Erro ao fazer pull em Serviços na branch ${bold}${branch}${reset}"
                sleep 1
                tput reset
                return 1
            fi
        fi
    else 
        tput reset
        print_error "Opção inválida, operação cancelada"
        sleep 0.6
        return 1
    fi
}

# pull diário
function dp() {
    while true; do
        print_prompt "Gostaria de executar o pull diário? (s/n):"
        read resposta
        if [[ "$resposta" == "s" ]]; then
            # Adapt
            print_info "Entrando na pasta Adapt..."
            sleep 0.2

            cd "$ADAPT_PATH"

            print_info "Entrando na branch de Desenvolvimento (Adapt)..."
            sleep 0.2
            git switch Desenvolvimento

            show_loading "Executando git pull em Desenvolvimento (Adapt)" 1
            git pull tecnotechs Desenvolvimento

            if [[ $? -eq 0 ]]; then
                sleep 0.2
                tput reset
                print_success "Pull em Desenvolvimento (Adapt) executado com sucesso!"
                
                # Servicos
                print_info "Entrando na pasta Servicos..."
                sleep 0.2

            cd "$SERVICOS_PATH"

                print_info "Entrando na branch de Desenvolvimento (Servicos)..."
                sleep 0.2
                git switch Desenvolvimento

                show_loading "Executando git pull em Desenvolvimento (Servicos)" 1
                git pull tecnotechs Desenvolvimento

                if [[ $? -eq 0 ]]; then
                    sleep 0.2
                    tput reset
                    print_success "Pull em Desenvolvimento (Servicos) executado com sucesso!"

                    sleep 0.3
                    tput reset
                    print_success "${bold}Pull diário executado com sucesso em ambas as pastas!${reset}"

                    break
                else 
                    print_error "Falha ao executar git pull (Servicos)"
                    sleep 1
                    tput reset
                    break
                fi
            else 
                print_error "Falha ao executar git pull (Adapt)"
                sleep 1
                tput reset
                break
            fi
        elif [[ "$resposta" == "n" ]]; then
            tput reset
            print_warning "Git pull cancelado"
            sleep 1
            break
        else 
            print_error "Opção Inválida..."
            sleep 0.6
            tput reset
            continue
        fi

        cd "$PATH_TO_ADAPT"
    done
}
