---
title: "Workflow: SPECIFICATION"
translation-status: pending
translation-source: pt-BR
---
# Workflow: SPECIFICATION

Gerar uma **Specification** estruturada a partir de um pedido refinado ou direto.

```
INPUT (refined request OU pedido direto)
   ↓
CLASSIFY (herda do /refine ou classifica)
   ↓
GATHER PROJECT CONTEXT
   ↓
CRITICAL INFO CHECK
   ↓
ASK IF CRITICAL (1-3 perguntas BLOQUEANTES)
   ↓
COMPLEXITY ASSESSMENT (SMALL / MEDIUM / LARGE)
   ↓
GENERATE SPEC (estrutura varia)
   ↓
READINESS (READY / READY WITH ASSUMPTIONS / NOT READY)
   ↓
RECOMMEND (comando de implementação)
```

---

## Fase 1: CLASSIFY

### Se veio de /refine

O Refined Request já tem `Task Type` declarado. Use-o.

### Se veio direto (sem /refine)

Tente classificar usando `@harness/core/task-classification.md`. Se UNCERTAIN:

- **FEATURE com elementos de bug?** → trate como FEATURE (recomendar /bug se o foco for correção)
- **INFO muito vaga?** → pule para `ASK IF CRITICAL` antes de classificar

---

## Fase 2: GATHER PROJECT CONTEXT

Mesma estratégia de `/refine` (reusar `@harness/workflows/refinement.md` Fase 2).

Fontes em ordem:
1. AGENTS.md do projeto (sem modificar)
2. CLAUDE.md (sem modificar)
3. `.opencode/context/project.md`
4. `.opencode/context/architecture.md`
5. `.opencode/context/conventions.md`
6. `.opencode/context/decisions.md`
7. README.md
8. Código (grep/glob)

Use `@investigator` para mapear "como o sistema faz X?" quando relevante.
Use `@architect` para avaliar impacto arquitetural de uma decisão proposta.

---

## Fase 3: CRITICAL INFO CHECK

Diferente de `/refine`, `/spec` só pergunta sobre o que **bloqueia** gerar a spec.

### O que é bloqueante vs. o que é "alto valor"

| `/refine` pergunta | `/spec` pergunta |
|---|---|
| Alto valor (3-7 perguntas) | **Bloqueante** (1-3 perguntas, ou zero) |
| Negócio, escopo, UX, AC | Só o que impede gerar spec útil |
| Pode ter múltiplas rodadas | **Apenas uma rodada**, sem follow-ups |

### O que é bloqueante para spec?

- Tipo da tarefa (se incerto)
- Regra de negócio que muda toda a arquitetura (ex: "soft delete ou hard?")
- Se há integração externa (ex: "vai chamar API de pagamento?")
- Se há regra de permissão crítica (ex: "só admin pode X?")
- Tamanho do escopo (se incerto, perguntar para dimensionar complexidade)

### O que NÃO é bloqueante

- Preferências de UX (assuma razoável, marque como ASSUMPTION)
- Detalhes de API (não invente endpoint, escreva "endpoint a definir")
- Schema exato de banco (escreva "campos necessários: X, Y, Z" sem prescrever tipos)
- Naming interno (use placeholder)

---

## Fase 4: ASK IF CRITICAL

Se houver 1-3 perguntas bloqueantes, faça-as **em uma única rodada**.

```markdown
Para gerar a spec com qualidade, preciso de 2 informações bloqueantes:

1. **[Pergunta crítica]**
   [Por que isso muda a spec — 1 frase]

2. **[Pergunta crítica]**
   [Por que isso muda a spec — 1 frase]
```

Se não houver pergunta bloqueante, **pule para COMPLEXITY ASSESSMENT**.

### Regras

- Máximo 3 perguntas.
- Se precisar de mais, o pedido é grande demais para uma spec — divida.
- Uma única rodada. Sem follow-up.

---

## Fase 5: COMPLEXITY ASSESSMENT

Determine SMALL / MEDIUM / LARGE para dimensionar a profundidade da spec.

### SMALL

Use quando:
- 1 arquivo (ou poucos muito coesos)
- Sem regras de negócio complexas
- Sem integrações externas
- Sem mudança de schema
- Mudança trivial de comportamento

Spec SMALL = 1 página. Não usar template completo.

### MEDIUM

