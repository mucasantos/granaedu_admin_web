-- Migration: Fix Leaderboard View
-- Created: 2026-02-24
-- Description: Add missing columns to leaderboard view (streak, coins, hearts)

-- ============================================================================
-- 1. DROP AND RECREATE LEADERBOARD VIEW WITH ALL COLUMNS
-- ============================================================================

DROP VIEW IF EXISTS public.leaderboard;

CREATE VIEW public.leaderboard WITH (security_invoker = true) AS
  SELECT 
    u.id,
    u.name,
    u.image_url,
    COALESCE(w.xp_balance, 0) as xp,
    COALESCE(w.streak, 0) as streak,
    COALESCE(w.coins, 0) as coins,
    COALESCE(w.hearts, 5) as hearts,
    w.last_heart_refill
  FROM public.users_profile u
  LEFT JOIN public.xp_wallet w ON u.id = w.user_id
  ORDER BY xp DESC;

-- ============================================================================
-- 2. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT ON public.leaderboard TO authenticated;
GRANT SELECT ON public.leaderboard TO anon;

-- ============================================================================
-- 3. VERIFY VIEW
-- ============================================================================

-- Test query (comment out after verification)
-- SELECT * FROM public.leaderboard LIMIT 5;

-- ============================================================================
-- NOTES
-- ============================================================================

-- This view now includes:
-- - id: user ID
-- - name: user name
-- - image_url: user avatar
-- - xp: XP balance (defaults to 0 if no wallet)
-- - streak: current streak (defaults to 0 if no wallet)
-- - coins: coin balance (defaults to 0 if no wallet)
-- - hearts: hearts balance (defaults to 5 if no wallet)
-- - last_heart_refill: timestamp of last heart refill

-- The view uses COALESCE to handle users without xp_wallet entries
-- Results are ordered by XP in descending order
