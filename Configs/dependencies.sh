# ═══════════════════════════════════════════════════════════════
# TecnoBash - Dependency Checker/Installer
# ═══════════════════════════════════════════════════════════════

TB_DEPS_REQUIRED=(
    git
    fzf
    awk
    sed
    grep
    sort
    comm
    mktemp
    wc
    tr
    seq
    tput
    clear
    sleep
    env
    printf
)

TB_DEPS_OPTIONAL=(
    docker
    nmcli
    jq
    sudo
)

function tb_list_dependencies() {
    echo "Dependências obrigatórias:"
    printf " - %s\n" "${TB_DEPS_REQUIRED[@]}"
    echo ""
    echo "Dependências opcionais:"
    printf " - %s\n" "${TB_DEPS_OPTIONAL[@]}"
}

function tb__detect_os() {
    local uname_out
    uname_out="$(uname -s 2>/dev/null)"
    case "$uname_out" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            echo "linux"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

function tb__detect_linux_pkg_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
        return 0
    fi
    if command -v dnf >/dev/null 2>&1; then
        echo "dnf"
        return 0
    fi
    echo "unknown"
}

function tb__missing_cmds() {
    local -a missing=()
    local cmd
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    printf "%s\n" "${missing[@]}"
}

function tb__install_linux_apt() {
    local -a pkgs=("$@")
    if [[ ${#pkgs[@]} -eq 0 ]]; then
        return 0
    fi
    sudo apt-get update -y >/dev/null 2>&1
    sudo apt-get install -y "${pkgs[@]}"
}

function tb__install_linux_dnf() {
    local -a pkgs=("$@")
    if [[ ${#pkgs[@]} -eq 0 ]]; then
        return 0
    fi
    sudo dnf install -y "${pkgs[@]}"
}

function tb__ensure_brew() {
    if command -v brew >/dev/null 2>&1; then
        return 0
    fi
    print_info "Homebrew não encontrado. Instalando..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if command -v brew >/dev/null 2>&1; then
        return 0
    fi
    print_error "Falha ao instalar o Homebrew."
    return 1
}

function tb__install_macos_brew() {
    local -a pkgs=("$@")
    if [[ ${#pkgs[@]} -eq 0 ]]; then
        return 0
    fi
    brew install "${pkgs[@]}"
}

function tb__install_macos_casks() {
    local -a casks=("$@")
    if [[ ${#casks[@]} -eq 0 ]]; then
        return 0
    fi
    brew install --cask "${casks[@]}"
}

function tb__map_required_apt() {
    local -a pkgs=()
    local dep
    for dep in "$@"; do
        case "$dep" in
            git)
                pkgs+=("git")
                ;;
            fzf)
                pkgs+=("fzf")
                ;;
            awk)
                pkgs+=("gawk")
                ;;
            sed)
                pkgs+=("sed")
                ;;
            grep)
                pkgs+=("grep")
                ;;
            sort|comm|mktemp|wc|tr|seq|env|printf|clear|sleep)
                pkgs+=("coreutils")
                ;;
            tput)
                pkgs+=("ncurses-bin")
                ;;
        esac
    done
    printf "%s\n" "${pkgs[@]}"
}

function tb__map_required_dnf() {
    local -a pkgs=()
    local dep
    for dep in "$@"; do
        case "$dep" in
            git)
                pkgs+=("git")
                ;;
            fzf)
                pkgs+=("fzf")
                ;;
            awk)
                pkgs+=("gawk")
                ;;
            sed)
                pkgs+=("sed")
                ;;
            grep)
                pkgs+=("grep")
                ;;
            sort|comm|mktemp|wc|tr|seq|env|printf|clear|sleep)
                pkgs+=("coreutils")
                ;;
            tput)
                pkgs+=("ncurses")
                ;;
        esac
    done
    printf "%s\n" "${pkgs[@]}"
}

function tb__map_required_macos() {
    local -a brew_pkgs=()
    local dep
    for dep in "$@"; do
        case "$dep" in
            git)
                brew_pkgs+=("git")
                ;;
            fzf)
                brew_pkgs+=("fzf")
                ;;
            awk)
                brew_pkgs+=("gawk")
                ;;
            sed)
                brew_pkgs+=("gnu-sed")
                ;;
            grep)
                brew_pkgs+=("grep")
                ;;
            sort|comm|mktemp|wc|tr|seq|env|printf|clear|sleep)
                brew_pkgs+=("coreutils")
                ;;
            tput)
                brew_pkgs+=("ncurses")
                ;;
        esac
    done
    printf "%s\n" "${brew_pkgs[@]}"
}

