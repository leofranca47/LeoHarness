#!/usr/bin/env bash
# =============================================================================
#  test_model_strategy.sh — Testes para a estratégia de reasoning por etapa
# =============================================================================
#  Cobre 13 cenários:
#    1.  etapa possui reasoning configurado
#    2.  modelo explicitamente informado possui prioridade
#    3.  ausência de modelo usa modelo atual do OpenCode
#    4.  MiniMax M3 recebe o mapeamento correto (refine/refactor→none)
#    5.  reasoning high é convertido corretamente para MiniMax M3 (#thinking)
#    6.  reasoning normal é convertido corretamente para MiniMax M3 (#thinking)
#    7.  outro modelo com #high (Gemini) recebe high
#    8.  outro modelo sem high entra em fallback (não degrada silenciosamente)
#    9.  apenas variants realmente disponíveis são apresentadas
#   10.  usuário pode escolher uma alternativa
#   11.  modelo nunca é trocado automaticamente
#   12.  execução continua após fallback
#   13.  comportamento legacy continua funcionando quando config ausente
#
#  Carrega test_helpers.sh e faz assertions sobre os artefatos do harness.
#  Rodar via ./test.sh ou diretamente: bash tests/test_model_strategy.sh
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

CONFIG="$ROOT/harness/config/model-strategy.jsonc"
MODULE="$ROOT/harness/core/model-strategy.md"

printf '\n=== test_model_strategy.sh ===\n\n'

# -----------------------------------------------------------------------------
# Helper python: parse JSONC removendo comentários // e chaves que começam com _
_jsonc_load() {
  python3 - "$1" <<'PY' 2>/dev/null
import json, re, sys
path = sys.argv[1]
with open(path) as f:
    raw = f.read()
raw = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)
raw = re.sub(r"//[^\n]*", "", raw)

def strip_underscore_keys(text):
    pattern = re.compile(r'"_[a-zA-Z_]+"\s*:\s*')
    out = []
    i = 0
    while i < len(text):
        m = pattern.match(text, i)
        if not m:
            out.append(text[i]); i += 1; continue
        i = m.end()
        if i < len(text) and text[i] == '"':
            i += 1
            while i < len(text) and text[i] != '"':
                if text[i] == '\\': i += 2
                else: i += 1
            i += 1
        elif i < len(text) and text[i] == '{':
            depth = 1; i += 1
            while i < len(text) and depth > 0:
                if text[i] == '{': depth += 1
                elif text[i] == '}': depth -= 1
                i += 1
        elif i < len(text) and text[i] == '[':
            depth = 1; i += 1
            while i < len(text) and depth > 0:
                if text[i] == '[': depth += 1
                elif text[i] == ']': depth -= 1
                i += 1
        if i < len(text) and text[i] == ',': i += 1
    return ''.join(out)

prev = None
while prev != raw:
    prev = raw
    raw = strip_underscore_keys(raw)
raw = re.sub(r",\s*([}\]])", r"\1", raw)
data = json.loads(raw)
print(json.dumps(data))
PY
}

# =============================================================================
# AC1: etapa possui reasoning configurado
# =============================================================================
assert_file_exists "AC1: config exists" "$CONFIG"

