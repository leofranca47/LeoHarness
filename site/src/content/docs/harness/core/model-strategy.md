---
title: "Modelo: Estratégia de Reasoning por Etapa"
---
> Carregado sob demanda via `@harness/core/model-strategy.md` por comandos que precisam aplicar o nível de reasoning preferido da etapa.

Este módulo descreve **o algoritmo de resolução** que o LLM deve seguir para aplicar a configuração de reasoning apropriada para cada etapa do OpenHarness, considerando o modelo atualmente selecionado. É o **único lugar** onde as regras de reasoning estão documentadas.

As funções bash abaixo são **gêmeas documentacionais** do algoritmo: servem como especificação executável e como rede de segurança contra drift entre markdown e implementação. Elas **não são chamadas em runtime** pelo harness — são executadas apenas pelos testes em `tests/test_model_strategy.sh`.

---

## Princípios (não negociáveis)

1. **Reasoning é ortogonal ao modelo.** Trocar reasoning nunca troca modelo.
2. **`model: null` significa "usar o modelo atualmente selecionado no OpenCode"**, nunca "não usar modelo".
3. **Reasoning é uma intenção abstrata.** Não é uma variant literal — é um nível semântico (`low`/`normal`/`high`) que é adaptado à configuração real de cada modelo.
4. **Sem lista global fixa de variants por modelo.** Descoberta é responsabilidade do LLM no momento da execução, com ajuda do CLI `opencode models --verbose`.
5. **MiniMax M3 tem tratamento explícito** (adapter dedicado) — não passa pelo generic adapter.
6. **Fallback transparente.** Reasoning preferida ausente (no generic adapter) → pergunta ao usuário, mas continua. Não há falha por variant ausente. Não há degradação silenciosa.
7. **Backward-compatible por construção.** Config ausente = comportamento idêntico ao atual.

---

## Algoritmo de resolução

Quando uma etapa do OpenHarness é iniciada (`/refine`, `/spec`, `/review`, `/debug`, `/refactor`, `/feature`, `/bug`, e as sub-fases `tdd/red` e `implement` em `/feature`/`/bug`/`/refactor`), siga estes passos **em ordem**:

```
1. Resolver o modelo
   ├─ usuário informou --model <modelo> explicitamente?
   │   ├─ sim → usar modelo informado
   │   └─ não → usar modelo atualmente selecionado no OpenCode
   │
2. Consultar o reasoning preferido em harness/config/model-strategy.jsonc
   ├─ config ausente? → seguir sem reasoning (comportamento legacy)
   ├─ etapa não tem chave? → seguir sem reasoning
   └─ etapa tem reasoning: null → seguir sem reasoning
   │
3. Adaptar reasoning ao modelo (adapt_reasoning)
   ├─ MiniMax-M3: adapter dedicado (low→none, normal→thinking, high→thinking)
   ├─ outros modelos: adapter genérico via opencode models --verbose
   │   ├─ low → "low" se existir, senão pedir fallback
   │   ├─ normal → "default" se existir, senão "medium", senão fallback
   │   └─ high → "high" se existir, senão "max"/"xhigh", senão fallback
   └─ adapter retorna "<modelo>#<variant>" OU sinaliza fallback
   │
4. Se adaptação retornou configuração → usar <modelo>#<variant>
   │
5. Fallback (signaling by adapter)
   ├─ informar motivo: "O modelo <modelo> não possui a configuração de reasoning '<nível>' para esta etapa."
   ├─ listar SOMENTE as variants realmente disponíveis para o modelo
   ├─ perguntar ao usuário qual usar
   └─ continuar a execução com a escolha (ou sem variant se usuário cancelar)
```

**Garantia:** em nenhum passo o modelo selecionado pelo usuário é trocado.

---

## Descoberta de variants

Quando precisar saber se uma variant existe no modelo atual:

1. **Primário:** execute `opencode models --verbose <provider>` (ex: `opencode models --verbose google`). O JSON de cada modelo inclui o objeto `"variants": { "<nome>": { ... }, ... }`. Se a variant preferida estiver nas chaves de `variants`, ela existe.
2. **Fallback:** use seu conhecimento de treino sobre o modelo. Se incerto, pergunte ao usuário.
3. **Último recurso:** assuma ausente e aplique o fluxo de fallback (passo 5).

---

## Adaptação por modelo (MiniMax M3 é特例)

**Por que M3 é特例:** o OpenCode `MiniMax-M3` expõe apenas 2 variants — `none` (thinking disabled) e `thinking` (thinking adaptive). Não há literal `#low` ou `#high`. O M3 adapter mapeia os 3 níveis abstratos de reasoning para as 2 capabilities reais:

