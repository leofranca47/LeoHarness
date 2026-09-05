---
title: "Workflow: REFINEMENT"
---
# Workflow: REFINEMENT

Transformar um pedido vago em um **Refined Request** estruturado, pronto para ser usado por `/spec`, `/feature`, `/bug`, `/debug` ou `/refactor`.

```
VAGUE REQUEST
   ↓
CLASSIFY
   ↓
GATHER PROJECT CONTEXT
   ↓
DETECT GAPS
   ↓
FILTER QUESTIONS (3-7 high-value)
   ↓
ASK (uma rodada, ou pular se já claro)
   ↓
OUTPUT: Refined Request
   ↓
RECOMMEND: próximo comando
```

---

## Fase 1: CLASSIFY

Objetivo: decidir o tipo da tarefa.

### Tipos (reusar `@harness/core/task-classification.md`)

- `FEATURE` — adicionar funcionalidade nova
- `BUGFIX` — comportamento errado reproduzível
- `DEBUG` — sintoma vago, causa desconhecida
- `REFACTOR` — melhorar estrutura sem mudar comportamento
- `INVESTIGATION` — só explorar/entender
- `REVIEW` — analisar diff/código
- `OTHER` — não se encaixa em nenhum

### Confiança

- `CONFIDENT` — tipo é claro pelo pedido
- `UNCERTAIN` — ambíguo, precisa perguntar

### Regra

Se `UNCERTAIN`, faça **uma única pergunta** para desambiguar entre 2 tipos candidatos (ex: "isso é bug ou feature nova?"). Não peça input longo para classificar.

### Saída do CLASSIFY

```markdown
**Tipo:** [TIPO]
**Confiança:** [CONFIDENT | UNCERTAIN]
**Raciocínio:** [1 frase explicando o porquê]
```

---

## Fase 2: GATHER PROJECT CONTEXT

Objetivo: evitar perguntas genéricas que o projeto já responde.

### Fontes (em ordem de prioridade)

1. **AGENTS.md do projeto** — fonte autoritativa. Respeitar sem modificar.
2. **CLAUDE.md do projeto** — idem.
3. **`.opencode/context/project.md`** — propósito e stack.
4. **`.opencode/context/architecture.md`** — camadas, módulos.
5. **`.opencode/context/conventions.md`** — padrões do projeto.
6. **`.opencode/context/decisions.md`** — decisões históricas.
7. **`.opencode/context/commands.md`** — comandos verificados.
8. **README.md / CONTRIBUTING.md** — docs do projeto.
9. **Código fonte** — buscar padrões relevantes via grep/glob.

### Quando o contexto NÃO existe

Se `.opencode/context/` não existir:
- Não pare.
- Não force o usuário a rodar `/init-project` agora.
- Use apenas AGENTS.md (se houver) e o que conseguir ler com grep/glob.
- Ao final, sugira `/init-project` para sessões futuras.

### O que extrair do contexto

- **Funcionalidades similares** — "o projeto já tem X?"
- **Entidades de domínio** — "existe Order? User? Payment?"
- **Padrões arquiteturais** — "usa Service+Repository? Controller+Action?"
- **Regras de negócio explícitas** — "decisões já tomadas em decisions.md"
- **Stack e versão** — para não sugerir coisas incompatíveis

### Use `@investigator` quando precisar

Para mapear "como o sistema faz X?", invoque `@investigator` em vez de fazer você mesmo. Ele é read-only e eficiente.

---

## Fase 3: DETECT GAPS

Objetivo: listar todas as perguntas candidatas baseado no tipo.

### Por tipo

#### FEATURE — perguntas candidatas

| # | Pergunta | Alto valor? |
|---|---|---|
| 1 | Qual problema está sendo resolvido? | SEMPRE |
| 2 | Quem vai usar? | Geralmente sim |
| 3 | Qual o resultado esperado? | SEMPRE |
| 4 | Quais as regras de negócio envolvidas? | SEMPRE |
| 5 | O que está dentro do escopo? | SEMPRE |
| 6 | O que está explicitamente fora do escopo? | Às vezes |
| 7 | Há regras de permissão/autorização? | Quando envolve auth |
| 8 | Afeta comportamento existente? | Quando toca código existente |
| 9 | Precisa de integração externa? | Quando envolve API/pagador/etc |
| 10 | Quais os critérios de aceitação? | SEMPRE |
| 11 | Há dados novos ou mudança de schema? | Quando envolve persistência |
| 12 | Como o usuário vai descobrir/usar? | Quando UX é relevante |
| 13 | Há restrições de prazo/plataforma/dispositivo? | Às vezes |
| 14 | Como medir sucesso? | Quando métrica importa |

