---
title: "Workflow: TDD (Test-Driven Development)"
---
Módulo reutilizável de TDD. Carregado via `@harness/workflows/tdd.md` por:

- `/feature` (durante IMPLEMENT)
- `/bug` (durante REGRESSION TEST)
- `/refactor` (durante VERIFY TEST COVERAGE / CHARACTERIZATION TESTS)
- `/debug` (na transição para fix após root cause)

**Não crie um `/tdd` command nem uma `tdd` skill.** TDD é integrado automaticamente.

---

## Filosofia: TDD-FIRST, QUANDO PRÁTICO

Para mudanças de comportamento observável (feature, bug fix, mudança de regra de negócio), preferir:

```
RED           →  GREEN         →  REFACTOR      →  VALIDATE
definir o                  implementar       melhorar           rodar
comportamento   mínimo      estrutura       restante
observável                  código         preservando
                          necessário       comportamento
escrever teste                             testes passam
que falha
```

**Não aplicar cegamente** quando:

- Mudança puramente configuracional (YAML, .env, config files)
- Mudança de documentação
- Investigação exploratória
- Infraestrutura sem validação automatizada disponível
- Bug de emergência antes do ambiente suportar testes

Nesses casos, **declarar explicitamente** no relatório:
```
TDD STATUS: NOT APPLIED
REASON: [motivo]
VALIDATION: [estratégia alternativa usada]
```

---

## Projeto Testing Discovery

Antes de aplicar TDD, descubra o que o projeto já tem.

### O que descobrir

| Pergunta | Como descobrir |
|---|---|
| O projeto tem testes automatizados? | `ls tests/`, `find . -name "*Test*.php"`, `find . -name "*.test.ts"` |
| Qual framework? | `composer.json`, `package.json`, `phpunit.xml`, `pestphp/pest` no composer |
| Onde ficam os testes? | Padrão do framework (PHPUnit: `tests/Unit`, `tests/Feature`; Jest: `__tests__`, `*.test.ts`) |
| Como rodar? | `composer.json` → `scripts.test`, `package.json` → `scripts.test` |
| Há testes para área similar? | `find tests -name "*FuncionalidadeSimilar*"` |
| Os testes funcionam agora? | Tente rodar `composer test` ou `npm test` — observe falhas pré-existentes |
| Qual a cobertura atual? | Se o projeto medir (`composer test:coverage`) |
| Convenções de naming? | Veja 3+ testes existentes: `test_X`, `it_X`, `XTest.php`? |

### Nunca invente

- ❌ Não assuma PHPUnit, Pest, Jest, Mocha sem ver em `composer.json`/`package.json`
- ❌ Não invente comandos de teste
- ❌ Não prescreva framework se o projeto usa outro

### Onde fica essa descoberta

Já parcialmente em `harness/profiles/php.md` e `harness/profiles/laravel.md`. Em `harness/gates/discovery.md` há a sub-fase formal.

---

## TDD Status Assessment

Classifique o projeto:

### TDD_READY

O projeto tem infraestrutura de testes utilizável.

**Indicadores:**
- Framework instalado e configurado
- Testes existentes rodam sem erro de setup
- Comando de teste documentado (composer.json, package.json)
- Há testes para área similar

**Ação:** aplicar TDD-first (RED → GREEN → REFACTOR)

### TDD_LIMITED

Testes existem mas com limitações.

**Exemplos:**
- Ambiente quebrado (dependências faltando, DB não conecta)
- Testes pré-existentes com falhas
- Setup complexo (precisa de Docker, banco específico, seed)
- Sem testes para a área a modificar

**Ação:**
- Se o problema for só na área a modificar: adicionar testes novos para essa área
- Se o ambiente estiver quebrado: tentar corrigir setup OU usar estratégia alternativa (teste manual, smoke test, log)
- **Não bloquear** indefinidamente. Escolha a melhor estratégia disponível.

### TDD_UNAVAILABLE

Projeto sem infraestrutura utilizável.

**Indicadores:**
- Sem framework de teste
- Sem testes no projeto
- Setup muito complexo para reproduzir em CI/dev

**Ação:**
- Para TDD puro: adicionar **uma pequena parte testável** (ex: lógica isolada em uma classe, helper) e testar isso
- Para integração: documentar manualmente, validar via smoke test, usar logs
- **Não fabricar** uma "suite de testes" só para seguir o princípio
- **Sempre** declarar o status no relatório final

### Como reportar

```
TDD STATUS: [READY | LIMITED | UNAVAILABLE | NOT_APPLICABLE]
REASON: [1 linha explicando]
TEST LEVEL: [UNIT | FEATURE | INTEGRATION | E2E | N/A]
```

---

## Test Level Selection

Selecione o nível apropriado baseado em:

### UNIT TEST

**Quando:**
- Lógica isolada (cálculos, transformações, regras puras)
- Sem dependência externa (DB, API, filesystem)
- Comportamento determinístico

**Ferramentas comuns (descobrir antes):**
- PHPUnit/Pest: métodos isolados, classes de serviço puras
- Jest: funções puras, helpers

