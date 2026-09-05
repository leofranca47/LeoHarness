---
title: OpenHarness — Global Engineering Harness for OpenCode
---
> Sistema comunitário de engenharia assistida por IA para o OpenCode.

Um conjunto de **comandos** (`/init-project`, `/refine`, `/spec`, `/feature`, `/bug`, `/debug`, `/refactor`, `/review`), **agentes especializados** (`@architect`, `@investigator`, `@debugger`, `@reviewer`) e **módulos de conhecimento** (princípios, workflows, gates, profiles, TDD) que deixam o OpenCode mais previsível, metódico e respeitoso às convenções dos seus projetos.

Funciona em **qualquer stack**: PHP/Laravel, Node, Python, Go, Rust… e é especialmente afinado com **PHP, Laravel, Docker, MySQL/MariaDB, Redis, Filas, APIs** e apps legados ou modernos.

---

## Sumário

1. [O que é](#1-o-que-é)
2. [Arquitetura em 3 camadas](#2-arquitetura-em-3-camadas)
3. [Pré-requisitos](#3-pré-requisitos)
4. [Instalação](#4-instalação)
5. [Atualização](#5-atualização)
6. [Configurando modelos por agente](#6-configurando-modelos-por-agente)
7. [Comandos disponíveis](#7-comandos-disponíveis)
8. [Agentes disponíveis](#8-agentes-disponíveis)
9. [Regras sobre `AGENTS.md` do projeto](#9-regras-sobre-agentsmd-do-projeto)
10. [Estrutura de arquivos](#10-estrutura-de-arquivos)
11. [Como funciona na prática](#11-como-funciona-na-prática)
12. [Test-Driven Development (TDD)](#12-test-driven-development-tdd)
13. [FAQ](#13-faq)

---

## 1. O que é

Um **harness comunitário** que adiciona ao OpenCode:

- **7 comandos** (`/`) que executam workflows estruturados (feature, bug, debug, refactor, review, init-project, refresh-context).
- **4 agentes** (`@`) especializados para tarefas específicas (architect, investigator, debugger, reviewer).
- **Princípios globais** carregados automaticamente em toda sessão (concisão + respeito ao projeto).
- **Módulos sob demanda** (`harness/`) carregados apenas quando você precisa, para economizar tokens.
- **Perfis de tecnologia** com guidance específico (genérico, PHP, Laravel) — sempre subordinados ao que o projeto já faz.

A ideia central: **o OpenCode continua sendo o OpenCode**, mas agora você tem um fluxo de trabalho repetível e disciplinado.

---

## 2. Arquitetura em 3 camadas

```text
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 1 — GLOBAL (este harness)                           │
│  Como o agente DEVE trabalhar.                              │
│  • Princípios de engenharia                                 │
│  • Workflows (DISCOVER→ANALYZE→PLAN→…)                      │
│  • Gates de validação                                       │
│  • Perfis de tecnologia                                     │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 2 — PROJETO (respeitada, nunca modificada)          │
│  Como ESTE projeto funciona.                                │
│  • AGENTS.md / CLAUDE.md do projeto (NUNCA tocar)           │
│  • Documentação oficial da stack                            │
│  • Código existente e padrões já em uso                     │
│  • .opencode/context/ pessoal (opcional, local)              │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 3 — DECISÃO                                          │
│  Em conflito, sempre vence o de cima.                       │
└─────────────────────────────────────────────────────────────┘
```

**Regra de ouro:** se o `AGENTS.md` do projeto diz X e o harness sugere Y, **siga X**. Convenções existentes sempre vencem práticas genéricas.

---

## 3. Pré-requisitos

| Requisito | Versão mínima | Como verificar |
|---|---|---|
| OpenCode | 1.18+ | `opencode --version` |
| Bash | 4.0+ | `bash --version` |
| find/cp/mkdir | coreutils padrão | `which find cp mkdir` |
| rsync (opcional, recomendado) | qualquer | `rsync --version` |

**Não precisa de:**
- ❌ Permissões de root
- ❌ Dependências externas (Python, Node, etc.)
- ❌ Acesso à rede
- ❌ Modificação de nenhum arquivo do projeto

---

## 4. Instalação

### Passo a passo

```bash
# 1. Clone ou baixe este repositório para algum lugar do seu $HOME
cd ~/OpenHarness

# 2. Rode o instalador
./install.sh
```

O instalador vai:
1. Verificar pré-requisitos.
2. Criar backups de qualquer `AGENTS.md` global existente.
3. Perguntar (caso exista) se deseja sobrescrever o `AGENTS.md` global.
4. Copiar `AGENTS.md`, `commands/`, `agents/` e `harness/` para `~/.config/opencode/`.
5. **Não tocar** no seu `opencode.jsonc`.

### Opções do instalador

```bash
./install.sh                 # Instalação interativa (recomendado)
./install.sh --dry-run       # Mostra o que faria sem fazer
./install.sh --force         # Sobrescreve AGENTS.md sem perguntar
./install.sh --uninstall     # Reverte usando os backups
```

### Variáveis de ambiente (caso precise)

```bash
# Se o OpenCode estiver em outro local
OPENCODE_HOME="$HOME/.config/opencode" ./install.sh

# Se o source estiver em outro lugar
HARNESS_SRC="/caminho/do/harness" ./install.sh
```

### Verificação pós-instalação

```bash
ls ~/.config/opencode/AGENTS.md
ls ~/.config/opencode/commands/
ls ~/.config/opencode/agents/
ls ~/.config/opencode/harness/
```

Todos devem existir e estar preenchidos.

---

## 5. Atualização

Quando você modificar arquivos no source (`~/OpenHarness/`) ou puxar uma nova versão do GitHub:

```bash
./update.sh                  # Aplica as mudanças (com diff antes)
./update.sh --diff-only      # Mostra o que mudaria, sem aplicar
./update.sh --show-snippet   # Imprime presets de modelos
./update.sh --show-snippet balanceado   # Imprime só o preset "balanceado"
./update.sh --uninstall      # Reverte para versão anterior
```

O `update.sh`:
- Compara arquivo por arquivo (origem vs destino).
- Mostra um diff resumido (`+`, `~`, `-`) **antes** de aplicar.
- Faz backup de tudo que vai sobrescrever em `~/.config/opencode/.harness-backups/<timestamp>/`.
- **Nunca** toca no `opencode.jsonc`.

---

## 6. Configurando modelos por agente

### Como funciona

Por padrão, **todos os agentes do harness herdam o modelo do agente primário** (`build` ou `plan`) que está configurado no seu `opencode.jsonc`. Isso significa que sem configuração extra, tudo já funciona.

Se você quiser **customizar o modelo por agente**, edite `~/.config/opencode/opencode.jsonc`:

```jsonc
{
  "agent": {
    "plan":  { "model": "kimi-for-coding/k3" },
    "build": { "model": "minimax/MiniMax-M3" },

    // Adicione estes para customizar os agentes do harness:
    "architect":    { "model": "kimi-for-coding/k3" },
    "investigator": { "model": "minimax/MiniMax-M3" },
    "debugger":     { "model": "kimi-for-coding/k3" },
    "reviewer":     { "model": "kimi-for-coding/k3" }
  }
}
```

### 3 presets prontos

O arquivo [`examples/presets.jsonc`](examples/presets.jsonc) tem **3 presets prontos para copiar/colar**:

| Preset | Quando usar | Custo vs. Qualidade |
|---|---|---|
| **rápido** | Desenvolvimento diário, tarefas rotineiras | Mínimo |
| **balanceado** | Trabalho geral, bom padrão | Médio |
| **profundo** | Bugs críticos, refatorações grandes, decisões arquiteturais | Máximo |

### Atalhos

```bash
# Ver os presets direto no terminal (sem abrir arquivo)
./update.sh --show-snippet                  # todos os presets
./update.sh --show-snippet rápido          # só o "rápido"
./update.sh --show-snippet balanceado      # só o "balanceado"
./update.sh --show-snippet profundo        # só o "profundo"
```

### Como customizar

A ordem de precedência (da maior para a menor):

1. **`agent.<nome>.model`** em `opencode.jsonc` ← maior prioridade
2. **Modelo do primary agent** (`build` ou `plan`)
3. **Default do provedor** ← menor prioridade

Para mudar o modelo de um agente, **só precisa editar o `opencode.jsonc`** em um único lugar. Não precisa editar arquivos do harness.

### Trocar o primary agent no TUI (`build` ↔ `plan`)

O TUI do OpenCode tem **dois primary agents** que você alterna com a tecla **Tab**:

- **build** — ferramentas completas, sem pedir aprovação (default ao abrir o TUI).
- **plan** — ferramentas restritas, usado para análise e planejamento sem editar nada.

Os comandos deste harness declaram qual agent devem usar no frontmatter:

| Frontmatter | Comandos | Comportamento esperado |
|---|---|---|
| `agent: plan` | `/refine`, `/spec`, `/review` | Mudam o label do TUI para `plan` ao rodar |
| `agent: build` | `/feature`, `/bug`, `/debug`, `/refactor`, `/init-project`, `/refresh-context` | Devem mudar o label para `build` ao rodar |

---

## 7. Comandos disponíveis

Os comandos são invocados com `/` no TUI do OpenCode. **Todos têm autocomplete** (digite `/` e veja a lista).

### `/init-project`

Inicializa o contexto pessoal do projeto em `.opencode/context/`.

```text
/init-project
```

**O que faz:**
1. Verifica se você está em um projeto real.
2. Detecta `AGENTS.md` / `CLAUDE.md` (se houver, **respeita, não mexe**).
3. Analisa stack, arquitetura, comandos do projeto.
4. Cria 5 arquivos em `.opencode/context/`: `project.md`, `architecture.md`, `conventions.md`, `commands.md`, `decisions.md`.
5. Não commita nada automaticamente.

**Quando usar:** na primeira vez que abrir um projeto novo no OpenCode.

---

### `/refresh-context`

Atualiza o contexto pessoal sem reescrever do zero.

```text
/refresh-context
```

**O que faz:**
1. Lê o que existe em `.opencode/context/`.
2. Re-analisa o que pode ter mudado.
3. Aplica **diffs mínimos** (preserva notas manuais).
4. Lista o que mudou.

**Quando usar:** periodicamente, ou depois de mudanças grandes no projeto.

---

### `/feature`

Implementa uma nova funcionalidade seguindo o workflow completo.

```text
/feature adicionar export CSV de pedidos
```

**Workflow:** `DISCOVER → ANALYZE → PLAN → IMPLEMENT → VALIDATE → REVIEW`

**Quando usar:** vai criar algo novo (endpoint, classe, migration, …).

---

### `/bug`

Corrige um bug reproduzível após identificar a causa raiz.

```text
/bug pedido não calcula frete quando cliente é de outro estado
```

**Workflow:** `REPRODUCE → INVESTIGATE → IDENTIFY ROOT CAUSE → REGRESSION TEST → MINIMAL FIX → VALIDATE → REVIEW`

**Quando usar:** comportamento claramente errado, com causa plausível.

---

### `/debug`

Investiga sistematicamente um sintoma vago ou intermitente.

```text
/debug às vezes o login falha sem mensagem de erro
```

**Workflow:** `GATHER EVIDENCE → IDENTIFY HYPOTHESES → RANK → TEST → ROOT CAUSE → PROPOSE/IMPLEMENT FIX → VALIDATE`

**Quando usar:** sintoma ambíguo, sem causa óbvia, ou após tentativas falhas de fix.

---

### `/refactor`

Refatora código **preservando comportamento**.

```text
/refactor extrair lógica de cálculo de frete para classe dedicada
```

**Workflow:** `ANALYZE → IDENTIFY DEPENDENCIES → VERIFY TEST COVERAGE → PLAN → REFACTOR → VALIDATE BEHAVIOR → REVIEW`

**Quando usar:** quer melhorar estrutura sem mudar o que o código faz. **Não muda comportamento.**

---

### `/review`

Revisa um diff ou arquivo **sem modificar**.

```text
/review                                   # revisa o último commit
/review caminho/arquivo.php               # revisa um arquivo específico
/review main...HEAD                       # revisa tudo entre branches
```

**Workflow:** `COLLECT DIFF → CLASSIFY FINDINGS → REPORT`

Categorias: `CRITICAL` / `HIGH` / `MEDIUM` / `LOW`.

**Quando usar:** antes de commit/PR, ou para segunda opinião.

---

### `/refine`

Transforma um pedido vago em um **Refined Request** estruturado. **Não implementa nada** — apenas clarifica.

```text
/refine quero melhorar o cadastro de usuários
```

**Workflow:** `CLASSIFY → GATHER CONTEXT → DETECT GAPS → FILTER QUESTIONS → ASK → OUTPUT`

**Quando usar:** quando o pedido é vago (sem objetivo claro, sem escopo, sem critério de pronto).

**Características-chave:**
- Faz no máximo 3-7 perguntas de alto valor (negócio, escopo, segurança, etc.)
- Se o pedido já está claro, **pula as perguntas** e entrega direto
- Reusa contexto do projeto (AGENTS.md, `.opencode/context/`, código)
- Saída é sempre inline (no chat) — nunca persiste

**Saída:** Refined Request estruturado, recomendação do próximo comando.

---

### `/spec`

Gera uma **Specification** estruturada. **Não implementa nada** — apenas especifica.

```text
/spec criar sistema de cupons                    # pedido direto
/spec                                            # após /refine ter rodado
```

**Workflow:** `CLASSIFY → GATHER CONTEXT → CRITICAL INFO CHECK → ASK IF CRITICAL → COMPLEXITY ASSESSMENT → GENERATE SPEC → READINESS → RECOMMEND`

**Quando usar:** após `/refine` para tarefas complexas (3+ arquivos, regras de negócio, integrações), OU quando o pedido direto já tem info suficiente.

**Características-chave:**
- Aceita pedido direto OU herda do `/refine` na conversa
- Estrutura **escala conforme complexidade**: SMALL (enxuto), MEDIUM (padrão), LARGE (completo)
- Marca fontes: `CONFIRMED` / `INFERRED FROM PROJECT` / `ASSUMPTION` / `UNKNOWN`
- Inclui **Testing Considerations** em MEDIUM/LARGE (test level, edge cases, regression scenarios)
- **Acceptance Criteria são testáveis** (observáveis, concretos, descrevem ator + condição + resultado)
- Declara `Implementation Readiness`: `READY` / `READY WITH ASSUMPTIONS` / `NOT READY`

---

## 8. Agentes disponíveis

Os agentes são invocados com `@` no TUI do OpenCode. **Todos têm autocomplete** (digite `@` e veja a lista).

### `@architect`

**Para que serve:** entender arquitetura, identificar padrões, avaliar impacto de mudanças.

**Quando usar:**
- Vai mexer em uma área desconhecida do código.
- Precisa decidir entre 2+ abordagens.
- Quer avaliar risco de uma mudança grande.

**Exemplo:**
```text
@architect qual o impacto de remover a coluna X?
@architect mapear como funciona o módulo de autenticação
```

---

### `@investigator`

**Para que serve:** explorar código desconhecido, encontrar implementações similares, mapear dependências.

**Quando usar:**
- "Como o sistema faz X?"
- "Onde fica Y?"
- "Já existe algo parecido?"

**Exemplo:**
```text
@investigator como o sistema atual envia e-mails?
@investigator onde fica a validação de CPF?
```

**É read-only** (não modifica código).

---

### `@debugger`

**Para que serve:** investigar bugs com método científico (hipóteses, teste, refutação).

**Quando usar:**
- Bug vago, intermitente, com várias causas possíveis.
- Investigação estruturada de causa raiz.

**Exemplo:**
```text
@debugger o worker morre depois de 5min sem log útil
@debugger às vezes a fila redis para de processar
```

---

### `@reviewer`

**Para que serve:** revisar código com olho crítico (bugs, segurança, arquitetura).

**Quando usar:**
- Antes de PR.
- Auditar código legado.
- Segunda opinião.

**Exemplo:**
```text
@reviewer revisar o último commit
@reviewer auditar essa classe de pagamento
```

**É read-only** (não modifica código).

---

### Quando usar command vs agent?

| Você quer… | Use |
|---|---|
| Implementar uma feature do começo ao fim | `/feature` |
| Corrigir um bug claro | `/bug` |
| Investigar sintoma vago | `/debug` |
| Apenas explorar/entender | `@investigator` |
| Apenas revisar | `/review` ou `@reviewer` |
| Análise arquitetural focada | `@architect` |
| Debug estruturado por agente | `@debugger` |

**Regra prática:** `/command` é um workflow completo. `@agent` é uma tarefa focada.

---

## 9. Regras sobre `AGENTS.md` do projeto

**Esta é a regra mais importante do harness.**

Se o projeto em que você está trabalhando tem um `AGENTS.md` ou `CLAUDE.md`:

1. ✅ **LER** como fonte autoritativa de instruções do projeto.
2. ❌ **NUNCA** sobrescrever.
3. ❌ **NUNCA** apagar conteúdo.
4. ❌ **NUNCA** adicionar referências a este harness.
5. ❌ **NUNCA** injetar caminhos pessoais (`/home/...`, `~/.config/...`).
6. ❌ **NUNCA** exigir que a equipe instale o harness.

**A equipe não precisa instalar nada deste harness** para que o projeto funcione normalmente. O harness vive 100% no seu `$HOME`.

O comando `/init-project` **respeita** qualquer `AGENTS.md` existente e apenas cria arquivos pessoais em `.opencode/context/` (que é local, opcionalmente ignorável no git).

---

## 10. Estrutura de arquivos

```text
~/OpenHarness/                              ← source-of-truth (este repo)
├── install.sh                             # instala no OpenCode
├── update.sh                              # atualiza
├── README.md                              # este arquivo
│
├── AGENTS.md                              # raiz global (concisa)
│
├── commands/                              # 7 comandos /x
│   ├── init-project.md
│   ├── refresh-context.md
│   ├── feature.md
│   ├── bug.md
│   ├── debug.md
│   ├── refactor.md
│   └── review.md
│
├── agents/                                # 4 agentes @x
│   ├── architect.md
│   ├── investigator.md
│   ├── debugger.md
│   └── reviewer.md
│
├── harness/                               # módulos sob demanda
│   ├── core/
│   │   ├── principles.md
│   │   ├── task-classification.md
│   │   ├── context-strategy.md
│   │   └── completion-criteria.md
│   ├── workflows/
│   │   ├── feature.md
│   │   ├── bugfix.md
│   │   ├── debug.md
│   │   ├── refactor.md
│   │   ├── investigation.md
│   │   └── review.md
│   ├── gates/
│   │   ├── discovery.md
│   │   ├── planning.md
│   │   └── completion.md
│   ├── profiles/
│   │   ├── generic.md
│   │   ├── php.md
│   │   └── laravel.md
│   └── templates/
│       └── project-context.md
│
└── examples/
    └── presets.jsonc                      # 3 presets de modelos

~/.config/opencode/                        ← destino (gerenciado por install/update)
├── AGENTS.md                              # = ~/OpenHarness/AGENTS.md
├── commands/                              # = ~/OpenHarness/commands/
├── agents/                                # = ~/OpenHarness/agents/
├── harness/                               # = ~/OpenHarness/harness/
├── .harness-backups/                      # backups timestamped (criado por install/update)
└── opencode.jsonc                         # ← seu, NÃO TOCADO pelo harness

.opencode/context/                         # criado pelo /init-project (no projeto)
├── project.md
├── architecture.md
├── conventions.md
├── commands.md
└── decisions.md
```

---

## 11. Como funciona na prática

### Cenário 1: primeiro uso

```bash
# 1. Instalar o harness
cd ~/OpenHarness && ./install.sh

# 2. Abrir um projeto no OpenCode
cd ~/meu-projeto && opencode

# 3. Inicializar contexto do projeto (uma vez)
/init-project

# 4. Trabalhar normalmente — use comandos e agentes conforme necessário
/feature adicionar X
@architect como funciona Y
```

### Cenário 2: usar sem instalar nada no projeto

O harness **não exige nada no projeto**. Você pode usar:

```bash
# Já dentro do projeto, no OpenCode:
/review          # revisa o último commit (sem init-project)
/bug pedido não funciona
@investigator como funciona autenticação?
```

Esses comandos funcionam mesmo sem `.opencode/context/` (eles usamão apenas os módulos do harness).

### Cenário 3: atualizar o harness

```bash
# 1. Você editou ~/OpenHarness/commands/feature.md
# 2. Ver o que vai mudar:
./update.sh --diff-only
# 3. Aplicar:
./update.sh
```

### Cenário 4: trocar preset de modelos

```bash
# Ver opções:
./update.sh --show-snippet
# Copiar o preset desejado
# Colar em ~/.config/opencode/opencode.jsonc (mesclando com o que já tem)
# Pronto — na próxima sessão do OpenCode, novos modelos já valem
```

### Cenário 5: revisar o que mudou no OpenCode

Os logs do OpenCode mostram qual modelo está ativo em cada agente. Você também pode:

```bash
opencode models    # lista modelos disponíveis no provider
```

---

## 12. Test-Driven Development (TDD)

O harness **prefere TDD quando prático** para mudanças de comportamento observável. TDD não é dogma — é a escolha padrão, com saída explícita quando não se aplica.

### Filosofia

```
RED → GREEN → REFACTOR → VALIDATE
 ↓       ↓          ↓          ↓
definir implementar  melhorar   rodar
comportamento mínimo estrutura restante
observável   código  preservando
                   comportamento
```

Detalhes completos em `harness/workflows/tdd.md` (carregado sob demanda).

### Quando TDD é aplicado automaticamente

| Command | Onde TDD entra |
|---|---|
| `/feature` | Fase IMPLEMENT — TDD-first quando prático |
| `/bug` | Fase REGRESSION TEST — RED-first (regression test failing → fix) |
| `/refactor` | Fase VERIFY TEST COVERAGE — TDD ou characterization tests para legado |
| `/debug` | Após root cause identificada — RED → GREEN antes do fix |
| `/refine` / `/spec` | **Não aplicam TDD**, mas orientam ACs a serem testáveis |

### TDD Status (assessment automático)

Cada projeto recebe um status baseado em evidências:

| Status | Quando | Ação |
|---|---|---|
| `TDD_READY` | Framework instalado, testes rodam, há testes similares | Aplicar TDD-first |
| `TDD_LIMITED` | Testes existem mas setup quebrado OU área sem cobertura | Adicionar testes para a área + aplicar TDD |
| `TDD_UNAVAILABLE` | Sem framework OU setup inviável | Documentar, validar via smoke test/log |
| `NOT_APPLICABLE` | Config pura, docs, infra sem suporte | Declarar no relatório, usar validação alternativa |

**Descobrir o status** é parte da sub-fase em `@harness/gates/discovery.md` — verifique `composer.json`, `package.json`, presença de `tests/`, e tente rodar o comando de teste antes de assumir.

### Test Level Selection

O harness seleciona o nível baseado em evidências:

- **UNIT** — lógica isolada, sem dependência externa
- **FEATURE** — fluxo de aplicação (request → response)
- **INTEGRATION** — interação entre componentes (Service → Repository → DB)
- **E2E** — só quando o projeto tem suporte (Cypress, Playwright, Dusk)

**Siga as convenções do projeto.** Se a maioria dos testes similares é feature, faça feature — não force unit.

### Characterization Tests (código legado)

Quando o código não tem testes e o comportamento é obscuro, characterization tests capturam **o que o código faz hoje** (não o que deveria). Servem como rede de segurança para refactor.

```php
test('comportamento atual de calcularFrete', function () {
    $resultado = calcularFrete(100, 'SP');
    expect($resultado)->toBe(15.50); // valor atual, mesmo que estranho
});
```

**Se o comportamento atual está errado**, é BUGFIX (com TDD normal), não REFACTOR.

### Como aparece no relatório

Para `/feature` e `/bug`, o relatório final inclui:

```markdown
**TDD STATUS:** [READY | LIMITED | UNAVAILABLE | NOT_APPLICABLE]
**TEST LEVEL:** [UNIT | FEATURE | INTEGRATION | E2E | N/A]
**REASON:** [1-2 frases explicando a estratégia escolhida]
```

### Quando NÃO aplicar TDD

- Mudança puramente configuracional (YAML, .env, config files)
- Mudança de documentação
- Investigação exploratória
- Infraestrutura sem validação automatizada disponível
- Bug de emergência antes do ambiente estar pronto

**Nesses casos**, declare explicitamente:

```
TDD STATUS: NOT_APPLICABLE
REASON: [motivo]
VALIDATION: [estratégia alternativa usada]
```

### Filosofia global (em `AGENTS.md`)

O harness adiciona **TDD-first quando prático** como o 6º princípio inegociável — conciso, com referência a `@harness/workflows/tdd.md` para detalhes.

---

## 13. Estratégia de Reasoning por Etapa

O OpenHarness permite que **cada etapa do Harness tenha um nível de reasoning recomendado** (`low`, `normal`, `high`), sem obrigar o Harness a escolher um modelo.

**Princípios:**

- O Harness **não escolhe modelo** — respeita o modelo atualmente selecionado no OpenCode quando o usuário não informa um.
- Quando o usuário informa um modelo explicitamente (ex: `--model google/gemini-3.7-flash`), esse modelo é preservado.
- Cada etapa possui um **nível de reasoning abstrato** declarado em `harness/config/model-strategy.jsonc`.
- O nível de reasoning é **adaptado à configuração real do modelo** via `adapt_reasoning` no módulo de estratégia.
- **MiniMax M3** tem adapter dedicado: M3 só expõe 2 capabilities (`none`/`thinking`), então o adapter mapeia `low`→`none` (thinking off) e `normal`/`high`→`thinking` (thinking on).
- **Outros modelos** usam o adapter genérico, que consulta `opencode models --verbose` para descobrir variants reais.
- Se a variant preferida não existir para o modelo (no adapter genérico), o Harness **lista as variants realmente disponíveis** e pergunta ao usuário qual usar — **sem trocar de modelo** e **sem degradar silenciosamente**.
- O Harness **nunca troca de modelo automaticamente** e nunca falha a execução por variant ausente.

### Tabela padrão de reasoning

| Etapa | Reasoning |
|---|---|
| refine | low |
| spec | high |
| tdd/red | high |
| implement | normal |
| debug | high |
| refactor | low |
| review | high |

O arquivo vive em `harness/config/model-strategy.jsonc` (instalado em `~/.config/opencode/harness/config/`). Para customizar, basta editar esse arquivo — mudanças têm efeito imediato.

### Exemplos práticos

**Exemplo 1 — MiniMax M3 + `/spec`:**

```text
Usuário ativo no OpenCode com: minimax/MiniMax-M3
Executa: /spec criar sistema de cupons

Harness resolve:
  - reasoning preferido da etapa spec: high
  - adapter MiniMax-M3: high → thinking
  - variant real existe? sim (thinking)

Harness aplica: minimax/MiniMax-M3#thinking
```

**Exemplo 2 — Gemini 3.7 Flash + `/spec`:**

```text
Usuário ativo no OpenCode com: google/gemini-3.7-flash
Executa: /spec criar sistema de cupons

Harness resolve:
  - reasoning preferido da etapa spec: high
  - adapter genérico: high → "high"
  - variant real existe? sim (Gemini 3.7 Flash tem low/medium/high)

Harness aplica: google/gemini-3.7-flash#high
```

**Exemplo 3 — modelo sem variant compatível (fallback):**

```text
Usuário ativo no OpenCode com: <modelo-x>
Executa: /spec ...

Harness resolve:
  - reasoning preferido: high
  - adapter genérico: high → "high"
  - variant "high" NÃO existe na lista de variants do modelo

Harness emite mensagem de fallback:
  "O modelo <modelo-x> não possui a configuração de reasoning 'high'
   para esta etapa.
   Variants disponíveis:
     1. low
     2. medium"

Usuário escolhe: 2 (medium)
Harness aplica: <modelo-x>#medium
Execução continua.
```

**Exemplo 4 — Ausência de modelo selecionado:**

```text
Usuário não tem modelo fixado no opencode.jsonc.
Executa: /refine quero melhorar o cadastro

Harness usa o modelo atualmente selecionado no OpenCode (resolvido pelo runtime).
Harness aplica reasoning "low" da etapa refine (adaptado ao modelo).
```

### Variants resultantes por stage (fim-a-fim)

A tabela "padrão de reasoning" acima mostra `stage → reasoning abstrato`. Esta tabela mostra o resultado **fim-a-fim** após o adapter — o que o usuário realmente recebe:

**Para MiniMax-M3** (adapter dedicado, 7 stages colapsam em 2 variants):

| Stage | Reasoning | Variant final | Thinking |
|---|---|---|---|
| `refine` | low | `#none` | off |
| `refactor` | low | `#none` | off |
| `implement` | normal | `#thinking` | on |
| `spec` | high | `#thinking` | on |
| `tdd_red` | high | `#thinking` | on |
| `debug` | high | `#thinking` | on |
| `review` | high | `#thinking` | on |

> No M3, **stages que compartilham reasoning são indistinguíveis em variant final**. Editar `model-strategy.jsonc` para separar `debug` de `review` não muda a variant no M3; só muda em modelos com variants granulares.

**Para modelos com adapter genérico** (ex: `google/gemini-3.7-flash` com `low`/`medium`/`high`): a mesma config pode produzir até 3 variants distintas (`#low`, `#medium`, `#high`). Veja `harness/core/model-strategy.md` para o algoritmo.

### Como verificar se a variant está realmente aplicada

O harness **não tem log de runtime** que confirme qual variant foi aplicada na chamada HTTP ao provedor. A única garantia observável é visual:

1. **Bloco `<think>` na resposta** (mais forte): com `#thinking`, o modelo emite um bloco de raciocínio antes da resposta visível. Com `#none`, esse bloco não existe. Você literalmente **vê** a diferença no chat.
2. **Teste A/B**: rodar o mesmo pedido curto em `/refine` (resolve para `#none` no M3) e em `/spec` (resolve para `#thinking` no M3). Se `/spec` mostrar bloco `<think>` e `/refine` não, o mecanismo está funcionando end-to-end.
3. **Proxy de latência** (fraco): `#thinking` gera tokens de raciocínio antes da resposta visível, então stages com `#thinking` consistentemente levam mais tempo que stages com `#none` para o mesmo input.

### Backward compatibility

Se `harness/config/model-strategy.jsonc` for removido, o Harness usa o comportamento legacy (sem reasoning aplicado). A feature é estritamente aditiva.

Para detalhes do algoritmo de resolução e adapters, veja `harness/core/model-strategy.md` (carregado sob demanda via `@harness/core/model-strategy.md`).

---

## 14. FAQ

### O harness funciona com qualquer stack?

**Sim.** O core é agnóstico. Tem profiles específicos para PHP e Laravel, mas você pode usar em qualquer projeto (Node, Python, Go, Rust, etc.).

### O projeto da minha equipe vai ter que mudar alguma coisa?

**Não.** O harness é 100% local (`~/.config/opencode/`). Nenhum arquivo do projeto é tocado automaticamente.

### E se o projeto já tem `AGENTS.md`?

Ele é lido como fonte autoritativa. **Nunca é modificado, sobrescrito ou apagado.**

### Como faço para resetar tudo?

```bash
./install.sh --uninstall   # restaura backups
```

Ou manualmente:

```bash
rm -rf ~/.config/opencode/AGENTS.md
rm -rf ~/.config/opencode/commands
rm -rf ~/.config/opencode/agents
rm -rf ~/.config/opencode/harness
```

### Como adiciono um novo comando/agent próprio?

Crie um arquivo `.md` (com frontmatter) em `~/OpenHarness/commands/` ou `~/OpenHarness/agents/`:

```bash
nano ~/OpenHarness/commands/meu-comando.md
./update.sh    # implanta no OpenCode
```

### Como adiciono um profile de tecnologia novo?

```bash
nano ~/OpenHarness/harness/profiles/python.md
./update.sh
```

E referencie nos commands via `@harness/profiles/python.md`.

### Como sei qual modelo está ativo em um agent?

Use `opencode models` para listar providers/modelos. Ao iniciar uma sessão, o log do OpenCode mostra o modelo ativo. Para garantir, adicione `model:` explicitamente no `opencode.jsonc` para aquele agent.

### O install sobrescreve meu `AGENTS.md` global sem perguntar?

**Não, sempre pergunta** (a menos que você use `--force`). E sempre faz backup antes.

### Como contribuir com melhorias?

Este é um projeto comunitário, mas a estrutura é versionável. Sugestões:

1. Edite o arquivo em `~/OpenHarness/`.
2. Rode `./update.sh --diff-only` para revisar.
3. Se gostar, faça commit e push para seu fork.

### Funciona com OpenCode Web / TUI / IDE?

Sim — comandos e agents funcionam em todas as interfaces que rodam sobre OpenCode ≥ 1.18.

### Tem risco de quebrar algo?

- O `opencode.jsonc` **nunca é tocado**.
- Os arquivos do OpenCode existentes recebem **backup timestamped** antes de sobrescrita.
- O `AGENTS.md` global só é sobrescrito com confirmação.
- Em caso de dúvida, use `./install.sh --dry-run` primeiro.

---

## Próximos passos

1. Rode `./install.sh` no seu ambiente.
2. Abra o OpenCode em qualquer projeto.
3. Digite `/` para ver a lista de comandos disponíveis.
4. Comece com `/init-project` em um projeto novo.
5. Ajuste modelos com `./update.sh --show-snippet` + edição do `opencode.jsonc`.

---

**Mantido por:** Leo França · OpenCode ≥ 1.18 · MIT-style (use à vontade)