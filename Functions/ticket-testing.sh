function tb_phpunit__print_header() {
    local title="$1"
    local width="${2:-76}"

    if command -v print_header >/dev/null 2>&1; then
        print_header "$title" "$width" "${rosa:-}"
        return 0
    fi

    printf "\n%s\n" "$title"
}

function tb_phpunit__print_label() {
    local label="$1"
    local value="$2"

    if command -v print_label >/dev/null 2>&1; then
        print_label "$label" "$value"
        return 0
    fi

    printf "%-18s %s\n" "${label}:" "$value"
}

function tb_phpunit__print_separator() {
    local width="${1:-76}"

    if command -v print_separator >/dev/null 2>&1; then
        print_separator "$width"
        return 0
    fi

    printf '%*s\n' "$width" '' | tr ' ' '-'
}

function tb_phpunit__usage() {
    local command_name="$1"
    local suite_label="$2"

    tb_phpunit__print_header "PHPUnit | ${suite_label}" 72
    echo "Uso: ${command_name} <nome_do_projeto> [arquivo|diretorio|classe] [args_do_phpunit]"
    echo "Exemplo: ${command_name} adapt"
    echo "Exemplo: ${command_name} adapt webservices"
    echo "Exemplo: ${command_name} adapt EntidadeClasseTest"
    echo "Exemplo: ${command_name} adapt webservices/EntidadeClasseTest.php --filter testListar"
}

function tb_phpunit__summary_value() {
    local summary_line="$1"
    local key="$2"

    printf '%s\n' "$summary_line" | sed -n "s/.*${key}: \([0-9][0-9]*\).*/\1/p"
}

function tb_phpunit__host_scope_root() {
    local project_dir="$1"
    local suite_dir="$2"

    printf '%s\n' "$HOME/Desenvolvimento/SITAC/$project_dir/tests_unit/$suite_dir"
}

function tb_phpunit__container_scope_root() {
    local project_dir="$1"
    local suite_dir="$2"

    printf '%s\n' "${TB_DOCKER_DATA_ROOT}/$project_dir/tests_unit/$suite_dir"
}

