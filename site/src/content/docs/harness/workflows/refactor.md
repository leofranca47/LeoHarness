---
title: "Workflow: REFACTOR"
---
# Workflow: REFACTOR

Melhoria de estrutura interna **sem alterar comportamento observável**.

```
ANALYZE → IDENTIFY DEPENDENCIES → VERIFY TEST COVERAGE → PLAN → REFACTOR → VALIDATE BEHAVIOR → REVIEW
```

## Regra crítica

**Refatoração preserva comportamento.**

Se o comportamento precisa mudar, isso é FEATURE ou BUGFIX, não REFACTOR.

**Exceção explícita:** o usuário pediu "refatore X e mude o comportamento Y também". Nesse caso, declare explicitamente quais partes são refactor e quais mudam comportamento.

## Quando usar

- Eliminar duplicação
- Renomear para clareza (sem mudar contrato)
- Extrair método/classe
- Mover código para lugar mais apropriado
- Simplificar condicional complexa
- Remover código morto

## Quando NÃO usar

- Há bug a corrigir → primeiro `/bug`
- Comportamento precisa mudar → `/feature`
- Não há testes adequados → adicione testes primeiro, depois refatore

---

## Fase 1: ANALYZE

**Objetivo:** entender a estrutura atual e o que está ruim.

### Perguntas

- Qual é a estrutura atual? (mapear brevemente)
- O que exatamente está ruim?
  - Acoplamento?
  - Duplicação?
  - Complexidade ciclomática?
  - Tamanho (LOC)?
  - Naming confuso?
- Qual é a estrutura desejada?

### Saída

Declaração clara do problema e da direção.

---

## Fase 2: IDENTIFY DEPENDENCIES

**Objetivo:** mapear quem depende do código a ser refatorado.

### Ações

```bash
# Quem chama?
grep -r "ClasseAlvo\|metodoAlvo\|funcaoAlvo" --include="*.php" --include="*.ts"

# Quem é chamado por?
grep -r "use \|require \|import " caminho/arquivo-alvo

# Testes cobrem?
find . -path "*/tests/*" -name "*alvo*"
```

### Classifique

| Tipo de caller | Risco de mudança |
|---|---|
| Mesmo módulo | Baixo |
| Outro módulo interno | Médio |
| API pública / contrato externo | **Alto** |
| Reflection / dynamic call | **Alto** |

### Se houver callers de alto risco

Discuta com o usuário antes. Talvez seja necessário:
- Manter compatibilidade (deprecated alias)
- Versionar a API
- Comunicar a mudança

---

## Fase 3: VERIFY TEST COVERAGE

**Objetivo:** garantir que existe cobertura para travar o comportamento atual.

### Por que isso é obrigatório

Refatorar sem testes é rezar para dar certo. Vai quebrar produção.

### Verificação

```bash
# Verificar cobertura (se o projeto medir)
composer test:coverage
# ou
npm run test:coverage
```

### Se cobertura insuficiente

**PARE.** Você tem 2 caminhos:

1. **Adicionar testes que travam o comportamento atual** (TDD normal — ver `@harness/workflows/tdd.md`)
2. **Adicionar characterization tests** se for código legado

### Characterization tests (código legado)

Quando o código não tem testes e o comportamento atual é obscuro, characterization tests capturam o que o código **faz hoje** (não o que deveria fazer). Carregue `@harness/workflows/tdd.md` para detalhes completos.

```php
// Captura comportamento atual (mesmo que pareça "errado")
test('comportamento atual de calcularFrete', function () {
    $resultado = calcularFrete(100, 'SP');
    expect($resultado)->toBe(15.50); // valor que o código retorna HOJE
});
```

**Importante:** characterization tests protegem o refactor de quebrar comportamento, mas **não validam correção**. Se o comportamento atual está errado, é BUGFIX (com TDD normal), não REFACTOR.

### Se não há testes no projeto

Adicione **pelo menos testes para o código que será refatorado**. Use characterization tests se a lógica for obscura. Não é o ideal, mas é melhor que nada.

---

## Fase 4: PLAN

**Objetivo:** apresentar plano antes de refatorar (especialmente se grande).

### Estrutura

