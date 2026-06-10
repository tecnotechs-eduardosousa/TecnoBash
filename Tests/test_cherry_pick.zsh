#!/usr/bin/env zsh

# =============================================================================
# Testes para Functions/cherry-pick.sh
# Execução: zsh Tests/test_cherry_pick.zsh
# =============================================================================

# ── Cores ANSI ───────────────────────────────────────────────────────────────
local green="\033[32m"
local red="\033[31m"
local yellow="\033[33m"
local cyan="\033[36m"
local bold="\033[1m"
local reset="\033[0m"

# ── Mocks ────────────────────────────────────────────────────────────────────
# Mock de funções visuais (substitui Design/visual.sh)
print_error() { echo "${red}[ERROR]${reset} $*" >&2 }
print_warning() { echo "${yellow}[WARNING]${reset} $*" >&2 }
print_info() { echo "${cyan}[INFO]${reset} $*" >&2 }
print_success() { echo "${green}[SUCCESS]${reset} $*" >&2 }
show_loading() { : }  # noop — evita background process nos testes

# Mock de tb_fzf — comportamento controlado pela variável MOCK_FZF_RESULT
# Se MOCK_FZF_RESULT estiver definido, retorna seu valor; senão, retorna vazio (simula cancelamento)
tb_fzf() {
    if [[ -n "$MOCK_FZF_RESULT" ]]; then
        echo "$MOCK_FZF_RESULT"
    fi
}

# Source o módulo de cherry-pick
source "${0:A:h}/../Functions/cherry-pick.sh" 2>/dev/null

# ── Contadores ───────────────────────────────────────────────────────────────
local passed=0 failed=0 total=0

# ── Helpers ──────────────────────────────────────────────────────────────────
setup_repo() {
    local dir=$(mktemp -d)
    git -C "$dir" init -q -b master
    git -C "$dir" config user.email "test@test.com"
    git -C "$dir" config user.name "Test"
    echo "$dir"
}

make_commit() {
    local msg="$1"
    echo "$msg" >> file.txt
    git add file.txt
    git commit -q -m "$msg"
}

assert_eq() {
    local test_name="$1" expected="$2" actual="$3"
    ((total++))
    if [[ "$actual" == "$expected" ]]; then
        echo "  ${green}✓ PASS:${reset} ${test_name}"
        ((passed++))
    else
        echo "  ${red}✗ FAIL:${reset} ${test_name}"
        echo "         expected: ${expected}"
        echo "         actual:   ${actual}"
        ((failed++))
    fi
}

assert_return() {
    local test_name="$1" expected="$2" actual="$3"
    ((total++))
    if [[ "$actual" == "$expected" ]]; then
        echo "  ${green}✓ PASS:${reset} ${test_name} (exit code: ${actual})"
        ((passed++))
    else
        echo "  ${red}✗ FAIL:${reset} ${test_name} (expected exit ${expected}, got ${actual})"
        ((failed++))
    fi
}

assert_contains() {
    local test_name="$1" needle="$2" haystack="$3"
    ((total++))
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "  ${green}✓ PASS:${reset} ${test_name}"
        ((passed++))
    else
        echo "  ${red}✗ FAIL:${reset} ${test_name}"
        echo "         expected to contain: ${needle}"
        echo "         actual: ${haystack}"
        ((failed++))
    fi
}

assert_line_count() {
    local test_name="$1" expected="$2" actual_text="$3"
    local count=$(echo "$actual_text" | wc -l | tr -d ' ')
    ((total++))
    if [[ "$count" == "$expected" ]]; then
        echo "  ${green}✓ PASS:${reset} ${test_name} (${count} linhas)"
        ((passed++))
    else
        echo "  ${red}✗ FAIL:${reset} ${test_name} (expected ${expected} linhas, got ${count})"
        ((failed++))
    fi
}

# Salvar diretório original
local ORIG_DIR=$(pwd)

echo ""
echo "  ${bold}Testes: Cherry-Pick Interativo (cherry-pick.sh)${reset}"
echo "  ${cyan}══════════════════════════════════════════════════════════════════${reset}"
echo ""

# ═════════════════════════════════════════════════════════════════
# tb__cpick_list_commits
# ═════════════════════════════════════════════════════════════════
echo "${yellow}${bold}═ tb__cpick_list_commits ═${reset}"
echo ""

