-- Create user_essays table
create table if not exists user_essays (
  id uuid default gen_random_uuid() primary key,
  user_id text not null,
  title text not null,
  content text not null,
  type text not null,
  topic text,
  prompt text,
  suggestions jsonb default '[]'::jsonb,
  grammar_errors jsonb default '[]'::jsonb,
  score jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Enable RLS
alter table user_essays enable row level security;

-- Create policies
DROP POLICY IF EXISTS "Users can view their own essays" on user_essays;
create policy "Users can view their own essays"
  on user_essays for select
  using (auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Users can insert their own essays" on user_essays;
create policy "Users can insert their own essays"
  on user_essays for insert
  with check (auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Users can update their own essays" on user_essays;
create policy "Users can update their own essays"
  on user_essays for update
  using (auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Users can delete their own essays" on user_essays;
create policy "Users can delete their own essays"
  on user_essays for delete
  using (auth.uid()::text = user_id);
