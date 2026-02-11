
# push rápido
push() {
    local BRANCH=$(git branch --show-current)

    if [[ -z "$BRANCH" ]]; then
        print_error "Não foi possível verificar a branch atual"
        sleep 2
        tput reset
        return 1
    fi 

    show_loading "Efetuando push em ${bold}${BRANCH}${reset}" 1

    if git push origin "$BRANCH" 2>/dev/null; then
        print_success "Push em ${bold}${ciano}${BRANCH}${reset}${verde} realizado com sucesso!${reset}"
    else
        print_error "Não foi possível efetuar o push em ${bold}${BRANCH}${reset}"
        sleep 0.7
        tput reset
        return 1
    fi
}