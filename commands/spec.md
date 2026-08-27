---
description: Gera especificação estruturada a partir de pedido refinado ou ideia direta
agent: plan
---

Você está executando `/spec`. Gere uma **Specification** estruturada.

**Este comando NUNCA implementa nada.** Apenas especifica.

## Input
$ARGUMENTS

## Filosofia

O `/spec` aceita dois tipos de input:

1. **Pedido direto:** `/spec criar sistema de cupons`
   → Faz mini-refine inline se info crítica faltar
2. **Pedido refinado:** `/spec` (após `/refine` já ter rodado)
   → Herda classificação e respostas do `/refine` no contexto da conversa
   → Não pergunta de novo o que já foi respondido

```
INPUT (direto ou já refinado)
   ↓
[classify]  — herda de /refine ou classifica
   ↓
[gather context]  — AGENTS.md, .opencode/context, README, código
   ↓
[critical info check]  — o que bloqueia gerar spec?
   ↓
[ask if critical]  — 1-3 perguntas BLOQUEANTES (não mais)
   ↓
[complexity assessment]  — SMALL / MEDIUM / LARGE
   ↓
[generate spec]  — estrutura varia por complexidade
   ↓
[readiness]  — READY / READY WITH ASSUMPTIONS / NOT READY
   ↓
[recommend]  — comando de implementação
```

## Workflow detalhado
**`@harness/workflows/specification.md`** — leia para entender cada fase.

## Módulos de apoio (carregue sob demanda via @)

- `@harness/workflows/specification.md` — workflow completo
- `@harness/core/task-classification.md` — classificação
- `@harness/core/context-strategy.md` — estratégia de contexto
- `@harness/core/principles.md` — regras globais
- `@harness/profiles/generic.md` — sempre
- `@harness/profiles/php.md` ou `@harness/profiles/laravel.md` se aplicável
- `@harness/gates/discovery.md` — checklist do que mapear
- `@harness/gates/planning.md` — estrutura de plano

## Regras inegociáveis

1. **Nunca inventar requisitos** — se não foi dito/confirmado, marque como `INFERRED` ou `UNKNOWN`.
2. **Distinguir claramente no output:**
   - `CONFIRMED` — dito pelo usuário ou evidência no código
   - `INFERRED FROM PROJECT` — deduzido de padrões existentes
   - `ASSUMPTION` — assumido para destravar a spec, mas precisa validação
   - `UNKNOWN` — informação crítica ausente
3. **Perguntas críticas no máximo 3.** Mais que isso é burocracia.
4. **Não forçar arquitetura** — descrever considerações baseadas na arquitetura existente.
5. **Não inventar endpoints, nomes de API, schema de banco** — só descrever o que o projeto tem ou o que foi pedido.
6. **Não criar arquivos automaticamente** — saída sempre inline (no chat).
7. **Respeitar AGENTS.md** do projeto como fonte autoritativa.
8. **Escalar profundidade da spec conforme complexidade** — não usar template gigante para tarefa trivial.

## Complexidade da spec

| Tamanho | Quando | Estrutura |
|---|---|---|
| SMALL | 1 arquivo, escopo claro, sem regras de negócio | Enxuta: Title, Type, Problem, Requirements, AC |
| MEDIUM | 2-5 arquivos, padrão identificável | Completa padrão |
| LARGE | 5+ arquivos, integrações, regras complexas | Completa + Edge Cases + Risks + Data/API/Integration Impact |

## Saída esperada

Ao final, o usuário recebe uma **Specification** estruturada em markdown com:

- `Implementation Readiness` claro (READY / READY WITH ASSUMPTIONS / NOT READY)
- Lista do que foi `CONFIRMED` vs `ASSUMPTION`
- Recomendação do próximo comando (`/feature`, `/bug`, `/refactor`)

## Integração com `/refine` e outros

```text
USER VAGUE → /refine → Refined Request → /spec → Specification → /feature
USER VAGUE → /spec → mini-refine inline → Specification → /feature
USER JÁ CLARO → /spec → Specification → /feature
```

## O que `/spec` nunca faz

- ❌ Não escreve código
- ❌ Não cria arquivos no projeto (`.opencode/specs/`, etc.)
- ❌ Não commita nada
- ❌ Não executa comandos destrutivos
- ❌ Não força Service+Repository se o projeto usa outra coisa
- ❌ Não inventa regras de negócio
- ❌ Não inventa endpoints/nomes/schema

## Próximo passo após entregar a Specification

Recomende UM destes baseado no tipo:
- `/feature` (FEATURE)
- `/bug` (BUGFIX)
- `/refactor` (REFACTOR)
- `/debug` (DEBUG — raro vir do `/spec`; normalmente vai direto para `/debug`)

**Nunca execute o próximo passo automaticamente.** O usuário decide.

Se `Implementation Readiness` for `NOT READY`, **não sugira ir para implementação** — sugira rodar `/refine` novamente com mais informação.