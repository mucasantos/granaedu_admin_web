# 🔒 Adicionar Constraint UNIQUE - Guia de Execução

## Objetivo
Prevenir duplicatas de planos semanais para o mesmo usuário na mesma data.

## O Que Foi Feito

### 1. Edge Function Atualizada ✅
A função `ai-orchestrator` agora:
- Verifica se já existe um plano para hoje antes de criar
- Se existir, ATUALIZA o plano existente em vez de criar duplicata
- Deleta as tasks antigas e cria novas
- Deployed com sucesso

### 2. Script SQL Criado ✅
Arquivo: `add_unique_constraint.sql`

## Como Executar

### Passo 1: Abrir Supabase Dashboard
1. Acesse: https://supabase.com/dashboard
2. Selecione o projeto: `learn_english_app`
3. Vá em: **SQL Editor** (menu lateral)

### Passo 2: Executar o Script

Copie e cole o conteúdo de `add_unique_constraint.sql` no SQL Editor.

**O script faz automaticamente:**

1. **Mostra duplicatas atuais**
   ```sql
   SELECT user_id, week_start, COUNT(*) as duplicate_count...
   ```

2. **Remove tasks das duplicatas**
   ```sql
   DELETE FROM daily_tasks WHERE plan_id IN (...)
   ```

3. **Remove planos duplicados** (mantém o mais recente)
   ```sql
   DELETE FROM weekly_plans WHERE id IN (...)
   ```

4. **Adiciona constraint UNIQUE**
   ```sql
   ALTER TABLE weekly_plans 
   ADD CONSTRAINT unique_user_week_start 
   UNIQUE (user_id, week_start);
   ```

5. **Verifica que não há mais duplicatas**
   ```sql
   SELECT ... HAVING COUNT(*) > 1;
   ```

### Passo 3: Executar

1. Cole todo o conteúdo do arquivo no SQL Editor
2. Clique em **Run** (ou Ctrl/Cmd + Enter)
3. Aguarde a execução
4. Verifique os resultados

### Resultado Esperado

**Antes:**
```
user_id | week_start  | count
--------|-------------|------
abc123  | 2026-02-20  | 2     ← Duplicata!
```

**Depois:**
```
(0 rows)  ← Sem duplicatas! ✅
```

## O Que Acontece Depois?

### Comportamento Futuro

**Cenário 1: Usuário gera plano pela primeira vez hoje**
- ✅ Cria novo plano normalmente

**Cenário 2: Usuário tenta gerar plano novamente no mesmo dia**
- ✅ Atualiza o plano existente (não cria duplicata)
- ✅ Deleta tasks antigas e cria novas
- ✅ Mantém o mesmo `plan_id`

**Cenário 3: Tentativa de INSERT duplicado (caso raro)**
- ❌ Banco rejeita com erro de constraint
- ✅ Edge Function trata o erro e atualiza em vez de inserir

## Verificação

Após executar, você pode verificar:

```sql
-- Ver todos os planos do usuário
SELECT id, user_id, week_start, created_at, level
FROM weekly_plans
WHERE user_id = 'SEU_USER_ID'
ORDER BY week_start DESC;

-- Verificar constraint foi criada
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'weekly_plans'
AND constraint_name = 'unique_user_week_start';
```

## Rollback (Se Necessário)

Se precisar remover a constraint:

```sql
ALTER TABLE weekly_plans 
DROP CONSTRAINT unique_user_week_start;
```

## Troubleshooting

### Erro: "constraint already exists"
- A constraint já foi adicionada anteriormente
- Não precisa fazer nada, está tudo certo! ✅

### Erro: "violates unique constraint"
- Ainda existem duplicatas no banco
- Execute novamente os passos 2 e 3 do script
- Depois execute o passo 4 (ALTER TABLE)

### Erro: "permission denied"
- Você precisa de permissões de admin no Supabase
- Use o SQL Editor do Dashboard (não o psql local)

## Commits Realizados

- ✅ Edge Function atualizada e deployed
- ✅ Script SQL criado (`add_unique_constraint.sql`)
- ✅ Documentação criada (`EXECUTE_CONSTRAINT.md`)

## Próximos Passos

1. Execute o script SQL no Supabase Dashboard
2. Teste gerando um plano no app
3. Tente gerar novamente no mesmo dia
4. Verifique que não há duplicatas no histórico
5. Confirme que o plano foi atualizado em vez de duplicado

---

**Data de Criação:** 2026-02-20  
**Status:** Pronto para execução  
**Prioridade:** Alta (previne duplicatas futuras)
