#!/usr/bin/env zsh

# =============================================================================
# Testes para tb__find_highest_part
# Execução: zsh Tests/test_find_highest_part.zsh
# =============================================================================

# ── Cores ANSI ───────────────────────────────────────────────────────────────
local green="\033[32m"
local red="\033[31m"
local yellow="\033[33m"
local cyan="\033[36m"
local bold="\033[1m"
local reset="\033[0m"

# Mock de print_warning (substitui a do Design/visual.sh)
print_warning() { echo "${yellow}[WARNING]${reset} $*" >&2 }

# Source apenas a função auxiliar
source "${0:A:h}/../Functions/commit.sh" 2>/dev/null

# Contadores
local passed=0 failed=0 total=0

# Helper: cria repo temporário (imprime path, caller faz cd)
setup_repo() {
    local dir=$(mktemp -d)
    git -C "$dir" init -q
    git -C "$dir" config user.email "test@test.com"
    git -C "$dir" config user.name "Test"
    echo "$dir"
}

# Helper: cria commit com mensagem específica (usa cwd)
make_commit() {
    local msg="$1"
    echo "$msg" >> file.txt
    git add file.txt
    git commit -q -m "$msg"
}

# Helper: assert
assert_eq() {
    local test_name="$1" expected="$2" actual="$3"
    ((total++))
    if [[ "$actual" == "$expected" ]]; then
        echo "  ${green}✓ PASS:${reset} ${test_name} → should return ${expected} (got ${actual})"
        ((passed++))
    else
        echo "  ${red}✗ FAIL:${reset} ${test_name} → should return ${expected} (got ${actual})"
        ((failed++))
    fi
}

# Salvar diretório original
local ORIG_DIR=$(pwd)

echo ""
echo "  ${bold}Validação Manual: tb__find_highest_part${reset}"
echo "  ${cyan}══════════════════════════════════════════════════════════════════${reset}"
echo ""

# ─────────────────────────────────────────────────────
# Cenário A: Commits normais sem merge
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário A: Commits normais (3 commits do ticket 42)${reset}"
local repo1=$(setup_repo)
cd "$repo1"
make_commit "Ticket #42 (Pt.1) - feat: primeiro"
make_commit "Ticket #42 (Pt.2) - fix: segundo"
make_commit "Ticket #42 (Pt.3) - refactor: terceiro"
local result=$(tb__find_highest_part 42)
assert_eq "3 commits Pt.1,2,3" "4" "$result"
cd "$ORIG_DIR"
rm -rf "$repo1"
echo ""

# ─────────────────────────────────────────────────────
# Cenário B: Commits intercalados de outros tickets
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário B: Commits de outros tickets intercalados${reset}"
local repo2=$(setup_repo)
cd "$repo2"
make_commit "Ticket #42 (Pt.1) - feat: inicio"
make_commit "Ticket #99 (Pt.5) - fix: outro ticket"
make_commit "Ticket #42 (Pt.2) - fix: continuação"
local result=$(tb__find_highest_part 42)
assert_eq "Ticket #42 Pt.1,2 with #99 in between" "3" "$result"
cd "$ORIG_DIR"
rm -rf "$repo2"
echo ""

# ─────────────────────────────────────────────────────
# Cenário C: Match exato (ticket 4 vs ticket 42)
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário C: Match exato (ticket 4 vs 42)${reset}"
local repo3=$(setup_repo)
cd "$repo3"
make_commit "Ticket #4 (Pt.1) - feat: ticket quatro"
make_commit "Ticket #4 (Pt.2) - fix: ticket quatro"
make_commit "Ticket #4 (Pt.3) - docs: ticket quatro"
make_commit "Ticket #42 (Pt.1) - feat: ticket quarenta e dois"
local result_42=$(tb__find_highest_part 42)
local result_4=$(tb__find_highest_part 4)
assert_eq "Ticket #4 Pt.3 + Ticket #42 Pt.1 → searching 42" "2" "$result_42"
assert_eq "Ticket #4 Pt.3 + Ticket #42 Pt.1 → searching 4" "4" "$result_4"
cd "$ORIG_DIR"
rm -rf "$repo3"
echo ""

# ─────────────────────────────────────────────────────
# Cenário D: Nenhum commit do ticket
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário D: Nenhum commit do ticket buscado${reset}"
local repo4=$(setup_repo)
cd "$repo4"
make_commit "Ticket #10 (Pt.1) - feat: outro"
make_commit "Ticket #20 (Pt.3) - fix: outro"
make_commit "Ticket #30 (Pt.2) - docs: outro"
make_commit "Ticket #50 (Pt.1) - chore: outro"
make_commit "Ticket #60 (Pt.4) - test: outro"
local result=$(tb__find_highest_part 42)
assert_eq "5 commits from other tickets" "1" "$result"
cd "$ORIG_DIR"
rm -rf "$repo4"
echo ""

# ─────────────────────────────────────────────────────
# Cenário E: Repo sem commits (vazio)
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário E: Repositório sem commits${reset}"
local repo5=$(setup_repo)
cd "$repo5"
local result=$(tb__find_highest_part 42)
assert_eq "Empty repo (no commits)" "1" "$result"
cd "$ORIG_DIR"
rm -rf "$repo5"
echo ""

# ─────────────────────────────────────────────────────
# Cenário F: Commit com Pt. malformado
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário F: Commit com Pt. malformado (Pt.abc)${reset}"
local repo6=$(setup_repo)
cd "$repo6"
make_commit "Ticket #42 (Pt.abc) - feat: malformado"
make_commit "Ticket #42 (Pt.2) - fix: valido"
local result=$(tb__find_highest_part 42)
assert_eq "Pt.abc ignored, only Pt.2 valid" "3" "$result"
cd "$ORIG_DIR"
rm -rf "$repo6"
echo ""

# ─────────────────────────────────────────────────────
# Cenário G: Commits fora de ordem
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário G: Commits fora de ordem numérica${reset}"
local repo7=$(setup_repo)
cd "$repo7"
make_commit "Ticket #42 (Pt.5) - feat: quinto"
make_commit "Ticket #42 (Pt.2) - fix: segundo"
make_commit "Ticket #42 (Pt.8) - docs: oitavo"
make_commit "Ticket #42 (Pt.3) - refactor: terceiro"
local result=$(tb__find_highest_part 42)
assert_eq "Out of order Pt.5,2,8,3 → max=8" "9" "$result"
cd "$ORIG_DIR"
rm -rf "$repo7"
echo ""

# ─────────────────────────────────────────────────────
# Cenário H: Ticket com número grande
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário H: Ticket com número grande (1234)${reset}"
local repo8=$(setup_repo)
cd "$repo8"
make_commit "Ticket #1234 (Pt.1) - feat: inicio"
make_commit "Ticket #123 (Pt.10) - fix: outro ticket"
make_commit "Ticket #12345 (Pt.7) - docs: outro ticket"
make_commit "Ticket #1234 (Pt.4) - refactor: quarto"
local result=$(tb__find_highest_part 1234)
assert_eq "Ignores #123 and #12345, only #1234" "5" "$result"
cd "$ORIG_DIR"
rm -rf "$repo8"
echo ""

# ─────────────────────────────────────────────────────
# Cenário I: Diretório sem .git (git log falha)
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Cenário I: Diretório sem .git (git log falha)${reset}"
local repo9=$(mktemp -d)
cd "$repo9"
local result=$(tb__find_highest_part 42)
assert_eq "No .git directory → fallback" "1" "$result"
cd "$ORIG_DIR"
rm -rf "$repo9"
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
