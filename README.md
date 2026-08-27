# Global Engineering Harness — OpenCode

> Sistema pessoal de engenharia assistida por IA para o OpenCode.

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

Um **harness pessoal** que adiciona ao OpenCode:

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
cd ~/leoHarness

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

Quando você modificar arquivos no source (`~/leoHarness/`) ou puxar uma nova versão do GitHub:

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

#### Limitação conhecida (assimetria)

Existe uma **assimetria observada**: comandos com `agent: plan` trocam o label do TUI corretamente (`build` → `plan`), mas comandos com `agent: build` **nem sempre** voltam de `plan` → `build` quando o usuário já estava em `plan`. O comportamento real (permissões de escrita, ferramentas habilitadas) **continua correto** — o build agent está ativo nos bastidores — apenas o **label visual** persiste em `plan`.

**Workaround atual:** se você rodou `/refine` ou `/spec` (TUI em `plan`) e em seguida rodou `/feature` mas o label continua mostrando `plan`, **pressione `Tab` uma vez** para trocar manualmente. O comando `/feature` vai executar normalmente em modo `build` independente do label.

#### Por que isso acontece

O OpenCode ainda **não expõe uma API pública no SDK** para trocar o primary agent programaticamente. Plugins podem observar eventos (`command.executed`, `tui.command.execute`) e mostrar toasts, mas não conseguem forçar a troca de `build` ↔ `plan` no TUI.

Esta é uma limitação **upstream do OpenCode**, não do harness. Quando o OpenCode adicionar essa capacidade ao SDK, este harness poderá oferecer um plugin opcional para automatizar a sincronia. Acompanhe em [https://github.com/anomalyco/opencode](https://github.com/anomalyco/opencode).

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
~/leoHarness/                              ← source-of-truth (este repo)
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
├── AGENTS.md                              # = ~/leoHarness/AGENTS.md
├── commands/                              # = ~/leoHarness/commands/
├── agents/                                # = ~/leoHarness/agents/
├── harness/                               # = ~/leoHarness/harness/
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
cd ~/leoHarness && ./install.sh

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
# 1. Você editou ~/leoHarness/commands/feature.md
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

## 13. FAQ

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

Crie um arquivo `.md` (com frontmatter) em `~/leoHarness/commands/` ou `~/leoHarness/agents/`:

```bash
nano ~/leoHarness/commands/meu-comando.md
./update.sh    # implanta no OpenCode
```

### Como adiciono um profile de tecnologia novo?

```bash
nano ~/leoHarness/harness/profiles/python.md
./update.sh
```

E referencie nos commands via `@harness/profiles/python.md`.

### Como sei qual modelo está ativo em um agent?

Use `opencode models` para listar providers/modelos. Ao iniciar uma sessão, o log do OpenCode mostra o modelo ativo. Para garantir, adicione `model:` explicitamente no `opencode.jsonc` para aquele agent.

### O install sobrescreve meu `AGENTS.md` global sem perguntar?

**Não, sempre pergunta** (a menos que você use `--force`). E sempre faz backup antes.

### Como contribuir com melhorias?

Este é um projeto pessoal, mas a estrutura é versionável. Sugestões:

1. Edite o arquivo em `~/leoHarness/`.
2. Rode `./update.sh --diff-only` para revisar.
3. Se gostar, faça commit e push para seu fork.

### Funciona com OpenCode Web / TUI / IDE?

Sim — comandos e agents funcionam em todas as interfaces que rodam sobre OpenCode ≥ 1.18.

### Por que o label do TUI não muda para `build` quando rodo `/feature`?

Limitação conhecida do OpenCode (não do harness). O comando `/feature` executa corretamente em modo `build`, mas o label do TUI pode permanecer em `plan` se você veio de `/refine` ou `/spec`. **Pressione `Tab`** uma vez para trocar manualmente. Detalhes completos em [Seção 6 — Trocar o primary agent no TUI](#trocar-o-primary-agent-no-tui-build--plan).

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