#!/usr/bin/env bash
# =============================================================================
#  test_helpers.sh — Bash assertion library minimalista
# =============================================================================
#  Usado por todos os scripts em tests/*.sh. Fornece assertions estilo xUnit
#  com saída legível em modo verbose.
#
#  Convenções:
#    - Cada assert incrementa PASS_COUNT ou FAIL_COUNT.
#    - assert_* imprime "PASS:<name>" ou "FAIL:<name>: <motivo>" em uma linha.
#    - Modo verbose (TEST_VERBOSE=1) imprime também a expressão avaliada.
#  =============================================================================

set -u

PASS_COUNT=0
FAIL_COUNT=0
TEST_VERBOSE="${TEST_VERBOSE:-0}"

_color_pass() { printf '\033[32mPASS\033[0m'; }
_color_fail() { printf '\033[31mFAIL\033[0m'; }

assert_equals() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '%s: %s\n' "$(_color_pass)" "$name"
    [[ "$TEST_VERBOSE" == "1" ]] && printf '       expected=%q actual=%q\n' "$expected" "$actual"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '%s: %s\n' "$(_color_fail)" "$name"
    printf '       expected=%q\n       actual  =%q\n' "$expected" "$actual"
  fi
}

assert_contains() {
  local name="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '%s: %s\n' "$(_color_pass)" "$name"
    [[ "$TEST_VERBOSE" == "1" ]] && printf '       contains=%q\n' "$needle"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '%s: %s\n' "$(_color_fail)" "$name"
    printf '       needle=%q\n       haystack=%s\n' "$needle" "$haystack"
  fi
}

assert_file_exists() {
  local name="$1" path="$2"
  if [[ -f "$path" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '%s: %s\n' "$(_color_pass)" "$name"
    [[ "$TEST_VERBOSE" == "1" ]] && printf '       file=%s\n' "$path"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '%s: %s\n' "$(_color_fail)" "$name"
    printf '       missing=%s\n' "$path"
  fi
}

assert_true() {
  local name="$1" condition="$2"
  if [[ "$condition" == "1" || "$condition" == "true" || "$condition" == "yes" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '%s: %s\n' "$(_color_pass)" "$name"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '%s: %s\n' "$(_color_fail)" "$name"
    printf '       condition=%s\n' "$condition"
  fi
}

assert_grep() {
  local name="$1" pattern="$2" file="$3"
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '%s: %s\n' "$(_color_pass)" "$name"
    [[ "$TEST_VERBOSE" == "1" ]] && printf '       pattern=%s file=%s\n' "$pattern" "$file"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '%s: %s\n' "$(_color_fail)" "$name"
    printf '       pattern=%s file=%s\n' "$pattern" "$file"
  fi
}

assert_not_grep() {
  local name="$1" pattern="$2" file="$3"
  if ! grep -qE "$pattern" "$file" 2>/dev/null; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '%s: %s\n' "$(_color_pass)" "$name"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '%s: %s\n' "$(_color_fail)" "$name"
    printf '       pattern=%s file=%s (foi encontrado, mas NAO deveria)\n' "$pattern" "$file"
  fi
}

assert_exit_zero() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '%s: %s\n' "$(_color_pass)" "$name"
  else
    local rc=$?
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '%s: %s\n' "$(_color_fail)" "$name"
    printf '       command failed rc=%d\n' "$rc"
  fi
}

summary_and_exit() {
  printf '\n'
  printf 'Results: %d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
  if [[ "$FAIL_COUNT" -gt 0 ]]; then exit 1; else exit 0; fi
}