### FEATURE / FUNCTIONAL TEST

**Quando:**
- Testa fluxo de aplicação (request → response)
- Envolve rotas, controllers, middleware
- Laravel: `tests/Feature/` é o lar padrão

**Ferramentas:**
- Laravel: `$this->get('/url')`, `$this->actingAs($user)`, `$this->assertDatabaseHas()`
- NestJS: Testing module, supertest

### INTEGRATION TEST

**Quando:**
- Interação entre componentes internos (Service → Repository → DB)
- Verifica que peças funcionam juntas
- Pode ou não envolver HTTP

**Quando usar:**
- Lógica que cruza camadas
- Regras de negócio que envolvem persistência
- Filas, eventos, listeners

### END-TO-END TEST

**Quando:**
- Testa fluxo completo do usuário (UI → backend → DB)
- Verifica integração com serviços externos

**Só usar quando:**
- O projeto tem suporte (Cypress, Playwright, Dusk)
- O ROI justifica o custo de manutenção

### Como decidir

| O código a testar... | Nível sugerido |
|---|---|
| É uma função pura | UNIT |
| Envolve model + DB | UNIT ou FEATURE (depende do escopo) |
| Envolve request HTTP | FEATURE |
| Envolve fila, evento, listener | INTEGRATION ou FEATURE |
| Envolve UI (clique, formulário) | E2E (se suportado) |

**Regra:** siga as convenções do projeto. Se a maioria dos testes similares é feature, faça feature. Não force unit se o projeto é majoritariamente feature.

---

## Fase RED

### O que fazer

1. **Identifique o comportamento observável** que vai ser implementado ou corrigido.
   - Entradas
   - Saídas
   - Side effects
   - Casos de erro

2. **Busque testes similares** no projeto.
   ```bash
   grep -r "comportamento_similar" tests/
   ```

3. **Escolha o test level** apropriado (ver seção anterior).

4. **Crie ou atualize o teste:**
   - Siga convenção de naming do projeto
   - Posicione na pasta correta
   - Use factories/fixtures existentes quando possível

5. **Rode o teste:**
   ```bash
   composer test -- --filter=MeuNovoTest
   # ou
   npm test -- MeuNovoTest
   ```

6. **Verifique que falha pelo motivo esperado.**

### "Falha significativa" — critério crítico

A falha do teste deve demonstrar que **o comportamento ainda não existe** ou está **errado**.

Falhas que **NÃO contam** como RED válido:

- ❌ Erro de sintaxe no teste
- ❌ Test setup quebrado (DB, mock faltando)
- ❌ Dependência não instalada
- ❌ Comando de teste errado
- ❌ Ambiente mal configurado

Se a falha é de setup: **corrija o setup primeiro**, depois confirme que o teste falha pelo comportamento.

### Saída do RED

```
Status: RED
Teste criado: tests/Unit/MeuTest.php (ou caminho equivalente)
Falha observada: [mensagem do test runner]
Causa da falha: [comportamento X não está implementado]
```

---

## Fase GREEN

### O que fazer

1. **Implemente o mínimo** de código de produção necessário para o teste passar.
   - Sem abstração prematura
   - Sem outras features
   - Sem drive-by refactor
   - Sem otimização especulativa

2. **Rode o teste novamente.**

3. **Verifique que passa.**

4. **Rode o resto dos testes** da área (não só o seu):
   ```bash
   composer test -- --filter=AreaAfetada
   ```

5. **Rode a suite inteira** se for mudança pequena:
   ```bash
   composer test
   ```

### O que NÃO fazer

- ❌ Adicionar outras features no mesmo commit
- ❌ Refatorar código adjacente
- ❌ Melhorar mensagens de erro (a menos que pedido)
- ❌ Adicionar logging extra
- ❌ Implementar "para o futuro"

### Saída do GREEN

```
Status: GREEN
Teste que falhou: agora passa
Implementação: [descrição mínima do que foi adicionado]
Testes rodados: [suite inteira ou filtro]
Resultado: N/N passou
```

---

## Fase REFACTOR

### Quando aplicar

- **Opcional.** Não refatore só porque o workflow diz para refatorar.
- Quando o código ficou feio (duplicação, complexidade óbvia)
- Quando o teste continua passando e o comportamento é preservado

### O que fazer

1. **Identifique melhoria específica** (sem "vamos limpar tudo").
2. **Refatore em passos pequenos**, rodando testes após cada um.
3. **Se um teste falhar após um passo:** reverta esse passo, investigue.

### Característica essencial

**Comportamento idêntico.** Se você perceber que precisa mudar comportamento, pare — isso é FEATURE ou BUGFIX, não REFACTOR.

### Saída do REFACTOR

```
Status: REFACTOR (opcional)
Mudanças: [descrição da refatoração]
Testes continuam passando: sim
Comportamento preservado: [evidência]
```

---

## Characterization Tests (código legado)

Para código sem testes, antes de mexer:

### O que é

Um teste que **captura o comportamento atual** (não o desejado). Serve como rede de segurança.

