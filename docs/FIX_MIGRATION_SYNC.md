# 🔧 Fix: Sincronização de Migrações Supabase

## Problema
Inconsistência entre migrações locais e remotas causando erro ao fazer `supabase db push` ou `supabase db pull`.

## Solução Rápida

### Opção 1: Aplicar via Supabase Dashboard (Recomendado)

Como as migrações já foram aplicadas com sucesso (`supabase db push` funcionou), a melhor abordagem é sincronizar o histórico:

```bash
cd learn_english_application/learn_english_admin

# 1. Marcar migrações como aplicadas no histórico
supabase migration repair --status applied 20260219000001
supabase migration repair --status applied 202602191200
supabase migration repair --status applied 202602191500
supabase migration repair --status applied 20260223
```

Se houver erro de chave duplicada, significa que a migração já está no banco. Nesse caso:

```bash
# Reverter e reaplicar
supabase migration repair --status reverted 20260219
supabase migration repair --status applied 20260219000001
```

### Opção 2: Aplicar SQL Diretamente no Dashboard

Se os comandos acima não funcionarem, você pode aplicar o SQL diretamente:

1. Acesse o Supabase Dashboard
2. Vá em **Database** > **SQL Editor**
3. Copie o conteúdo de `supabase/migrations/20260223_adaptive_weekly_plan_phase1.sql`
4. Execute no SQL Editor

### Opção 3: Reset Completo (Última Opção)

⚠️ **CUIDADO:** Isso vai resetar o banco de dados local.

```bash
# Fazer backup primeiro
supabase db dump -f backup.sql

# Reset local
supabase db reset

# Puxar do remoto
supabase db pull
```

## Verificar Status

```bash
# Ver lista de migrações
supabase migration list

# Deve mostrar algo como:
#   Local          | Remote         | Time (UTC)          
#  ----------------|----------------|---------------------
#   20260223       | 20260223       | 20260223
```

## Testar se Tabelas Foram Criadas

Execute no SQL Editor do Supabase Dashboard:

```sql
-- Verificar se tabelas existem
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('user_skill_profile', 'weekly_skill_snapshot');

-- Deve retornar 2 linhas

-- Verificar colunas adicionadas
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'weekly_plans' 
AND column_name IN ('primary_focus', 'secondary_focus', 'status');

-- Deve retornar 3 linhas

-- Verificar trigger
SELECT trigger_name 
FROM information_schema.triggers 
WHERE trigger_name = 'on_speaking_submission_update_profile';

-- Deve retornar 1 linha
```

## Status Atual

✅ **Migrações aplicadas com sucesso!**

As seguintes migrações foram aplicadas no banco remoto:
- `20260219_add_speaking_score.sql` ✅
- `20260223_adaptive_weekly_plan_phase1.sql` ✅

O que foi criado:
- ✅ Tabela `user_skill_profile`
- ✅ Tabela `weekly_skill_snapshot`
- ✅ Colunas adicionadas em `weekly_plans`
- ✅ Colunas adicionadas em `daily_tasks`
- ✅ Trigger `update_skill_profile_from_speaking()`
- ✅ Funções helper

## Próximos Passos

Agora que as tabelas estão criadas, você pode:

1. **Testar o trigger** (ver `ADAPTIVE_PLAN_NEXT_STEPS.md`)
2. **Deploy das Edge Functions**
3. **Configurar Cron Job**

## Comandos Úteis

```bash
# Ver status das migrações
supabase migration list

# Ver diferenças entre local e remoto
supabase db diff

# Criar nova migração
supabase migration new nome_da_migracao

# Aplicar migrações pendentes
supabase db push

# Puxar schema do remoto
supabase db pull
```

## Troubleshooting

### Erro: "duplicate key value violates unique constraint"
Significa que a migração já existe no banco. Use:
```bash
supabase migration repair --status reverted TIMESTAMP
```

### Erro: "migration history does not match"
Sincronize o histórico:
```bash
supabase migration list  # Ver diferenças
supabase migration repair --status applied TIMESTAMP  # Para cada migração local
```

### Arquivo `check_rls.sql` causando erro
Remova ou renomeie:
```bash
rm supabase/migrations/check_rls.sql
# OU
mv supabase/migrations/check_rls.sql supabase/migrations/20260224000000_check_rls.sql
```

---

**Última atualização:** 2026-02-23  
**Status:** Migrações aplicadas com sucesso ✅
