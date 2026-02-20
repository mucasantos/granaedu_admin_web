-- Script para limpar planos antigos (anteriores a 2024)
-- Execute este script no Supabase SQL Editor do projeto correto

-- 1. Verificar quantos planos antigos existem
SELECT 
  COUNT(*) as total_old_plans,
  MIN(week_start) as oldest_plan,
  MAX(week_start) as newest_old_plan
FROM weekly_plans
WHERE week_start < '2024-01-01';

-- 2. Ver detalhes dos planos antigos (opcional)
-- SELECT id, user_id, week_start, level, created_at
-- FROM weekly_plans
-- WHERE week_start < '2024-01-01'
-- ORDER BY week_start DESC
-- LIMIT 20;

-- 3. Deletar tasks associadas aos planos antigos
-- ATENÇÃO: Descomente apenas quando tiver certeza!
-- DELETE FROM daily_tasks 
-- WHERE plan_id IN (
--   SELECT id FROM weekly_plans 
--   WHERE week_start < '2024-01-01'
-- );

-- 4. Deletar os planos antigos
-- ATENÇÃO: Descomente apenas quando tiver certeza!
-- DELETE FROM weekly_plans 
-- WHERE week_start < '2024-01-01';

-- 5. Verificar duplicatas (planos com mesma data para mesmo usuário)
SELECT 
  user_id, 
  week_start, 
  COUNT(*) as duplicate_count,
  ARRAY_AGG(id) as plan_ids,
  ARRAY_AGG(created_at) as created_dates
FROM weekly_plans
GROUP BY user_id, week_start
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 6. Para remover duplicatas, mantendo apenas o mais recente:
-- ATENÇÃO: Descomente apenas quando tiver certeza!
-- WITH duplicates AS (
--   SELECT 
--     id,
--     ROW_NUMBER() OVER (
--       PARTITION BY user_id, week_start 
--       ORDER BY created_at DESC
--     ) as rn
--   FROM weekly_plans
-- )
-- DELETE FROM daily_tasks
-- WHERE plan_id IN (
--   SELECT id FROM duplicates WHERE rn > 1
-- );

-- DELETE FROM weekly_plans
-- WHERE id IN (
--   SELECT id FROM duplicates WHERE rn > 1
-- );

-- 7. Adicionar constraint para prevenir duplicatas futuras
-- ATENÇÃO: Execute apenas uma vez!
-- ALTER TABLE weekly_plans 
-- ADD CONSTRAINT unique_user_week_start 
-- UNIQUE (user_id, week_start);
