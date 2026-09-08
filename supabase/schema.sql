-- Community Watch database
create extension if not exists "pgcrypto";

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz not null default now()
);

create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  description text not null,
  category text not null,
  location text not null,
  incident_at timestamptz not null,
  status text not null default 'Pending'
    check (status in ('Pending','Under Investigation','Resolved','Rejected')),
  image_url text,
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now()
);

-- Ensure latitude and longitude columns exist on existing databases
alter table reports add column if not exists latitude double precision;
alter table reports add column if not exists longitude double precision;
alter table reports add column if not exists image_urls text[];

create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  message text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;
alter table reports enable row level security;
alter table notifications enable row level security;

-- Drop existing policies if they already exist so the script runs cleanly
drop policy if exists "profiles_select_own" on profiles;
drop policy if exists "profiles_insert_own" on profiles;
drop policy if exists "profiles_update_own" on profiles;
drop policy if exists "reports_read_authenticated" on reports;
drop policy if exists "reports_insert_own" on reports;
drop policy if exists "reports_update_own" on reports;
drop policy if exists "reports_update_policy" on reports;
drop policy if exists "reports_delete_own" on reports;
drop policy if exists "reports_delete_policy" on reports;
drop policy if exists "notifications_own" on notifications;
drop policy if exists "notifications_select_own" on notifications;
drop policy if exists "notifications_insert" on notifications;
drop policy if exists "notifications_update_own" on notifications;
drop policy if exists "notifications_delete_own" on notifications;
drop policy if exists "Allow authenticated uploads to report-images" on storage.objects;
drop policy if exists "Allow public read of report-images" on storage.objects;

create policy "profiles_select_own" on profiles for select
using (auth.uid() = id);

create policy "profiles_insert_own" on profiles for insert
with check (auth.uid() = id);

create policy "profiles_update_own" on profiles for update
using (auth.uid() = id);

create policy "reports_read_authenticated" on reports for select
using (auth.role() = 'authenticated');

create policy "reports_insert_own" on reports for insert
with check (auth.uid() = user_id);

-- Authors can update their own report, and admins can update any report (e.g. status changes)
create policy "reports_update_policy" on reports for update
using (
  auth.uid() = user_id
  or exists (
    select 1 from profiles
    where profiles.id = auth.uid() and profiles.role = 'admin'
  )
);

create policy "reports_delete_policy" on reports for delete
using (
  auth.uid() = user_id
  or exists (
    select 1 from profiles
    where profiles.id = auth.uid() and profiles.role = 'admin'
  )
);

create policy "notifications_select_own" on notifications for select
using (auth.uid() = user_id);

create policy "notifications_insert" on notifications for insert
with check (auth.role() = 'authenticated');

create policy "notifications_update_own" on notifications for update
using (auth.uid() = user_id);

create policy "notifications_delete_own" on notifications for delete
using (auth.uid() = user_id);

-- Storage bucket for report images
insert into storage.buckets (id, name, public)
values ('report-images', 'report-images', true)
on conflict (id) do nothing;

create policy "Allow authenticated uploads to report-images"
on storage.objects for insert
to authenticated
with check (bucket_id = 'report-images');

create policy "Allow public read of report-images"
on storage.objects for select
to public
using (bucket_id = 'report-images');

-- Incident comments and updates
create table if not exists report_comments (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references reports(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  user_name text not null,
  comment text not null,
  is_official boolean not null default false,
  created_at timestamptz not null default now()
);

alter table report_comments enable row level security;

drop policy if exists "report_comments_select" on report_comments;
drop policy if exists "report_comments_insert" on report_comments;

create policy "report_comments_select" on report_comments for select
using (auth.role() = 'authenticated');

create policy "report_comments_insert" on report_comments for insert
with check (auth.uid() = user_id);

-- IMPORTANT: after creating your first account, promote that user's profile
-- to admin from the Supabase SQL editor:
-- update profiles set role = 'admin' where id = 'YOUR-USER-UUID';

-- Trigger to automatically create a profile when a new user signs up in auth.users
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(coalesce(new.email, 'resident'), '@', 1)),
    'user'
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();