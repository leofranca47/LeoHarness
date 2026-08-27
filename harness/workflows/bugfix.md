# Workflow: BUGFIX

Correção de bug reproduzível após identificação da causa raiz.

```
REPRODUCE → INVESTIGATE → IDENTIFY ROOT CAUSE → CREATE/IDENTIFY REGRESSION TEST → IMPLEMENT MINIMAL FIX → VALIDATE → REVIEW
```

## Regra crítica

**NÃO corrija sintomas.** Investigue a causa raiz primeiro.

Sintoma: "Usuário recebe erro 500 ao fazer X"
- ❌ Errado: capturar a exception e retornar 200
- ✅ Certo: entender por que a exception ocorre e corrigir a causa

## Quando usar

- Comportamento claramente errado
- Você consegue reproduzir (ou tem evidência confiável do usuário)
- Sintoma é específico

## Quando NÃO usar

- Sintoma vago, intermitente, sem repro claro → `/debug`
- Não é bug, é feature faltando → `/feature`
- Não é bug, é melhoria desejada → `/feature` (ou conversa)

---

## Fase 1: REPRODUCE

**Objetivo:** confirmar que o bug existe e isolar condições.

### O que coletar

```markdown
## Reprodução

**Comando/ação:** [passo exato]
**Input:** [dados de entrada exatos]
**Ambiente:** [dev/staging/prod, versões relevantes]
**Output obtido:** [resultado errado]
**Output esperado:** [resultado correto]
**Stack trace (se houver):** [completo]
```

### Formas de reproduzir

| Tipo | Como |
|---|---|
| Comando único | Execute e observe |
| Sequência de UI | Descreva passos numerados |
| Condição de corrida | Use `script` para repetir em loop |
| Dados específicos | Use fixture ou seed |

### Se NÃO conseguir reproduzir

Pare. Redirecione para `/debug` ou peça mais informação ao usuário.

---

## Fase 2: INVESTIGATE

**Objetivo:** mapear contexto histórico e atual.

### Ações

```bash
# Quando o bug apareceu?
git log --all --oneline -- caminho/afetado | head -20

# O que mudou recentemente?
git log --since="3 months ago" -- caminho/afetado

# Quem introduziu o trecho suspeito?
git blame caminho/arquivo.php

# Há issues/PRs relacionados?
git log --all --grep="palavra-chave"
```

### Perguntas

- Quando isso começou? (introduzido quando/quando?)
- É em uma versão específica?
- Afeta todos os usuários ou só alguns?
- Dados específicos envolvidos?

---

## Fase 3: IDENTIFY ROOT CAUSE

**Objetivo:** chegar à causa raiz com evidência.

### Método dos 5 porquês

```
Sintoma: erro 500 ao criar pedido
Por quê? Service lança UnexpectedValueException
Por quê? Item do pedido está null
Por quê? Repository retornou null
Por quê? Query não encontrou o item (id errado)
Por quê? ID foi gerado com timezone errado (causa raiz)
```

### Critério para parar

Você tem a causa raiz quando:
- Removê-la impede o sintoma
- Ela é específica (não "algo no servidor")
- Você tem evidência (log, teste, git blame)

### Declare explicitamente

```markdown
**Causa raiz:** [1 frase clara]
**Evidência:** [como você verificou]
```

---

## Fase 4: REGRESSION TEST (RED-first)

**Objetivo:** ter um teste que falha antes do fix e passa depois — seguindo o ciclo TDD.

### Por que isso é obrigatório

Sem teste de regressão:
- O bug volta 3 meses depois
- Ninguém percebe
- Você gasta mais tempo para re-debugar

### Abordagem: TDD RED-first

Carregue `@harness/workflows/tdd.md` para a Fase RED completa. Resumo:

1. **Descobrir capacidade de teste** (sub-fase em `@harness/gates/discovery.md`)
2. **Classificar TDD status** — `TDD_READY` / `LIMITED` / `UNAVAILABLE`
3. **Se READY ou LIMITED:**
   - Escrever teste que reproduz o bug (REPRODUCE → testa)
   - Verificar que falha pelo motivo esperado (não por erro de setup)
   - Esse é o RED
4. **Se UNAVAILABLE:** documentar o teste de regressão manual (script, log) e usar smoke test até o ambiente estar pronto

### Tipos de teste de regressão

| Tipo | Quando |
|---|---|
| Unit | Lógica isolada está errada |
| Feature/Integração | Fluxo completo está errado |
| Manual (script) | Difícil de automatizar (registre como comentário) |

### Posicionamento do teste

- Próximo ao código que está sendo corrigido
- Seguindo padrões do projeto (Pest vs PHPUnit, etc.)
- Com nome descritivo: `test_rejeita_pedido_quando_item_nao_existe`

---

## Fase 5: IMPLEMENT MINIMAL FIX

**Objetivo:** corrigir com a menor mudança possível.

### Princípios

- **Menor diff** que resolve a causa raiz
- **Sem reformatação** de código adjacente
- **Sem outras correções** ("drive-by fixes")
- **Sem novas abstrações** (a menos que necessárias)

### Antes de aplicar

Confirme:
- O fix resolve a causa raiz?
- Não introduz regressões?
- Não muda comportamento intencional fora do escopo?

---

## Fase 6: VALIDATE

**Objetivo:** confirmar que funciona.

### Comandos

```bash
# O teste de regressão agora passa
composer test -- --filter=RegressionTestName

# Outros testes não quebraram
composer test

# Lint/análise estática
composer analyse
```

Se algum falhar: pare, corrija, re-valide.

---

## Fase 7: REVIEW

**Objetivo:** revisar o próprio fix.

### Checklist

```markdown
[ ] Causa raiz realmente identificada (não sintoma)
[ ] Teste de regressão adicionado ou identificado
[ ] Fix é mínimo
[ ] Sem drive-by
[ ] Sem nova falha em outros testes
[ ] Mensagens de erro mais claras (se apropriado)
[ ] Logs/observabilidade suficientes para detectar reincidência
```

---

## Relatório final

```markdown
## Bug: [título]

**Causa raiz:** [1 frase]
**Evidência:** [como verificou]

**Testing:**
- TDD Status: [READY | LIMITED | UNAVAILABLE | NOT_APPLICABLE]
- Test Level: [UNIT | FEATURE | INTEGRATION | E2E | N/A]
- Cycle: RED (regression test failing) → GREEN (minimal fix)
- Teste de regressão:
  - Novo: `caminho/teste` — [descrição]
  - OU Existente: `caminho:linha` — [descrição]

**Arquivos alterados:**
- `caminho:linha` — [motivo]

**Validação:**
- `[comando]` → [resultado]

**Não validado:**
- [se houver]

**Notas:**
- [prevenção, melhorias sugeridas — como itens separados, não no escopo deste fix]
```

---

## Anti-padrões

- ❌ Corrigir o sintoma em vez da causa
- ❌ Sem teste de regressão
- ❌ Drive-by: "já que estou aqui, vou..."
- ❌ Declarar pronto antes de validar
- ❌ Tentar adivinhar a causa sem evidência
- ❌ Fix que muda comportamento de coisas adjacentes

## Quando escalar para `/debug`

Se durante REPRODUCE ou INVESTIGATE você perceber:
- Sintoma intermitente
- Múltiplas causas possíveis sem clareza
- Não consegue reproduzir

**Pare e redirecione para `/debug`.** É mais rápido e estruturado.