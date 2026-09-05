---
description: Corrige um bug reproduzível após identificar a causa raiz
agent: build
title: Corrige um bug reproduzível após identificar a causa raiz
translation-status: pending
translation-source: pt-BR
banner:
  content: Conteúdo refletido de **pt-BR** — tradução nativa ainda não disponível.
---

Você está executando `/bug`. Corrija um bug reproduzível.

## Descrição do bug
$ARGUMENTS

## Workflow
**REPRODUCE → INVESTIGATE → IDENTIFY ROOT CAUSE → CREATE/IDENTIFY REGRESSION TEST → IMPLEMENT MINIMAL FIX → VALIDATE → REVIEW**

## Sugestão de /refine

Se o pedido de bug chegou vago (sem erro claro, sem passos de reprodução, sem ambiente afetado), sugira ao usuário rodar `/refine` antes — vai poupar tempo identificando qual é o sintoma real e separando bug de feature nova. Se o sintoma é intermitente ou vago demais para reprodutível, redirecione para `/debug` em vez de `/bug`.

## Módulos de apoio

- `@harness/workflows/bugfix.md` — workflow detalhado
- `@harness/workflows/tdd.md` — ciclo TDD para a fase REGRESSION TEST (RED-first)
- `@harness/gates/completion.md` — checklist de validação
- `@harness/core/principles.md` — sempre
- `@harness/profiles/generic.md` — sempre
- `@harness/core/model-strategy.md` — **aplicar reasoning preferido da etapa; carregar também nas sub-fases `tdd_red` e `implement`**

## Regra crítica

**NÃO comece corrigindo sintomas.** Investigue a causa raiz primeiro.

Se você não conseguir reproduzir o bug ou não entender a causa raiz **com evidência**, pare e pergunte ao usuário ou redirecione para `/debug`.

## Quando usar `/bug` vs `/debug`

| Use `/bug` quando... | Use `/debug` quando... |
|---|---|
| Você consegue reproduzir | Não consegue reproduzir |
| Sabe aproximadamente onde está | Não sabe nem por onde começar |
| Sintoma é claro | Sintoma é vago |
| Já existe uma teoria da causa | Precisa formar teorias |

## Fases

### REPRODUCE
Confirme que o bug existe com evidência:
- Comando exato
- Input exato
- Output esperado vs obtido
- Logs ou stack trace

### INVESTIGATE
- Quando apareceu? (git blame, histórico)
- O que mudou recentemente?
- Quem usa esse código?

### ROOT CAUSE
- Seja explícito: declare "A causa raiz é X, evidência Y"
- Não pare em "pode ser" — vá até "é"

### REGRESSION TEST
- **Aborde como RED-first:** carregue `@harness/workflows/tdd.md` para o ciclo completo
- Crie OU identifique um teste que falhe antes do fix (não por erro de setup)
- Sem teste de regressão, o bug volta

### MINIMAL FIX
- Menor mudança possível que resolve a causa raiz
- Não reformate código adjacente
- Não melhore performance a menos que pedido

### VALIDATE
- O teste de regressão agora passa
- Nenhum teste existente quebrou

### REVIEW
- O diff é focado?
- Não introduziu novo bug?
- Comentários são úteis (não óbvios)?

## Ao terminar

Mostre:
- Causa raiz em uma frase
- Arquivo(s) alterado(s) com linhas
- Teste de regressão (novo ou existente)
- Comando de validação executado + resultado
- O que ficou sem validação (com motivo)