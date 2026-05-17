-- ---------------------------------------------------------------------------
-- Activity log
-- ---------------------------------------------------------------------------
create table public.activity_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,

  activity_name text not null,
  duration_minutes integer not null check (duration_minutes > 0),
  calories_burned numeric(8,2) not null check (calories_burned > 0),
  notes text,

  logged_at date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index activity_log_user_date_idx
  on public.activity_log (user_id, logged_at desc);

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger activity_log_set_updated_at
  before update on public.activity_log
  for each row
  execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.activity_log enable row level security;

create policy "activity_log_select_own"
  on public.activity_log for select to authenticated
  using (auth.uid() = user_id);

create policy "activity_log_insert_own"
  on public.activity_log for insert to authenticated
  with check (auth.uid() = user_id);

create policy "activity_log_update_own"
  on public.activity_log for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "activity_log_delete_own"
  on public.activity_log for delete to authenticated
  using (auth.uid() = user_id);
