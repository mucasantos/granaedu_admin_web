-- Migration: Explicitly set views to SECURITY INVOKER
-- Date: 2026-02-10

-- Fix public.leaderboard
DROP VIEW IF EXISTS public.leaderboard;
CREATE VIEW public.leaderboard WITH (security_invoker = true) AS
  SELECT u.id, u.name, u.image_url, COALESCE(w.xp_balance, 0) as xp
  FROM public.users_profile u
  LEFT JOIN public.xp_wallet w ON u.id = w.user_id
  ORDER BY xp DESC;

-- Fix public.chat_session_analytics
DROP VIEW IF EXISTS public.chat_session_analytics;
CREATE VIEW public.chat_session_analytics WITH (security_invoker = true) AS
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