function tb_install_dependencies() {
    local -a required_missing=("$@")
    local -a pkgs=()
    local os pkg_mgr
    os="$(tb__detect_os)"

    if [[ "$os" == "linux" ]]; then
        pkg_mgr="$(tb__detect_linux_pkg_manager)"
        case "$pkg_mgr" in
            apt)
                pkgs=($(tb__map_required_apt "${required_missing[@]}"))
                if [[ ${#pkgs[@]} -eq 0 ]]; then
                    print_error "Sem pacotes mapeados para instalar dependências obrigatórias."
                    return 1
                fi
                tb__install_linux_apt "${pkgs[@]}"
                ;;
            dnf)
                pkgs=($(tb__map_required_dnf "${required_missing[@]}"))
                if [[ ${#pkgs[@]} -eq 0 ]]; then
                    print_error "Sem pacotes mapeados para instalar dependências obrigatórias."
                    return 1
                fi
                tb__install_linux_dnf "${pkgs[@]}"
                ;;
            *)
                print_error "Gerenciador de pacotes não suportado (apt/dnf)."
                return 1
                ;;
        esac
        return $?
    fi

    if [[ "$os" == "macos" ]]; then
        if ! tb__ensure_brew; then
            return 1
        fi
        pkgs=($(tb__map_required_macos "${required_missing[@]}"))
        if [[ ${#pkgs[@]} -eq 0 ]]; then
            print_error "Sem pacotes mapeados para instalar dependências obrigatórias."
            return 1
        fi
        tb__install_macos_brew "${pkgs[@]}"
        return $?
    fi

    print_error "Sistema operacional não suportado para instalação automática."
    return 1
}

function tb__map_optional_linux() {
    local -a pkgs=()
    local dep
    for dep in "$@"; do
        case "$dep" in
            docker)
                pkgs+=("docker.io")
                ;;
            nmcli)
                pkgs+=("network-manager")
                ;;
            jq)
                pkgs+=("jq")
                ;;
            sudo)
                pkgs+=("sudo")
                ;;
        esac
    done
    printf "%s\n" "${pkgs[@]}"
}

function tb__map_optional_dnf() {
    local -a pkgs=()
    local dep
    for dep in "$@"; do
        case "$dep" in
            docker)
                pkgs+=("docker")
                ;;
            nmcli)
                pkgs+=("NetworkManager")
                ;;
            jq)
                pkgs+=("jq")
                ;;
            sudo)
                pkgs+=("sudo")
                ;;
        esac
    done
    printf "%s\n" "${pkgs[@]}"
}

function tb__map_optional_macos() {
    local -a brew_pkgs=()
    local -a brew_casks=()
    local dep
    for dep in "$@"; do
        case "$dep" in
            docker)
                brew_casks+=("docker")
                ;;
            jq)
                brew_pkgs+=("jq")
                ;;
            nmcli)
                ;;
            sudo)
                ;;
        esac
    done
    printf "%s\n" "${brew_pkgs[@]}"
    echo "::casks::"
    printf "%s\n" "${brew_casks[@]}"
}

function tb_ensure_dependencies() {
    if [[ -n "${TB_DEPS_CHECKED:-}" ]]; then
        return 0
    fi

    local -a missing_required
    local -a missing_optional
    local os pkg_mgr

    missing_required=($(tb__missing_cmds "${TB_DEPS_REQUIRED[@]}"))
    missing_optional=($(tb__missing_cmds "${TB_DEPS_OPTIONAL[@]}"))

    if [[ ${#missing_required[@]} -gt 0 ]]; then
        print_info "Instalando dependências obrigatórias..."
        if ! tb_install_dependencies "${missing_required[@]}"; then
            print_error "Falha ao instalar dependências obrigatórias."
            return 1
        fi
    fi

    # Recheck required after install
    missing_required=($(tb__missing_cmds "${TB_DEPS_REQUIRED[@]}"))
    if [[ ${#missing_required[@]} -gt 0 ]]; then
        print_error "Dependências obrigatórias ainda ausentes: ${missing_required[*]}"
        return 1
    fi

    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        os="$(tb__detect_os)"
        if [[ "$os" == "linux" ]]; then
            pkg_mgr="$(tb__detect_linux_pkg_manager)"
            if [[ "$pkg_mgr" == "apt" ]]; then
                local -a opt_pkgs
                opt_pkgs=($(tb__map_optional_linux "${missing_optional[@]}"))
                if [[ ${#opt_pkgs[@]} -gt 0 ]]; then
                    print_info "Instalando dependências opcionais..."
                    tb__install_linux_apt "${opt_pkgs[@]}" >/dev/null 2>&1 || true
                fi
            elif [[ "$pkg_mgr" == "dnf" ]]; then
                local -a opt_pkgs
                opt_pkgs=($(tb__map_optional_dnf "${missing_optional[@]}"))
                if [[ ${#opt_pkgs[@]} -gt 0 ]]; then
                    print_info "Instalando dependências opcionais..."
                    tb__install_linux_dnf "${opt_pkgs[@]}" >/dev/null 2>&1 || true
                fi
            fi
        elif [[ "$os" == "macos" ]]; then
            if tb__ensure_brew; then
                local -a brew_pkgs
                local -a brew_casks
                local marker_seen=0
                while read -r line; do
                    if [[ "$line" == "::casks::" ]]; then
                        marker_seen=1
                        continue
                    fi
                    if [[ $marker_seen -eq 0 ]]; then
                        [[ -n "$line" ]] && brew_pkgs+=("$line")
                    else
                        [[ -n "$line" ]] && brew_casks+=("$line")
                    fi
                done < <(tb__map_optional_macos "${missing_optional[@]}")

                if [[ ${#brew_pkgs[@]} -gt 0 ]]; then
                    print_info "Instalando dependências opcionais..."
                    tb__install_macos_brew "${brew_pkgs[@]}" >/dev/null 2>&1 || true
                fi
                if [[ ${#brew_casks[@]} -gt 0 ]]; then
                    print_info "Instalando dependências opcionais (cask)..."
                    tb__install_macos_casks "${brew_casks[@]}" >/dev/null 2>&1 || true
                fi
            fi
        fi
    fi

    # Recheck optional to report
    missing_optional=($(tb__missing_cmds "${TB_DEPS_OPTIONAL[@]}"))
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        print_warning "Dependências opcionais ausentes: ${missing_optional[*]}"
        print_info "Algumas funções podem não funcionar sem essas dependências."
    fi

    TB_DEPS_CHECKED=1
    return 0
}