Use quando:
- 2-5 arquivos
- Algumas regras de negócio
- Pode envolver mudança de schema
- Pode ter 1 integração externa
- Critérios de aceitação claros

Spec MEDIUM = estrutura padrão completa.

### LARGE

Use quando:
- 5+ arquivos
- Regras de negócio complexas
- Múltiplas integrações externas
- Mudança significativa de schema ou arquitetura
- Equipe precisa estar alinhada

Spec LARGE = estrutura completa + Edge Cases + Risks + Data/API/Integration Impact.

---

## Fase 6: GENERATE SPEC

A estrutura muda conforme a complexidade.

### Estrutura SMALL

```markdown
# Specification

## Title
[Curto e descritivo]

## Task Type
[FEATURE | BUGFIX | REFACTOR | etc.]

## Problem Statement
[1-2 frases]

## Objective
[1-2 frases]

## Functional Requirements
- [R1]
- [R2]

## Acceptance Criteria
- [ ] [AC 1]
- [ ] [AC 2]

## Implementation Readiness
[READY | READY WITH ASSUMPTIONS | NOT READY]
[Se WITH ASSUMPTIONS, listar]

## Recommended Next Step
[/feature | /bug | /refactor]
```

### Estrutura MEDIUM (padrão)

```markdown
# Specification

## Title
[Curto e descritivo]

## Task Type
[FEATURE | BUGFIX | REFACTOR | etc.]

## Problem Statement
[2-4 frases descrevendo o problema]

## Objective
[1-3 frases — como é o sucesso]

## Background / Context
[Contexto relevante: de /refine, AGENTS.md, .opencode/context/, decisões conhecidas]

## Scope
**Incluído:**
- [...]

**Out of Scope:**
- [...]

## Functional Requirements
- [R1 — declarativo]
- [R2]
- [...]

## Business Rules
[Só regras confirmadas. Marcar (CONFIRMED) ou (INFERRED FROM PROJECT).]

## User Flow
[Se aplicável, descrever o fluxo esperado.]

## Permissions and Authorization
[Se aplicável — quem pode fazer o quê.]

## Data Impact
- New data: [tabelas/coleções/campos novos]
- Existing changes: [mudanças em tabelas/registros existentes]
- Migrations: [sim/não, descrição]
- Integrity: [constraints, índices]

## API Impact
[Se aplicável:]
- Inputs: [...]
- Outputs: [...]
- Error behavior: [...]
- Compatibility: [...]

## Integration Impact
[Se aplicável:]
- External APIs: [...]
- Events: [...]
- Queues: [...]
- Notifications: [...]
- Webhooks: [...]

## Technical Considerations
[Baseado em arquitetura existente — não prescreva. Descreva o que existe e como isso se encaixa.]

## Edge Cases
- [EC1]
- [EC2]

## Risks
- [R1 — probabilidade / impacto / mitigação]
- [R2]

## Acceptance Criteria
- [ ] [AC 1 — observável, concreto e testável: ator + condição + resultado]
- [ ] [AC 2]
- [ ] [AC 3]

> **Teste behavior, não implementação.** ACs descrevem o que o usuário/sistema observa, não como o código está estruturado internamente. Isso facilita o ciclo TDD em `/feature` ou `/bug`.

## Testing Considerations
[Sempre incluir em MEDIUM/LARGE. Apenas quando útil em SMALL.]

- **Test level recomendado:** [UNIT | FEATURE | INTEGRATION | E2E]
  - Justificativa: [baseada na natureza do comportamento e nas convenções do projeto]
- **Cenários de regressão importantes:**
  - [comportamento existente que NÃO pode quebrar]
  - [outro comportamento existente que NÃO pode quebrar]
- **Edge cases a testar:**
  - [EC1 — caso de borda]
  - [EC2 — entrada inválida]
- **Onde adicionar/alterar testes:** [caminho no projeto, ex: `tests/Feature/UserCancellationTest.php`]

> **Não invente comandos de teste.** Use apenas o que está documentado em `@harness/profiles/<stack>.md` ou descoberto via `@investigator`.

## Validation Strategy
[Comandos que existem no projeto. NÃO invente.]
- [Unit tests via `composer test --filter=X`]
- [Manual smoke test: Y]

## Open Questions
[Apenas se houver perguntas cujas respostas mudam a spec.]

## Implementation Readiness
[READY | READY WITH ASSUMPTIONS | NOT READY]
[Se WITH ASSUMPTIONS ou NOT READY, listar.]

## Recommended Next Step
[/feature | /bug | /refactor]
[Justificativa breve]
```