#### BUGFIX — perguntas candidatas

| # | Pergunta | Alto valor? |
|---|---|---|
| 1 | Comportamento atual (obtido)? | SEMPRE |
| 2 | Comportamento esperado? | SEMPRE |
| 3 | Como reproduzir? Passos exatos? | SEMPRE |
| 4 | Mensagem de erro exata? | Quando há erro |
| 5 | Stack trace disponível? | Quando há erro |
| 6 | Quando começou? | Geralmente sim |
| 7 | Acontece consistentemente ou intermitente? | SEMPRE |
| 8 | Quais ambientes são afetados? | SEMPRE |
| 9 | Dados específicos envolvidos? | Às vezes |
| 10 | Há workaround? | Às vezes |

#### DEBUG — perguntas candidatas

| # | Pergunta | Alto valor? |
|---|---|---|
| 1 | Qual o sintoma observado? | SEMPRE |
| 2 | Que evidência já existe? | SEMPRE |
| 3 | Logs disponíveis? | Quando há logs |
| 4 | Mensagem de erro? | Quando há erro |
| 5 | Quando acontece? | SEMPRE |
| 6 | Com que frequência? | SEMPRE |
| 7 | O que mudou recentemente? | SEMPRE |
| 8 | Quais hipóteses você já tem? | Às vezes |

#### REFACTOR — perguntas candidatas

| # | Pergunta | Alto valor? |
|---|---|---|
| 1 | Qual problema existe no código atual? | SEMPRE |
| 2 | O que deve melhorar? | SEMPRE |
| 3 | Que comportamento deve permanecer idêntico? | SEMPRE |
| 4 | Qual escopo é permitido? | SEMPRE |
| 5 | Quais os riscos? | Geralmente sim |
| 6 | Há cobertura de testes suficiente? | SEMPRE |
| 7 | Refactor + mudança de comportamento? | SEMPRE (para separar) |

#### INVESTIGATION — perguntas candidatas

| # | Pergunta | Alto valor? |
|---|---|---|
| 1 | Qual pergunta precisa ser respondida? | SEMPRE |
| 2 | Que decisão depende dessa resposta? | SEMPRE |
| 3 | Que evidência é necessária? | SEMPRE |
| 4 | Há prazo/urgência? | Às vezes |

---

## Fase 4: FILTER QUESTIONS

Objetivo: das 10-15 candidatas, escolher **3 a 7** de alto valor.

### Critério "alto valor"

A pergunta é de alto valor **SE** a resposta pode mudar:
- Comportamento de negócio
- Arquitetura
- Escopo (in/out)
- Segurança
- Autorização
- Integridade de dados
- Integrações externas
- Comportamento de API
- Experiência do usuário
- Estratégia de teste
- Critérios de aceitação

### Critério "NÃO perguntar"

**NÃO pergunte** sobre:
- Detalhes de implementação (qual framework usar, qual padrão interno)
- Preferências estilísticas (formatação, naming)
- Coisas que o projeto já define (procure no contexto antes)
- Coisas que você pode inferir (ex: "precisa de auth?" se é endpoint público)
- "O que é X?" se X é claro pelo pedido ou contexto

### Quando pular perguntas inteiramente

Se após DETECT GAPS você perceber que:
- O pedido já cobre objetivo, escopo, AC, regras de negócio
- O contexto do projeto cobre o resto (entidades, padrões, restrições)
- As "perguntas restantes" são triviais

**Pule a fase ASK** e vá direto para OUTPUT.

### Número de perguntas

| Caso | Nº de perguntas |
|---|---|
| Pedido direto, contexto rico | 0-3 |
| Pedido vago, contexto médio | 3-5 |
| Pedido muito vago, sem contexto | 5-7 |

