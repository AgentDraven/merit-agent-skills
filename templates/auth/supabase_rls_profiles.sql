-- Platform free-community apps use gateway store identity (email on register) by default.
-- Optional BYOK Supabase for own-host session UI (FR-MPD-14 scaffold).

-- profiles: extends auth.users when app adopts Supabase Auth
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  consumer_id text not null,
  email text,
  handle text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);