# ─────────────────────────────────────────────────────
# Cenário A: Lista commits de uma branch existente
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário A: Lista commits de uma branch com 3 commits${reset}"
local repo1=$(setup_repo)
cd "$repo1"
make_commit "feat: primeiro commit"
make_commit "fix: segundo commit"
make_commit "docs: terceiro commit"
local result
result=$(tb__cpick_list_commits "master" 2>/dev/null)
local rc=$?
assert_return "exit code 0" "0" "$rc"
assert_line_count "3 commits listados" "3" "$result"
assert_contains "contém hash + mensagem do terceiro" "terceiro commit" "$result"
cd "$ORIG_DIR"
rm -rf "$repo1"
echo ""

# ─────────────────────────────────────────────────────
# Cenário B: Branch inexistente retorna erro
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário B: Branch inexistente retorna erro${reset}"
local repo2=$(setup_repo)
cd "$repo2"
make_commit "initial commit"
tb__cpick_list_commits "branch-que-nao-existe" >/dev/null 2>&1
local rc=$?
assert_return "exit code 1 para branch inexistente" "1" "$rc"
cd "$ORIG_DIR"
rm -rf "$repo2"
echo ""

# ─────────────────────────────────────────────────────
# Cenário C: Limita a 50 commits
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário C: Limita a 50 commits máximo${reset}"
local repo3=$(setup_repo)
cd "$repo3"
for i in $(seq 1 60); do
    make_commit "commit número $i"
done
local result
result=$(tb__cpick_list_commits "master" 2>/dev/null)
local rc=$?
assert_return "exit code 0" "0" "$rc"
assert_line_count "máximo 50 commits" "50" "$result"
cd "$ORIG_DIR"
rm -rf "$repo3"
echo ""

# ─────────────────────────────────────────────────────
# Cenário D: Formato correto (hash mensagem (data))
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário D: Formato correto do output${reset}"
local repo4=$(setup_repo)
cd "$repo4"
make_commit "feat: implementar algo"
local result
result=$(tb__cpick_list_commits "master" 2>/dev/null)
local first_line=$(echo "$result" | head -1)
# Deve ter hash (7+ chars hex), mensagem, e data entre parênteses
local has_hash=$([[ "$first_line" =~ ^[a-f0-9]+ ]] && echo "yes" || echo "no")
local has_parens=$([[ "$first_line" == *"("*")"* ]] && echo "yes" || echo "no")
assert_eq "linha começa com hash" "yes" "$has_hash"
assert_eq "linha contém data entre parênteses" "yes" "$has_parens"
assert_contains "contém a mensagem do commit" "feat: implementar algo" "$first_line"
cd "$ORIG_DIR"
rm -rf "$repo4"
echo ""

# ─────────────────────────────────────────────────────
# Cenário E: Diretório sem git
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário E: Diretório sem repositório git${reset}"
local repo5=$(mktemp -d)
cd "$repo5"
tb__cpick_list_commits "master" >/dev/null 2>&1
local rc=$?
assert_return "exit code 1 sem repo git" "1" "$rc"
cd "$ORIG_DIR"
rm -rf "$repo5"
echo ""

# ═════════════════════════════════════════════════════════════════
# tb__cpick_select_mode (com mock de tb_fzf)
# ═════════════════════════════════════════════════════════════════
echo "${yellow}${bold}═ tb__cpick_select_mode ═${reset}"
echo ""

# ─────────────────────────────────────────────────────
# Cenário F: Seleção de modo único
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário F: Seleção retorna 'single' para Cherry-pick único${reset}"
MOCK_FZF_RESULT="Cherry-pick único"
local result
result=$(tb__cpick_select_mode 2>/dev/null)
local rc=$?
assert_return "exit code 0" "0" "$rc"
assert_eq "retorna 'single'" "single" "$result"
unset MOCK_FZF_RESULT
echo ""

# ─────────────────────────────────────────────────────
# Cenário G: Seleção de modo múltiplo
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário G: Seleção retorna 'multi' para Cherry-pick múltiplo${reset}"
MOCK_FZF_RESULT="Cherry-pick múltiplo"
local result
result=$(tb__cpick_select_mode 2>/dev/null)
local rc=$?
assert_return "exit code 0" "0" "$rc"
assert_eq "retorna 'multi'" "multi" "$result"
unset MOCK_FZF_RESULT
echo ""

