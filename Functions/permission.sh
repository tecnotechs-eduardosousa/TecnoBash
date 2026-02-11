
# dar permissao
such() {
    echo -e "${azul} Qual o nome da pasta? ${reset}"
    read FILE

    sudo chmod 777 $FILE &&
    echo -e "${verde} Permissão dada com sucesso para $FILE! ${reset}" || {
        echo -e "${vermelho} Não foi possível dar permissão para $FILE... ${reset}"
        sleep 2
        clear
        return 1
    }
}