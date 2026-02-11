
crea() {
    if ! cd "$EXTRAS_PATH" 2>/dev/null; then
        print_error "Falha ao acessar $EXTRAS_PATH"
        return 1
    fi
    
    local crea
    
    print_info "Buscando CREAs disponíveis..."
    
    crea=$(git branch --list | sed 's/^..//' | \
      tb_fzf --prompt="▶ Selecione um CREA: " \
      --pointer="→" \
      --border=rounded \
      --color="prompt:magenta,pointer:cyan,marker:green")
    
    if [ -z "$crea" ]; then
        print_warning "Nenhum CREA foi informado"
        return 1
    fi

    arg=$(echo "$crea" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '[:lower:]' '[:upper:]')

    show_loading "Resetando repositório" 1
    if ! git reset --hard HEAD 2>/dev/null; then
        print_error "Falha ao resetar o repositório"
        return 1
    fi
    
    if ! git clean -f -d 2>/dev/null; then
        print_error "Falha ao limpar arquivos não rastreados"
        return 1
    fi
    
    print_info "Mudando para a branch ${bold}${ciano}${arg}${reset}"
    if ! git switch "$arg" 2>/dev/null; then
        print_error "Falha ao fazer switch para a branch ${bold}${arg}${reset}"
        return 1
    fi
    
    show_loading "Efetuando pull para ${bold}${arg}${reset}" 1
    if ! git pull origin "$arg" 2>/dev/null; then
        print_error "Falha ao tentar efetuar pull para a branch ${bold}${arg}${reset}"
        return 1
    fi
    
    if ! git reset --hard origin/$arg 2>/dev/null; then
        print_error "Falha ao sincronizar com a branch remota ${bold}${arg}${reset}"
        return 1
    fi

    show_loading "Copiando arquivo de configuração" 1
    if ! cp "$TECNO_BASH_FILES/configer_via_bash.php" "$ADAPT_PATH/lib/configer/configer_via_bash.php" 2>/dev/null; then
        print_error "Falha ao copiar configer_via_bash.php"
        return 1
    fi

    show_loading "Executando script PHP no container Docker" 1
    if ! docker exec -i "$TB_DOCKER_CONTAINER" php data/adapt/lib/configer/configer_via_bash.php $arg 2>/dev/null; then
        print_error "Falha ao executar o script PHP no container Docker"
        return 1
    fi

    if ! rm "$ADAPT_PATH/lib/configer/configer_via_bash.php" 2>/dev/null; then
        print_error "Falha ao remover o arquivo temporário"
        return 1
    fi

    sleep 0.5

    if ! cd "$ADAPT_PATH" 2>/dev/null; then
        print_error "Falha ao acessar o diretório $ADAPT_PATH"
        return 1
    fi

    print_success "Alterado para o ${bold}${ciano}${arg}${reset}${verde}!${reset}"

    tput reset
}
