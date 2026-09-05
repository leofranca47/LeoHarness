# Site de documentação OpenHarness

Gerado com **[Astro](https://astro.build/) + [Starlight](https://starlight.astro.build/)** a partir dos arquivos `.md` do source-of-truth do [OpenHarness](../). Design system baseado no projeto Stitch **"Obsidian Cybernetic Harness"**.

## Pré-requisitos

- Node ≥ 20
- npm ≥ 10

## Comandos

| Comando | O que faz |
|---|---|
| `npm install` | Instala dependências |
| `npm run sync:content` | Espelha arquivos `.md` do harness para `src/content/docs/{pt,en}/` |
| `npm run dev` | Inicia dev server (http://localhost:4321) |
| `npm run build` | Sincroniza conteúdo + build de produção em `dist/` |
| `npm run preview` | Serve o build de produção |
| `npm test` | Roda os testes unitários do script de sync |
| `npm run check:routes` | Smoke test — verifica HTTP 200 nas rotas principais |

## Estrutura

- `src/content/docs/` — Conteúdo espelhado (gerado por `sync:content`)
- `src/styles/tokens.css` — CSS variables do design system
- `src/styles/custom.css` — Overrides sobre defaults do Starlight
- `src/components/` — Componentes Astro (Card, CodeTerminal, etc.)
- `src/i18n/` — Dicionários de UI strings
- `scripts/sync-content.mjs` — Pipeline de espelhamento (lê do harness, escreve em `src/content/docs/`)
- `scripts/check-routes.mjs` — Smoke test das rotas

## Restrição importante

Este site **só lê** os arquivos do harness como fonte de conteúdo. Ele **nunca modifica** `commands/`, `agents/`, `harness/`, `AGENTS.md` ou `README.md` na raiz do repo.
