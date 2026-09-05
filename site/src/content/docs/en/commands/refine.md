---
description: Transforma pedido vago em pedido refinado antes de implementar
agent: plan
title: Transforma pedido vago em pedido refinado antes de implementar
translation-status: pending
translation-source: pt-BR
---

Você está executando `/refine`. Transforme um pedido vago em um **Refined Request** estruturado.

**Este comando NUNCA implementa nada.** Apenas clarifica e estrutura.

## Pedido do usuário
$ARGUMENTS

## Filosofia

Não comece gerando uma especificação. Comece entendendo o que falta.

```
VAGUE REQUEST
   ↓
[classify]  — qual o tipo? (FEATURE / BUGFIX / DEBUG / REFACTOR / INVESTIGATION / REVIEW / OTHER)
   ↓
[gather context]  — inspecione AGENTS.md, .opencode/context, README, código
   ↓
[detect gaps]  — o que está faltando baseado no tipo?
   ↓
[filter questions]  — selecione 3-7 perguntas de ALTO VALOR
   ↓
[ask]  — UMA rodada de perguntas. Se já estiver claro, PULE.
   ↓
[output]  — Refined Request estruturado
   ↓
[recommend]  — próximo comando (/spec, /feature, /bug, /debug, /refactor)
```

## Workflow detalhado
**`@harness/workflows/refinement.md`** — leia este arquivo para entender cada fase em detalhe.

## Módulos de apoio (carregue sob demanda via @)

- `@harness/workflows/refinement.md` — workflow completo
- `@harness/core/task-classification.md` — para classificar (estende com confiança + OTHER)
- `@harness/core/context-strategy.md` — estratégia para carregar contexto do projeto
- `@harness/core/principles.md` — regras globais (evidência > suposição)
- `@harness/core/model-strategy.md` — **aplicar reasoning preferido da etapa (low/normal/high)**
- `@harness/profiles/generic.md` — sempre
- `@harness/profiles/php.md` ou `@harness/profiles/laravel.md` se a stack exigir

## Regras inegociáveis

1. **Nunca inventar requisitos.** Se falta informação, pergunte.
2. **Máximo 3-7 perguntas por rodada.** Se só precisa de uma, faça uma.
3. **Só perguntas de alto valor:** afetam negócio, arquitetura, escopo, segurança, auth, dados, integrações, UX, testes, AC?
4. **Não perguntar sobre detalhes triviais** (formatação, naming interno, ordem de campos).
5. **Se o pedido já está claro, PULE as perguntas** e vá direto ao output.
6. **NÃO implementar nada.** Apenas clarificar e estruturar.
7. **Reusar contexto do projeto** quando existir, para evitar perguntas genéricas.
8. **Respeitar AGENTS.md do projeto** — fonte autoritativa de regras do projeto.

## O que `/refine` nunca faz

- ❌ Não escreve código
- ❌ Não cria arquivos no projeto
- ❌ Não commita nada
- ❌ Não executa comandos destrutivos
- ❌ Não faz múltiplas rodadas de perguntas
- ❌ Não pergunta "o que é X" se o projeto já define X

## Saída esperada

Após `/refine`, o usuário recebe um **Refined Request** estruturado (formato em `@harness/workflows/refinement.md`) que pode ser:

- **Direto para `/feature`** se o tipo for claro e info suficiente
- **Refinado e passado para `/spec`** se a tarefa for complexa (3+ arquivos ou regras de negócio)
- **Redirecionado para `/bug` ou `/debug`** se a classificação revelou que é bug, não feature
- **Refinado e passado para `/refactor`** se o problema for estrutural

## Integração com outros commands

| Comando | Integração |
|---|---|
| `/feature`, `/bug`, `/debug`, `/refactor` | Quando recebem input vago, sugerem rodar `/refine` antes |
| `/spec` | Aceita o Refined Request do `/refine` ou um pedido direto; faz mini-refine inline se crítico |

## Próximo passo após entregar o Refined Request

Sempre termine sugerindo UM destes:
- `/spec` (se tarefa complexa — 3+ arquivos, regras de negócio, integrações)
- `/feature` (se feature clara e bem definida)
- `/bug` (se classificado como bug)
- `/debug` (se classificado como debug)
- `/refactor` (se classificado como refactor)
- `/init-project` (se o projeto ainda não tem contexto — `.opencode/context/` ausente)

**Nunca execute o próximo passo automaticamente.** O usuário decide.