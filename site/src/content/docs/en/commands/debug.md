---
description: Investiga causa de bug vago ou sintoma desconhecido
agent: build
title: Investiga causa de bug vago ou sintoma desconhecido
---

Você está executando `/debug`. Investigue **sistematicamente** um sintoma sem causa conhecida.

## Sintoma
$ARGUMENTS

## Workflow
**GATHER EVIDENCE → IDENTIFY HYPOTHESES → RANK HYPOTHESES → TEST HYPOTHESES → IDENTIFY ROOT CAUSE → PROPOSE/IMPLEMENT FIX → VALIDATE**

## Sugestão de /refine

Se o pedido chegou sem nenhuma evidência (sem logs, sem erro, sem sintoma claro, sem "o que mudou recentemente"), sugira ao usuário rodar `/refine` antes — vai ajudar a elicitir exatamente o que está sendo observado, quando, com que frequência, e desde quando. Sem essa base, o `/debug` vai gastar tokens formando hipóteses sem ter com o quê.

## Módulos de apoio

- `@harness/workflows/debug.md` — workflow detalhado de debug
- `@harness/core/principles.md` — sempre
- `@harness/core/model-strategy.md` — **aplicar reasoning preferido da etapa (low/normal/high)**

## Regra crítica

**Não faça mudanças aleatórias no código "para ver se resolve".**

Diferencie claramente:
- **EVIDÊNCIA** — fato observado, verificável
- **HIPÓTESE** — explicação possível
- **FATO VERIFICADO** — hipótese confirmada
- **SUPOSIÇÃO** — crença sem evidência

## Diferença entre `/debug` e `/bug`

| `/debug` | `/bug` |
|---|---|
| Sintoma vago, sem causa óbvia | Bug reproduzível, causa plausível |
| Você está formando teorias | Você já tem uma teoria |
| Mudanças precisam ser cirúrgicas e reversíveis | Correção pode ser feita diretamente |
| Saída esperada: causa raiz identificada | Saída esperada: bug corrigido |

## Fases

### GATHER EVIDENCE
Colete sem filtrar:
- Mensagens de erro exatas
- Stack traces
- Logs relevantes
- Comportamento esperado vs observado
- Condições de reprodução

### HYPOTHESES
Liste 3-5 hipóteses candidatas. Seja criativo mas fundamentado.

### RANK
Ordene por:
- Plausibilidade técnica
- Consistência com a evidência
- Facilidade de testar/refutar

### TEST
Para cada hipótese (começando pela mais provável):
- Como você testa/refuta?
- Execute o teste (comando, leitura de código, log)
- Registre o resultado

### ROOT CAUSE
Declare explicitamente quando encontrar: **"A causa raiz é X, evidência Y."**

### FIX
Proponha **antes** de aplicar (a menos que o usuário tenha pedido para ir direto).

### VALIDATE
Confirme que o sintoma desapareceu e nada quebrou.

## Ao terminar

Apresente um relatório estruturado:
1. **Sintoma** (1 linha)
2. **Evidências coletadas** (bullet list)
3. **Hipóteses testadas** (com resultado de cada)
4. **Causa raiz** (1 frase, com evidência)
5. **Fix aplicado** (se aplicável)
6. **Validação** (comandos + resultados)
7. **O que ficou sem validar** (se algo)