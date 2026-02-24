-- Migration: Setup Weekly Regeneration Cron Job
-- Created: 2026-02-24
-- Description: Configures pg_cron to run weekly plan regeneration every Monday at 00:00

-- ============================================================================
-- 1. ENABLE PG_CRON EXTENSION
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ============================================================================
-- 2. GRANT PERMISSIONS TO POSTGRES USER
-- ============================================================================

-- Grant usage on cron schema
GRANT USAGE ON SCHEMA cron TO postgres;

-- ============================================================================
-- 3. CREATE CRON JOB FOR WEEKLY REGENERATION
-- ============================================================================

-- Remove existing job if it exists
SELECT cron.unschedule('weekly-plan-regeneration');

-- Schedule new job: Every Monday at 00:00 UTC
SELECT cron.schedule(
  'weekly-plan-regeneration',
  '0 0 * * 1', -- Cron expression: minute hour day month weekday (1 = Monday)
  $$
  SELECT
    net.http_post(
      url := current_setting('app.settings.supabase_url') || '/functions/v1/check-weekly-regeneration',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := '{}'::jsonb,
      timeout_milliseconds := 300000 -- 5 minutes timeout
    ) AS request_id;
  $$
);

-- ============================================================================
-- 4. CREATE APP SETTINGS TABLE (if not exists)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supabase_url TEXT,
  service_role_key TEXT,
  openai_key TEXT,
  gemini_key TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Only service role can access
DROP POLICY IF EXISTS "Service role can manage app settings" ON public.app_settings;
CREATE POLICY "Service role can manage app settings"
ON public.app_settings FOR ALL
USING (true);

-- ============================================================================
-- 5. HELPER FUNCTION TO UPDATE CRON JOB URL
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_cron_job_url()
RETURNS void AS $$
DECLARE
  v_supabase_url TEXT;
  v_service_key TEXT;
BEGIN
  -- Get settings from app_settings table
  SELECT supabase_url, service_role_key 
  INTO v_supabase_url, v_service_key
  FROM public.app_settings
  LIMIT 1;

  -- If settings exist, update the cron job
  IF v_supabase_url IS NOT NULL AND v_service_key IS NOT NULL THEN
    -- Unschedule existing job
    PERFORM cron.unschedule('weekly-plan-regeneration');
    
    -- Schedule with updated URL
    PERFORM cron.schedule(
      'weekly-plan-regeneration',
      '0 0 * * 1',
      format(
        $$
        SELECT
          net.http_post(
            url := '%s/functions/v1/check-weekly-regeneration',
            headers := '{"Content-Type": "application/json", "Authorization": "Bearer %s"}'::jsonb,
            body := '{}'::jsonb,
            timeout_milliseconds := 300000
          ) AS request_id;
        $$,
        v_supabase_url,
        v_service_key
      )
    );
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 6. VIEW CRON JOBS
-- ============================================================================

-- Create a view to easily see scheduled jobs
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
WHERE jobname = 'weekly-plan-regeneration';

-- Grant access to authenticated users (read-only)
GRANT SELECT ON public.cron_jobs_view TO authenticated;

-- ============================================================================
-- NOTES FOR MANUAL CONFIGURATION
-- ============================================================================

-- If the automatic setup doesn't work, configure manually via Supabase Dashboard:
-- 
-- 1. Go to Database > Cron Jobs
-- 2. Click "Create a new cron job"
-- 3. Fill in:
--    - Name: weekly-plan-regeneration
--    - Schedule: 0 0 * * 1 (Every Monday at 00:00)
--    - Command: 
--      SELECT net.http_post(
--        url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-weekly-regeneration',
--        headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb
--      );
--
-- IMPORTANT: Replace YOUR_PROJECT_REF and YOUR_SERVICE_ROLE_KEY with actual values

-- ============================================================================
-- TESTING
-- ============================================================================

-- To test the cron job manually (without waiting for Monday):
-- SELECT net.http_post(
--   url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-weekly-regeneration',
--   headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb
-- );

-- To view scheduled jobs:
-- SELECT * FROM cron.job WHERE jobname = 'weekly-plan-regeneration';

-- To view job run history:
-- SELECT * FROM cron.job_run_details 
-- WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'weekly-plan-regeneration')
-- ORDER BY start_time DESC
-- LIMIT 10;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
