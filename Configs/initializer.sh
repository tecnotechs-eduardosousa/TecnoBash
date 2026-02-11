
# ═══════════════════════════════════════════════════════════════
# TecnoBash Initializer
# ═══════════════════════════════════════════════════════════════

function initializeForTecnoBash() {
    tb__bootstrap_repo_path || return 1
    getTecnoBashFiles
}

function tb__bootstrap_repo_path() {
    if [[ -n "$TECNO_BASH_FILES" ]]; then
        return 0
    fi

    local this_file this_dir trace_file

    if (( ${#funcfiletrace[@]} > 0 )); then
        trace_file="${funcfiletrace[1]%:*}"
        if [[ -f "$trace_file" ]]; then
            this_file="$trace_file"
        fi
    fi

    if [[ -z "$this_file" ]]; then
        this_file="${(%):-%x}"
        if [[ -z "$this_file" || ! -f "$this_file" ]]; then
            this_file="${(%):-%N}"
        fi
    fi

    if [[ -n "$this_file" && -f "$this_file" ]]; then
        this_file="${this_file:A}"
        this_dir="$(cd "$(dirname "$this_file")"/.. && pwd)"
        TECNO_BASH_FILES="$this_dir"
    else
        if [[ -f "./Configs/initializer.sh" ]]; then
            TECNO_BASH_FILES="$(pwd)"
        fi
    fi

    if [[ -z "$TECNO_BASH_FILES" ]]; then
        echo -e "${vermelho}ERRO: Não foi possível resolver o caminho do TecnoBash.${reset}";
        return 1
    fi

    if [[ "$TECNO_BASH_FILES" == "/" || "$TECNO_BASH_FILES" == "/home" || ! -f "$TECNO_BASH_FILES/Configs/initializer.sh" ]]; then
        echo -e "${vermelho}ERRO: Caminho inválido para TECNO_BASH_FILES: $TECNO_BASH_FILES${reset}";
        return 1
    fi
}

function getTecnoBashFiles() {
    if command -v tb_load_paths >/dev/null 2>&1; then
        tb_load_paths || return 1
    fi

    if [[ ! -d "$TECNO_BASH_FILES" ]]; then 
        echo -e "${vermelho}ERRO: Não foi possível achar os arquivos do TecnoBash.${reset}";
        sleep 2
        tput reset
        return 1
    fi

    getConfigsFiles
    getAttendantFile
    getDesignFiles
}

function getConfigsFiles() {
    if [[ -d "$TECNO_BASH_FILES/Configs" ]]; then
        local config_count=0
        for config_file in "$TECNO_BASH_FILES/Configs"/*.sh; do
            if [[ -f "$config_file" && "$config_file" ]]; then
                source "$config_file"
                ((config_count++))
            fi
        done
    fi
}

function getAttendantFile() {
    local attendant_file="$TECNO_BASH_FILES/Functions/attendant.sh"
    if [[ -f "$attendant_file" ]]; then
        source "$attendant_file"
    fi
}

function getDesignFiles() {
    if [[ -d "$TECNO_BASH_FILES/Design" ]]; then
        local function_count=0
        for function_file in "$TECNO_BASH_FILES/Design"/*.sh; do
            if [[ -f "$function_file" ]]; then
                source "$function_file"
                ((function_count++))
            fi
        done
    fi
}

function getSitagCorporativoPath() {
    if [[ -z "$SITAG_ADAPT_PATH" ]]; then 
        echo -e "${vermelho}ERRO: SITAG_ADAPT_PATH não definido.${reset}";
        sleep 2
        tput reset
        return 1
    fi

    if [[ ! -d "$SITAG_ADAPT_PATH" ]]; then
        echo -e "${vermelho}ERRO: Não foi possível achar a pasta do Corporativo do SITAG.${reset}";
        sleep 2
        tput reset
        return 1
    fi
}

function getAdaptPath() {
    if [[ -z "$ADAPT_PATH" ]]; then 
        echo -e "${vermelho}ERRO: ADAPT_PATH não definido.${reset}";
        sleep 2
        tput reset
        return 1
    fi

    if [[ ! -d "$ADAPT_PATH" ]]; then
        echo -e "${vermelho}ERRO: Não foi possível achar a pasta Adapt.${reset}";
        sleep 2
        tput reset
        return 1
    fi
}

function getSitagServicosPath() {
    if [[ -z "$SITAG_SERVICOS_PATH" ]]; then 
        echo -e "${vermelho}ERRO: SITAG_SERVICOS_PATH não definido.${reset}";
        sleep 2
        tput reset
        return 1
    fi

    if [[ ! -d "$SITAG_SERVICOS_PATH" ]]; then
        echo -e "${vermelho}ERRO: Não foi possível achar a pasta de Serviços do SITAG.${reset}";
        sleep 2
        tput reset
        return 1
    fi
}

function getServicosPath() {
    if [[ -z "$SERVICOS_PATH" ]]; then 
        echo -e "${vermelho}ERRO: SERVICOS_PATH não definido.${reset}";
        sleep 2
        tput reset
        return 1
    fi

    if [[ ! -d "$SERVICOS_PATH" ]]; then
        echo -e "${vermelho}ERRO: Não foi possível achar a pasta Serviços.${reset}";
        sleep 2
        tput reset
        return 1
    fi
}

function getSitagExtrasPath() {
    if [[ -z "$SITAG_EXTRAS_PATH" ]]; then 
        echo -e "${vermelho}ERRO: SITAG_EXTRAS_PATH não definido.${reset}";
        sleep 2
        tput reset
        return 1
    fi

    if [[ ! -d "$SITAG_EXTRAS_PATH" ]]; then
        echo -e "${vermelho}ERRO: Não foi possível achar a pasta Extras do SITAG.${reset}";
        sleep 2
        tput reset
        return 1
    fi
}

function getExtrasPath() {
    if [[ -z "$EXTRAS_PATH" ]]; then 
        echo -e "${vermelho}ERRO: EXTRAS_PATH não definido.${reset}";
        sleep 2
        tput reset
        return 1
    fi

    if [[ ! -d "$EXTRAS_PATH" ]]; then
        echo -e "${vermelho}ERRO: Não foi possível achar a pasta Extras.${reset}";
        sleep 2
        tput reset
        return 1
    fi
}

function getDockerConfiger() {
    if [[ -f "$TECNO_BASH_FILES/configer_via_bash.php" ]]; then
        source "$TECNO_BASH_FILES/configer_via_bash.php"
    fi
}