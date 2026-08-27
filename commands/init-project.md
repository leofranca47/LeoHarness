---
description: Inicializa contexto pessoal do projeto em .opencode/context/
agent: build
---

Você está executando `/init-project`. Esta é uma tarefa de **inicialização pessoal** — nada aqui deve tocar em arquivos versionados do time.

## Argumentos
$ARGUMENTS

## Módulos de apoio (carregue sob demanda via @)

- `@harness/templates/project-context.md` — template completo dos arquivos a gerar
- `@harness/profiles/generic.md` — guidance agnóstico de stack
- Profile específico se a stack for detectada: `@harness/profiles/php.md` ou `@harness/profiles/laravel.md`

## Passo 1 — Verificação de segurança

Antes de qualquer coisa, confirme que estamos em um projeto de software. Procure por:
- `.git/`
- `composer.json`, `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`
- `README.md`, `docs/`
- Pastas de código-fonte (`src/`, `app/`, `lib/`)
- Configurações Docker (`Dockerfile`, `docker-compose.yml`)

Se **nenhum indicador** estiver presente, **PARE** e pergunte ao usuário antes de prosseguir.

## Passo 2 — Detectar instruções existentes

Procure **obrigatoriamente** por:
- `AGENTS.md` (na raiz e em subpastas relevantes)
- `CLAUDE.md`
- `README.md`, `CONTRIBUTING.md`
- `docs/`

## Passo 3 — REGRA DE OURO: proteger AGENTS.md do projeto

Se encontrar `AGENTS.md` ou `CLAUDE.md` no projeto:

1. **LEIA COMPLETAMENTE** antes de prosseguir
2. **NÃO modifique, NÃO sobrescreva, NÃO apague**
3. **NÃO adicione** referências a este harness
4. **NÃO injete** caminhos pessoais (`/home/...`, `~/.config/...`)
5. Trate o conteúdo como **fonte autoritativa** de instruções do projeto
6. Adapte suas sugestões a essas instruções, não o contrário

Avise o usuário que o AGENTS.md do projeto foi detectado e será respeitado.

## Passo 4 — Analisar o projeto (use evidências)

Investigue **apenas com evidências** do repositório:

### Projeto
- Propósito (se identificável)
- Tecnologias principais (versões reais do composer.json/package.json/etc.)
- Frameworks

### Arquitetura
- Estrutura de diretórios (tree de 2-3 níveis)
- Camadas da aplicação
- Local de regras de negócio
- Padrão de acesso a dados
- Módulos

### Infraestrutura
- Docker (Dockerfile, compose, etc.)
- Bancos de dados
- Cache (Redis, etc.)
- Filas
- Jobs em background

### APIs
- Controllers, routes
- Auth (middlewares, guards)
- Padrões de resposta

### Desenvolvimento
- Testes (framework, comandos)
- Formatação / lint
- Análise estática
- Comandos de build
- CI/CD

**NÃO invente.** Se algo não puder ser determinado: `UNKNOWN`.

## Passo 5 — Gerar contexto pessoal

Crie os arquivos abaixo em `.opencode/context/` (na raiz do projeto atual):

```
.opencode/context/
├── project.md
├── architecture.md
├── conventions.md
├── commands.md
└── decisions.md
```

Siga `@harness/templates/project-context.md` para o conteúdo de cada arquivo.

## Ownership local

Os arquivos gerados são **pessoais e locais**:
- **NÃO** adicione ao git automaticamente
- **NÃO** modifique `.gitignore`
- **NÃO** faça commit
- Apenas reporte o que foi criado no final

## Relatório final

Liste ao usuário:
1. Arquivos criados (caminhos absolutos apenas no output, não dentro dos arquivos)
2. Stack detectado (com versões verificadas)
3. AGENTS.md do projeto foi detectado? Sim/Não — se sim, está sendo respeitado
4. O que ficou como `UNKNOWN`
5. Como atualizar depois: `/refresh-context`
6. Como usar os workflows: `/feature`, `/bug`, `/debug`, `/refactor`, `/review`