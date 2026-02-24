-- Migration: Adaptive Weekly Plan - Phase 1 (Base Structure)
-- Created: 2026-02-23
-- Description: Creates tables and triggers for conditional weekly plan regeneration

-- ============================================================================
-- 1. USER SKILL PROFILE TABLE
-- ============================================================================
-- Stores current skill assessment updated after each speaking task

CREATE TABLE IF NOT EXISTS public.user_skill_profile (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Individual skill scores (0-100)
  speaking_score FLOAT DEFAULT 0,
  grammar_score FLOAT DEFAULT 0,
  vocabulary_score FLOAT DEFAULT 0,
  fluency_score FLOAT DEFAULT 0,
  listening_score FLOAT DEFAULT 0,
  
  -- Calculated Fluency Index (weighted average)
  fluency_index FLOAT DEFAULT 0,
  
  -- Dominant skills (weakest areas to focus on)
  primary_skill VARCHAR(50), -- skill with lowest score
  secondary_skill VARCHAR(50), -- second lowest score
  
  -- Metadata
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_skill_profile_user_id ON public.user_skill_profile(user_id);
CREATE INDEX IF NOT EXISTS idx_user_skill_profile_fi ON public.user_skill_profile(fluency_index);
CREATE INDEX IF NOT EXISTS idx_user_skill_profile_primary ON public.user_skill_profile(primary_skill);

-- Enable RLS
ALTER TABLE public.user_skill_profile ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view their own skill profile" ON public.user_skill_profile;
CREATE POLICY "Users can view their own skill profile"
ON public.user_skill_profile FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role can manage all profiles" ON public.user_skill_profile;
CREATE POLICY "Service role can manage all profiles"
ON public.user_skill_profile FOR ALL
USING (true);

-- ============================================================================
-- 2. WEEKLY SKILL SNAPSHOT TABLE
-- ============================================================================
-- Captures skill state at the beginning of each week (Monday)

CREATE TABLE IF NOT EXISTS public.weekly_skill_snapshot (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start DATE NOT NULL,
  
  -- Captured state
  fluency_index FLOAT NOT NULL,
  primary_skill VARCHAR(50),
  secondary_skill VARCHAR(50),
  
  -- Snapshot of individual scores
  speaking_score FLOAT,
  grammar_score FLOAT,
  vocabulary_score FLOAT,
  fluency_score FLOAT,
  listening_score FLOAT,
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id, week_start)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_weekly_snapshot_user_week ON public.weekly_skill_snapshot(user_id, week_start);
CREATE INDEX IF NOT EXISTS idx_weekly_snapshot_week ON public.weekly_skill_snapshot(week_start);

-- Enable RLS
ALTER TABLE public.weekly_skill_snapshot ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view their own snapshots" ON public.weekly_skill_snapshot;
CREATE POLICY "Users can view their own snapshots"
ON public.weekly_skill_snapshot FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role can manage all snapshots" ON public.weekly_skill_snapshot;
CREATE POLICY "Service role can manage all snapshots"
ON public.weekly_skill_snapshot FOR ALL
USING (true);

-- ============================================================================
-- 3. UPDATE WEEKLY_PLANS TABLE
-- ============================================================================
-- Add fields for conditional regeneration tracking

ALTER TABLE public.weekly_plans
ADD COLUMN IF NOT EXISTS primary_focus VARCHAR(50),
ADD COLUMN IF NOT EXISTS secondary_focus VARCHAR(50),
ADD COLUMN IF NOT EXISTS generated_from_snapshot UUID REFERENCES public.weekly_skill_snapshot(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS teacher_adjusted BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active',
ADD COLUMN IF NOT EXISTS regeneration_reason VARCHAR(100);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_weekly_plans_status ON public.weekly_plans(status);
CREATE INDEX IF NOT EXISTS idx_weekly_plans_snapshot ON public.weekly_plans(generated_from_snapshot);
CREATE INDEX IF NOT EXISTS idx_weekly_plans_user_status ON public.weekly_plans(user_id, status);

-- ============================================================================
-- 4. UPDATE DAILY_TASKS TABLE
-- ============================================================================
-- Add fields for task type tracking

ALTER TABLE public.daily_tasks
ADD COLUMN IF NOT EXISTS task_type VARCHAR(50), -- speaking / grammar / vocabulary / listening / review
ADD COLUMN IF NOT EXISTS generated_by VARCHAR(20) DEFAULT 'ai'; -- ai / teacher

-- Indexes
CREATE INDEX IF NOT EXISTS idx_daily_tasks_type ON public.daily_tasks(task_type);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_generated_by ON public.daily_tasks(generated_by);

-- ============================================================================
-- 5. FUNCTION: UPDATE SKILL PROFILE FROM SPEAKING
-- ============================================================================
-- Automatically updates user_skill_profile when a speaking submission is created

CREATE OR REPLACE FUNCTION public.update_skill_profile_from_speaking()
RETURNS TRIGGER AS $$
DECLARE
  v_grammar FLOAT;
  v_fluency FLOAT;
  v_vocabulary FLOAT;
  v_pronunciation FLOAT;
  v_clarity FLOAT;
  v_fi FLOAT;
  v_primary VARCHAR(50);
  v_secondary VARCHAR(50);
  v_speaking_score FLOAT;
BEGIN
  -- Extract scores from analysis_json
  v_grammar := COALESCE((NEW.analysis_json->'scores'->>'grammar')::FLOAT, 0);
  v_fluency := COALESCE((NEW.analysis_json->'scores'->>'fluency')::FLOAT, 0);
  v_vocabulary := COALESCE((NEW.analysis_json->'scores'->>'vocabulary')::FLOAT, 0);
  v_pronunciation := COALESCE((NEW.analysis_json->'scores'->>'pronunciation')::FLOAT, 0);
  v_clarity := COALESCE((NEW.analysis_json->'scores'->>'clarity')::FLOAT, 0);
  v_speaking_score := COALESCE(NEW.score, 0);
  
  -- Calculate Fluency Index (weighted average)
  -- Grammar: 25%, Fluency: 30%, Vocabulary: 25%, Pronunciation: 10%, Clarity: 10%
  v_fi := (v_grammar * 0.25 + v_fluency * 0.30 + v_vocabulary * 0.25 + v_pronunciation * 0.10 + v_clarity * 0.10);
  
  -- Determine primary and secondary skills (lowest scores = areas to focus on)
  WITH skill_scores AS (
    SELECT 'grammar' as skill, v_grammar as score
    UNION ALL SELECT 'fluency', v_fluency
    UNION ALL SELECT 'vocabulary', v_vocabulary
    UNION ALL SELECT 'pronunciation', v_pronunciation
    UNION ALL SELECT 'clarity', v_clarity
  ),
  ranked AS (
    SELECT skill, score, ROW_NUMBER() OVER (ORDER BY score ASC) as rank
    FROM skill_scores
  )
  SELECT 
    MAX(CASE WHEN rank = 1 THEN skill END),
    MAX(CASE WHEN rank = 2 THEN skill END)
  INTO v_primary, v_secondary
  FROM ranked;
  
  -- Upsert into user_skill_profile
  INSERT INTO public.user_skill_profile (
    user_id, 
    speaking_score, 
    grammar_score, 
    vocabulary_score, 
    fluency_score, 
    listening_score, 
    fluency_index, 
    primary_skill, 
    secondary_skill, 
    updated_at,
    created_at
  )
  VALUES (
    NEW.user_id, 
    v_speaking_score, 
    v_grammar, 
    v_vocabulary,
    v_fluency, 
    0, -- listening will be updated from other sources
    v_fi, 
    v_primary, 
    v_secondary, 
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    speaking_score = EXCLUDED.speaking_score,
    grammar_score = EXCLUDED.grammar_score,
    vocabulary_score = EXCLUDED.vocabulary_score,
    fluency_score = EXCLUDED.fluency_score,
    fluency_index = EXCLUDED.fluency_index,
    primary_skill = EXCLUDED.primary_skill,
    secondary_skill = EXCLUDED.secondary_skill,
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 6. TRIGGER: ON SPEAKING SUBMISSION
-- ============================================================================
-- Automatically update skill profile when speaking submission is created

DROP TRIGGER IF EXISTS on_speaking_submission_update_profile ON public.speaking_submissions;
CREATE TRIGGER on_speaking_submission_update_profile
  AFTER INSERT ON public.speaking_submissions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_skill_profile_from_speaking();

-- ============================================================================
-- 7. HELPER FUNCTION: GET CURRENT WEEK START
-- ============================================================================
-- Returns the Monday of the current week

CREATE OR REPLACE FUNCTION public.get_current_week_start()
RETURNS DATE AS $$
BEGIN
  RETURN (CURRENT_DATE - (EXTRACT(DOW FROM CURRENT_DATE)::INTEGER - 1) * INTERVAL '1 day')::DATE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- 8. HELPER FUNCTION: CALCULATE FI DELTA
-- ============================================================================
-- Calculates the change in Fluency Index from last snapshot

CREATE OR REPLACE FUNCTION public.calculate_fi_delta(p_user_id UUID)
RETURNS FLOAT AS $$
DECLARE
  v_current_fi FLOAT;
  v_last_snapshot_fi FLOAT;
BEGIN
  -- Get current FI
  SELECT fluency_index INTO v_current_fi
  FROM public.user_skill_profile
  WHERE user_id = p_user_id;
  
  IF v_current_fi IS NULL THEN
    RETURN 0;
  END IF;
  
  -- Get last snapshot FI
  SELECT fluency_index INTO v_last_snapshot_fi
  FROM public.weekly_skill_snapshot
  WHERE user_id = p_user_id
  ORDER BY week_start DESC
  LIMIT 1;
  
  IF v_last_snapshot_fi IS NULL THEN
    RETURN 0;
  END IF;
  
  RETURN v_current_fi - v_last_snapshot_fi;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 9. GRANT PERMISSIONS
-- ============================================================================

GRANT ALL ON public.user_skill_profile TO service_role;
GRANT SELECT ON public.user_skill_profile TO authenticated;

GRANT ALL ON public.weekly_skill_snapshot TO service_role;
GRANT SELECT ON public.weekly_skill_snapshot TO authenticated;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- Phase 1: Base Structure ✅
-- Next: Phase 2 - Conditional Regeneration Logic (Edge Functions)
