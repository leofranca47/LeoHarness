---
description: Refatora código preservando comportamento
agent: build
---

Você está executando `/refactor`. Melhore a estrutura interna **sem alterar comportamento observável**.

## Alvo da refatoração
$ARGUMENTS

## Workflow
**ANALYZE → IDENTIFY DEPENDENCIES → VERIFY TEST COVERAGE → PLAN → REFACTOR → VALIDATE BEHAVIOR → REVIEW**

## Sugestão de /refine e /spec

Se o pedido chegou vago ("esse código está ruim", "melhorar isso aqui"), sugira rodar `/refine` antes para elicitar: qual o problema específico (acoplamento? duplicação? complexidade?), que comportamento deve permanecer idêntico, qual o escopo permitido, e se há cobertura de testes. Para refactors grandes (5+ arquivos, mudança de arquitetura), recomende `/refine` → `/spec` → `/refactor` para alinhar antes de mexer.

## Módulos de apoio

- `@harness/workflows/refactor.md` — workflow detalhado
- `@harness/workflows/tdd.md` — para characterization tests em código legado + TDD quando adicionar testes
- `@harness/gates/completion.md` — checklist
- `@harness/core/principles.md`
- `@harness/core/model-strategy.md` — **aplicar reasoning preferido da etapa (low/normal/high)**

## Regra crítica

**Refatoração preserva comportamento.** Se o comportamento precisa mudar, isso é uma feature/bug, não refactor.

Exceção: o usuário pediu explicitamente para mudar comportamento junto com a refatoração. Nesse caso, declare isso claramente.

## Fases

### ANALYZE
- Qual é a estrutura atual?
- O que exatamente está ruim? (acoplamento, duplicação, complexidade, naming)
- Qual é a estrutura desejada?

### DEPENDENCIES
- Quem usa o código a ser refatorado?
- Quantos call sites?
- Algum é externo (API pública, contrato)?
- Algum é hot path (performance-sensitive)?

### TEST COVERAGE
**Obrigatório** ter cobertura de testes adequada antes de refatorar.

Se a cobertura for insuficiente:
1. PARE
2. Adicione testes que travam o comportamento atual
3. Para código legado sem cobertura clara, use **characterization tests** (carregue `@harness/workflows/tdd.md` para detalhes)
4. Depois prossiga

Não refatore código descoberto — vai quebrar produção.

### PLAN
Apresente o plano:
- Estrutura atual
- Estrutura alvo
- Passos ordenados (commits intermediários se grandes)
- Riscos
- Estratégia de rollback

Para refactors grandes (>5 arquivos), **obtenha aprovação do usuário antes**.

### REFACTOR
- Mudanças pequenas e validáveis
- Após cada passo, rode os testes
- Se um teste falhar: pare, reverta, investigue

### VALIDATE BEHAVIOR
Comportamento idêntico ao anterior:
- Todos os testes existentes passam
- Smoke test manual se aplicável
- Resposta de API idêntica (para endpoints)

### REVIEW
- Diff é puramente estrutural? (sem mudança de comportamento)
- Sem "melhorias" extras escondidas?
- Comentários foram ajustados onde necessário?

## Tipos comuns de refactor

- Extrair método/classe
- Mover método/classe
- Renomear (com cuidado com APIs públicas)
- Substituir condicional por polimorfismo
- Introduzir/objetos de valor
- Remover código morto (cuidado: confirme que está morto)

## Ao terminar

- Liste arquivos alterados
- Liste testes executados + resultado
- Confirme que comportamento foi preservado (com evidência)
- Confirme que nenhum "drive-by fix" foi incluído