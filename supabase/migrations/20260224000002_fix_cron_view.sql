-- Fix cron jobs view
-- The pg_cron extension stores jobs in cron.job table

-- Drop existing view if it exists
DROP VIEW IF EXISTS public.cron_jobs_view;

-- Create a view to see ALL cron jobs (not just weekly-plan-regeneration)
CREATE OR REPLACE VIEW public.cron_jobs_view AS
SELECT 
    jobid,
    schedule,
    command,
    nodename,
    nodeport,
    database,
    username,
    active,
    jobname
FROM cron.job
WHERE database = current_database();

-- Grant access to authenticated users
GRANT SELECT ON public.cron_jobs_view TO authenticated;

-- Add comment
COMMENT ON VIEW public.cron_jobs_view IS 'View of all pg_cron jobs for current database';

-- Verify the view works
DO $
BEGIN
  RAISE NOTICE 'Cron jobs view created successfully. Run: SELECT * FROM public.cron_jobs_view;';
END $;

