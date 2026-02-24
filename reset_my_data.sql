-- ============================================================================
-- RESET YOUR USER DATA - Execute this in Supabase SQL Editor
-- ============================================================================
-- This will clean all your adaptive plan data and allow fresh generation

-- STEP 1: Find your user_id
-- Run this first to get your user_id:
-- SELECT id, name, email FROM public.users_profile WHERE email = 'your-email@example.com';

-- STEP 2: Replace 'YOUR_USER_ID_HERE' with your actual user_id and run:
SELECT reset_user_adaptive_data('f15a8df7-9801-4ccb-8005-49e89255fd87'::UUID);

-- This will:
-- ✅ Delete all your daily_tasks
-- ✅ Delete all your weekly_plans
-- ✅ Delete all your weekly_skill_snapshots
-- ✅ Reset your skill_profile scores to 0 (will trigger new evaluation)

-- After running this:
-- 1. Close and reopen the app
-- 2. Do the Initial Assessment speaking task
-- 3. System will create your skill profile
-- 4. System will generate a new weekly plan with speaking tasks
