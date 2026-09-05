---
description: Revisa diff ou arquivos modificados sem alterar código
agent: plan
title: Revisa diff ou arquivos modificados sem alterar código
---

Você está executando `/review`. Revise código **sem modificá-lo** (a menos que o usuário peça).

## Alvo da revisão
$ARGUMENTS

## Workflow
**COLLECT DIFF → CLASSIFY FINDINGS → REPORT → (opcional) SUGGEST FIXES**

## Módulos de apoio

- `@harness/workflows/review.md` — workflow detalhado
- `@harness/core/model-strategy.md` — **aplicar reasoning preferido da etapa (low/normal/high)**
- `@harness/profiles/generic.md` — sempre
- `@harness/profiles/php.md` ou `@harness/profiles/laravel.md` se aplicável

## Sem alteração automática

**Não modifique código durante o review.** Apenas relate os achados.

Se o usuário pedir explicitamente "aplique os fixes", aí sim.

## Fases

### COLLECT DIFF
- Se `$ARGUMENTS` não foi passado, use `git diff` (último commit ou staged)
- Se foi passado (arquivo, branch, hash), use isso
- Colete contexto adicional se necessário: arquivos relacionados, testes, callers

### CLASSIFY

Categorize cada achado em:

#### CRITICAL
- Vulnerabilidades de segurança (injection, XSS, CSRF, auth bypass)
- Corrupção de dados
- Breaking change sério
- Vazamento de credenciais

#### HIGH
- Bug funcional
- Validação crítica faltando
- Violação arquitetural séria
- Race condition
- Memory leak óbvio

#### MEDIUM
- Edge case não tratado
- Teste faltando para código novo
- Manutenibilidade ruim
- Acoplamento desnecessário

#### LOW
- Melhoria de estilo
- Naming inconsistente
- Comentários faltando ou obsoletos
- Otimização prematura

### REPORT

Formato sugerido:
```
## Achados CRITICAL (N)
- arquivo:linha — descrição

## Achados HIGH (N)
- ...

## Achados MEDIUM (N)
- ...

## Achados LOW (N)
- ...

## Pontos positivos
- ...
```

Use referências `file:linha` para facilitar navegação.

### SUGGEST FIXES (opcional)

Após o relatório, ofereça:
- Mostrar diff sugerido para cada achado crítico/alto
- NÃO aplicar automaticamente

## Checklist contextual

Além dos achados específicos, valide:
- [ ] Testes para código novo existem
- [ ] Mudanças são focadas (sem drive-by)
- [ ] Sem credenciais/secrets commitados
- [ ] Mensagens de commit claras (se aplicável)
- [ ] Performance aceitável (sem N+1 óbvios, etc.)
- [ ] Tratamento de erro adequado

## Ao terminar

Ofereça próximos passos:
- Corrigir achados CRITICAL/HIGH?
- Adicionar testes?
- Commitar?