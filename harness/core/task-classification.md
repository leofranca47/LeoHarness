# Classificação de Tarefas

Antes de agir, classifique. A classificação determina o workflow.

## Os 6 tipos

### FEATURE
**Quando:** adicionar funcionalidade nova.
**Sinal:** "implementar", "criar", "adicionar", "novo endpoint", etc.
**Workflow:** `/feature` → DISCOVER → ANALYZE → PLAN → IMPLEMENT → VALIDATE → REVIEW

### BUGFIX
**Quando:** comportamento errado, mas reproduzível.
**Sinal:** "X não funciona", "deveria fazer Y mas faz Z", com sintoma claro.
**Workflow:** `/bug` → REPRODUCE → INVESTIGATE → ROOT CAUSE → REGRESSION TEST → FIX → VALIDATE

### DEBUG
**Quando:** sintoma vago, causa desconhecida.
**Sinal:** "alguma coisa está errada", "não sei o que acontece", intermitente.
**Workflow:** `/debug` → EVIDENCE → HYPOTHESES → RANK → TEST → ROOT CAUSE → FIX

### REFACTOR
**Quando:** melhorar estrutura sem mudar comportamento.
**Sinal:** "esse método está grande", "há duplicação", "renomear para clareza".
**Workflow:** `/refactor` → ANALYZE → DEPS → TEST COVERAGE → PLAN → REFACTOR → VALIDATE

### REVIEW
**Quando:** analisar diff/código sem modificar.
**Sinal:** "revisa esse PR", "olha esse código", "vale commitar?".
**Workflow:** `/review` → COLLECT → CLASSIFY → REPORT

### INVESTIGATION
**Quando:** só explorar/entender.
**Sinal:** "como funciona X?", "onde fica Y?", "me explique Z".
**Workflow:** `@investigator` → busca, leitura, mapeamento, relatório

## Matriz de decisão

Perguntas em ordem:

```
1. O usuário quer que eu MODIFIQUE código?
   ├─ Não → REVIEW ou INVESTIGATION
   └─ Sim ↓
   
2. Comportamento está ERRADO (algo não funciona como deveria)?
   ├─ Sim, e consigo REPRODUZIR → BUGFIX
   ├─ Sim, mas sintoma é VAGO/INTERMITENTE → DEBUG
   └─ Não, é algo NOVO ↓
   
3. O objetivo é MUDAR COMPORTAMENTO ou só REORGANIZAR?
   ├─ Reorganizar sem mudar → REFACTOR
   └─ Mudar/adicionar comportamento → FEATURE
```

## Quando a classificação é ambígua

Se a tarefa não se encaixa claramente:

**Opção A:** Investigar primeiro (`@investigator`) e classificar depois.

**Opção B:** Perguntar ao usuário:
> "Isso parece mais um bug (sintoma específico) ou um debug (sintoma vago)? Devo seguir /bug ou /debug?"

**Nunca:** Escolha o workflow errado só para parecer produtivo. Refazer é pior que perguntar.

## Workflows completos disponíveis

| Tipo | Comando/Agent |
|---|---|
| FEATURE | `/feature` |
| BUGFIX | `/bug` |
| DEBUG | `/debug` |
| REFACTOR | `/refactor` |
| REVIEW | `/review` |
| INVESTIGATION | `@investigator` (subagent) |

Cada um carrega via `@` os módulos detalhados de `harness/workflows/`.

## Sinais de classificação errada

Você pode ter classificado errado se:

- Passou 10 min em FEATURE e ainda não sabe o que mudar → talvez seja INVESTIGATION primeiro
- Está aplicando "fixes" em DEBUG sem ter causa raiz → volte para DEBUG, pare de chutar
- Em REFACTOR, percebe que está mudando comportamento → pare, vire FEATURE
- Em BUGFIX, não consegue reproduzir → redirecione para DEBUG

**Não há vergonha em reclassificar.** Reclassifique e siga.

## Tipo OTHER e confiança de classificação

Quando o pedido não se encaixa claramente em nenhum dos 6 tipos acima, marque como `OTHER` (ex: pedido puramente conceitual, dúvida de arquitetura sem código envolvido, decisão de stack, etc.).

A classificação pode ter dois níveis de confiança:

- `CONFIDENT` — o pedido é claramente do tipo X; pode prosseguir.
- `UNCERTAIN` — o pedido é ambíguo entre 2+ tipos; precisa de clarificação.

### Quem usa esta confiança

Os commands `/refine` e `/spec` consultam esta seção:

- **`/refine` em modo CONFIDENT:** pula a pergunta de classificação, vai direto para DETECT GAPS.
- **`/refine` em modo UNCERTAIN:** faz **uma única pergunta** para desambiguar entre 2 tipos candidatos (ex: "isso é bug ou feature nova?"); nunca faz rodada longa de perguntas só para classificar.
- **`/spec` herda a classificação** do `/refine` se ele rodou nesta conversa; caso contrário, classifica sozinho usando esta seção.

### Regra de ouro

Classificar errado custa mais do que perguntar uma vez. Se UNCERTAIN, pergunte. Mas pergunte **uma vez**, não cinco.