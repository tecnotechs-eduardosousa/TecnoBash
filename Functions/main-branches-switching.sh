
function dev() {
    print_info "Entrando na branch Desenvolvimento..."
    sleep 0.4

    if git switch Desenvolvimento 2>/dev/null; then
        print_success "Agora você está em: ${bold}${ciano}Desenvolvimento${reset}"
    else
        print_error "Não foi possível entrar na branch Desenvolvimento"
        sleep 0.8
        clear
        return 1
    fi

    # Caso tenha entrado na branch desenvolvimento
    show_loading "Efetuando pull em Desenvolvimento" 1

    if git pull tecnotechs Desenvolvimento 2>/dev/null; then
        print_success "Pull efetuado com sucesso em ${bold}Desenvolvimento${reset}${verde}!${reset}"
    else
        print_error "Não foi possível efetuar pull em Desenvolvimento"
        sleep 2
        clear
        return 1
    fi
}

function prod() {
    print_info "Entrando na branch Producao..."
    sleep 0.4

    if git switch Producao 2>/dev/null; then
        print_success "Agora você está em: ${bold}${ciano}Producao${reset}"
    else
        print_error "Não foi possível entrar na branch Producao"
        sleep 0.8
        clear
        return 1
    fi

    # Caso tenha entrado na branch producao
    show_loading "Efetuando pull em Producao" 1

    if git pull tecnotechs Producao 2>/dev/null; then
        print_success "Pull efetuado com sucesso em ${bold}Producao${reset}${verde}!${reset}"
    else
        print_error "Não foi possível efetuar pull em Producao"
        sleep 2
        clear
        return 1
    fi
}