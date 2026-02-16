-- Migration: Fix Supabase Security Vulnerabilities
-- Date: 2026-02-10

-- ==========================================
-- 1. Fix SECURITY DEFINER views
-- ==========================================

-- Fix public.leaderboard
-- Dropping and recreating as SECURITY INVOKER (default)
DROP VIEW IF EXISTS public.leaderboard;
CREATE VIEW public.leaderboard AS
  SELECT u.id, u.name, u.image_url, COALESCE(w.xp_balance, 0) as xp
  FROM public.users_profile u
  LEFT JOIN public.xp_wallet w ON u.id = w.user_id
  ORDER BY xp DESC;

-- Fix public.chat_session_analytics
-- Dropping and recreating as SECURITY INVOKER (default)
DROP VIEW IF EXISTS public.chat_session_analytics;
CREATE VIEW public.chat_session_analytics AS
  SELECT 
    user_id,
    count(*) as total_sessions,
    sum(duration_seconds) as total_duration_seconds,
    sum(user_message_count) as total_user_messages,
    sum(ai_message_count) as total_ai_messages,
    sum(voice_messages_count) as total_voice_messages,
    sum(text_messages_count) as total_text_messages
  FROM public.chat_sessions
  GROUP BY user_id;

-- ==========================================
-- 2. Enable RLS and Create Policies
-- ==========================================

-- Helper function to check if a table's user_id or firebase_uid matches auth.uid()
-- Note: Some tables use 'user_id' (uuid) others use 'firebase_uid' (text)

-- STORE_ITEMS (Public Read)
ALTER TABLE public.store_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access for store_items" ON public.store_items;
CREATE POLICY "Allow public read access for store_items" ON public.store_items FOR SELECT USING (true);

-- APP_SETTINGS (Public Read)
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access for app_settings" ON public.app_settings;
CREATE POLICY "Allow public read access for app_settings" ON public.app_settings FOR SELECT USING (true);

-- USERS_PROFILE
ALTER TABLE public.users_profile ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users_profile;
CREATE POLICY "Users can view their own profile" ON public.users_profile FOR SELECT USING (auth.uid()::text = firebase_uid);
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users_profile;
CREATE POLICY "Users can update their own profile" ON public.users_profile FOR UPDATE USING (auth.uid()::text = firebase_uid);
DROP POLICY IF EXISTS "Service role can do everything on users_profile" ON public.users_profile;
CREATE POLICY "Service role can do everything on users_profile" ON public.users_profile TO service_role USING (true) WITH CHECK (true);

-- XP_WALLET
ALTER TABLE public.xp_wallet ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own wallet" ON public.xp_wallet;
CREATE POLICY "Users can view their own wallet" ON public.xp_wallet FOR SELECT USING (
  user_id IN (SELECT id FROM public.users_profile WHERE firebase_uid = auth.uid()::text)
);
DROP POLICY IF EXISTS "Service role can update wallet" ON public.xp_wallet;
CREATE POLICY "Service role can update wallet" ON public.xp_wallet TO service_role USING (true) WITH CHECK (true);

-- WEEKLY_PLANS
ALTER TABLE public.weekly_plans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own plans" ON public.weekly_plans;
CREATE POLICY "Users can view their own plans" ON public.weekly_plans FOR SELECT USING (
  user_id IN (SELECT id FROM public.users_profile WHERE firebase_uid = auth.uid()::text)
);
DROP POLICY IF EXISTS "Service role can manage plans" ON public.weekly_plans;
CREATE POLICY "Service role can manage plans" ON public.weekly_plans TO service_role USING (true) WITH CHECK (true);

-- DAILY_TASKS
ALTER TABLE public.daily_tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own tasks" ON public.daily_tasks;
CREATE POLICY "Users can view their own tasks" ON public.daily_tasks FOR SELECT USING (
  user_id IN (SELECT id FROM public.users_profile WHERE firebase_uid = auth.uid()::text)
);
DROP POLICY IF EXISTS "Users can update their own tasks" ON public.daily_tasks;
CREATE POLICY "Users can update their own tasks" ON public.daily_tasks FOR UPDATE USING (
  user_id IN (SELECT id FROM public.users_profile WHERE firebase_uid = auth.uid()::text)
);
DROP POLICY IF EXISTS "Service role can manage tasks" ON public.daily_tasks;
CREATE POLICY "Service role can manage tasks" ON public.daily_tasks TO service_role USING (true) WITH CHECK (true);

-- QUIZZES
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own quizzes" ON public.quizzes;
CREATE POLICY "Users can view their own quizzes" ON public.quizzes FOR SELECT USING (
  user_id IN (SELECT id FROM public.users_profile WHERE firebase_uid = auth.uid()::text)
);
DROP POLICY IF EXISTS "Users can insert their own quizzes" ON public.quizzes;
CREATE POLICY "Users can insert their own quizzes" ON public.quizzes FOR INSERT WITH CHECK (
  user_id IN (SELECT id FROM public.users_profile WHERE firebase_uid = auth.uid()::text)
);

-- CONVERSATIONS
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own conversations" ON public.conversations;
CREATE POLICY "Users can view their own conversations" ON public.conversations FOR SELECT USING (
  user_id = auth.uid()
);
DROP POLICY IF EXISTS "Users can manage their own conversations" ON public.conversations;
CREATE POLICY "Users can manage their own conversations" ON public.conversations FOR ALL USING (
  user_id = auth.uid()
);

-- XP_TRANSACTIONS
ALTER TABLE public.xp_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own transactions" ON public.xp_transactions;
CREATE POLICY "Users can view their own transactions" ON public.xp_transactions FOR SELECT USING (
  user_id IN (SELECT id FROM public.users_profile WHERE firebase_uid = auth.uid()::text)
);

-- SUBSCRIPTIONS
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can view their own subscriptions" ON public.subscriptions FOR SELECT USING (
  user_id = auth.uid()
);

-- FLASHCARDS
ALTER TABLE public.flashcards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own flashcards" ON public.flashcards;
CREATE POLICY "Users can manage their own flashcards" ON public.flashcards FOR ALL USING (
  user_id = auth.uid()::text
);

-- LEARNING_PROGRESS
ALTER TABLE public.learning_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own progress" ON public.learning_progress;
CREATE POLICY "Users can view their own progress" ON public.learning_progress FOR SELECT USING (
  user_id = auth.uid()::text
);

-- ERROR_MEMORY
ALTER TABLE public.error_memory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own errors" ON public.error_memory;
CREATE POLICY "Users can view their own errors" ON public.error_memory FOR SELECT USING (
  user_id = auth.uid()::text
);
