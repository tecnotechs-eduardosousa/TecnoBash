#!/usr/bin/env zsh

# =============================================================================
# Teste de verificação: getVersionedBranch
# Execução: zsh Tests/test_ticket_versioning.zsh
#
# Este teste verifica que a correção do bug de typo
# (EXISTENT_BRANCHES vs EXISTING_BRANCHES) está funcionando corretamente.
# Todos os cenários DEVEM PASSAR no código corrigido.
# =============================================================================

# ── Cores ANSI ───────────────────────────────────────────────────────────────
local green="\033[32m"
local red="\033[31m"
local yellow="\033[33m"
local cyan="\033[36m"
local bold="\033[1m"
local reset="\033[0m"

# Contadores
local passed=0 failed=0 total=0

# Helper: assert
assert_eq() {
    local test_name="$1" expected="$2" actual="$3"
    ((total++))
    if [[ "$actual" == "$expected" ]]; then
        echo "  ${green}✓ PASS:${reset} ${test_name}"
        echo "         expected: ${expected}"
        echo "         got:      ${actual}"
        ((passed++))
    else
        echo "  ${red}✗ FAIL:${reset} ${test_name}"
        echo "         expected: ${expected}"
        echo "         got:      ${actual}"
        ((failed++))
    fi
}

echo ""
echo "  ${bold}Bug Exploration Test: getVersionedBranch${reset}"
echo "  ${cyan}══════════════════════════════════════════════════════════════════${reset}"
echo ""

# ── Mock git to simulate branch lists ────────────────────────────────────────
# We override `git` so that `git branch --list <pattern>` returns our mock data.
# The TICKET_NUMBER variable is used by getVersionedBranch internally (from sed).
MOCK_BRANCHES=""

git() {
    if [[ "$1" == "branch" && "$2" == "--list" ]]; then
        echo "$MOCK_BRANCHES"
    fi
}

# Source the function under test
source "${0:A:h}/../Functions/ticket.sh"

# ─────────────────────────────────────────────────────
# Scenario 1 (Original bug condition):
# branches "ticket-9000" and "ticket-9000-2" exist
# Expected: getVersionedBranch should return "ticket-9000-3"
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Scenario 1: ticket-9000 and ticket-9000-2 already exist${reset}"
echo "  Expected next branch: ticket-9000-3"
echo ""

MOCK_BRANCHES="  ticket-9000
  ticket-9000-2"

# We need TICKET_NUMBER set for the sed regex inside getVersionedBranch
TICKET_NUMBER="9000"

local result=$(getVersionedBranch "ticket-9000")
assert_eq "Given ticket-9000 and ticket-9000-2 exist → should return ticket-9000-3" \
    "ticket-9000-3" "$result"

echo ""

# ─────────────────────────────────────────────────────
# Scenario 2: branches "ticket-9000", "ticket-9000-2", "ticket-9000-3" exist
# Expected: getVersionedBranch should return "ticket-9000-4"
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Scenario 2: ticket-9000, ticket-9000-2, ticket-9000-3 already exist${reset}"
echo "  Expected next branch: ticket-9000-4"
echo ""

MOCK_BRANCHES="  ticket-9000
  ticket-9000-2
  ticket-9000-3"

TICKET_NUMBER="9000"

local result2=$(getVersionedBranch "ticket-9000")
assert_eq "Given ticket-9000, ticket-9000-2, ticket-9000-3 exist → should return ticket-9000-4" \
    "ticket-9000-4" "$result2"

echo ""

# ─────────────────────────────────────────────────────
# Scenario 3 (Regression): no branches exist
# Expected: getVersionedBranch should return "ticket-9000" (no suffix)
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Scenario 3: no branches exist (regression test)${reset}"
echo "  Expected next branch: ticket-9000"
echo ""

MOCK_BRANCHES=""

TICKET_NUMBER="9000"

local result3=$(getVersionedBranch "ticket-9000")
assert_eq "Given no branches exist → should return ticket-9000 (no suffix)" \
    "ticket-9000" "$result3"

echo ""

# ─────────────────────────────────────────────────────
# Scenario 4 (Regression): only "ticket-9000" exists
# Expected: getVersionedBranch should return "ticket-9000-2"
# ─────────────────────────────────────────────────────
echo "${yellow}${bold}Scenario 4: only ticket-9000 exists (regression test)${reset}"
echo "  Expected next branch: ticket-9000-2"
echo ""

MOCK_BRANCHES="  ticket-9000"

TICKET_NUMBER="9000"

local result4=$(getVersionedBranch "ticket-9000")
assert_eq "Given only ticket-9000 exists → should return ticket-9000-2" \
    "ticket-9000-2" "$result4"

echo ""

# ═══════════════════════════════════════════════════════
# Resultado final
# ═══════════════════════════════════════════════════════
echo "  ${cyan}══════════════════════════════════════════════════════════════════${reset}"
echo ""
echo "  Resultado: ${green}${passed} passed${reset} / ${red}${failed} failed${reset} / ${total} total"
echo ""

# Exit code: 0 if all passed, 1 if any failed
[[ $failed -eq 0 ]]
