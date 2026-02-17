-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create table for listening content generations (AI Material)
CREATE TABLE IF NOT EXISTS public.listening_generations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    text_content TEXT,
    dialogue_json JSONB, -- For multi-speaker dialogue
    audio_url TEXT,
    audio_hash TEXT, -- To easily find duplicates
    provider TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.listening_generations ENABLE ROW LEVEL SECURITY;

-- Policy: Service role can do everything (for Edge Functions)
GRANT ALL ON public.listening_generations TO service_role;
GRANT SELECT ON public.listening_generations TO authenticated; 

-- Create table for speaking submissions
CREATE TABLE IF NOT EXISTS public.speaking_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    task_id UUID REFERENCES public.daily_tasks(id) ON DELETE SET NULL,
    audio_url TEXT,
    transcript TEXT,
    analysis_json JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.speaking_submissions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can insert their own submissions
CREATE POLICY "Users can insert their own speaking submissions"
ON public.speaking_submissions
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can view their own submissions
CREATE POLICY "Users can view their own speaking submissions"
ON public.speaking_submissions
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Admin/Service role can view all (implicit for service role, but good to be explicit for admin users if any)
-- Assuming service role bypasses RLS, so this is mainly for user access.

-- Grant access to authenticated users
GRANT ALL ON public.speaking_submissions TO authenticated;
GRANT ALL ON public.speaking_submissions TO service_role;

-- Create storage bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('speaking-audio', 'speaking-audio', true)
ON CONFLICT (id) DO NOTHING;

-- Policy: Users can upload to their own folder in speaking-audio
CREATE POLICY "Users can upload their own speaking audio"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'speaking-audio' AND
  auth.uid() = owner
);

-- Policy: Users can view their own speaking audio
CREATE POLICY "Users can view their own speaking audio"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'speaking-audio' AND
  auth.uid() = owner
);