| Reasoning abstrato | M3 variant real | Significado |
|---|---|---|
| `low` | `none` | thinking **off** — respostas diretas, baixo custo |
| `normal` | `thinking` | thinking **on** — raciocínio moderado |
| `high` | `thinking` | thinking **on** — raciocínio profundo |

> Decisão de design: para MiniMax M3, `low` é "off" e `normal`/`high` colapsam em "on" porque M3 só tem 2 estados reais. Não há fallback porque não há alternativa melhor que `thinking` para `high` no M3.

**Para outros modelos:** o generic adapter consulta `opencode models --verbose` para descobrir variants reais e prefere a literal (`low`, `normal`/`default`, `high`). Se a preferida não existe, oferece fallback ao usuário.

---

## Variants resultantes por stage

Composição final de `stage → reasoning → variant` aplicada ao modelo atualmente selecionado. Esta tabela é o resultado **fim-a-fim** do algoritmo de resolução; é o que o usuário realmente recebe quando executa cada comando.

### MiniMax-M3 (adapter dedicado — colapso 3→2)

| Stage | Reasoning abstrato | Variant final no M3 | Thinking |
|---|---|---|---|
| `refine` | `low` | `#none` | off |
| `refactor` | `low` | `#none` | off |
| `implement` | `normal` | `#thinking` | on |
| `spec` | `high` | `#thinking` | on |
| `tdd_red` | `high` | `#thinking` | on |
| `debug` | `high` | `#thinking` | on |
| `review` | `high` | `#thinking` | on |

**Observações sobre o colapso:**

- 7 stages → apenas **2 variants efetivas** (`#none` e `#thinking`) no M3.
- Stages que compartilham reasoning abstrato (`low` ou `high`) são indistinguíveis em variant final.
- Editing `model-strategy.jsonc` para separar stages que hoje compartilham reasoning **não muda a variant no M3** — só muda em modelos com variants granulares.

### Modelos com adapter genérico (low/medium/high literais)

Em modelos como `google/gemini-3.7-flash` (3 variants reais), a mesma config produz até 3 variants distintas:

| Stage | Reasoning abstrato | Variant final típica |
|---|---|---|
| `refine` | `low` | `#low` |
| `refactor` | `low` | `#low` |
| `implement` | `normal` | `#default` ou `#medium` |
| `spec` | `high` | `#high` |
| `tdd_red` | `high` | `#high` |
| `debug` | `high` | `#high` |
| `review` | `high` | `#high` |

A variant exata por modelo é resolvida em runtime por `adapt_reasoning` consultando `opencode models --verbose <provider>`.

### Como verificar a variant em uso (sem instrumentation de runtime)

O harness **não tem log de runtime** que confirme qual variant foi aplicada na chamada HTTP ao provedor. A única garantia observável é visual:

1. **Bloco `<think>` na resposta**: com `#thinking`, o modelo emite um bloco de raciocínio **antes** da resposta visível. Com `#none`, esse bloco não existe.
2. **Teste A/B**: rodar o mesmo pedido curto em `/refine` (resolve para `#none` no M3) e em `/spec` (resolve para `#thinking` no M3). Se `/spec` mostrar bloco `<think>` e `/refine` não, o mecanismo está funcionando end-to-end.
3. **Proxy de latência**: `#thinking` gera tokens de raciocínio antes da resposta visível, então stages que resolvem para `#thinking` consistentemente levam mais tempo que stages que resolvem para `#none` para o mesmo input. Não é prova, mas é sinal coerente.

A garantia mais forte (1) é a única que prova que a variant foi aplicada de fato.

---

## Mapeamento de etapas

| Etapa do Harness | Onde é resolvida |
|---|---|
| `refine` | comando `/refine` |
| `spec` | comando `/spec` |
| `review` | comando `/review` |
| `debug` | comando `/debug` |
| `refactor` | comando `/refactor` |
| `tdd_red` (tdd/red) | fase interna em `/feature`, `/bug`, `/refactor` |
| `implement` | fase interna em `/feature`, `/bug`, `/refactor` |

---

## Funções bash (especificações executáveis)

### `resolve_reasoning <model> <stage>`

Resolve o reasoning completo (modelo + configuração) para uma etapa. Retorna `"<model>"` se sem reasoning aplicável, ou `"<model>#<variant>"` se aplicável. Se a configuração preferida não existir e o adapter sinaliza fallback, retorna `"<model>"` (LLM deve detectar e perguntar ao usuário).

<<'BASH_EOF_RESOLVE'
# resolve_reasoning <model> <stage>
# Retorna: "<model>" se sem reasoning aplicável, "<model>#<variant>" se aplicável.