# ─────────────────────────────────────────────────────
# Cenário H: Cancelamento retorna exit 1
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário H: Cancelamento (fzf vazio) retorna exit 1${reset}"
MOCK_FZF_RESULT=""
tb__cpick_select_mode >/dev/null 2>&1
local rc=$?
assert_return "exit code 1 no cancelamento" "1" "$rc"
unset MOCK_FZF_RESULT
echo ""

# ═════════════════════════════════════════════════════════════════
# tb__cpick_select_branch (com mock de tb_fzf)
# ═════════════════════════════════════════════════════════════════
echo "${yellow}${bold}═ tb__cpick_select_branch ═${reset}"
echo ""

# ─────────────────────────────────────────────────────
# Cenário I: Seleciona branch com sucesso
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário I: Seleciona branch de origem com sucesso${reset}"
local repo6=$(setup_repo)
cd "$repo6"
make_commit "initial"
git checkout -q -b feature-branch
make_commit "feature commit"
git checkout -q master
MOCK_FZF_RESULT="feature-branch"
local result
result=$(tb__cpick_select_branch 2>/dev/null)
local rc=$?
assert_return "exit code 0" "0" "$rc"
assert_eq "retorna 'feature-branch'" "feature-branch" "$result"
unset MOCK_FZF_RESULT
cd "$ORIG_DIR"
rm -rf "$repo6"
echo ""

# ─────────────────────────────────────────────────────
# Cenário J: Sem outras branches disponíveis
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário J: Sem outras branches (apenas a atual)${reset}"
local repo7=$(setup_repo)
cd "$repo7"
make_commit "initial"
MOCK_FZF_RESULT=""
tb__cpick_select_branch >/dev/null 2>&1
local rc=$?
assert_return "exit code 1 sem outras branches" "1" "$rc"
unset MOCK_FZF_RESULT
cd "$ORIG_DIR"
rm -rf "$repo7"
echo ""

# ─────────────────────────────────────────────────────
# Cenário K: Cancelamento na seleção de branch
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário K: Cancelamento na seleção de branch${reset}"
local repo8=$(setup_repo)
cd "$repo8"
make_commit "initial"
git checkout -q -b outra-branch
make_commit "outro commit"
git checkout -q master
MOCK_FZF_RESULT=""
tb__cpick_select_branch >/dev/null 2>&1
local rc=$?
assert_return "exit code 1 no cancelamento" "1" "$rc"
unset MOCK_FZF_RESULT
cd "$ORIG_DIR"
rm -rf "$repo8"
echo ""

# ═════════════════════════════════════════════════════════════════
# Cherry-pick integrado (single mode com mock)
# ═════════════════════════════════════════════════════════════════
echo "${yellow}${bold}═ Cherry-pick integrado ═${reset}"
echo ""

# ─────────────────────────────────────────────────────
# Cenário L: Cherry-pick single com sucesso
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário L: Cherry-pick único aplicado com sucesso${reset}"
local repo9=$(setup_repo)
cd "$repo9"
make_commit "initial commit"
git checkout -q -b source-branch
make_commit "feat: nova funcionalidade"
local commit_hash=$(git log --format='%h' -1)
git checkout -q master

# Mock tb_fzf para retornar a linha do commit
MOCK_FZF_RESULT="${commit_hash} feat: nova funcionalidade (2 seconds ago)"
tb__cpick_single "source-branch" 2>/dev/null
local rc=$?

# Verificar que o commit foi aplicado na master
local main_log=$(git log --oneline -1)
assert_return "exit code 0 (sucesso)" "0" "$rc"
assert_contains "commit aplicado na branch master" "nova funcionalidade" "$main_log"
unset MOCK_FZF_RESULT
cd "$ORIG_DIR"
rm -rf "$repo9"
echo ""

# ─────────────────────────────────────────────────────
# Cenário M: Cherry-pick multi com sucesso (ordem cronológica)
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário M: Cherry-pick múltiplo aplica em ordem cronológica${reset}"
local repo10=$(setup_repo)
cd "$repo10"
make_commit "initial commit"
git checkout -q -b source-branch
make_commit "feat: primeiro"
local hash1=$(git log --format='%h' -1)
make_commit "feat: segundo"
local hash2=$(git log --format='%h' -1)
make_commit "feat: terceiro"
local hash3=$(git log --format='%h' -1)
git checkout -q master

