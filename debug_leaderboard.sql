-- Debug: Leaderboard Issue
-- Execute este script no Supabase Dashboard > SQL Editor

-- ============================================================================
-- 1. VERIFICAR ESTRUTURA DA VIEW LEADERBOARD
-- ============================================================================

SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'leaderboard'
ORDER BY ordinal_position;

-- ============================================================================
-- 2. VERIFICAR ESTRUTURA DA TABELA XP_WALLET
-- ============================================================================

SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'xp_wallet'
ORDER BY ordinal_position;

-- ============================================================================
-- 3. TESTAR QUERY DA VIEW LEADERBOARD
-- ============================================================================

SELECT * FROM public.leaderboard LIMIT 10;

-- ============================================================================
-- 4. VERIFICAR DADOS REAIS
-- ============================================================================

SELECT 
  u.id,
  u.name,
  u.image_url,
  w.xp_balance,
  w.coins,
  w.hearts,
  w.streak
FROM public.users_profile u
LEFT JOIN public.xp_wallet w ON u.id = w.user_id
ORDER BY w.xp_balance DESC NULLS LAST
LIMIT 10;

-- ============================================================================
-- 5. VERIFICAR SE EXISTE COLUNA STREAK
-- ============================================================================

SELECT 
  column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'xp_wallet'
  AND column_name = 'streak';
