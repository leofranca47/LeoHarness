---
description: Implementa uma nova feature seguindo o workflow completo
agent: build
title: Implementa uma nova feature seguindo o workflow completo
translation-status: pending
translation-source: pt-BR
banner:
  content: Conteúdo refletido de **pt-BR** — tradução nativa ainda não disponível.
---

Você está executando `/feature`. Implemente uma nova funcionalidade seguindo o workflow estruturado.

## Pedido do usuário
$ARGUMENTS

## Workflow
**DISCOVER → ANALYZE → PLAN → IMPLEMENT → VALIDATE → REVIEW**

## Módulos de apoio (carregue sob demanda via @)

- `@harness/workflows/feature.md` — workflow detalhado
- `@harness/workflows/tdd.md` — ciclo RED → GREEN → REFACTOR (carregar na fase IMPLEMENT)
- `@harness/gates/discovery.md` — checklist da fase DISCOVER (inclui testing capability discovery)
- `@harness/gates/planning.md` — estrutura do plano
- `@harness/gates/completion.md` — checklist antes de declarar pronto
- `@harness/profiles/generic.md` — sempre
- `@harness/profiles/php.md` ou `@harness/profiles/laravel.md` se a stack exigir
- `@harness/core/context-strategy.md` — para saber o que carregar e quando
- `@harness/core/model-strategy.md` — **aplicar reasoning preferido da etapa; carregar também nas sub-fases `tdd_red` e `implement`**

## Regras gerais

- **Classifique** a tarefa primeiro. Se não for claramente FEATURE, considere `/bug`, `/debug` ou `@investigator`
- **Trivialidades** (1-2 linhas, sem impacto arquitetural) podem pular ANALYZE formal
- **Tarefas médias** (1 arquivo, claro) podem ter um plano curto inline
- **Tarefas grandes** exigem plano explícito antes de implementar
- **Pedido vago?** Se o pedido não tem objetivo claro, escopo definido e critérios de pronto, sugira ao usuário rodar `/refine` antes — ou `/spec` se a tarefa for grande (3+ arquivos, regras de negócio, integrações)

## Antes de começar

1. Leia o `AGENTS.md` do projeto se existir — ele tem prioridade
2. Se `.opencode/context/` existir, use como referência rápida
3. Se não existir, considere rodar `/init-project` primeiro (ou apenas absorva o essencial)

## Fases

### DISCOVER
Procure funcionalidades similares existentes. Identifique padrões. **Não invente.**

### ANALYZE
Impacto direto, indireto, banco, API, filas, cache, testes.

### PLAN
Para tarefas complexas, apresente o plano ao usuário **antes** de implementar. Use a estrutura em `@harness/gates/planning.md`.

### IMPLEMENT
- **Prefira TDD quando prático:** carregar `@harness/workflows/tdd.md` para ciclo RED → GREEN → REFACTOR
- Siga os padrões existentes
- Mudanças mínimas e focadas
- Sem refatorações paralelas
- Reuse abstrações existentes

### VALIDATE
Execute **apenas** comandos que existem no projeto (`@harness/gates/completion.md` tem a lista). **Nunca invente comandos.**

### REVIEW
Revise o diff antes de declarar pronto. Procure por:
- Bugs óbvios
- Testes faltando
- Complexidade desnecessária
- Violações arquiteturais
- Mudanças fora do escopo

## Ao terminar

Resuma o que foi feito e o que ficou sem validação (com motivo).