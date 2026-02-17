-- Fix RLS policies for speaking submissions (idempotent version)

-- 1. Drop ALL existing policies for speaking_submissions
DO $$ 
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'speaking_submissions' 
        AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.speaking_submissions', policy_record.policyname);
    END LOOP;
END $$;

-- 2. Create fresh policies

-- Allow service role to insert for any user (Edge Function)
CREATE POLICY "Service role can insert all speaking submissions"
ON public.speaking_submissions
FOR INSERT
TO service_role
WITH CHECK (true);

-- Allow authenticated users to view their own submissions
CREATE POLICY "Users can view their own speaking submissions"
ON public.speaking_submissions
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Allow service role to view all (for admin purposes)
CREATE POLICY "Service role can view all speaking submissions"
ON public.speaking_submissions
FOR SELECT
TO service_role
USING (true);

-- 3. Fix storage policies for speaking-audio bucket

-- Drop existing storage policies
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN
        SELECT policyname
        FROM pg_policies
        WHERE tablename = 'objects'
        AND schemaname = 'storage'
        AND (policyname LIKE '%speaking%' OR policyname LIKE '%Service role%')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', policy_record.policyname);
    END LOOP;
END $$;

-- Create fresh storage policies

-- Service role can upload (Edge Functions use service role)
CREATE POLICY "Service role can upload speaking audio"
ON storage.objects
FOR INSERT
TO service_role
WITH CHECK (bucket_id = 'speaking-audio');

-- Service role can view all
CREATE POLICY "Service role can view speaking audio"
ON storage.objects
FOR SELECT
TO service_role
USING (bucket_id = 'speaking-audio');

-- Public can view (bucket is public)
CREATE POLICY "Public can view speaking audio"
ON storage.objects
FOR SELECT
TO anon, authenticated
USING (bucket_id = 'speaking-audio');