### Quando usar

- Refatorar código sem cobertura
- Tentar entender código legado via testes
- Tarefas em projetos com `TDD_UNAVAILABLE` mas com lógica isolada

### Como escrever

```php
// PHP - Pest
test('comportamento atual de calcularFrete', function () {
    $resultado = $calcularFrete(100, 'SP');
    expect($resultado)->toBe(15.50); // valor atual, mesmo que estranho
});
```

```ts
// Jest
test('comportamento atual de normalizarNome', () => {
    expect(normalizarNome('  João  ')).toBe('Joao'); // comportamento atual
});
```

### Distinção importante

| CURRENT OBSERVED BEHAVIOR | DESIRED BEHAVIOR |
|---|---|
| O código FAZ isso hoje | O código DEVERIA fazer isso |
| Captura via characterization test | Implementado em TDD normal |
| Não é "correto" — é o que existe | É o que o usuário pediu |

**Se o comportamento atual está errado**, não preserve — corrija. Characterization tests são para refactor; bugfix usa TDD normal.

---

## Quando NÃO aplicar TDD

Declare explicitamente quando pular:

### Configuração pura

- `.env`, `docker-compose.yml`, CI YAML
- Sem código de produção a ser testado

**Validação alternativa:** rodar a configuração em ambiente real ou usar linter de config

### Documentação

- README, markdown, comentários
- Sem código a ser testado

**Validação alternativa:** renderização, link check

### Investigação exploratória

- "como isso funciona?", "onde fica X?"
- Sem intenção de mudar código

**Validação alternativa:** nenhuma (é só leitura)

### Infraestrutura sem suporte

- Provisionamento manual, scripts shell sem teste
- Ambiente complexo demais para setup em CI

**Validação alternativa:** documentar o procedimento, executar manualmente

### Emergência antes do ambiente estar pronto

- Bug crítico, produção fora, ambiente quebrado
- Não dá para esperar TDD ser montado

**Validação alternativa:** hotfix + smoke test manual + adicionar teste depois

---

## TDD Decision Output (formato padrão)

Para tarefas significativas em `/feature` e `/bug`, declare no relatório final:

```markdown
**TDD STATUS:** [READY | LIMITED | UNAVAILABLE | NOT_APPLICABLE]

**TEST LEVEL:** [UNIT | FEATURE | INTEGRATION | E2E | N/A]

**CYCLE:**
- RED: [teste criado em caminho:teste]
- GREEN: [implementação em caminho:arquivo]
- REFACTOR: [sim/não, motivo]

**REASON:** [1-2 frases explicando a estratégia escolhida]

**VALIDATION:**
- [comando]: [resultado]

**NOT VALIDATED:** [se algo ficou sem validação, com motivo]
```

Para tarefas triviais, mantenha leve:
```
TDD aplicado: sim/não (motivo)
```

---

## Integração com os workflows existentes

### `/feature` usa este módulo em IMPLEMENT

```
DISCOVER → ... → PLAN → IMPLEMENT → ...
                       ↓
                   Carrega @harness/workflows/tdd.md
                       ↓
                   TDD status assessment
                       ↓
                   RED → GREEN → REFACTOR
                       ↓
                   TDD_STATUS no relatório final
```

### `/bug` usa este módulo em REGRESSION TEST

```
REPRODUCE → INVESTIGATE → ROOT CAUSE → REGRESSION TEST → ...
                                              ↓
                                       Carrega @harness/workflows/tdd.md
                                              ↓
                                       RED → GREEN → VALIDATE
                                              ↓
                                       TDD_STATUS no relatório final
```

### `/refactor` usa este módulo em TEST COVERAGE

```
ANALYZE → DEPENDENCIES → TEST COVERAGE → ...
                              ↓
                         Carrega @harness/workflows/tdd.md
                              ↓
                         Cobertura insuficiente?
                              ↓
                         Characterization tests primeiro
                              ↓
                         Refactor mantendo verde
```

### `/debug` usa este módulo após root cause

```
... → ROOT CAUSE → [TRANSITION TO RED]
                          ↓
                    Carrega @harness/workflows/tdd.md
                          ↓
                    Regression test failing
                          ↓
                    Minimal fix
                          ↓
                    Validar
```

---

## Anti-padrões a evitar

- ❌ TDD cego sem descobrir o que o projeto tem
- ❌ TDD quando não é prático (config pura, etc.) sem declarar
- ❌ Escrever produção inteira e testes depois
- ❌ Testes que falham por erro de setup (não contam como RED)
- ❌ Múltiplas mudanças experimentais sem reverter
- ❌ Refactor durante GREEN (vira FEATURE/BUGFIX)
- ❌ Characterization tests que assumem comportamento "correto"
- ❌ Inventar framework/comandos que não existem no projeto

---

## Quando terminar

TDD termina quando:
1. Comportamento implementado (ou bug corrigido)
2. Testes passando (verde)
3. Relatório final tem TDD_STATUS declarado
4. Próximo passo sugerido (refactor opcional, review)

**Nunca** continua além disso.
