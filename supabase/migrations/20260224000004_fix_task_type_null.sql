-- ============================================================================
-- FIX: Update task_type from skill where task_type is NULL
-- ============================================================================
-- This fixes existing tasks that were created without task_type

UPDATE public.daily_tasks
SET task_type = skill
WHERE task_type IS NULL AND skill IS NOT NULL;

-- Add a comment to document this fix
COMMENT ON COLUMN public.daily_tasks.task_type IS 'Type of task (speaking, grammar, vocabulary, listening, reading, writing, review, mixed). Should match skill field.';