# Mock tb_fzf — simula seleção de 3 commits (ordem mais recente primeiro, como fzf retorna)
MOCK_FZF_RESULT="${hash3} feat: terceiro (2 seconds ago)
${hash2} feat: segundo (2 seconds ago)
${hash1} feat: primeiro (2 seconds ago)"
tb__cpick_multi "source-branch" 2>/dev/null
local rc=$?

# Verificar que todos os 3 commits foram aplicados
local commit_count=$(git log --oneline | wc -l | tr -d ' ')
assert_return "exit code 0" "0" "$rc"
assert_eq "4 commits na master (1 initial + 3 cherry-picks)" "4" "$commit_count"

# Verificar ordem cronológica (mais antigo primeiro)
local log_msg_2=$(git log --oneline --skip=2 --max-count=1)
local log_msg_0=$(git log --oneline --max-count=1)
assert_contains "segundo commit é o mais antigo (primeiro aplicado)" "primeiro" "$log_msg_2"
assert_contains "último commit é o mais recente (terceiro aplicado)" "terceiro" "$log_msg_0"
unset MOCK_FZF_RESULT
cd "$ORIG_DIR"
rm -rf "$repo10"
echo ""

# ─────────────────────────────────────────────────────
# Cenário N: Cherry-pick com conflito
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário N: Cherry-pick com conflito retorna warning${reset}"
local repo11=$(setup_repo)
cd "$repo11"
echo "linha original" > conflito.txt
git add conflito.txt
git commit -q -m "initial: arquivo base"
git checkout -q -b source-branch
echo "mudança na source" > conflito.txt
git add conflito.txt
git commit -q -m "feat: mudança conflitante"
local conflict_hash=$(git log --format='%h' -1)
git checkout -q master
echo "mudança na master" > conflito.txt
git add conflito.txt
git commit -q -m "fix: mudança na master"

# Tentar cherry-pick que vai conflitar
MOCK_FZF_RESULT="${conflict_hash} feat: mudança conflitante (2 seconds ago)"
local output=$(tb__cpick_single "source-branch" 2>&1)

assert_contains "output menciona conflito" "Conflito" "$output"
assert_contains "output menciona cherry-pick --continue" "--continue" "$output"
assert_contains "output menciona cherry-pick --abort" "--abort" "$output"

# Limpar estado de conflito
git cherry-pick --abort 2>/dev/null
unset MOCK_FZF_RESULT
cd "$ORIG_DIR"
rm -rf "$repo11"
echo ""

# ─────────────────────────────────────────────────────
# Cenário O: Cherry-pick multi com conflito no meio
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário O: Multi cherry-pick para no conflito e reporta${reset}"
local repo12=$(setup_repo)
cd "$repo12"
echo "base" > conflito.txt
git add conflito.txt
git commit -q -m "initial"
git checkout -q -b source-branch
make_commit "feat: commit sem conflito"
local hash_ok=$(git log --format='%h' -1)
echo "conflitante" > conflito.txt
git add conflito.txt
git commit -q -m "feat: commit conflitante"
local hash_conflict=$(git log --format='%h' -1)
git checkout -q master
echo "master mudou" > conflito.txt
git add conflito.txt
git commit -q -m "fix: master muda arquivo"

# Simula seleção em ordem mais-recente-primeiro (tac vai inverter)
MOCK_FZF_RESULT="${hash_conflict} feat: commit conflitante (2 seconds ago)
${hash_ok} feat: commit sem conflito (2 seconds ago)"
tb__cpick_multi "source-branch" >/dev/null 2>&1
local rc=$?

assert_return "exit code 1 (conflito)" "1" "$rc"

# Limpar estado
git cherry-pick --abort 2>/dev/null
unset MOCK_FZF_RESULT
cd "$ORIG_DIR"
rm -rf "$repo12"
echo ""

# ═══════════════════════════════════════════════════════
# Resultado final
# ═══════════════════════════════════════════════════════
echo "  ${cyan}══════════════════════════════════════════════════════════════════${reset}"
echo ""
echo "  Resultado: ${green}${passed} passed${reset} / ${red}${failed} failed${reset} / ${total} total"
echo ""

# Exit code para uso em CI/automação
[[ $failed -eq 0 ]]
