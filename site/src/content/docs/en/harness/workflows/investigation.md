---
title: "Workflow: INVESTIGATION"
translation-status: pending
translation-source: pt-BR
---
# Workflow: INVESTIGATION

Exploração de código desconhecido para responder perguntas ou mapear terreno.

```
DEFINE QUESTION → SEARCH → READ → MAP → REPORT
```

## Quando usar

- "Como o sistema faz X?"
- "Onde fica Y?"
- "Quem chama Z?"
- Antes de implementar em área desconhecida
- Para validar hipótese ("já existe algo assim?")

## Quem executa

- O subagent `@investigator` é especializado nisso
- O command `/init-project` usa princípios similares
- Qualquer agente/command pode executar investigação como subfase

---

## Fase 1: DEFINE QUESTION

**Objetivo:** esclarecer exatamente o que precisa ser respondido.

### Boa pergunta

```
"Específico: onde a função `calculateShipping` é chamada?"
"Aberto: como o sistema processa pedidos?"
"Comparativo: como diferentes controllers lidam com erros?"
```

### Pergunta ruim

```
"O que esse código faz?" (genérica demais)
"Como funciona o sistema?" (vago demais)
```

### Saída

Pergunta refinada + critérios de "respondido".

---

## Fase 2: SEARCH

**Objetivo:** encontrar candidatos.

### Estratégias

```bash
# Por nome (mais rápido)
grep -r "NomeExato" --include="*.php" --include="*.ts"

# Por padrão (mais lento, mais cobertura)
grep -rn "interface \w*Repository" --include="*.php"

# Por estrutura
find . -path "*/Repositories/*" -name "*.php"

# Por conteúdo adjacente
grep -rl "calcular frete" --include="*.php"
```

### Resultados esperados

- Lista de arquivos candidatos
- Confirmação se algo existe ou não

---

## Fase 3: READ

**Objetivo:** entender o que cada candidato faz.

### Disciplina

- **Leia o suficiente** para entender a responsabilidade
- **Não leia tudo** se não precisa
- **Triangule** (3+ fontes se a primeira for ambígua)
- **Tire notas** do que importa

### Para cada candidato

```markdown
## `caminho/arquivo:linha`

**Responsabilidade:** [...]
**Padrão usado:** Service | Controller | Action | Helper | ...
**Como é chamado:** [...]
**Notas:** [...]
```

---

## Fase 4: MAP

**Objetivo:** montar visão geral a partir dos pedaços.

### Tipos de mapa

#### Mapa de chamadas (callers/callees)

```
Para a função X:
- Chamada por: A (linha 42), B (linha 18), C (linha 91)
- Chama: Y (linha 33), Z (linha 47)
- Risco de mudança: médio (3 callers internos)
```

#### Mapa de fluxo

```
Request → Middleware → Controller X → Service Y → Repository Z → DB
                                  ↓
                                Event Listener (async)
```

#### Mapa de convenções

```
Controllers neste projeto:
- Estilo: Single Action (apenas __invoke) vs CRUD completo
- Resposta: API Resource vs array direto
- Validação: FormRequest vs inline
- Erros: Handler custom vs padrão Laravel
```

---

## Fase 5: REPORT

**Objetivo:** entregar resposta útil ao solicitante.

### Estrutura recomendada

```markdown
## Investigação: [pergunta]

### Resumo direto
[1-3 frases respondendo a pergunta]

### Onde está (com paths)
- `caminho/arquivo:linha` — [papel]
- ...

### Padrão observado
[descrição do padrão usado no projeto]

### Onde NÃO mexer
[arquivos/caminhos que devem ser evitados, com motivo]

### Onde adicionar/modificar para estender
[caminho recomendado]

### Evidência adicional
[grep usado, referências a docs, etc.]

### Pontos ambíguos
[onde não tive certeza]
```

### Tom

- Direto (não prolixo)
- Específico (paths e linhas)
- Honesto (admita quando não soube)
- Útil (sugira próximos passos)

---

## Anti-padrões

- ❌ Inventar resposta sem verificar
- ❌ Responder com base em um único trecho
- ❌ Listar 30 arquivos sem destacar o que importa
- ❌ Não distinguir evidência de inferência
- ❌ Ler 1000 linhas quando 50 respondem
- ❌ Recomendar mudanças (não é seu papel aqui — só investigar)

## Quando virar outra coisa

| Situação | Redirecionar para |
|---|---|
| Achei que vai virar mudança | Após investigar, voltar para `/feature` ou `/bug` |
| Achei causa raiz durante investigação | Após investigar, ir para `/debug` ou `/bug` |
| Achei problema de segurança crítico | Reportar imediatamente ao usuário (não investigar mais) |

A investigação é **read-only**. Quando virar escrita, é outro workflow.