**Máximo absoluto: 7. Se precisar de mais, é porque o pedido é grande demais para um único /refine — divida em partes.**

---

## Fase 5: ASK

Objetivo: UMA rodada de perguntas focadas.

### Formato

Faça as perguntas **claramente numeradas** e em **uma única mensagem**. Não faça múltiplas rodadas.

```markdown
Para gerar o Refined Request com qualidade, preciso entender:

1. **[Pergunta sobre comportamento de negócio]**
   [Por que importa — 1 frase]

2. **[Pergunta sobre escopo]**
   [Por que importa — 1 frase]

3. **[Pergunta sobre AC]**
   [Por que importa — 1 frase]

Você pode responder em texto livre, ou apontar para contexto existente
(ex: "veja o decisions.md, decisão #3").
```

### Quando o usuário responde parcialmente

- Use o que foi respondido.
- Marque lacunas restantes como `UNKNOWN` no output.
- NÃO faça segunda rodada de perguntas. Aceite lacunas.

---

## Fase 6: OUTPUT

Gerar o **Refined Request** estruturado.

### Template

```markdown
# Refined Request

## Task Type

[FEATURE | BUGFIX | DEBUG | REFACTOR | INVESTIGATION | REVIEW | OTHER]

**Confidence:** [CONFIDENT | UNCERTAIN]

## Objective

[Descrição clara do resultado desejado. 1-3 frases.]

## Context

[Contexto relevante do projeto ou do negócio. Use AGENTS.md, .opencode/context/, README. Se nada existir, escreva "Sem contexto prévio do projeto."]

## Problem

[O problema que está sendo resolvido. Se não aplicável, escreva "N/A — tarefa aditiva."]

## Expected Behavior

[Comportamento esperado, descrito de forma concreta e testável.]

## Requirements

[Requisitos concretos, em bullet list. Cada requisito deve ser uma frase declarativa.]

- [Requisito 1]
- [Requisito 2]
- [...]

## Business Rules

[Só regras confirmadas. Se não houver, escreva "Nenhuma regra explícita identificada."]

## Scope

**Incluído:**
- [...]

**Não-Goals (se conhecido):**
- [...]

## Constraints

[Restrições técnicas ou de projeto. Ex: "PHP 8.1+", "deve funcionar com Redis atual", "sem nova dependência".]

## Open Questions

[Apenas perguntas cuja resposta muda materialmente o trabalho. Se não houver, escreva "Nenhuma."]

## Suggested Acceptance Criteria

**Oriente os ACs para serem observáveis e testáveis.** Isso facilita o ciclo TDD em `/feature` ou `/bug`.

| ❌ Fraco | ✅ Melhor |
|---|---|
| "O sistema deve funcionar corretamente" | "Admin pode cancelar pedido em status PENDING" |
| "Validação adequada" | "Cadastro rejeita CPF duplicado com erro 'CPF já cadastrado'" |
| "Boa performance" | "Lista de 1000 pedidos carrega em < 500ms" |

Cada AC deve descrever:
- Quem faz (ou sofre) a ação
- Sob que condição
- Qual o resultado observável

```markdown
- [ ] [AC 1 — observável e testável: ator + condição + resultado]
- [ ] [AC 2]
- [ ] [...]
```

**Não gere testes durante `/refine`** — isso é papel do `/feature` ou `/bug` quando carregarem `@harness/workflows/tdd.md`.

## Recommended Next Step

[Um destes: /spec | /feature | /bug | /debug | /refactor | /init-project]

**Justificativa:** [Por que este e não outro? Em 1-2 frases.]
```

### Tom

- Direto (sem floreio)
- Concreto (sem abstração desnecessária)
- Calibrado (não inflar nem subestimar)
- Honesto (admita `UNKNOWN` onde houver)

---

## Fase 7: RECOMMEND

Escolher o próximo comando baseado no tipo e na complexidade.

### Matriz de recomendação

