---
title: "Profile: Generic (Tecnologia-agnóstico)"
---
Este é o profile base. Carregue-o sempre. Profiles específicos (PHP, Laravel) carregam em cima deste.

## Filosofia

**Você é um engenheiro de software, não um especialista em uma stack.**

Princípios universais primeiro. Adaptações específicas depois.

## Princípios transversais

### 1. Versionamento explícito

- Verifique versão da linguagem, framework, bibliotecas **antes** de assumir APIs disponíveis
- Procure em: `composer.json`, `package.json`, `pyproject.toml`, `*.lock`, `.nvmrc`, `.python-version`, etc.
- Não confie em "provavelmente é 8.x" — confirme

### 2. Gerenciamento de dependências

- **Nunca** adicione dependência sem justificativa
- Use a versão mais recente **compatível** com a versão atual do projeto
- Se for atualizar dependência, mencione no relatório (mudança de escopo)

### 3. Testes

- **Descubra** que framework de teste é usado (PHPUnit, Pest, Jest, Vitest, pytest, etc.)
- **Siga** o padrão do projeto (data providers, factories, fixtures)
- **Mire** na cobertura de caminho novo, não em 100% coverage
- **Não pule** testes com `@skip`/`@todo` sem justificativa

### 4. Análise estática

- Se o projeto usa (PHPStan, ESLint, Psalm, mypy, ruff, etc.), rode-o
- Não introduza erros novos mesmo se já há erros pré-existentes
- Se o projeto **não** usa, não adicione (a menos que pedido)

### 5. Formatação

- Se há prettier/pint/editorconfig, deixe ele formatar
- **Não reformate** manualmente arquivos que você não está editando
- Se não há formatação automática, siga o estilo local (3+ ocorrências)

## Padrões de código (genéricos)

### Nomenclatura

| Elemento | Convenção |
|---|---|
| Classes | PascalCase |
| Métodos/funções | camelCase ou snake_case (siga o projeto) |
| Constantes | UPPER_SNAKE |
| Variáveis | camelCase ou snake_case (siga o projeto) |
| Booleanos | `is`, `has`, `should`, `can` como prefixo |
| Coleções | plural (`users`, não `userList`) |

### Estrutura de função

```text
[modificador] function nome(argumentos): tipo_retorno
```

- Argumentos: máximo 3-4; se mais, considere objeto
- Efeitos colaterais: explícitos (nome diz o que muda)
- Erros: exceções tipadas, não strings

### Tratamento de erros

- **Não silencie** exceções sem logging
- **Não capture** genérico (`catch (Exception)` sem motivo)
- **Propague** quando não souber tratar
- **Documente** erros esperados vs inesperados

### Logging

- Log com contexto (request id, user id, dados relevantes)
- Níveis apropriados (debug/info/warn/error)
- Não logue dados sensíveis (senha, token, PII)

## Estrutura de arquivos

### Quando criar arquivo novo

- Considere onde arquivos similares ficam (não crie `utils/` se o projeto usa `helpers/`)
- Nome reflete propósito, não tipo genérico (`OrderProcessor.php`, não `Handler.php`)
- Se for classe, geralmente 1 classe por arquivo

### Quando modificar

- Mantenha a estrutura do arquivo (imports agrupados, ordem de métodos)
- Não mova código sem motivo (facilita review)
- Não reformate (deixe para ferramenta automática)

## Performance

- **Não otimize prematuramente.** Mas não escreva N+1 óbvio.
- **I/O:** minimize, agrupe, cacheie quando há ganho real
- **Memória:** processe streams quando viável
- **Mensure** se performance for requisito

## Segurança (genérica)

- **Valide** toda entrada externa
- **Escape** toda saída
- **Auth** em toda operação não-pública
- **Authz** (autorização) — não confundir com auth
- **Não** commitar secrets (.env, chaves, tokens)
- **Não** logar secrets/PII

## Documentação

- Documente o "porquê", não o "o quê" (código diz o quê)
- README atualizado quando adiciona funcionalidade significativa
- Comentários em decisões não-óbvias
- **Não** comente o óbvio (`i++; // increment i`)

## Versionamento semântico (semver)

- **MAJOR**: breaking changes
- **MINOR**: feature nova, backward-compat
- **PATCH**: bug fix, backward-compat

Siga isso se o projeto segue. Se não segue (ex: Laravel), siga o do projeto.

## Quando não há padrão claro

Se você não consegue decidir entre duas abordagens:

1. **Olhe 3+ ocorrências similares no projeto** — siga o que predomina
2. **Pergunte ao usuário** — não chute
3. **Documente a decisão** em `.opencode/context/decisions.md` (se for importante)

---

## Carregamento de profiles mais específicos

Este profile é carregado **sempre**. Profiles específicos adicionam:

- `@harness/profiles/php.md` → adiciona guidance PHP puro
- `@harness/profiles/laravel.md` → adiciona guidance Laravel (assume PHP já carregado)

**Hierarquia:** Generic → PHP → Laravel (cada um adiciona, não substitui).