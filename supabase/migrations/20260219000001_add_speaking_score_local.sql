-- Add score column to speaking_submissions table

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'speaking_submissions' 
                   AND column_name = 'score') THEN
        ALTER TABLE public.speaking_submissions 
        ADD COLUMN score INTEGER DEFAULT 0;
    END IF;
END $$;
