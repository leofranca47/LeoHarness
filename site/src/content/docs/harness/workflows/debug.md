---
title: "Workflow: DEBUG"
---
# Workflow: DEBUG

Investigação sistemática de sintoma vago ou causa desconhecida.

```
GATHER EVIDENCE → IDENTIFY HYPOTHESES → RANK HYPOTHESES → TEST HYPOTHESES → IDENTIFY ROOT CAUSE → PROPOSE/IMPLEMENT FIX → VALIDATE
```

## Filosofia

**Você é um cientista.** Hipóteses precisam ser testadas. Suposições precisam ser marcadas.

Diferencie sempre:

| Tipo | Significado | Confiança |
|---|---|---|
| **EVIDÊNCIA** | Fato observável | Alta |
| **HIPÓTESE** | Explicação possível | Média |
| **VERIFICADO** | Hipótese confirmada | Alta |
| **SUPOSIÇÃO** | Crença sem evidência | Baixa |

## Quando usar

- Sintoma intermitente
- Não consegue reproduzir consistentemente
- Múltiplas causas possíveis
- "Alguma coisa está errada" sem mais detalhe
- Após tentativa de fix ter falhado

## Quando NÃO usar

- Você consegue reproduzir e tem causa plausível → `/bug`
- Não é bug, é feature → `/feature`
- Não é bug, é dúvida conceitual → `@investigator`

---

## Fase 1: GATHER EVIDENCE

**Objetivo:** coletar fatos sem filtrar.

### O que coletar

- Mensagens de erro (com stack trace completo)
- Logs relevantes (horário, severidade, contexto)
- Estado do sistema antes/durante/depois
- Comportamento esperado vs observado
- Dados de entrada (se houver)
- Configuração de ambiente (variáveis, versões)
- Comportamento em diferentes condições (horário, carga, usuário)

### Fontes comuns

```bash
# Logs
tail -n 500 storage/logs/laravel.log | grep -A 5 "ERROR"

# Stack traces
grep -r "Stack trace" storage/logs/ | head

# Métricas de sistema
top, free -h, df -h, iostat

# Network (se aplicável)
netstat -tlnp, ss -tlnp

# Processos
ps auxf | grep -i <service>

# Estado de banco
SHOW PROCESSLIST; SHOW ENGINE INNODB STATUS;
```

### Organize

```markdown
## Evidências

### E1. [descrição do fato]
- Fonte: [arquivo:linha / comando / log]
- Timestamp: [quando]
- Detalhes: [...]

### E2. ...
```

---

## Fase 2: IDENTIFY HYPOTHESES

**Objetivo:** listar explicações possíveis (3-5).

### Brainstorm guiado

Pergunte a si mesmo:

- "O que tem que ser verdade para esse sintoma ocorrer?"
- "Que camada/componente pode falhar para produzir isso?"
- "Há mudanças recentes nessa área?"
- "Isso acontece em condições específicas?"
- "Há padrões conhecidos (N+1, race, leak) que produzem isso?"

### Liste

```markdown
## Hipóteses

### H1. [descrição]
- Plausibilidade: alta/média/baixa
- Como testar: [...]

### H2. ...
```

**Não descarte hipóteses "óbvias"** sem testar. Às vezes o óbvio está certo.

---

## Fase 3: RANK HYPOTHESES

**Objetivo:** ordenar por probabilidade.

### Critérios

| Critério | Peso |
|---|---|
| Consistência com evidência | Alto |
| Plausibilidade técnica | Alto |
| Facilidade de refutar | Médio |
| Histórico do projeto (algo parecido aconteceu antes?) | Médio |

### Ordem de teste

Comece pela mais provável **E** pela mais fácil de testar/refutar.

---

## Fase 4: TEST HYPOTHESES

**Objetivo:** refutar (não confirmar) cada hipótese.

### Por que refutar é melhor

Se você procurar só confirmações, vai encontrar ruído. Refutar força clareza.

### Para cada hipótese

```markdown
### [H1] test

**Teste:** [o que você fez — comando, leitura de código, etc.]
**Resultado:** refutada | confirmada | inconclusiva
**Evidência:** [log, output, observação]
```

### Se inconclusiva

Faça teste mais específico. Se ainda assim, anote e siga para próxima hipótese.

---

## Fase 5: IDENTIFY ROOT CAUSE

**Objetivo:** declarar a causa raiz com evidência.

### Quando você tem a causa raiz

- Ela é consistente com TODA a evidência
- Refutá-la elimina o sintoma (em teste ou raciocínio)
- É específica (não "alguma coisa no servidor")

### Declare

```markdown
## Causa raiz

**Hipótese confirmada:** H2
**Descrição:** [1 frase]
**Evidência:**
- [fato 1]
- [fato 2]
**Verificação adicional:** [como você confirmou]
```

### Se NENHUMA hipótese sobreviveu

Volte à Fase 2. Colete mais evidência. Reformule hipóteses. **Não force uma resposta.**

---

## Fase 6: PROPOSE/IMPLEMENT FIX

**Objetivo:** propor ou aplicar o fix.

### Primeiro: propor

Mesmo se "/debug" foi chamado, normalmente o usuário quer entender antes de consertar. Apresente:

```markdown
## Fix proposto

**Mudança:** [descrição mínima]
**Arquivo:** `caminho/linha`
**Risco:** baixo/médio/alto
**Alternativas:** [se houver]
```

Aguarde aprovação se for além de trivial.

### Segundo: implementar (se aprovado)

**Transição para TDD:** uma vez que a causa raiz foi identificada e o fix é necessário, faça a transição explícita para o ciclo RED → GREEN antes de aplicar a correção:

1. **Carregue `@harness/workflows/tdd.md`** para o ciclo completo
2. **RED:** crie um teste que reproduza o bug — verifique que falha pelo motivo esperado
3. **GREEN:** aplique o fix mínimo
4. **VALIDATE:** o teste de regressão agora passa; nada mais quebrou

Não force TDD se o status for `TDD_UNAVAILABLE` e o ambiente não suportar — nesse caso, documente o teste manual e prossiga com fix + smoke test.

---

## Fase 7: VALIDATE

**Objetivo:** confirmar resolução.

- O sintoma desapareceu
- Logs não mostram mais o erro
- Teste de regressão (se criado) passa
- Outros testes continuam passando

---

## Relatório final

```markdown
## Debug: [título do sintoma]

### Sintoma
[1 linha]

### Evidências coletadas
- [lista de E1, E2, ...]

### Hipóteses testadas
- [H1] → resultado — evidência
- [H2] → resultado — evidência
- [H3] → resultado — evidência

### Causa raiz
[1 frase com evidência]

### Fix
[descrição ou referência ao /bug]

### Validação
[comandos + resultados]

### O que NÃO fazer (anti-padrões específicos)
- [lição específica deste caso]
```

---

## Anti-padrões

- ❌ Mudar código "para ver se resolve"
- ❌ Acumular mudanças experimentais sem reverter
- ❌ Apresentar suposição como verificado
- ❌ Parar na primeira hipótese plausível sem testar alternativas
- ❌ "Acho que é..." sem evidência
- ❌ Não documentar hipóteses refutadas (vai esquecer e refazer)
- ❌ Fix sem teste de regressão

## Dica: mudanças experimentais

Se precisar mudar código para testar hipótese:

1. **Documente** o estado inicial (git stash + nome)
2. **Mude o mínimo** possível
3. **Observe** resultado
4. **Reverta imediatamente** (git stash pop para restaurar se for a mudança boa; senão, drop)

**Nunca** acumule 5 mudanças experimentais. Você não vai saber qual causou o quê.