### Estrutura LARGE

Mesma estrutura MEDIUM, mas **expandir**:

- **Background / Context:** mais profundo (reunião, issue, RFC, links)
- **Functional Requirements:** categorizados (Must / Should / Could / Won't)
- **Edge Cases:** mínimo 5, idealmente 8-10
- **Risks:** com probabilidade, impacto, mitigação explícita
- **Data Impact:** schema completo proposto (sem fixar tipos)
- **API Impact:** contrato completo proposto
- **Integration Impact:** cada integração com sequência de chamadas
- **Acceptance Criteria:** 10+ ACs cobrindo happy path + edge cases + erros
- **Validation Strategy:** detalhada por tipo de teste

### Regras comuns

#### Marcar fontes

Ao longo da spec, marque a fonte de cada afirmação importante:

- `(CONFIRMED)` — dito pelo usuário
- `(INFERRED FROM PROJECT)` — deduzido de padrão existente
- `(ASSUMPTION)` — assumido para destravar, precisa validação
- `(UNKNOWN)` — informação crítica ausente

Exemplo:
```markdown
## Business Rules

- Pedido pode ser cancelado até 24h após criação (CONFIRMED)
- Cancelamento reembolsa 100% se antes do envio (INFERRED FROM PROJECT — ver conventions.md)
- Cliente recebe e-mail de confirmação após cancelamento (ASSUMPTION — validar com PO)
```

#### Não inventar

- ❌ Não invente regras de negócio (use CONFIRMED ou ASSUMPTION explícito)
- ❌ Não invente endpoints (escreva "endpoint a definir com base em padrão Y do projeto")
- ❌ Não invente schema de banco (escreva "campos necessários: X, Y, Z" sem tipos fixos)
- ❌ Não force arquitetura (descreva considerações baseadas no que existe)

---

## Fase 7: READINESS

Decida `READY` / `READY WITH ASSUMPTIONS` / `NOT READY`.

### READY

Use quando:
- Todas as perguntas críticas foram respondidas
- Não há suposições que mudariam a implementação
- Contexto do projeto é suficiente

### READY WITH ASSUMPTIONS

Use quando:
- Há suposições marcadas como ASSUMPTION
- As suposições não mudam a abordagem geral
- A implementação pode começar, mas precisa validação contínua

**Liste todas as suposições no campo correspondente.**

### NOT READY

Use quando:
- Falta informação que muda materialmente a implementação
- Conflitos de regras não resolvidos
- Decisões de negócio bloqueantes pendentes

**Liste o que falta no campo Open Questions.** Não sugira ir para implementação; sugira rodar `/refine` novamente.

---

## Fase 8: RECOMMEND

Baseado no Task Type:

| Tipo | Recomendar |
|---|---|
| FEATURE | `/feature` |
| BUGFIX | `/bug` |
| REFACTOR | `/refactor` |
| DEBUG | `/debug` (raro vir de /spec) |
| INVESTIGATION | `@investigator` (raro vir de /spec) |

Se `NOT READY`, recomende `/refine` para preencher lacunas.

---

## Anti-padrões

- ❌ Spec gigante para tarefa trivial
- ❌ Spec genérica que não menciona a arquitetura real do projeto
- ❌ Inventar endpoints/schema/regras
- ❌ Mais de 3 perguntas bloqueantes
- ❌ Múltiplas rodadas de perguntas
- ❌ Forçar Service+Repository se projeto usa outra coisa
- ❌ Implementar qualquer coisa
- ❌ Salvar spec em arquivo automaticamente

---

## Quando parar

`/spec` termina quando:
1. Spec completa foi entregue, **E**
2. Readiness está claro, **E**
3. Próximo comando foi recomendado.

**Nunca** continua além disso.

---

## Exemplo completo (ilustrativo)

**Input:** `/spec` (após /refine ter gerado o Refined Request do exemplo de "melhoria no cadastro de usuários")

**Depois de CLASSIFY (FEATURE), GATHER CONTEXT, e CRITICAL INFO CHECK (sem perguntas — info do /refine é suficiente):**

**COMPLEXITY ASSESSMENT:** MEDIUM (3 arquivos: StoreUserRequest, UserController, template; 2 regras de negócio; sem integração externa)

**GENERATE SPEC (estrutura MEDIUM):**
```markdown
# Specification

## Title
Cadastro de usuários com validação de CPF único e idade mínima

## Task Type
FEATURE (CONFIRMED via /refine)

## Problem Statement
O cadastro atual de usuários permite cadastros com CPF duplicado
e aceita menores de 18 anos, violando regras de negócio e potencialmente
expondo o sistema a cadastros inválidos.

## Objective
Adicionar validação no StoreUserRequest para rejeitar CPFs duplicados
e usuários com menos de 18 anos, exibindo erros inline no template.

## Background / Context
(INFERRED FROM PROJECT) Projeto usa Laravel 10 com FormRequest para
validação centralizada. Controllers são single-action (`__invoke`).
Stack detectada via composer.json.

## Scope
**Incluído:**
- Validação de CPF único
- Validação de idade >= 18
- Exibição inline de erros no template

**Out of Scope:**
- Edição de perfil
- Reset de senha
- Verificação de CPF em API externa

## Functional Requirements
- O cadastro deve rejeitar CPFs já cadastrados (CONFIRMED)
- O cadastro deve rejeitar menores de 18 anos (CONFIRMED)
- Erros de validação devem aparecer inline no formulário (CONFIRMED)

## Business Rules
- CPF único por usuário (CONFIRMED)
- Idade mínima 18 anos (CONFIRMED)

## User Flow
1. Usuário acessa rota de cadastro
2. Preenche formulário (nome, CPF, data de nascimento, email, senha)
3. Submete
4. Se validação falhar → exibe erros inline
5. Se passar → cria usuário e redireciona

## Permissions and Authorization
Rota pública (cadastro aberto). Nenhuma verificação adicional necessária.

## Data Impact
- Nenhuma migration nova
- Campos `cpf` e `data_nascimento` assumidos como existentes em `users`
  (ASSUMPTION — verificar schema antes de implementar)

## API Impact
N/A (rota web)

## Integration Impact
Nenhuma.

## Technical Considerations
- Usar `Rule::unique('users', 'cpf')` no FormRequest
- Para idade, usar `date` + `before:today` ajustado, ou `Date::now()->subYears(18)`
- Erros inline: padrão Laravel (`@error` directive) já é usado em outros templates
  (INFERRED FROM PROJECT — confirmar com conventions.md se existir)

## Edge Cases
- CPF com formatação (pontos/traços) — normalizar antes de validar
- Data de nascimento no futuro — rejeitar (ASSUMPTION)
- Usuário tenta cadastrar duas vezes seguidas (rate limiting — fora do escopo)

## Risks
- Risco: schema não tem `cpf` ou `data_nascimento` — Mitigação: verificar migrations antes
- Risco: UX inconsistente se template atual não usa `@error` — Mitigação: confirmar padrão visual

## Acceptance Criteria
- [ ] Cadastro com CPF duplicado retorna erro "CPF já cadastrado"
- [ ] Cadastro com data de nascimento < 18 anos retorna erro de idade
- [ ] Cadastro com data no futuro retorna erro
- [ ] Erros aparecem inline próximos aos campos
- [ ] Cadastro válido continua funcionando como antes

## Validation Strategy
- Teste feature: `tests/Feature/RegistrationTest.php` (adicionar caso de CPF duplicado e idade)
- Smoke test manual: submeter formulário inválido e verificar erros

## Open Questions
Nenhuma.

## Implementation Readiness
READY WITH ASSUMPTIONS

**Assumptions:**
- Schema de `users` já tem `cpf` e `data_nascimento`
- Padrão visual de erros no template está alinhado com o resto

## Recommended Next Step
/feature

**Justificativa:** Spec clara, escopo pequeno, ACs testáveis,
pronto para implementar com suposições validadas no DISCOVER.
```

---

## Integração com outros commands

```text
USER VAGUE → /refine → Refined Request → /spec → Specification → /feature
USER VAGUE → /spec → mini-refine inline → Specification → /feature
USER JÁ CLARO → /spec → Specification → /feature
```

`/feature` recebe a Specification como input (do contexto da conversa) e usa como base para:
- DISCOVER (validar suposições)
- PLAN (montar plano de implementação)
- IMPLEMENT (seguindo ACs)
- VALIDATE (conferir ACs)
- REVIEW (revisar diff vs spec)