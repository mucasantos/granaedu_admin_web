-- Migration: Fix Users Profile RLS to use ID instead of Firebase UID
-- Date: 2026-02-17

-- 1. USERS_PROFILE
-- Switch from checking firebase_uid to checking id (which matches auth.uid())
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users_profile;
CREATE POLICY "Users can view their own profile" ON public.users_profile FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.users_profile;
CREATE POLICY "Users can update their own profile" ON public.users_profile FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users_profile;
CREATE POLICY "Users can insert their own profile" ON public.users_profile FOR INSERT WITH CHECK (auth.uid() = id);

-- 2. DAILY_TASKS
-- Simplify policy to check user_id directly against auth.uid() (assuming user_id = auth.uid())
DROP POLICY IF EXISTS "Users can view their own tasks" ON public.daily_tasks;
CREATE POLICY "Users can view their own tasks" ON public.daily_tasks FOR SELECT USING (
  user_id = auth.uid()
);

DROP POLICY IF EXISTS "Users can update their own tasks" ON public.daily_tasks;
CREATE POLICY "Users can update their own tasks" ON public.daily_tasks FOR UPDATE USING (
  user_id = auth.uid()
);

-- 3. XP_WALLET
-- Simplify policy
DROP POLICY IF EXISTS "Users can view their own wallet" ON public.xp_wallet;
CREATE POLICY "Users can view their own wallet" ON public.xp_wallet FOR SELECT USING (
  user_id = auth.uid()
);

-- 4. WEEKLY_PLANS
-- Simplify policy
DROP POLICY IF EXISTS "Users can view their own plans" ON public.weekly_plans;
CREATE POLICY "Users can view their own plans" ON public.weekly_plans FOR SELECT USING (
  user_id = auth.uid()
);

-- 5. QUIZZES
-- Simplify policy
DROP POLICY IF EXISTS "Users can view their own quizzes" ON public.quizzes;
CREATE POLICY "Users can view their own quizzes" ON public.quizzes FOR SELECT USING (
  user_id = auth.uid()
);

DROP POLICY IF EXISTS "Users can insert their own quizzes" ON public.quizzes;
CREATE POLICY "Users can insert their own quizzes" ON public.quizzes FOR INSERT WITH CHECK (
  user_id = auth.uid()
);

-- 6. XP_TRANSACTIONS
DROP POLICY IF EXISTS "Users can view their own transactions" ON public.xp_transactions;
CREATE POLICY "Users can view their own transactions" ON public.xp_transactions FOR SELECT USING (
  user_id = auth.uid()
);