resolve_reasoning() {
  local model="$1"
  local stage="$2"

  # Sem model, sem reasoning.
  [[ -z "$model" ]] && { echo ""; return; }

  # Localiza config.
  local cfg="${OPENCODE_HARNESS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)}/harness/config/model-strategy.jsonc"
  [[ ! -f "$cfg" ]] && { echo "$model"; return; }

  # Extrai reasoning da etapa via python3 (parsing JSONC confiável).
  local reasoning
  reasoning=$(python3 - "$cfg" "$stage" <<'PY' 2>/dev/null || echo ""
import json, re, sys
path, stage = sys.argv[1], sys.argv[2]
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
try:
    data = json.loads(raw)
except Exception:
    sys.exit(1)
r = data.get("stages", {}).get(stage, {}).get("reasoning")
print("" if r is None else r)
PY
  )

  # Sem reasoning configurado → modelo puro.
  [[ -z "$reasoning" || "$reasoning" == "null" ]] && { echo "$model"; return; }

  # Delega ao adapt_reasoning.
  adapt_reasoning "$model" "$reasoning"
}
BASH_EOF_RESOLVE

---

### `adapt_reasoning <model> <level>`

Adapta um nível de reasoning abstrato (`low`/`normal`/`high`) para a configuração real do modelo. Retorna `"<model>#<variant>"` se conseguir aplicar, ou string vazia `""` se deve entrar em fallback (LLM deve perguntar ao usuário).

<<'BASH_EOF_ADAPT'
# adapt_reasoning <model> <level>
# Retorna: "<model>#<variant>" se aplicável, ou "" para sinalizar fallback.
#
# MiniMax-M3 tem adapter dedicado.
# Outros modelos usam generic adapter via opencode models --verbose.

adapt_reasoning() {
  local model="$1"
  local level="$2"

  [[ -z "$model" || -z "$level" ]] && { echo ""; return; }

  # ----- ADAPTER ESPECÍFICO: MiniMax M3 -----
  # M3 só tem 2 variants reais: "none" e "thinking".
  # low→none, high→thinking, normal→thinking (collapse).
  if [[ "$model" == minimax/* ]]; then
    case "$level" in
      low)    echo "${model}#none" ;;
      normal) echo "${model}#thinking" ;;
      high)   echo "${model}#thinking" ;;
      *)      echo "${model}#thinking" ;;  # unknown level → default to thinking on
    esac
    return
  fi

  # ----- GENERIC ADAPTER: outros modelos -----
  # Tenta mapear level → variant literal do modelo.
  local preferred_variant=""
  case "$level" in
    low)    preferred_variant="low" ;;
    normal) preferred_variant="default" ;;  # fallback se não houver: medium
    high)   preferred_variant="high" ;;
    *)      echo ""; return ;;  # level desconhecido → fallback
  esac

  # Descobre variants reais do modelo via CLI.
  local provider="${model%%/*}"
  local available_variants=""
  if command -v opencode >/dev/null 2>&1; then
    available_variants=$(opencode models --verbose "$provider" 2>/dev/null \
      | awk -v mid="$model" '
          $0 ~ "^" mid "$" { found=1; next }
          found && /^google\/|^minimax\/|^anthropic\/|^openai\/|^kimi-for-coding\// { exit }
          found && /"variants"/ { in_v=1 }
          in_v && /^  }/ { exit }
          in_v && /^    "/ {
            gsub(/^    "/, "")
            gsub(/":.*/, "")
            print
          }
        ')
  fi

  # Se CLI indisponível ou modelo desconhecido, sinaliza fallback (não degrada silenciosamente).
  if [[ -z "$available_variants" ]]; then
    echo ""  # LLM deve perguntar ao usuário
    return
  fi

  # Se a variant preferida existe → aplica.
  if grep -qx "$preferred_variant" <<<"$available_variants"; then
    echo "${model}#${preferred_variant}"
    return
  fi

  # Fallbacks por nível (em ordem de preferência).
  case "$level" in
    low)
      # low não tem substituto claro; sinaliza fallback.
      echo ""
      ;;
    normal)
      # normal pode cair para medium se disponível.
      if grep -qx "medium" <<<"$available_variants"; then
        echo "${model}#medium"
      else
        echo ""
      fi
      ;;
    high)
      # high pode cair para max/xhigh se disponível.
      if grep -qx "max" <<<"$available_variants"; then
        echo "${model}#max"
      elif grep -qx "xhigh" <<<"$available_variants"; then
        echo "${model}#xhigh"
      else
        echo ""
      fi
      ;;
  esac
}
BASH_EOF_ADAPT

---

## Quando este módulo é carregado

Carregue `@harness/core/model-strategy.md` no início de qualquer comando que precise aplicar o reasoning preferido:

- `/refine`, `/spec`, `/review`, `/debug`, `/refactor`, `/feature`, `/bug`

Para `/feature`, `/bug` e `/refactor`, carregue também no início de cada sub-fase `tdd_red` e `implement` documentada no workflow correspondente.