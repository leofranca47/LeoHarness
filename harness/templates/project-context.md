# Template: Project Context

Template para os 5 arquivos gerados em `.opencode/context/` pelo comando `/init-project`.

**Objetivo:** contexto pessoal (não versionado) que ajuda você a entender e trabalhar no projeto rapidamente.

## Arquivos a gerar

```
.opencode/context/
├── project.md        # Visão geral: o que é, com o que é feito
├── architecture.md   # Como é organizado: camadas, fluxo, módulos
├── conventions.md    # Padrões observados: naming, validação, etc.
├── commands.md       # Comandos verificados para testar/build/lint
└── decisions.md      # Decisões arquiteturais identificadas com evidência
```

## Regras gerais

- **Apenas fatos comprovados.** Se não puder verificar, marque como `UNKNOWN`.
- **Caminhos relativos** ao projeto (nunca absolutos).
- **Sem inventar.** Se algo é ambíguo, escreva o que você VERIFICOU.
- **Conciso.** 30-100 linhas por arquivo, idealmente.
- **Atualize** quando o projeto mudar (use `/refresh-context`).
- **Não commite** (adicione manualmente ao `.gitignore` se quiser compartilhar).

---

## project.md

```markdown
# Projeto: [nome]

## Propósito
[1-3 frases sobre o que o sistema faz. Se não identificável: UNKNOWN]

## Stack principal

| Componente | Tecnologia | Versão |
|---|---|---|
| Linguagem | [ex: PHP] | [ex: 8.3] |
| Framework | [ex: Laravel 11] | [ex: 11.x] |
| Banco | [ex: MySQL] | [ex: 8.0] |
| Cache | [ex: Redis] | [ex: 7.2] |
| Queue | [ex: Redis] | [ex: -] |
| Frontend | [ex: Blade + Alpine] | [-] |

(Fonte: composer.json, package.json, .env, config/database.php)

## Infraestrutura
- Docker: [sim/não, compose em X]
- CI: [GitHub Actions / GitLab / outro]
- Deploy: [descreva se identificável]

## Estrutura de alto nível
[árvore de 2-3 níveis: app/, src/, etc.]

## Como começar (verificado)
[comandos exatos para clonar, instalar deps, rodar local — só os que existem]
```

---

## architecture.md

```markdown
# Arquitetura

## Camadas (verificado)
- [ex: Controller → FormRequest → Service → Repository → Model]
- Fonte: `app/Http/Controllers/UserController.php`, `app/Services/UserService.php`

## Fluxo de request
```
HTTP Request
  ↓
Middleware (auth, throttle)
  ↓
Route → Controller
  ↓
Form Request (validação)
  ↓
Service / UseCase (lógica)
  ↓
Repository / Eloquent (dados)
  ↓
Database
```

## Local de regras de negócio
[Onde fica a lógica. Service? Action? Model? Controller? — com exemplos]

## Acesso a dados
- ORM: [ex: Eloquent]
- Padrão de repository: [existe/não existe/com exemplo]
- Transações: [onde são usadas — `DB::transaction(...)`]

## Módulos / bounded contexts
[Se identificável, liste os módulos do projeto]

## Processamento assíncrono
- Filas: [conexão padrão, workers]
- Jobs em background: [exemplos]

## Eventos
- Eventos disparados: [lista com referência]
- Listeners: [quem escuta]

## Integrações externas
- [APIs de terceiros: pagador, email, storage, etc.]
- [Como são chamadas: Guzzle, SDK específico]

## Pontos críticos / acoplamentos
- [Onde o sistema é frágil]
- [Onde tem contratos externos]
- [Onde tem hardcoded values]
```

---

## conventions.md

