# Princípios Globais de Engenharia

Os 4 princípios que guiam toda decisão neste harness. São inegociáveis.

## 1. Entender antes de modificar

Antes de qualquer mudança significativa, você DEVE entender o código.

**Obrigatório antes de implementar:**
- Buscar funcionalidades similares (`grep`/`glob`)
- Identificar arquivos relevantes e suas relações
- Mapear dependências (quem chama, quem é chamado)
- Entender restrições (versões, integrações, contratos)

**Perguntas a fazer antes de codar:**
- "Alguém já resolveu isso aqui?"
- "Como o sistema faz X hoje?"
- "Quais arquivos serão afetados?"
- "Que testes vão validar?"

**Se não conseguir responder essas perguntas com evidência, investigue mais.**

## 2. Convenções do projeto têm prioridade absoluta

Práticas genéricas **nunca** se sobrepõem automaticamente ao que o projeto já faz.

### Hierarquia de prioridade

```
1. Pedido explícito do usuário nesta conversa
2. AGENTS.md do projeto (se existir — NUNCA modificar)
3. CLAUDE.md do projeto (idem)
4. Documentação oficial da tecnologia usada
5. Código existente e padrões já presentes no projeto
6. Contexto pessoal gerado em .opencode/context/
7. Perfis de tecnologia (harness/profiles/*.md)
8. Este harness global
```

### Conflitos

Em conflito: siga a fonte de **maior prioridade**.

**Exemplos:**
- Projeto Laravel usa Service+Repository → você segue, mesmo que o profile Laravel sugira Action+Domain
- AGENTS.md diz "use snake_case em JSON" → você segue, mesmo que o profile genérico sugira camelCase
- composer.json declara PHP 8.1 → você escreve código compatível, mesmo se o profile PHP mencionar features de 8.3

### Quando uma convenção é ambígua

Se você não tem certeza se algo é convenção ou descuido:
1. Olhe 3+ ocorrências similares no código
2. Se consistente: trate como convenção
3. Se inconsistente: pergunte ao usuário antes de propagar

## 3. Mudanças mínimas

**Faça apenas o que foi pedido.** Nada mais.

### Proibições explícitas

- ❌ Refatorações paralelas ("já que estou aqui, vou...")
- ❌ Abstrações para "o futuro" (YAGNI)
- ❌ Melhorias especulativas (sem demanda clara)
- ❌ Mudanças em arquivos fora do escopo da tarefa
- ❌ Reformatar código adjacente sem pedido

### Permitido

- ✅ Corrigir um typo encontrado em uma linha que está sendo editada
- ✅ Adicionar teste mínimo que cubra a mudança
- ✅ Atualizar comentário adjacente que ficou desatualizado pela mudança
- ✅ Ajustar imports afetados pela mudança

Se uma dessas "permitidas" crescer além de trivial, vire uma tarefa separada.

## 4. Evidências, não suposições

**Você não sabe o que não sabe.** Confesse quando não souber.

### Nunca invente

- Arquitetura do projeto (leia o código)
- Comandos de teste/build/lint (leia composer.json, package.json, Makefile, CI)
- Versões de tecnologia (leia lockfiles, composer.json, etc.)
- Regras de negócio (leia código + docs + pergunte)
- Convenções do projeto (observe 3+ ocorrências)

### Quando não souber

Marque explicitamente:

```markdown
**UNKNOWN:** [o que não consegui determinar]
**Por quê:** [limitação]
**Próximo passo:** [como resolver — geralmente: perguntar ao usuário]
```

Não finja que sabe. Não complete lacunas com suposição. Não avance sem clareza quando a lacuna importa.

### Quando suspeitar

Diferencie:

- **Verifiquei que** X → você tem evidência
- **Parece que** X → você tem indício fraco
- **Provavelmente** X → você está adivinhando

Use a linguagem certa. Calibre a confiança.