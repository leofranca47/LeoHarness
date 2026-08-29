#!/usr/bin/env bash
# =============================================================================
#  test.sh — Runner de testes do OpenHarness
# =============================================================================
#  Descobre e executa todos os scripts tests/test_*.sh.
#  Retorna 0 somente se todos os testes passarem.
#
#  Uso:
#     ./test.sh                  # roda todos os testes
#     TEST_VERBOSE=1 ./test.sh   # modo verbose
#     bash tests/test_foo.sh     # roda um arquivo específico diretamente
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "$SCRIPT_DIR/tests" ]]; then
  printf 'Erro: diretório tests/ não encontrado em %s\n' "$SCRIPT_DIR" >&2
  exit 2
fi

total_pass=0
total_fail=0
failed_files=()

shopt -s nullglob
test_files=( "$SCRIPT_DIR"/tests/test_*.sh )
shopt -u nullglob

if [[ ${#test_files[@]} -eq 0 ]]; then
  printf 'Nenhum teste encontrado em tests/test_*.sh\n'
  exit 2
fi

printf 'OpenHarness test runner\n'
printf 'Encontrados %d arquivo(s) de teste:\n' "${#test_files[@]}"

for f in "${test_files[@]}"; do
  rel="${f#$SCRIPT_DIR/}"
  printf '\n→ %s\n' "$rel"
  if bash "$f"; then
    :
  else
    failed_files+=( "$rel" )
  fi
done

printf '\n================================================\n'
if [[ ${#failed_files[@]} -eq 0 ]]; then
  printf '✓ Todos os %d arquivo(s) passaram.\n' "${#test_files[@]}"
  exit 0
else
  printf '✗ %d arquivo(s) falharam:\n' "${#failed_files[@]}"
  for f in "${failed_files[@]}"; do
    printf '  - %s\n' "$f"
  done
  exit 1
fi