function tb_phpunit__resolve_target() {
    local project_dir="$1"
    local suite_dir="$2"
    local selector="$3"
    local host_root
    local container_root
    local candidate
    local -a matches

    host_root="$(tb_phpunit__host_scope_root "$project_dir" "$suite_dir")"
    container_root="$(tb_phpunit__container_scope_root "$project_dir" "$suite_dir")"

    if [[ -z "$selector" ]]; then
        printf '%s\n' "$container_root"
        return 0
    fi

    if [[ ! -d "$host_root" ]]; then
        printf '%s\n' "$container_root/$selector"
        return 0
    fi

    candidate="$host_root/$selector"
    if [[ -e "$candidate" ]]; then
        printf '%s\n' "$container_root/${selector#./}"
        return 0
    fi

    if [[ -e "${candidate}.php" ]]; then
        printf '%s\n' "$container_root/${selector#./}.php"
        return 0
    fi

    while IFS= read -r candidate; do
        [[ -n "$candidate" ]] && matches+=("${candidate#$host_root/}")
    done < <(find "$host_root" -type d \( -iname "$selector" -o -ipath "*${selector}*" \) | sort)

    if (( ${#matches[@]} == 0 )); then
        while IFS= read -r candidate; do
            [[ -n "$candidate" ]] && matches+=("${candidate#$host_root/}")
        done < <(find "$host_root" -type f \( -iname "$selector" -o -iname "${selector}.php" -o -iname "${selector}Test.php" -o -iname "*${selector}*.php" \) | sort)
    fi

    if (( ${#matches[@]} == 1 )); then
        printf '%s\n' "$container_root/${matches[1]}"
        return 0
    fi

    if (( ${#matches[@]} > 1 )); then
        print_warning "O alvo \"$selector\" combinou com mais de um caminho."
        printf '%s\n' "${matches[@]}" | sed 's/^/  - /'
        print_info "Refine o nome ou informe o caminho relativo completo."
        return 1
    fi

    print_error "Nenhum teste encontrado para \"$selector\" em $host_root"
    return 1
}

function tb_phpunit__print_issue_cards() {
    local output_file="$1"
    local project_dir="$2"
    local suite_dir="$3"
    local command_name="$4"

    awk -v project="$project_dir" -v suite="$suite_dir" -v command_name="$command_name" '
        function flush_issue(    i, line, message_count, joined, test_name, method_name, location, relative_path, focus_path) {
            if (header == "") {
                return
            }

            message_count = 0
            joined = ""
            location = ""

            for (i = 2; i <= block_count; i++) {
                line = block_lines[i]

                if (line ~ /^\/.*:[0-9]+$/) {
                    if (location == "" && line ~ /\/tests_unit\//) {
                        location = line
                    }
                    continue
                }

                if (line == "" || line ~ /^(FAILURES!|ERRORS!|Tests: |Time: |OK \()/) {
                    continue
                }

                issue_messages[++message_count] = line
            }

            test_name = header
            sub(/^[0-9]+\) /, "", test_name)

            method_name = test_name
            sub(/^.*::/, "", method_name)

            relative_path = location
            sub("^/data/" project "/tests_unit/" suite "/", "", relative_path)
            focus_path = relative_path
            sub(/:[0-9]+$/, "", focus_path)

            printf " [%s] %s\n", issue_index, test_name

            if (message_count >= 1) {
                printf "   Motivo : %s\n", issue_messages[1]
            }

            if (message_count >= 2) {
                joined = issue_messages[2]
                for (i = 3; i <= message_count; i++) {
                    joined = joined " | " issue_messages[i]
                }
                printf "   Detalhe: %s\n", joined
            }

            if (location != "") {
                printf "   Arquivo: %s\n", relative_path
                printf "   Foco   : %s %s %s --filter %s\n", command_name, project, focus_path, method_name
            } else {
                printf "   Foco   : %s %s --filter %s\n", command_name, project, method_name
            }

            printf "\n"

            delete issue_messages
            delete block_lines
            header = ""
            block_count = 0
        }

        /^[0-9]+\) / {
            flush_issue()
            issue_index = $1
            sub(/\)/, "", issue_index)
            header = $0
            block_lines[++block_count] = $0
            next
        }

        header != "" {
            if ($0 ~ /^There (was|were) [0-9]+ (failure|failures|error|errors)/) {
                next
            }
            block_lines[++block_count] = $0
        }

        END {
            flush_issue()
        }
    ' "$output_file"
}

function tb_phpunit__print_raw_failure() {
    local output_file="$1"

    tb_phpunit__print_separator 76
    sed -n '1,120p' "$output_file"
    tb_phpunit__print_separator 76
}

function tb_phpunit__run() {
    local suite_dir="$1"
    local suite_label="$2"
    local command_name="$3"
    shift 3

    local project_dir="$1"
    if [[ -z "$project_dir" ]]; then
        tb_phpunit__usage "$command_name" "$suite_label"
        return 1
    fi
    shift

    local selector=""
    if (( $# > 0 )) && [[ "$1" != -* ]]; then
        selector="$1"
        shift
    fi

    local -a extra_args
    extra_args=("$@")

    local target_path
    local bootstrap_path
    local output_file
    local exit_code
    local time_line
    local summary_line
    local tests_count
    local assertions_count
    local failures_count
    local errors_count
    local skipped_count
    local target_label

    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker não está disponível no shell atual."
        return 1
    fi

    if [[ -z "$TB_DOCKER_CONTAINER" || -z "$TB_DOCKER_DATA_ROOT" ]]; then
        print_error "TB_DOCKER_CONTAINER e TB_DOCKER_DATA_ROOT precisam estar definidos."
        return 1
    fi

    if ! docker inspect "$TB_DOCKER_CONTAINER" >/dev/null 2>&1; then
        print_error "Container \"$TB_DOCKER_CONTAINER\" não está acessível."
        return 1
    fi

    target_path="$(tb_phpunit__resolve_target "$project_dir" "$suite_dir" "$selector")" || return 1
    bootstrap_path="${TB_DOCKER_DATA_ROOT}/$project_dir/vendor/autoload.php"
    output_file="$(mktemp /tmp/tecnobash-phpunit.XXXXXX)"
    target_label="${selector:-todos os testes}"

    tb_phpunit__print_header "PHPUnit | ${suite_label}" 76
    tb_phpunit__print_label "Projeto" "$project_dir"
    tb_phpunit__print_label "Suite" "$suite_label"
    tb_phpunit__print_label "Alvo" "$target_label"
    tb_phpunit__print_label "Container" "$TB_DOCKER_CONTAINER"
    tb_phpunit__print_label "Bootstrap" "$bootstrap_path"
    if (( ${#extra_args[@]} > 0 )); then
        tb_phpunit__print_label "Args extras" "${extra_args[*]}"
    fi
    echo ""
    print_info "Executando PHPUnit..."

    docker exec -i "$TB_DOCKER_CONTAINER" ./phpunit --colors="never" --bootstrap "$bootstrap_path" "${extra_args[@]}" "$target_path" >"$output_file" 2>&1
    exit_code=$?

    time_line="$(grep -E '^Time: ' "$output_file" | tail -1)"
    summary_line="$(grep -E '^Tests: ' "$output_file" | tail -1)"

    if [[ -n "$summary_line" ]]; then
        tests_count="$(tb_phpunit__summary_value "$summary_line" "Tests")"
        assertions_count="$(tb_phpunit__summary_value "$summary_line" "Assertions")"
        failures_count="$(tb_phpunit__summary_value "$summary_line" "Failures")"
        errors_count="$(tb_phpunit__summary_value "$summary_line" "Errors")"
        skipped_count="$(tb_phpunit__summary_value "$summary_line" "Skipped")"
    else
        local ok_line
        ok_line="$(grep -E '^OK \(' "$output_file" | tail -1)"
        tests_count="$(printf '%s\n' "$ok_line" | sed -n 's/.*(\([0-9][0-9]*\) tests\{0,1\},.*/\1/p')"
        assertions_count="$(printf '%s\n' "$ok_line" | sed -n 's/.*tests\{0,1\}, \([0-9][0-9]*\) assertions\{0,1\}).*/\1/p')"
        failures_count=0
        errors_count=0
        skipped_count=0
    fi

    echo ""
    if [[ "$exit_code" -eq 0 ]]; then
        print_success "Suite aprovada."
    else
        print_error "Suite com falhas."
    fi

    [[ -n "$tests_count" ]] && tb_phpunit__print_label "Testes" "$tests_count"
    [[ -n "$assertions_count" ]] && tb_phpunit__print_label "Assertions" "$assertions_count"
    [[ -n "$failures_count" ]] && tb_phpunit__print_label "Failures" "${failures_count:-0}"
    [[ -n "$errors_count" ]] && tb_phpunit__print_label "Errors" "${errors_count:-0}"
    [[ -n "$skipped_count" && "$skipped_count" != "0" ]] && tb_phpunit__print_label "Skipped" "$skipped_count"
    [[ -n "$time_line" ]] && tb_phpunit__print_label "Tempo" "${time_line#Time: }"

    if [[ "$exit_code" -ne 0 ]]; then
        echo ""
        tb_phpunit__print_separator 76
        echo "Falhas detalhadas"
        tb_phpunit__print_separator 76
        tb_phpunit__print_issue_cards "$output_file" "$project_dir" "$suite_dir" "$command_name"

        if ! grep -Eq '^[0-9]+\) ' "$output_file"; then
            print_warning "O PHPUnit falhou antes de gerar um relatório estruturado."
            tb_phpunit__print_raw_failure "$output_file"
        fi
    fi

    rm -f "$output_file"
    return "$exit_code"
}

test() {
    tb_phpunit__run "unit" "Unitários" "test" "$@"
}

testi() {
    tb_phpunit__run "integration" "Integração" "testi" "$@"
}
