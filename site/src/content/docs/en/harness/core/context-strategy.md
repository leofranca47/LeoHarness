---
title: Estratégia de Carregamento de Contexto
translation-status: pending
translation-source: pt-BR
banner:
  content: Conteúdo refletido de **pt-BR** — tradução nativa ainda não disponível.
---
**Nada do `harness/` é carregado por padrão.** Carregue sob demanda via `@`.

## Princípio

```
TAREFA
   ↓
CLASSIFICAR (FEATURE / BUGFIX / DEBUG / REFACTOR / REVIEW / INVESTIGATION)
   ↓
IDENTIFICAR CONTEXTO RELEVANTE
   ↓
CARREGAR APENAS O NECESSÁRIO
   ↓
EXPLORAR CÓDIGO QUANDO PRECISAR
```

## Mapa de carregamento por tipo de tarefa

### Tarefa de arquitetura
**Priorize:**
- `architecture.md` (em `.opencode/context/`)
- `decisions.md`
- `@architect` (subagent)
- `@harness/profiles/generic.md` ou profile específico

**Evite carregar:**
- Workflows detalhados
- Templates
- Gates

### Tarefa de implementação (FEATURE)
**Priorize:**
- `conventions.md`
- `architecture.md` (resumo)
- `@harness/workflows/feature.md`
- `@harness/gates/discovery.md` (se complexo)
- `@harness/gates/planning.md` (se complexo)
- `@harness/profiles/<stack>.md`

### Tarefa de bug
**Priorize:**
- `architecture.md` (se bug arquitetural)
- `conventions.md` (se viola padrão)
- `@harness/workflows/bugfix.md`
- `@harness/core/principles.md`
- `@investigator` ou `@debugger` se vago

### Tarefa de debug
**Priorize:**
- `@harness/workflows/debug.md`
- `@harness/core/principles.md`
- `@debugger` (subagent)

**Evite carregar:**
- Workflows de FEATURE/REFACTOR
- Templates

### Tarefa de review
**Priorize:**
- `@harness/workflows/review.md`
- `conventions.md`
- Profile específico (PHP/Laravel)
- `@reviewer` (subagent)

### Tarefa de investigação
**Priorize:**
- `architecture.md` se existir
- `@investigator` (subagent)
- Profiles conforme stack

**Evite carregar:**
- Gates
- Workflows (não está implementando ainda)

## Quando carregar o quê

### Profile de tecnologia
Carregue apenas UM profile, baseado na stack detectada:

| Detecção | Carregar |
|---|---|
| `composer.json` com `laravel/framework` | `@harness/profiles/laravel.md` |
| `composer.json` sem framework | `@harness/profiles/php.md` |
| Sem PHP detectado | `@harness/profiles/generic.md` |
| Múltiplas stacks | Carregue todas, mas cite apenas a relevante |

**Profile carrega em cima do genérico.** O profile assume que `@harness/profiles/generic.md` já foi lido.

### Workflows
Carregue apenas o workflow do tipo atual:

- Implementando feature → `@harness/workflows/feature.md`
- Corrigindo bug → `@harness/workflows/bugfix.md`
- Investigando → `@harness/workflows/investigation.md`

**Não carregue todos "por garantia".** Cada workflow tem 2-5KB.

### Gates
Carregue gates apenas quando estiver naquela fase:

- Em DISCOVER → `@harness/gates/discovery.md`
- Em PLAN → `@harness/gates/planning.md`
- Em VALIDATE/REVIEW (final) → `@harness/gates/completion.md`

## Hierarquia de leitura

Se múltiplos arquivos são relevantes, leia nesta ordem:

```
1. AGENTS.md do projeto (se existir) — fonte autoritativa
2. .opencode/context/project.md — visão geral
3. .opencode/context/conventions.md — padrões
4. .opencode/context/architecture.md — estrutura
5. .opencode/context/decisions.md — contexto histórico
6. .opencode/context/commands.md — comandos disponíveis
```

Não leia tudo de uma vez. Puxe conforme a pergunta surge.

## Lazy loading em prática

### Bom
```
Usuário: "implementar export CSV de usuários"

Você:
1. Carrega @harness/workflows/feature.md
2. Carrega @harness/profiles/laravel.md (detectou Laravel)
3. Executa DISCOVER (lê código do projeto, não o harness)
4. Carrega @harness/gates/planning.md antes de PLAN
```

### Ruim (carrega demais)
```
Usuário: "implementar export CSV"

Você:
1. Carrega TODOS os workflows
2. Carrega TODOS os profiles
3. Carrega TODOS os gates
4. Carrega TODOS os cores
= gastou 30k tokens antes de fazer qualquer coisa
```

## Indicadores de over-loading

Se você está gastando muitos tokens sem progredir:

- Carregou um arquivo mas nunca referenciou → carregou à toa
- Carregou 3+ profiles → só 1 é relevante
- Carregou todos os gates → só 1-2 são necessários
- Carregou workflow de BUGFIX durante FEATURE → classificou errado

**Solução:** descarregue mentalmente. Foque no que está em mãos.

## Cache mental

Conforme você trabalha, mantenha **na cabeça** (não no contexto):

- Padrões do projeto já identificados
- Arquivos-chave já localizados
- Comandos do projeto já descobertos

Releitura custa tokens. Memória é grátis.