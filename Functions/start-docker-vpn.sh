

isVPNActive() {
    ACTIVE=$(nmcli connection show --active)
    echo "$ACTIVE" | grep -q program
    return $?
}

start() {
    # liga a vpn
    # echo -e "${azul} Ligando a VPN... ${reset}"

    # vpn='program'

    # if isVPNActive; then
    #     echo -e "${fundo_azul} VPN já está ativada. ${reset}"
    #     sleep 1
    #     clear
    # else
    #     OUTPUT_ERROR=$(nmcli connection up id $vpn) &&
    #     echo -e "${verde} VPN ligada com sucesso! ${reset}" || {
    #         echo -e "${vermelho} Falha ao ligar a VPN. ${reset}"
    #         echo -e "Mensagem de retorno: $OUTPUT_ERROR. ${reset}"
    #         sleep 1 
    #         clear
    #     }
    # fi

    echo -e "${marrom} Iniciando docker... ${reset}"

    docker start "$TB_DOCKER_CONTAINER" && 
    echo -e "${verde} Docker iniciado! ${reset}" || {
        echo -e "${vermelho} Falha ao tentar iniciar o Docker... ${reset}"
        sleep 2
        clear
        return 1
    }
    
    sleep 2
    clear
}