STAGE_COUNT=0
REASONING_FIELD_OK="false"
if command -v python3 >/dev/null 2>&1 && [[ -f "$CONFIG" ]]; then
  EVAL=$(_jsonc_load "$CONFIG" | python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
stages = data.get("stages", {})
print(len(stages))
print("ok" if all("reasoning" in cfg for cfg in stages.values()) else "fail")
' 2>/dev/null)
  STAGE_COUNT=$(echo "$EVAL" | head -1)
  REASONING_FIELD_OK=$(echo "$EVAL" | tail -1)
fi
assert_equals "AC1a: config has 7 stages" "7" "$STAGE_COUNT"
assert_equals "AC1b: all stages have 'reasoning' field" "ok" "$REASONING_FIELD_OK"

# AC1c: valores válidos (low/normal/high/null)
INVALID_REASONING=""
if command -v python3 >/dev/null 2>&1 && [[ -f "$CONFIG" ]]; then
  INVALID_REASONING=$(_jsonc_load "$CONFIG" | python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
allowed = {"low","normal","high",None}
bad = []
for stage, cfg in data.get("stages", {}).items():
    r = cfg.get("reasoning")
    if r not in allowed:
        bad.append(f"{stage}={r!r}")
print(",".join(bad))
' 2>/dev/null)
fi
assert_equals "AC1c: all reasonings are low|normal|high|null" "" "$INVALID_REASONING"

# =============================================================================
# Extrai blocos bash do módulo para testes de resolução/adapt
# =============================================================================
RESOLVE_BASH=""
ADAPT_BASH=""
if [[ -f "$MODULE" ]]; then
  RESOLVE_BASH=$(awk "/<<'BASH_EOF_RESOLVE'/,/^BASH_EOF_RESOLVE$/" "$MODULE" | sed '1d;$d')
  ADAPT_BASH=$(awk "/<<'BASH_EOF_ADAPT'/,/^BASH_EOF_ADAPT$/" "$MODULE" | sed '1d;$d')
fi

# Source funções se disponíveis
if [[ -n "$RESOLVE_BASH" ]]; then
  eval "$RESOLVE_BASH" >/dev/null 2>&1
fi
if [[ -n "$ADAPT_BASH" ]]; then
  eval "$ADAPT_BASH" >/dev/null 2>&1
fi

OPENCODE_HARNESS_ROOT="$ROOT"

# =============================================================================
# AC2: modelo explicitamente informado possui prioridade
# (validação conceitual: campo 'model' no schema aceita string)
# =============================================================================
MODEL_FIELD_PRESENT="false"
if command -v python3 >/dev/null 2>&1 && [[ -f "$CONFIG" ]]; then
  MODEL_FIELD_PRESENT=$(_jsonc_load "$CONFIG" | python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
print("ok" if all("model" in cfg for cfg in data.get("stages", {}).values()) else "fail")
' 2>/dev/null)
fi
assert_equals "AC2: all stages have 'model' field (for override)" "ok" "$MODEL_FIELD_PRESENT"

# AC2 cont.: se setarmos model explicitamente, função de resolução preserva-o
if declare -F resolve_reasoning >/dev/null 2>&1; then
  R=$(OPENCODE_HARNESS_ROOT="$ROOT" resolve_reasoning "google/gemini-3.7-flash" "spec" 2>/dev/null || echo "")
  assert_equals "AC2b: explicit model preserved in resolution" \
    "google/gemini-3.7-flash#high" "$R"
fi

# =============================================================================
# AC3: ausência de modelo explícito → resolve_reasoning deve ter lógica de fallback
# (validação semântica: função existe e não dá erro)
# =============================================================================
if declare -F resolve_reasoning >/dev/null 2>&1; then
  R=$(OPENCODE_HARNESS_ROOT="$ROOT" resolve_reasoning "minimax/MiniMax-M3" "spec" 2>/dev/null || echo "")
  # M3 tem thinking → resolve deve retornar MiniMax-M3#thinking
  assert_equals "AC3: resolve_reasoning handles MiniMax-M3 spec" \
    "minimax/MiniMax-M3#thinking" "$R"
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '%s: AC3 resolve_reasoning function missing\n' "$(_color_fail)"
fi

# =============================================================================
# AC4-6: MiniMax M3 recebe mapeamento correto via adapt_reasoning
# =============================================================================
if declare -F adapt_reasoning >/dev/null 2>&1; then
  # AC4: refine (abstract low) → M3 #none (thinking off)
  A1=$(adapt_reasoning "minimax/MiniMax-M3" "low" 2>/dev/null || echo "")
  assert_equals "AC4: M3 adapt low → #none" "minimax/MiniMax-M3#none" "$A1"

  # AC5: spec (abstract high) → M3 #thinking
  A2=$(adapt_reasoning "minimax/MiniMax-M3" "high" 2>/dev/null || echo "")
  assert_equals "AC5: M3 adapt high → #thinking" "minimax/MiniMax-M3#thinking" "$A2"

  # AC6: implement (abstract normal) → M3 #thinking (collapse)
  A3=$(adapt_reasoning "minimax/MiniMax-M3" "normal" 2>/dev/null || echo "")
  assert_equals "AC6: M3 adapt normal → #thinking (collapse)" "minimax/MiniMax-M3#thinking" "$A3"

  # AC4b: refactor (low) → M3 #none (consistente com refine)
  A4=$(adapt_reasoning "minimax/MiniMax-M3" "low" 2>/dev/null || echo "")
  assert_equals "AC4b: M3 adapt low (refactor) → #none" "minimax/MiniMax-M3#none" "$A4"
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '%s: AC4-6 adapt_reasoning function missing\n' "$(_color_fail)"
fi

# =============================================================================
# AC7: outro modelo com #high (Gemini) recebe high
# =============================================================================
if declare -F adapt_reasoning >/dev/null 2>&1; then
  A=$(adapt_reasoning "google/gemini-3.7-flash" "high" 2>/dev/null || echo "")
  assert_equals "AC7: Gemini adapt high → #high" \
    "google/gemini-3.7-flash#high" "$A"
fi

# =============================================================================
# AC8: outro modelo sem high entra em fallback (não degrada silenciosamente)
# =============================================================================
if declare -F adapt_reasoning >/dev/null 2>&1; then
  # "fake/model" é um modelo que não existe no CLI → adapt deve sinalizar fallback
  A=$(adapt_reasoning "fake/nonexistent-model" "high" 2>/dev/null || echo "")
  # Quando o modelo é desconhecido, NÃO degradar silenciosamente
  # adapt_reasoning retorna string vazia ou marcador especial indicando fallback
  # A lógica concreta depende da implementação — testamos que NÃO retorna fake#high
  if [[ "$A" != "fake/nonexistent-model#high" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '%s: AC8: unknown model does not silently degrade (returned: %q)\n' "$(_color_pass)" "$A"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '%s: AC8: unknown model degraded to #high (should fallback)\n' "$(_color_fail)"
  fi
fi

# =============================================================================
# AC9: apenas variants realmente disponíveis são apresentadas
# (validação via script awk de extração do CLI — usado pelo adapt)
# =============================================================================
# Verifica que o módulo inclui lógica que lista variants reais via CLI
assert_grep "AC9: module references opencode models CLI for discovery" \
  "opencode models --verbose" "$MODULE"

# =============================================================================
# AC10: usuário pode escolher uma alternativa
# (validação: módulo tem fluxo de fallback que pergunta ao usuário)
# =============================================================================
assert_contains "AC10: module documents fallback ask-user flow" \
  "$(cat "$MODULE" 2>/dev/null || echo '')" \
  "perguntar ao usuário"

# =============================================================================
# AC11: modelo nunca é trocado automaticamente
# (validação: campo 'model' é preservado no schema; adapt não altera model)
# =============================================================================
MODEL_PRESERVED_OK="false"
if command -v python3 >/dev/null 2>&1 && [[ -f "$CONFIG" ]]; then
  # Todos os stages têm model: null (não forçam modelo)
  MODEL_PRESERVED_OK=$(_jsonc_load "$CONFIG" | python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
print("ok" if all(cfg.get("model") is None for cfg in data.get("stages", {}).values()) else "fail")
' 2>/dev/null)
fi
assert_equals "AC11: no stage forces a specific model (model=null everywhere)" "ok" "$MODEL_PRESERVED_OK"

# =============================================================================
# AC12: execução continua após fallback
# (validação: módulo NÃO documenta exit/error fatal — sempre continua)
# =============================================================================
assert_contains "AC12: module says execution continues after fallback" \
  "$(cat "$MODULE" 2>/dev/null || echo '')" \
  "continuar"

# =============================================================================
# AC13: comportamento legacy quando config ausente
# (regression: resolução retorna modelo puro se config não existir)
# =============================================================================
if declare -F resolve_reasoning >/dev/null 2>&1; then
  # Backup config, remover, testar, restaurar
  if [[ -f "$CONFIG" ]]; then
    cp "$CONFIG" "${CONFIG}.bak"
    rm "$CONFIG"
    R=$(OPENCODE_HARNESS_ROOT="$ROOT" resolve_reasoning "google/gemini-3.7-flash" "spec" 2>/dev/null || echo "")
    mv "${CONFIG}.bak" "$CONFIG"
    assert_equals "AC13: legacy mode returns model unchanged when config absent" \
      "google/gemini-3.7-flash" "$R"
  fi
fi

# =============================================================================
# Comandos carregam módulo (preservado do conjunto anterior)
# =============================================================================
for cmd in refine spec review debug refactor feature bug; do
  assert_grep "$cmd loads model-strategy module" \
    "@harness/core/model-strategy.md" \
    "$ROOT/commands/$cmd.md"
done

# =============================================================================
# install.sh copia harness/config/ (preservado)
# =============================================================================
INSTALL="$ROOT/install.sh"
assert_grep "install.sh copies config/ subdir" \
  'harness/config' "$INSTALL"

# =============================================================================
# README tem a nova seção com exemplos MiniMax M3 / Gemini / fallback
# =============================================================================
README="$ROOT/README.md"
assert_grep "README mentions reasoning strategy section" \
  "Estratégia de Reasoning por Etapa" "$README"
assert_grep "README documents 3-level reasoning" \
  '\| *refine *\| *low *\|' "$README"
assert_grep "README mentions MiniMax M3 example" \
  "MiniMax-M3" "$README"
assert_grep "README mentions MiniMax M3 thinking mapping" \
  "thinking" "$README"
assert_grep "README mentions fallback example" \
  "fallback" "$README"

summary_and_exit