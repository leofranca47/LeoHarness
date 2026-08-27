---
description: Atualiza contexto pessoal do projeto sem reescrever tudo
agent: build
---

Você está executando `/refresh-context`. Objetivo: **atualizar minimamente** o contexto pessoal em `.opencode/context/`.

## Argumentos
$ARGUMENTS

## Módulos de apoio

- `@harness/templates/project-context.md` — template de referência
- `@harness/core/principles.md` — sempre respeitar mudanças mínimas

## Regras inegociáveis

1. **LEIA primeiro** os arquivos em `.opencode/context/` antes de qualquer mudança
2. Preserve notas manuais do usuário (qualquer bloco com `<!-- manual -->` ou precedido por comentário `personal note:`)
3. Atualize **somente** o que mudou de fato no projeto
4. **NÃO** delete informações sem evidência de que estão erradas
5. **NÃO** toque no `AGENTS.md` do projeto
6. **NÃO** adicione esses arquivos ao git automaticamente

## Passo 1 — Estado atual

Leia:
- `.opencode/context/project.md`
- `.opencode/context/architecture.md`
- `.opencode/context/conventions.md`
- `.opencode/context/commands.md`
- `.opencode/context/decisions.md`

Se algum não existir, sinalize e ofereça criar do zero (nesse caso, redirecione para `/init-project`).

## Passo 2 — Re-analisar apenas o que pode ter mudado

Varredura cirúrgica:
- `composer.json` / `package.json` / lockfiles (dependências)
- Estrutura de diretórios (novas pastas?)
- Configurações Docker / CI
- Arquivos de teste (novos frameworks?)
- Documentação nova em `docs/`

Cuidado: mudanças em código de feature **não** devem alterar o contexto arquitetural. Foque em mudanças **estruturais**.

## Passo 3 — Aplicar diffs mínimos

Para cada arquivo `.opencode/context/*.md`:

1. Identifique o que está desatualizado
2. Aplique edição focada via `edit`
3. Preserve parágrafos adjacentes intocados
4. Marque novas informações com timestamp `[atualizado YYYY-MM-DD]` quando relevante

## Passo 4 — Validar consistência

Confirme que os 5 arquivos continuam consistentes entre si:
- `commands.md` cita comandos que ainda existem no projeto
- `architecture.md` menciona diretórios que ainda existem
- `decisions.md` não contradiz `conventions.md`

## Passo 5 — Relatório

Mostre ao usuário um diff resumido:
```
Arquivo                   | Mudança
--------------------------|----------------------------------
project.md                | + 1 linha (versão PHP 8.3 → 8.4)
commands.md               | + 2 comandos novos
architecture.md           | inalterado
conventions.md            | inalterado
decisions.md              | inalterado
```

Liste qualquer nota manual que foi preservada.