-- Script de Verificação: Adaptive Weekly Plan Tables
-- Execute este script no Supabase Dashboard > SQL Editor

-- ============================================================================
-- 1. VERIFICAR TABELAS CRIADAS
-- ============================================================================

SELECT 
  'user_skill_profile' as table_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'user_skill_profile'
  ) THEN '✅ EXISTS' ELSE '❌ NOT FOUND' END as status
UNION ALL
SELECT 
  'weekly_skill_snapshot',
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'weekly_skill_snapshot'
  ) THEN '✅ EXISTS' ELSE '❌ NOT FOUND' END
;

-- ============================================================================
-- 2. VERIFICAR COLUNAS ADICIONADAS EM WEEKLY_PLANS
-- ============================================================================

SELECT 
  column_name,
  data_type,
  '✅ EXISTS' as status
FROM information_schema.columns 
WHERE table_schema = 'public'
  AND table_name = 'weekly_plans' 
  AND column_name IN ('primary_focus', 'secondary_focus', 'generated_from_snapshot', 'teacher_adjusted', 'status', 'regeneration_reason')
ORDER BY column_name;

-- ============================================================================
-- 3. VERIFICAR COLUNAS ADICIONADAS EM DAILY_TASKS
-- ============================================================================

SELECT 
  column_name,
  data_type,
  '✅ EXISTS' as status
FROM information_schema.columns 
WHERE table_schema = 'public'
  AND table_name = 'daily_tasks' 
  AND column_name IN ('task_type', 'generated_by')
ORDER BY column_name;

-- ============================================================================
-- 4. VERIFICAR TRIGGER
-- ============================================================================

SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement,
  '✅ EXISTS' as status
FROM information_schema.triggers 
WHERE trigger_name = 'on_speaking_submission_update_profile';

-- ============================================================================
-- 5. VERIFICAR FUNÇÕES
-- ============================================================================

SELECT 
  routine_name,
  routine_type,
  '✅ EXISTS' as status
FROM information_schema.routines 
WHERE routine_schema = 'public'
  AND routine_name IN (
    'update_skill_profile_from_speaking',
    'get_current_week_start',
    'calculate_fi_delta'
  )
ORDER BY routine_name;

-- ============================================================================
-- 6. VERIFICAR INDEXES
-- ============================================================================

SELECT 
  indexname,
  tablename,
  '✅ EXISTS' as status
FROM pg_indexes 
WHERE schemaname = 'public'
  AND indexname IN (
    'idx_user_skill_profile_user_id',
    'idx_user_skill_profile_fi',
    'idx_weekly_snapshot_user_week',
    'idx_weekly_plans_status',
    'idx_daily_tasks_type'
  )
ORDER BY indexname;

-- ============================================================================
-- 7. VERIFICAR RLS POLICIES
-- ============================================================================

SELECT 
  tablename,
  policyname,
  '✅ EXISTS' as status
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN ('user_skill_profile', 'weekly_skill_snapshot')
ORDER BY tablename, policyname;

-- ============================================================================
-- RESUMO FINAL
-- ============================================================================

SELECT 
  'SUMMARY' as section,
  (SELECT COUNT(*) FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN ('user_skill_profile', 'weekly_skill_snapshot')) as tables_created,
  (SELECT COUNT(*) FROM information_schema.triggers 
   WHERE trigger_name = 'on_speaking_submission_update_profile') as triggers_created,
  (SELECT COUNT(*) FROM information_schema.routines 
   WHERE routine_schema = 'public'
   AND routine_name IN ('update_skill_profile_from_speaking', 'get_current_week_start', 'calculate_fi_delta')) as functions_created;
