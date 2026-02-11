test() {
    PROJECT_DIR=$1
    TEST_FILE=$2

    if [ -z "$PROJECT_DIR" ]; then
        echo "Uso: test <nome_do_projeto> [arquivo_de_teste]"
        echo "Exemplo: test adapt (para rodar todos os testes)"
        echo "Exemplo: test servicos ExemploTest (para rodar um arquivo específico)"
        return 1
    fi

    TEST_PATH="${TB_DOCKER_DATA_ROOT}/$PROJECT_DIR/tests_unit/unit/"

    if [ ! -z "$TEST_FILE" ]; then
        TEST_PATH="${TEST_PATH}${TEST_FILE}"
    fi

    docker exec -it "$TB_DOCKER_CONTAINER" ./phpunit --colors="always" --bootstrap "${TB_DOCKER_DATA_ROOT}/$PROJECT_DIR/vendor/autoload.php" "$TEST_PATH"
}

testi() {
    PROJECT_DIR=$1
    TEST_FILE=$2

    if [ -z "$PROJECT_DIR" ]; then
        echo "Uso: test <nome_do_projeto> [arquivo_de_teste]"
        echo "Exemplo: test adapt (para rodar todos os testes)"
        echo "Exemplo: test servicos ExemploTest (para rodar um arquivo específico)"
        return 1
    fi

    TEST_PATH="${TB_DOCKER_DATA_ROOT}/$PROJECT_DIR/tests_unit/integration/"

    if [ ! -z "$TEST_FILE" ]; then
        TEST_PATH="${TEST_PATH}${TEST_FILE}"
    fi

    docker exec -it "$TB_DOCKER_CONTAINER" ./phpunit --colors="always" --bootstrap "${TB_DOCKER_DATA_ROOT}/$PROJECT_DIR/vendor/autoload.php" "$TEST_PATH"
}
