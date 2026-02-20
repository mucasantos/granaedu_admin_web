-- Script para remover duplicatas e adicionar constraint UNIQUE
-- Execute este script no Supabase SQL Editor

-- PASSO 1: Ver as duplicatas atuais
SELECT 
  user_id, 
  week_start, 
  COUNT(*) as duplicate_count,
  ARRAY_AGG(id ORDER BY created_at DESC) as plan_ids,
  ARRAY_AGG(created_at ORDER BY created_at DESC) as created_dates
FROM weekly_plans
GROUP BY user_id, week_start
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- PASSO 2: Remover duplicatas, mantendo apenas o mais recente
-- Esta query deleta as tasks das duplicatas primeiro
WITH duplicates AS (
  SELECT 
    id,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, week_start 
      ORDER BY created_at DESC
    ) as rn
  FROM weekly_plans
)
DELETE FROM daily_tasks
WHERE plan_id IN (
  SELECT id FROM duplicates WHERE rn > 1
);

-- PASSO 3: Remover os planos duplicados (mantém o mais recente)
WITH duplicates AS (
  SELECT 
    id,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, week_start 
      ORDER BY created_at DESC
    ) as rn
  FROM weekly_plans
)
DELETE FROM weekly_plans
WHERE id IN (
  SELECT id FROM duplicates WHERE rn > 1
);

-- PASSO 4: Adicionar constraint UNIQUE para prevenir duplicatas futuras
ALTER TABLE weekly_plans 
ADD CONSTRAINT unique_user_week_start 
UNIQUE (user_id, week_start);

-- PASSO 5: Verificar que não há mais duplicatas
SELECT 
  user_id, 
  week_start, 
  COUNT(*) as count
FROM weekly_plans
GROUP BY user_id, week_start
HAVING COUNT(*) > 1;

-- Se a query acima retornar 0 linhas, está tudo certo! ✅
