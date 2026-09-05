---
title: Critérios de Conclusão
translation-status: pending
translation-source: pt-BR
---
# Critérios de Conclusão

**Tarefa não está pronta quando o código foi escrito.** Está pronta quando foi **validada e revisada**.

## O que constitui "pronto"

Uma tarefa está pronta quando:

```
[1] Código escrito
[2] Validação executada (e passou)
[3] Diff revisado pelo próprio agente
[4] Relatório final entregue ao usuário
```

## Matriz de validação

Diferentes tipos de tarefa exigem diferentes validações.

### Para qualquer mudança de código

| Verificação | Quando | Comando (se aplicável) |
|---|---|---|
| Sintaxe | Sempre | O que o projeto expõe (lint, parse) |
| Testes existentes | Se existem | Ver `commands.md` do projeto |
| Build | Se o projeto tem build | Ver `commands.md` |

### Para FEATURE
- [ ] Sintaxe OK
- [ ] Lint/formatter passou (se existir)
- [ ] Análise estática passou (se existir)
- [ ] Testes existentes ainda passam
- [ ] **TDD_STATUS declarado** (READY/LIMITED/UNAVAILABLE/NOT_APPLICABLE) — ver `@harness/workflows/tdd.md`
- [ ] **Ciclo TDD aplicado** se READY: RED → GREEN → [REFACTOR]
- [ ] Feature funciona ponta-a-ponta (smoke test)

### Para BUGFIX
- [ ] Teste de regressão existe (novo ou identificado) e falha ANTES do fix
- [ ] **TDD_STATUS declarado** — abordagem RED-first via `@harness/workflows/tdd.md`
- [ ] Teste de regressão PASSA depois do fix
- [ ] Outros testes continuam passando
- [ ] Sintoma original não acontece mais (verificação manual ou log)

### Para DEBUG
- [ ] Causa raiz identificada COM evidência
- [ ] Sintoma não acontece mais (mesmo critério de validação do BUGFIX)
- [ ] Logs/observabilidade suficientes para detectar reincidência

### Para REFACTOR
- [ ] Comportamento idêntico (todos os testes passam sem mudança de assertions)
- [ ] Smoke test passou
- [ ] Diff é puramente estrutural (sem mudança de comportamento acidental)
- [ ] Sem drive-by fix disfarçado

### Para REVIEW
- [ ] Categorização de achados feita (CRITICAL/HIGH/MEDIUM/LOW)
- [ ] Cada achado tem `file:linha`
- [ ] Sugestões de correção para HIGH+
- [ ] Reconhecimento de pontos positivos

## Quais validações executar

### Princípio

**Execute apenas validações que:**
1. Existem no projeto (verificadas em `composer.json`, `package.json`, Makefile, CI)
2. São relevantes para a mudança
3. Você confirmou que o comando existe

### Onde encontrar comandos válidos

Antes de validar, SEMPRE verifique:

- `composer.json` → `scripts` (PHP)
- `package.json` → `scripts` (Node)
- `Makefile` → `make <alvo>`
- `.github/workflows/*.yml` → comandos rodados no CI
- `README.md` ou `CONTRIBUTING.md` → menções a comandos
- `.opencode/context/commands.md` se existir

**Nunca invente comandos.** Se `commands.md` não existir e você não tem certeza, declare:

```
**Não validado:** [comando que seria ideal mas não tenho certeza se existe]
**Motivo:** não encontrei referência em composer.json/package.json/Makefile/README
```

## Quando NÃO há validação automatizada

Em projetos legados sem testes, ou em mudanças triviais:

1. **Faça smoke test manual** se possível
2. **Documente** que ficou sem validação automatizada
3. **Sugira** ao usuário adicionar pelo menos um teste mínimo

Não finja que validou. Não minta que testes passam se eles não existem.

## Checklist final antes de declarar pronto

Antes de dizer "concluído" ao usuário:

```
[ ] O código faz o que foi pedido (verifiquei, não assumi)
[ ] Validação executada (qual: ___) → resultado: passou
[ ] Mudanças fora do escopo: nenhuma
[ ] Diff revisado: nenhum problema óbvio
[ ] Pontos sem validação: listados ao usuário (se houver)
[ ] Próximos passos sugeridos (se houver)
```

## Relatório final

Ao usuário, entregue:

1. **O que foi feito** (1-3 frases)
2. **Arquivos alterados** (paths relativos)
3. **Validação executada** (comando + resultado)
4. **O que ficou sem validação** (se houver, com motivo)
5. **Próximos passos** (se houver — adicionar teste, commitar, etc.)

**Nunca declare "pronto" sem ter passado pelo checklist acima.**

## Anti-padrão: declaração prematura

❌ **Errado:**
> "Implementei a feature. Ficou pronto."

✅ **Certo:**
> "Implementei a feature em 3 arquivos (X, Y, Z). Validei com `composer test` (28/28 passou) e `phpstan` (0 erros). Smoke test manual no endpoint também passou. Sugiro adicionar teste específico para o caso de borda X antes do próximo deploy."

A diferença: **evidência e transparência**.