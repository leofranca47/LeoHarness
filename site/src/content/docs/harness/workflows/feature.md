---
title: "Workflow: FEATURE"
---
# Workflow: FEATURE

Implementação de nova funcionalidade seguindo o pipeline estruturado.

```
DISCOVER → ANALYZE → PLAN → IMPLEMENT → VALIDATE → REVIEW
```

## Quando usar

- Adicionar endpoint/rota nova
- Criar nova classe/serviço/módulo
- Adicionar campo/coluna/tabela
- Implementar integração com API externa
- Criar comando artisan, console command, etc.

## Quando NÃO usar

- Bug → `/bug`
- Sintoma vago → `/debug`
- Melhoria estrutural sem mudar comportamento → `/refactor`

---

## Fase 1: DISCOVER

**Objetivo:** mapear funcionalidades similares, padrões e dependências ANTES de codar.

### Ações obrigatórias

```bash
# Buscar features similares
grep -r "palavra-chave" --include="*.php" --include="*.ts" etc.

# Mapear estrutura
find . -type d -name "src" -o -name "app" -o -name "lib" | head

# Identificar padrões
ls app/Http/Controllers/ app/Services/ app/Models/
```

### O que procurar

| Item | Por quê |
|---|---|
| Funcionalidade similar existente | Reutilizar antes de criar |
| Camadas/pastas relevantes | Onde o código novo vai morar |
| Padrão de nomenclatura | Manter consistência |
| Tratamento de erros usado | Idem |
| Testes para features similares | Como testar isso aqui |

### Saída do DISCOVER

Antes de prosseguir, você deve ser capaz de responder:

- [ ] "Onde isso vai ficar?"
- [ ] "Quem vai chamar/usar?"
- [ ] "Que padrões devo seguir?"
- [ ] "Já existe algo parecido que posso reutilizar?"

Se não consegue responder, investigue mais. **Não prossiga com lacunas.**

---

## Fase 2: ANALYZE

**Objetivo:** entender impacto em todas as dimensões.

### Matriz de impacto

| Dimensão | Perguntas |
|---|---|
| **Direto** | Quais arquivos vou criar/alterar? |
| **Indireto** | Quem depende desses arquivos? |
| **Banco** | Preciso de migration? Afeta outras tabelas? |
| **API** | Novo endpoint? Muda contrato existente? Versionar? |
| **Filas** | Dispara jobs? Workers preparados? |
| **Cache** | Cache precisa ser invalidado? Chaves afetadas? |
| **Eventos** | Dispara/listeners existentes? |
| **Testes** | Que testes existentes podem quebrar? |
| **Performance** | Hot path? N+1? Query pesada? |
| **Segurança** | Auth? Autorização? Validação? Injection? |
| **Observabilidade** | Logs? Métricas? Traces? |

### Saída do ANALYZE

Lista explícita de impactos categorizados. Se algum item for "alto risco", destaque.

---

## Fase 3: PLAN

**Objetivo:** apresentar plano claro ANTES de implementar (para tarefas complexas).

### Estrutura do plano

```markdown
# Plano: [nome curto da feature]

## Objetivo
[1-2 frases]

## Arquivos esperados (alterar/criar)
- `caminho/arquivo.php` — criar/alterar (motivo)
- ...

## Passos ordenados
1. [ ] Passo 1 — descrição
2. [ ] Passo 2 — descrição
3. [ ] ...

## Riscos
- [risco 1] — mitigação
- [risco 2] — mitigação

## Como validar
- [comando/teste 1]
- [comando/teste 2]
```

### Quando apresentar plano formal

- Tarefa > 3 arquivos: **SIM**
- Tarefa 1-2 arquivos, mudança clara: **inline (1-2 frases)**
- Tarefa trivial (1 linha): **pode pular**

**Para tarefas grandes, obtenha aprovação do usuário antes de implementar.**

---

## Fase 4: IMPLEMENT

