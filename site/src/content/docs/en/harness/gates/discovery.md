---
title: "Gate: DISCOVERY"
---
# Gate: DISCOVERY

Checklist da fase de descoberta, antes de planejar uma mudança significativa.

## Antes de começar a implementação

Você DEVE ser capaz de responder a todas estas perguntas. Se não conseguir, investigue mais.

### Sobre funcionalidades similares

- [ ] **Já existe algo parecido?** Sim/Não — onde? (`file:linha`)
- [ ] **Posso reutilizar?** Qual parte é reutilizável? Qual não é?
- [ ] **Por que o código novo é necessário?** (se já existe algo)

### Sobre a estrutura

- [ ] **Onde esse código vai morar?** (caminho concreto)
- [ ] **Que camada/componente é responsável?** (Service, Action, Controller direto, etc.)
- [ ] **Que padrão o projeto usa para esse tipo de coisa?** (com 2-3 exemplos de arquivo)

### Sobre dependências

- [ ] **Quem vai usar/importar/chamar?** (callers conhecidos)
- [ ] **Que serviços/classes externas preciso usar?** (e onde estão)
- [ ] **Há contratos externos** (API pública, eventos publicados)? Se sim, quais?

### Sobre restrições

- [ ] **Versão da linguagem:** qual é a do projeto? (composer.json, package.json)
- [ ] **Versão do framework:** qual é a do projeto?
- [ ] **Versões mínimas:** alguma feature moderna está disponível?
- [ ] **Restrições de plataforma:** (PHP 8.1+ mas projeto é 8.0)

### Sobre testes

- [ ] **Que testes existem para área similar?** Onde?
- [ ] **Que tipo de teste é o padrão?** (unit, feature, integration)
- [ ] **Há fixtures/factories que devo usar?**

### Sobre comandos disponíveis

- [ ] **Como rodo testes?** (comando exato)
- [ ] **Como rodo lint?** (se houver)
- [ ] **Como rodo análise estática?** (se houver)
- [ ] **Como rodo formatação?** (se houver)

## Comandos de busca úteis

```bash
# Estrutura geral
tree -L 3 -I 'node_modules|vendor|.git'

# Buscar por padrão
grep -r "class.*Controller" app/Http/Controllers/ | head

# Ver composer.json
cat composer.json | jq '.require, .scripts'

# Ver package.json
cat package.json | jq '.scripts, .dependencies'

# Testes existentes
find . -path "*/tests/*" -name "*.php" -o -path "*/test/*" -name "*.ts" | head
```

## Saída esperada

Ao terminar a fase DISCOVER, você deve ter:

```markdown
## Discovery — [nome da tarefa]

### Funcionalidade similar
- `caminho:linha` — [descrição do que faz]
- Decisão: reutilizar / estender / criar do zero

### Localização
- Criar em: `caminho/novo`
- Modificar: `caminho/existente`

### Padrão a seguir
- Tipo: [Service | Action | Controller | ...]
- Exemplo de referência: `caminho/exemplo:linha`

### Dependências
- Usará: [...]
- Será usado por: [...]

### Restrições
- PHP: [versão]
- Framework: [versão]
- Outras: [...]

### Comandos
- Teste: `[comando]`
- Lint: `[comando ou N/A]`
- Análise: `[comando ou N/A]`
```

Se QUALQUER item ficou `UNKNOWN`, preencha antes de prosseguir para PLAN.

## Testing Capability Discovery

Antes de aplicar TDD, descubra o que o projeto já tem. Esta sub-fase alimenta o **TDD Status Assessment** definido em `@harness/workflows/tdd.md`.

### O que descobrir

| Pergunta | Como descobrir | Saída |
|---|---|---|
| O projeto tem testes automatizados? | `ls tests/` ou `find . -name "*Test*.php"` | sim/não |
| Qual framework? | `composer.json` (`phpunit/phpunit`, `pestphp/pest`), `package.json` (`jest`, `vitest`) | PHPUnit/Pest/Jest/etc |
| Onde ficam os testes? | Padrão do framework (PHPUnit: `tests/Unit`, `tests/Feature`) | path |
| Como rodar? | `composer.json` → `scripts.test`, `package.json` → `scripts.test` | comando exato |
| Os testes rodam sem erro? | Tente `composer test` ou `npm test` | OK / falhas pré-existentes |
| Há testes para área similar? | `find tests -name "*SimilarFuncionalidade*"` | sim/não |

### Status assessment (TDD)

Classifique com base nas evidências:

- **TDD_READY** — framework instalado, testes rodam, há testes similares
- **TDD_LIMITED** — testes existem mas setup quebrado OU área sem cobertura
- **TDD_UNAVAILABLE** — sem framework OU sem testes OU setup inviável

### Nunca invente

- ❌ Não assuma framework sem ver em lockfile
- ❌ Não invente comando de teste
- ❌ Não prescreva PHPUnit/Pest/etc — descubra qual o projeto usa

### Saída esperada da testing discovery

```markdown
### Testing capability
- Framework: [PHPUnit 10 / Pest 2 / Jest 29 / N/A]
- Comando: `[composer test]` ou `[npm test]` ou N/A
- Cobertura similar: [sim/não — onde]
- Status: [TDD_READY | TDD_LIMITED | TDD_UNAVAILABLE]
- Razão: [1 linha]
```

Para detalhes completos do TDD workflow, consulte `@harness/workflows/tdd.md`.