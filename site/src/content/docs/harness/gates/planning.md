---
title: "Gate: PLANNING"
---
Estrutura esperada do plano antes de implementar mudanças não-triviais.

## Quando apresentar plano formal

| Complexidade | Como apresentar |
|---|---|
| Trivial (1-2 linhas) | Pule o plano, vá direto |
| Pequena (1-2 arquivos, claro) | Plano inline curto (3-5 linhas) |
| Média (3-5 arquivos) | Plano em markdown, mas conciso |
| Grande (5+ arquivos) | Plano formal com aprovação |

## Estrutura do plano (para tarefas médias/grandes)

```markdown
# Plano: [título curto e descritivo]

## Objetivo
[1-2 frases explicando o que será entregue]

## Motivação
[Por que isso é necessário? — link para issue/task, contexto]

## Arquivos esperados

### Criar
- `caminho/novo/arquivo.php` — [responsabilidade]

### Modificar
- `caminho/existente/arquivo.php` — [o que muda e por quê]

### Remover (raramente)
- `caminho/sera/removido.php` — [motivo,替代]

## Passos ordenados

1. [ ] Passo 1 — [descrição curta]
   - Validação intermediária: [como saber se deu certo]
2. [ ] Passo 2 — [...]
3. [ ] Passo 3 — [...]
4. ...

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| [...] | alta/média/baixa | alto/médio/baixo | [...] |

## Dependências externas

- [APIs externas, serviços, migrations que afetam outros]

## Compatibilidade

- [Breaking changes? Versionamento? Backward compat?]

## Como validar

- [comando/teste 1] — esperado: [...]
- [comando/teste 2] — esperado: [...]

## Estratégia de rollback

- [Como reverter se algo der errado]

## Pontos em aberto

- [Decisões que precisam de input do usuário]
- [Áreas cinzentas]
```

## Checklist antes de apresentar

- [ ] Todas as decisões foram tomadas? (ou estão listadas como "abertas"?)
- [ ] Passos estão em ordem lógica?
- [ ] Cada passo tem critério de validação?
- [ ] Riscos foram pensados?
- [ ] Compatibilidade considerada?
- [ ] Plano pode ser executado por outra pessoa (não só você)?

## Como apresentar ao usuário

```markdown
Vou implementar [X]. Plano:

**Arquivos:**
- Criar: A, B
- Modificar: C, D

**Passos:**
1. ...
2. ...

**Riscos principais:**
- [risco]

**Validação:**
- [comando]

Posso prosseguir? (Responda com s/N ou ajustes)
```

## Princípios do plano

- **Curto:** o plano é uma referência, não um documento
- **Claro:** sem ambiguidade sobre o que vai ser feito
- **Validável:** cada passo tem critério de "feito"
- **Reversível:** sempre tem estratégia de rollback
- **Conversador:** se algo é incerto, declare — não finja certeza

## O que NÃO incluir

- ❌ Código completo (mostre no IMPLEMENT, não no PLAN)
- ❌ Pseudo-código detalhado
- ❌ Decisões que podem mudar
- ❌ Listas de "considerações" genéricas

## Quando atualizar o plano

- Se durante IMPLEMENT algo diverge do plano → atualize o plano e notifique
- Se descobre um novo risco → mencione
- Se um passo não pode ser completado → explique por quê e proponha alternativa

**Não esconda desvio do plano.** Transparência > aparência.