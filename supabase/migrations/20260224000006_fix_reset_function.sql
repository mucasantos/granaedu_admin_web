-- ============================================================================
-- FIX: Reset function - remove non-existent column
-- ============================================================================

CREATE OR REPLACE FUNCTION reset_user_adaptive_data(target_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delete daily tasks for this user
  DELETE FROM public.daily_tasks WHERE user_id = target_user_id;
  
  -- Delete weekly plans for this user
  DELETE FROM public.weekly_plans WHERE user_id = target_user_id;
  
  -- Delete weekly snapshots for this user
  DELETE FROM public.weekly_skill_snapshot WHERE user_id = target_user_id;
  
  -- Reset skill profile (keep it but reset scores to trigger new evaluation)
  UPDATE public.user_skill_profile
  SET 
    fluency_index = 0,
    grammar_score = 0,
    fluency_score = 0,
    vocabulary_score = 0,
    speaking_score = 0,
    listening_score = 0,
    primary_skill = NULL,
    secondary_skill = NULL,
    updated_at = NOW()
  WHERE user_id = target_user_id;
  
  RAISE NOTICE 'Reset complete for user %', target_user_id;
END;
$$;

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION reset_user_adaptive_data(UUID) TO service_role;

COMMENT ON FUNCTION reset_user_adaptive_data IS 'Resets all adaptive plan data for a specific user (for testing purposes)';