```markdown
# Plano de refactor: [título]

## Estado atual
[breve descrição]

## Estado desejado
[breve descrição]

## Passos
1. [passo pequeno e validável]
2. [próximo passo]
3. ...

## Riscos
- [risco 1]
- [risco 2]

## Estratégia de rollback
[git revert X / feature flag Y / etc.]
```

### Granularidade

- Pequenos passos são melhores (5-30 min cada)
- Cada passo deve poder ser validado isoladamente
- Cada passo pode ser commit separado (squash depois se quiser)

---

## Fase 5: REFACTOR

**Objetivo:** executar mudanças estruturais.

### Disciplina

- **Pequenos passos** (cada um validável)
- **Após cada passo:** rode os testes
- **Se um teste falhar:** pare, reverta, investigue
- **Sem "drive-by":** se notar um bug durante refactor, anote para depois; **não corrija no mesmo commit**

### Tipos comuns

| Tipo | Técnica |
|---|---|
| Extrair método | Identificar trecho coeso, dar nome |
| Extrair classe | Mover responsabilidades correlatas |
| Mover método | Para classe que tem mais contexto |
| Renomear | IDE refactor + atualizar todos os callers |
| Inline | Substituir delegação trivial por conteúdo |
| Substituir condicional | Strategy, polymorphism, null object |
| Introduzir parâmetro objeto | Em vez de N parâmetros correlatos |
| Remover código morto | Confirmar com git blame que é morto |

---

## Fase 6: VALIDATE BEHAVIOR

**Objetivo:** confirmar que comportamento idêntico foi preservado.

### O que validar

- Todos os testes existentes passam (sem mudar assertions)
- Smoke test manual (se aplicável)
- API pública responde igual (se aplicável)
- Logs/métricas não mudaram

### Validação comparativa

Se possível, compare antes/depois:

```bash
# Capturar baseline
composer test > before.log 2>&1

# Refatorar

# Comparar
composer test > after.log 2>&1
diff before.log after.log  # deve ser vazio ou apenas diferenças de tempo
```

---

## Fase 7: REVIEW

**Objetivo:** revisar o próprio diff.

### Checklist

```markdown
[ ] Comportamento idêntico (todos os testes passam, sem mudar assertions)
[ ] Mudanças são puramente estruturais (sem mudança funcional)
[ ] Sem drive-by fixes
[ ] Sem reformatação desnecessária
[ ] Comentários atualizados onde necessário
[ ] Cobertura de testes preservada (ou melhorada)
[ ] Sem novas dependências introduzidas
[ ] Nomes melhoram clareza
[ ] Acoplamento reduzido (se era o objetivo)
[ ] Complexidade reduzida (se era o objetivo)
```

### Anti-diff

Se no diff aparecer:
- Mudança em assertions de teste
- Mudança em mensagens de erro (que o usuário veria)
- Mudança em formato de log
- Mudança em resposta de API

**Pare.** Isso é mudança de comportamento. Reclassifique.

---

## Relatório final

```markdown
## Refactor: [título]

**Tipo:** extração | renomeação | movimentação | simplificação | ...
**Escopo:** X arquivos, Y LOC alteradas (adicionar/remover líquido)

**Comportamento preservado:**
- [evidência 1]
- [evidência 2]

**Testes:**
- Antes: X testes
- Depois: Y testes (Y >= X)
- Resultado: passaram

**Não validado:**
- [se algo ficou sem smoke test, declare]

**Próximos passos sugeridos:**
- [outras melhorias identificadas, mas FORA do escopo]
```

---

## Anti-padrões

- ❌ Refatorar sem testes
- ❌ Mudar comportamento durante refactor
- ❌ Drive-by fixes ("já que estou aqui...")
- ❌ Refatorar 50 arquivos em 1 commit
- ❌ Não rodar testes entre passos
- ❌ Aceitar regressão "porque é pequena"
- ❌ Refatorar código que está prestes a ser deletado
- ❌ Combinar refactor + feature + bugfix em um único PR (espalhe)

## Quando parar de refatorar

- Você atingiu o objetivo declarado
- Próximas mudanças adicionam risco sem benefício claro
- Está reescrevendo do zero (vire um projeto novo)