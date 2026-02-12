# ═══════════════════════════════════════════════════════════════
# TecnoBash - Paths Loader/Validator
# ═══════════════════════════════════════════════════════════════

TECNO_BASH_FILES="$HOME/TecnoBash"

ADAPT_PATH="$HOME/Desenvolvimento/SITAC/adapt"
SERVICOS_PATH="$HOME/Desenvolvimento/SITAC/servicos"
EXTRAS_PATH="$HOME/Desenvolvimento/SITAC/extras"

# SITAG_ADAPT_PATH="$HOME/Desenvolvimento/sitag/sitag-corp"
# SITAG_SERVICOS_PATH="$HOME/Desenvolvimento/sitag/sitag-serv"
# SITAG_EXTRAS_PATH="$HOME/Desenvolvimento/sitag/sitag-extras"

TB_DOCKER_DATA_ROOT="/data"
TB_DOCKER_CONTAINER="sitac"

function tb_load_paths() {
    local -a required_dirs=(
        TECNO_BASH_FILES
        ADAPT_PATH
        SERVICOS_PATH
        EXTRAS_PATH
        SITAG_ADAPT_PATH
        SITAG_SERVICOS_PATH
        SITAG_EXTRAS_PATH
    )

    local -a required_values=(
        TB_DOCKER_DATA_ROOT
        TB_DOCKER_CONTAINER
    )

    local var value
    for var in "${required_dirs[@]}"; do
        value="${(P)var}"
        if [[ -z "$value" ]]; then
            tb__paths_echo_error "Variável não definida: $var"
            return 1
        fi
        if [[ ! -d "$value" ]]; then
            tb__paths_echo_error "Diretório não encontrado para $var: $value"
            return 1
        fi
    done

    return 0
}

function tb__paths_echo_info() {
    if command -v print_info >/dev/null 2>&1; then
        print_info "$1"
    else
        echo "INFO: $1"
    fi
}

function tb__paths_echo_warn() {
    if command -v print_warning >/dev/null 2>&1; then
        print_warning "$1"
    else
        echo "AVISO: $1"
    fi
}

function tb__paths_echo_error() {
    if command -v print_error >/dev/null 2>&1; then
        print_error "$1"
    else
        echo "ERRO: $1"
    fi

    sleep 3
}