**Objetivo:** executar mudanças seguindo padrões descobertos.

### Abordagem preferida: TDD-first

Para mudanças de comportamento observável, prefira o ciclo **RED → GREEN → REFACTOR** definido em `@harness/workflows/tdd.md`:

1. Descobrir a capacidade de teste do projeto (sub-fase em `@harness/gates/discovery.md`)
2. Classificar TDD status: `TDD_READY` / `LIMITED` / `UNAVAILABLE`
3. Se READY ou LIMITED (com cobertura possível na área):
   - **RED** — escrever teste falhando
   - **GREEN** — implementar mínimo para passar
   - **REFACTOR** (opcional) — melhorar mantendo verde
4. Se UNAVAILABLE ou NOT_APPLICABLE: declarar no relatório, usar validação alternativa

**Só pule TDD** se a tarefa for puramente configuracional, documental ou de infra sem suporte — declare no relatório final.

### Regras durante implementação

- **Siga os padrões existentes** (não invente novos)
- **Mudanças focadas** (sem drive-by)
- **Reuse** abstrações existentes em vez de criar novas
- **Siga as convenções** de `.opencode/context/conventions.md` se existir
- **Não reformate** código adjacente

### Estratégia para tarefas grandes

- Commits intermediários (lógicos e testáveis)
- Após cada passo, valide (teste ou smoke)
- Se quebrar: pare, reverta, investigue

### Saída do IMPLEMENT

Código escrito, arquivos listados, TDD_STATUS definido.

---

## Fase 5: VALIDATE

**Objetivo:** confirmar que funciona e não quebrou nada.

### Comandos a executar (apenas se existirem no projeto)

Verifique primeiro em `composer.json`, `package.json`, Makefile, CI:

```bash
# Comandos comuns (NÃO execute se não existirem)
composer test
composer lint
composer analyse
npm test
npm run lint
npm run build
```

Ver `@harness/core/completion-criteria.md` para a matriz completa.

### O que validar

- [ ] Sintaxe OK
- [ ] Lint/formatter passou
- [ ] Análise estática passou
- [ ] Testes existentes passam
- [ ] Teste novo adicionado (recomendado)
- [ ] Smoke test manual (se aplicável)

### Se validação falhar

Pare. Investigue. Corrija. **Não declare pronto com falha.**

---

## Fase 6: REVIEW

**Objetivo:** revisar o próprio diff antes de entregar.

### Checklist de auto-review

```markdown
[ ] O código faz exatamente o que foi pedido
[ ] Mudanças estão focadas (sem extras)
[ ] Sem bugs óbvios
[ ] Sem regressões óbvias
[ ] Testes adequados
[ ] Sem segredos/credenciais
[ ] Comentários úteis onde realmente necessário
[ ] Convenções do projeto respeitadas
```

### Se encontrar problema no próprio review

Corrija antes de entregar. Ou declare explicitamente ao usuário.

---

## Relatório final ao usuário

```markdown
## Feature: [nome]

**Implementado em:** [lista de arquivos]

**Testing:**
- TDD Status: [READY | LIMITED | UNAVAILABLE | NOT_APPLICABLE]
- Test Level: [UNIT | FEATURE | INTEGRATION | E2E | N/A]
- Cycle: RED → GREEN → [REFACTOR]
- Teste criado/alterado: `caminho/teste`

**Validação:**
- `[comando]` → [resultado]
- `[comando]` → [resultado]

**Não validado:**
- [item, se houver, com motivo]

**Notas:**
- [decisões, trade-offs observados]

**Próximos passos sugeridos:**
- [ ]
```

---

## Anti-padrões a evitar

- ❌ Pular DISCOVER e ir direto para código
- ❌ Não validar e declarar pronto
- ❌ Implementar extras "enquanto estou aqui"
- ❌ Inventar arquitetura que não existe no projeto
- ❌ Comitar tudo de uma vez sem validação intermediária
- ❌ Ignorar testes existentes (eles protegem o código)