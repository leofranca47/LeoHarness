---
title: "Workflow: REVIEW"
---
Análise crítica de código/diff sem modificá-lo.

```
COLLECT DIFF → CLASSIFY FINDINGS → REPORT → (opcional) SUGGEST FIXES
```

## Filosofia

**Você é um revisor, não um autor.**

- Critique código, não pessoas
- Seja específico (`file:linha`)
- Reconheça o que está bom (não só o ruim)
- Calibre a severidade (reserve CRITICAL para o que realmente é)
- Não modifique nada (a menos que o usuário peça explicitamente)

## Quando usar

- Antes de um commit/PR
- Após feature grande ser implementada
- Auditar código legado
- Segunda opinião sobre mudança

## Quem executa

- O subagent `@reviewer` é especializado nisso
- O command `/review` invoca esse workflow

---

## Fase 1: COLLECT DIFF

**Objetivo:** obter o material a revisar.

### Fontes

| Fonte | Comando |
|---|---|
| Último commit | `git diff HEAD~1` ou `git show HEAD` |
| Staged (não commitado) | `git diff --staged` |
| Working tree (não staged) | `git diff` |
| Branch vs main | `git diff main...HEAD` |
| Arquivo específico (passado como argumento) | ler diretamente |
| PR específico | `gh pr diff <n>` |

### Sem git?

Se não há repositório git, use a fonte passada como argumento ou os arquivos do working tree.

### Contexto adicional

Colete se relevante:
- Testes relacionados
- Callers (quem usa isso?)
- Histórico (`git log -- caminho/arquivo`)

---

## Fase 2: CLASSIFY FINDINGS

**Objetivo:** categorizar cada achado.

### Categorias de severidade

#### CRITICAL
- Vulnerabilidade de segurança explorável (injection, XSS, CSRF, auth bypass, deserialization)
- Corrupção de dados
- Breaking change sério não documentado
- Vazamento de credenciais/secrets
- SQL/NoSQL injection
- Command injection

#### HIGH
- Bug funcional
- Validação crítica faltando
- Violação arquitetural séria
- Race condition / deadlock / TOCTOU
- Memory leak óbvio
- Falta de tratamento de erro em operação destrutiva
- Logging silencioso de erro crítico

#### MEDIUM
- Edge case não tratado
- Teste faltando para código novo
- Acoplamento desnecessário
- Tratamento de erro inadequado (mas não destrutivo)
- Performance ruim óbvia (N+1, sem índice, sem cache)
- N+1 queries em código novo
- Falta de transação onde deveria ter

#### LOW
- Melhoria de estilo
- Naming inconsistente
- Comentário faltando ou obsoleto
- Otimização prematura
- Sugestão de refatoração
- Magic number que poderia ser constante

### Checklist mental durante a revisão

```markdown
## Segurança
- [ ] Input validation
- [ ] Output encoding
- [ ] Authentication checks
- [ ] Authorization checks
- [ ] Secrets handling
- [ ] SQL/NoSQL/Command injection
- [ ] CSRF protection (se aplicável)
- [ ] Rate limiting (se aplicável)

## Funcionalidade
- [ ] Lógica correta
- [ ] Edge cases tratados
- [ ] Condições de erro cobertas
- [ ] Estados intermediários consistentes

## Performance
- [ ] Sem N+1 óbvio
- [ ] Queries indexadas
- [ ] Sem loop infinito
- [ ] Sem I/O desnecessário

## Manutenibilidade
- [ ] Nomes claros
- [ ] Funções com responsabilidade única
- [ ] Sem código duplicado
- [ ] Sem comentário obsoleto
- [ ] Sem dead code

## Testes
- [ ] Testes para código novo existem
- [ ] Casos de erro cobertos
- [ ] Não há testes pulados (.skip sem justificativa)

## Operacional
- [ ] Sem mudança fora do escopo
- [ ] Sem drive-by fix
- [ ] Mensagens de commit claras
- [ ] Sem arquivo temporário esquecido
```

---

## Fase 3: REPORT

**Objetivo:** entregar achados estruturados.

### Formato obrigatório

```markdown
## Code Review: [título/descrição do que está sendo revisado]

### Resumo
[1-3 frases sobre o escopo da revisão]

### CRITICAL (N)
- `arquivo:linha` — descrição do problema
  - Por que é crítico: [...]
  - Sugestão: [como corrigir]

### HIGH (N)
- `arquivo:linha` — ...
  - Sugestão: ...

### MEDIUM (N)
- `arquivo:linha` — ...

### LOW (N)
- `arquivo:linha` — ...

### Pontos positivos
- [...]
- [...]

### Verificações automáticas
- [ ] Testes adicionados/atualizados
- [ ] Sem segredos commitados
- [ ] Sem mudança fora do escopo
- [ ] Mensagens de commit claras
- [ ] Performance aceitável
- [ ] Logs adequados para debug futuro

### Veredicto
- ✅ Aprovar
- ⚠️ Aprovar com mudanças sugeridas
- ❌ Bloquear até correções críticas/altas
```

### Tom

- Específico, não vago
- Construtivo, não destrutivo
- Educado, não condescendente
- Direto, não prolixo

---

## Fase 4: SUGGEST FIXES (opcional)

**Objetivo:** oferecer correções concretas.

### Como oferecer

Após o report, pergunte:

> "Quer que eu mostre o diff sugerido para os achados CRITICAL e HIGH?"

Ou, se o usuário já tinha pedido:

> Aplique a formatação:

```diff
- return $user->save();
+ return DB::transaction(function () use ($user) {
+     return $user->save();
+ });
```

### Quando aplicar diretamente

**Nunca por padrão.** Só se o usuário disser explicitamente:
- "Aplique os fixes"
- "Corrija os CRITICAL e HIGH"

---

## Anti-padrões

- ❌ Inflar severidades (CRITICAL para qualquer coisa)
- ❌ Listar achados sem `file:linha`
- ❌ Sugerir mudanças puramente estilísticas como HIGH
- ❌ Inventar problemas que não existem
- ❌ Criticar a pessoa ("você deveria saber...")
- ❌ Fazer suposições sobre intenção sem perguntar
- ❌ Modificar código durante o review

## Calibração de severidade (guia rápido)

| Situação | Severidade |
|---|---|
| `eval($_GET['x'])` | CRITICAL |
| `password_hash` não usado onde devia | HIGH |
| Falta teste para função nova simples | MEDIUM |
| `==` em vez de `===` em comparação de id | MEDIUM |
| Variável pouco descritiva | LOW |
| Comentário explicando código óbvio | LOW |
| Falta `readonly` em classe imutável | LOW |
| N+1 em endpoint crítico | HIGH |
| N+1 em admin que roda 1x/dia | MEDIUM |
| Bloco try/catch genérico sem logging | MEDIUM |
| Bloco try/catch vazio silenciando erro crítico | HIGH |

---

## Quando terminar a revisão

Se você:
- Não tem mais nada a adicionar após 1 releitura → termine
- Está adicionando LOW redundantes → pare
- Está inventando problemas → pare

**Menos é mais.** Um review focado em CRITICAL/HIGH reais é mais útil que um com 50 Lows.