| Tipo | Complexidade | Recomendar |
|---|---|---|
| FEATURE | Trivial (1-2 arquivos) | `/feature` direto |
| FEATURE | Média (3-5 arquivos) | `/spec` → `/feature` |
| FEATURE | Grande (5+ arquivos) | `/spec` → `/feature` |
| BUGFIX | Qualquer | `/bug` direto |
| DEBUG | Qualquer | `/debug` direto |
| REFACTOR | Qualquer | `/spec` → `/refactor` |
| INVESTIGATION | Qualquer | `@investigator` direto |
| REVIEW | Qualquer | `/review` direto |
| OTHER | — | Perguntar ao usuário o que fazer |

### Sem contexto prévio do projeto

Se `.opencode/context/` não existir E a tarefa for não-trivial:
- Recomende `/init-project` antes de `/feature`/`/bug`/etc.
- Explique que vai economizar tempo em perguntas futuras.

---

## Anti-padrões

- ❌ Mais de 7 perguntas
- ❌ Múltiplas rodadas de perguntas
- ❌ Perguntar o que o projeto já diz
- ❌ Inventar regras de negócio
- ❌ Pular DETECT GAPS e ir direto para output
- ❌ Recomendar implementação sem classificar antes
- ❌ Executar o próximo comando automaticamente

## Quando parar

`/refine` termina quando:
1. O Refined Request está completo no output, **E**
2. A recomendação de próximo passo foi dada.

**Nunca** continua além disso. Nunca implementa. Nunca cria arquivos.

---

## Exemplo completo (ilustrativo)

**Input:**
```
/refine quero melhorar o cadastro de usuários
```

**Depois de CLASSIFY (FEATURE, CONFIDENT) e GATHER CONTEXT (Laravel 10, PHP 8.2, sem AGENTS.md do projeto, sem .opencode/context/):**

**ASK (3 perguntas):**
```markdown
Para gerar um Refined Request com qualidade, preciso entender:

1. **Qual problema o cadastro atual tem?** (lentidão? bugs? UX ruim? falta de campos?)
   [Saber o "por quê" define escopo e tipo de solução.]

2. **Os usuários são quem?** (clientes finais? admins? ambos?)
   [Define auth, perfil, e como o cadastro é acessado.]

3. **Há regras de validação específicas?** (documento único? idade mínima? verificação?)
   [Define regras de negócio que viram validação no FormRequest.]
```

**Depois de respostas, OUTPUT:**
```markdown
# Refined Request

## Task Type
FEATURE
**Confidence:** CONFIDENT

## Objective
Melhorar o cadastro de usuários para suportar validação de CPF único,
idade mínima de 18 anos, e melhor feedback visual de erros.

## Context
Laravel 10 com PHP 8.2. Stack detectada via composer.json.
Sem AGENTS.md nem .opencode/context/ no projeto.
Profile Laravel carregado.

## Problem
Cadastro atual aceita CPFs duplicados e não valida idade.

## Expected Behavior
- Cadastro rejeita CPF duplicado com mensagem clara.
- Cadastro rejeita menores de 18 anos.
- Erros aparecem inline no formulário.

## Requirements
- Validar CPF único no FormRequest StoreUserRequest
- Validar idade >= 18 no FormRequest
- Exibir erros inline no template de cadastro

## Business Rules
- CPF único por usuário
- Idade mínima 18 anos

## Scope
**Incluído:** StoreUserRequest, validações, template.
**Não-Goals:** edição de perfil (escopo separado).

## Constraints
- Manter compat com código existente em UserController.
- Não adicionar nova dependência.

## Open Questions
Nenhuma.

## Suggested Acceptance Criteria
- [ ] Cadastro com CPF duplicado retorna erro "CPF já cadastrado"
- [ ] Cadastro com data de nascimento < 18 retorna erro "Idade mínima 18 anos"
- [ ] Erros aparecem inline no template

## Recommended Next Step
/spec → /feature

**Justificativa:** Tarefa pequena mas com regras de negócio
claras; spec ajuda a alinhar antes de codificar.
```

---

## Integração com outros commands

- `/spec` lê este output (se houver) e usa como base.
- `/feature`, `/bug`, `/debug`, `/refactor` quando recebem input vago, sugerem `/refine` primeiro.
- `/init-project` quando contexto está ausente, prepara o terreno para `/refine` futuros.