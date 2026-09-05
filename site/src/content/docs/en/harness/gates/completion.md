---
title: "Gate: COMPLETION"
---
Checklist obrigatório antes de declarar uma tarefa como pronta.

## Filosofia

**"Pronto" ≠ "código escrito".**

" Pronto" = código escrito + validado + revisado + comunicado.

---

## Bloco 1: O que foi feito

```markdown
- [ ] Código faz exatamente o que foi pedido
- [ ] Sem features extras escondidas
- [ ] Sem drive-by fixes não autorizados
- [ ] Sem reformatação desnecessária
```

## Bloco 2: Validação executada

### O que validar (matriz por tipo)

#### Para QUALQUER mudança de código

```markdown
- [ ] Sintaxe OK (sem erros de parse)
```

#### Para FEATURE

```markdown
- [ ] Lint/formatter passou (se existir no projeto)
- [ ] Análise estática passou (se existir)
- [ ] Testes existentes continuam passando
- [ ] Teste novo adicionado para a feature (recomendado)
- [ ] Smoke test manual da feature ponta-a-ponta
```

#### Para BUGFIX

```markdown
- [ ] Teste de regressão existe (novo OU identificado)
- [ ] Teste de regressão PASSA depois do fix
- [ ] Outros testes continuam passando
- [ ] Sintoma original não acontece mais (verificação manual/log)
- [ ] Logs/observabilidade suficientes para detectar reincidência
```

#### Para REFACTOR

```markdown
- [ ] Comportamento idêntico (todos os testes passam SEM mudar assertions)
- [ ] Smoke test manual passou
- [ ] Sem mudança funcional acidental
- [ ] Sem drive-by
```

#### Para REVIEW

```markdown
- [ ] Categorização de achados feita (CRITICAL/HIGH/MEDIUM/LOW)
- [ ] Cada achado tem `file:linha`
- [ ] Sugestões de correção para HIGH+
- [ ] Reconhecimento de pontos positivos
```

#### Para DEBUG

```markdown
- [ ] Causa raiz identificada COM evidência
- [ ] Sintoma não acontece mais
- [ ] Validação de não-regressão executada
```

### Quais comandos rodar?

**NUNCA invente comandos.** Antes de validar, SEMPRE confirme em:

| Fonte | O que procurar |
|---|---|
| `composer.json` (PHP) | `scripts.test`, `scripts.lint`, etc. |
| `package.json` (Node) | `scripts.test`, `scripts.lint` |
| `Makefile` | `test:`, `lint:`, `analyse:` |
| `.github/workflows/*.yml` | Comandos do CI |
| `README.md` | Comandos documentados |
| `CONTRIBUTING.md` | Idem |
| `.opencode/context/commands.md` | Se existir |

Se você não tem certeza se o comando existe, **declare explicitamente**:

```
**Não validado:** `composer test:coverage`
**Motivo:** não encontrei referência ao script `test:coverage` em composer.json
```

## Bloco 3: Auto-revisão do diff

```markdown
- [ ] Mudanças focadas (sem extras)
- [ ] Sem bugs óbvios
- [ ] Sem regressões óbvias
- [ ] Sem segredos/credenciais commitados
- [ ] Comentários úteis (não óbvios)
- [ ] Convenções do projeto respeitadas
- [ ] Nomes claros
- [ ] Sem código morto
- [ ] Sem comentários obsoletos
```

## Bloco 4: Comunicação ao usuário

### Relatório final (template)

```markdown
## [FEATURE|BUGFIX|REFACTOR|...]: [título]

**Feito:**
- [1-3 frases]

**Arquivos alterados:**
- `caminho/arquivo:linha` — [motivo]
- `caminho/outro:linha` — [motivo]
- (criado) `caminho/novo` — [responsabilidade]

**Validação executada:**
- `[comando]` → [resultado]
- `[comando]` → [resultado]

**Não validado (se houver):**
- `[item]` — motivo

**Próximos passos sugeridos:**
- [ ] [opcional 1]
- [ ] [opcional 2]
```

### Tom

- Direto (não prolixo)
- Honesto (admita o que não foi validado)
- Construtivo (sugira próximos passos quando relevante)
- Calibrado (não infle sucesso nem problemas)

---

## Anti-padrões

- ❌ Declarar "pronto" sem validar
- ❌ Mentir sobre testes passando
- ❌ Inventar comandos de validação
- ❌ Esconder o que ficou sem validação
- ❌ Entregar diff gigante sem revisão própria
- ❌ Responder com "ok, fiz" sem relatório

## Quando NÃO marcar como pronto

Se qualquer um destes for verdade, **NÃO marque como pronto**:

- Algum teste falha
- Lint/análise estática reporta erro novo
- Sintoma original persiste (em bug)
- Comportamento mudou (em refactor)
- Sem teste de regressão (em bug fix)
- Mudanças fora do escopo sem autorização
- Há dúvida sobre se atende o pedido

**Pare, corrija, depois marque como pronto.**