```markdown
# Convenções observadas

## Nomenclatura

| Elemento | Padrão | Exemplo |
|---|---|---|
| Classes | PascalCase | `UserController` |
| Métodos | camelCase | `findActive` |
| ... | ... | ... |

(Fonte: 3+ exemplos em arquivos do projeto)

## Controllers
- Single Action (`__invoke`) ou CRUD completo?
- Local: `app/Http/Controllers/`
- Padrão: [com exemplos]

## Services / UseCases
- Local: `app/Services/` (ou outro)
- Injeção via constructor: [sim/não]
- Retornam: [Model, DTO, Resource?]

## Validação
- FormRequest: [usado? onde?]
- Inline: [usado em quais casos?]
- Mensagens customizadas: [sim/não, idioma]

## Acesso a banco
- Eloquent direto: [sim/não]
- Repository pattern: [existe? onde?]
- Query Builder: [em quais casos?]

## Tratamento de exceções
- Hierarquia: [arquivo de classes base]
- Onde são tratadas: [Handler, controller, service?]
- Resposta HTTP: [API Resource de erro, padrão]

## Resposta de API
- API Resources: [usados? onde?]
- Formato: [envelope, direto, paginação?]
- Status codes: [convenções]

## Filas
- Conexão padrão: [database/redis/sqs]
- Job padrão: [estrutura]

## Testes
- Framework: [PHPUnit, Pest]
- Estrutura: [tests/Feature, tests/Unit]
- Factories: [existem? convenção?]
- Mocking: [estratégia]

## Logs
- Canal padrão: [stack, daily, etc.]
- Contexto: [request id, user id?]

## Estilo de código
- PSR-12: [sim/não]
- Ferramenta de formatação: [pint, php-cs-fixer]
- Strict types: [sim/não]

## Comentários
- PHPDoc: [estilo, em quê]
- Comentários inline: [frequência, conteúdo]
```

---

## commands.md

```markdown
# Comandos verificados

> Apenas comandos confirmados em composer.json, package.json, Makefile, CI ou README.
> Comandos "provavelmente existem" não estão aqui.

## Setup inicial
```bash
# Instalar dependências
[comando verificado]

# Copiar env
[comando verificado]

# Gerar key
[comando verificado]

# Migrar + seed
[comando verificado]
```

## Desenvolvimento
```bash
# Subir servidor local
[comando verificado]

# Subir workers
[comando verificado]

# Subir Docker (se houver)
[comando verificado]
```

## Testes
```bash
# Rodar todos
[comando verificado]

# Filtrar
[comando verificado]

# Com cobertura
[comando verificado — se existir]
```

## Qualidade de código
```bash
# Lint
[comando verificado — se existir]

# Análise estática
[comando verificado — se existir]

# Formatação
[comando verificado — se existir]
```

## Banco de dados
```bash
# Migrações
[comando verificado]

# Seed
[comando verificado]

# Reset
[comando verificado]
```

## Filas
```bash
# Processar jobs
[comando verificado]

# Jobs falhados
[comando verificado]
```

## Cache
```bash
# Limpar
[comando verificado]

# Otimizar
[comando verificado]
```

## Debug
```bash
# Tinker / REPL
[comando verificado]

# Telescope / logs
[comando verificado]
```
```

---

## decisions.md

```markdown
# Decisões arquiteturais

> Decisões identificadas com evidência. Não inferir motivos históricos.

## Decision: [título]

**Descrição:** [o que foi decidido]

**Evidência:** [arquivo:linha ou commit onde isso é visível]

**Tipo:**
- [ ] Decisão explícita (declarada em código/docs)
- [ ] Padrão inferido (consistência observada)

**Notas:** [contexto adicional se houver]

---

## Decision: [outra]

**Descrição:** [...]

**Evidência:** [...]

**Tipo:** [...]

---

## Patterns observados

- [Pattern 1: ex: "Repositories são interfaces com implementação Eloquent"]
- [Pattern 2: ex: "Validação sempre via FormRequest"]
- [Pattern 3: ex: "Resposta de API sempre via API Resource"]
```

---

## Como gerar esses arquivos

O comando `/init-project` deve:

1. **Investigar** o projeto (ler arquivos, não inventar)
2. **Detectar AGENTS.md/CLAUDE.md** (respeitar, não modificar)
3. **Criar `.opencode/context/`** se não existir
4. **Escrever** os 5 arquivos seguindo este template
5. **Reportar** o que criou e o que ficou como UNKNOWN

## Atualização

Use `/refresh-context` para atualizar:
- Lê os arquivos existentes
- Re-analisa o que pode ter mudado
- Aplica diffs mínimos
- Preserva notas manuais

## Ownership

- **Local** ao desenvolvedor (não compartilhar sem querer)
- **Sugestão:** adicione `.opencode/context/` ao `.gitignore` pessoal
- **Compartilhar:** se a equipe achar útil, mova para o repo como `docs/context/` (mas isso é decisão da equipe, não sua)