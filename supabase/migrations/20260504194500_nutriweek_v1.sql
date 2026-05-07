-- NutriWeek v1.0 — Supabase schema (PostgreSQL)
-- Apply in Supabase SQL Editor or via: supabase db push

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Profiles (identity + onboarding; one row per auth user)
-- ---------------------------------------------------------------------------
create table public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,

  onboarding_complete boolean not null default false,
  onboarding_step integer not null default 0,

  gender text,
  age integer,
  height_cm numeric,
  weight_kg numeric,
  activity_level text,

  goal text,

  dietary_preferences jsonb not null default '[]'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.profiles.onboarding_step is
  '0 = not started, 1–4 = in progress, 5 = complete';

-- ---------------------------------------------------------------------------
-- Body measurements (history; analytics)
-- ---------------------------------------------------------------------------
create table public.body_measurements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,

  waist_cm numeric,
  hips_cm numeric,
  chest_cm numeric,
  left_arm_cm numeric,
  left_leg_cm numeric,

  weight_kg numeric,

  measured_at date not null default current_date,
  created_at timestamptz not null default now()
);

create index body_measurements_user_measured_idx
  on public.body_measurements (user_id, measured_at desc);

-- ---------------------------------------------------------------------------
-- Nutrition targets (derived from profile; updated on profile change)
-- ---------------------------------------------------------------------------
create table public.nutrition_targets (
  user_id uuid primary key references auth.users (id) on delete cascade,

  bmi numeric,
  bmi_category text,
  bmr integer,
  tdee integer,
  target_calories integer,

  protein_g integer,
  carbs_g integer,
  fat_g integer,

  protein_pct numeric,
  carbs_pct numeric,
  fat_pct numeric,

  calculated_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Weekly meal plans (Gemma JSON)
-- ---------------------------------------------------------------------------
create table public.weekly_meal_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,

  week_start_date date not null,
  plan_json jsonb not null,
  generated_at timestamptz not null default now(),

  unique (user_id, week_start_date)
);

create index weekly_meal_plans_user_idx
  on public.weekly_meal_plans (user_id, week_start_date desc);

-- ---------------------------------------------------------------------------
-- Food log (per-item rows)
-- ---------------------------------------------------------------------------
create table public.food_log_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,

  log_date date not null,
  food_name text not null,
  grams numeric not null,

  calories numeric not null,
  protein_g numeric not null,
  carbs_g numeric not null,
  fat_g numeric not null,

  fdc_id bigint,

  logged_at timestamptz not null default now()
);

create index food_log_entries_user_date_idx
  on public.food_log_entries (user_id, log_date desc);

-- ---------------------------------------------------------------------------
-- Logging streaks
-- ---------------------------------------------------------------------------
create table public.logging_streaks (
  user_id uuid primary key references auth.users (id) on delete cascade,
  current_count integer not null default 0,
  longest_count integer not null default 0,
  last_log_date date,
  updated_at timestamptz not null default now()
);

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

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

create trigger nutrition_targets_set_updated_at
  before update on public.nutrition_targets
  for each row
  execute function public.set_updated_at();

create trigger logging_streaks_set_updated_at
  before update on public.logging_streaks
  for each row
  execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Auto-create profile row on sign-up (optional but recommended)
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.body_measurements enable row level security;
alter table public.nutrition_targets enable row level security;
alter table public.weekly_meal_plans enable row level security;
alter table public.food_log_entries enable row level security;
alter table public.logging_streaks enable row level security;

-- profiles
create policy "profiles_select_own"
  on public.profiles for select to authenticated
  using (auth.uid() = user_id);

create policy "profiles_insert_own"
  on public.profiles for insert to authenticated
  with check (auth.uid() = user_id);

create policy "profiles_update_own"
  on public.profiles for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "profiles_delete_own"
  on public.profiles for delete to authenticated
  using (auth.uid() = user_id);

-- body_measurements
create policy "body_measurements_select_own"
  on public.body_measurements for select to authenticated
  using (auth.uid() = user_id);

create policy "body_measurements_insert_own"
  on public.body_measurements for insert to authenticated
  with check (auth.uid() = user_id);

create policy "body_measurements_update_own"
  on public.body_measurements for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "body_measurements_delete_own"
  on public.body_measurements for delete to authenticated
  using (auth.uid() = user_id);

-- nutrition_targets
create policy "nutrition_targets_select_own"
  on public.nutrition_targets for select to authenticated
  using (auth.uid() = user_id);

create policy "nutrition_targets_insert_own"
  on public.nutrition_targets for insert to authenticated
  with check (auth.uid() = user_id);

create policy "nutrition_targets_update_own"
  on public.nutrition_targets for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "nutrition_targets_delete_own"
  on public.nutrition_targets for delete to authenticated
  using (auth.uid() = user_id);

-- weekly_meal_plans
create policy "weekly_meal_plans_select_own"
  on public.weekly_meal_plans for select to authenticated
  using (auth.uid() = user_id);

create policy "weekly_meal_plans_insert_own"
  on public.weekly_meal_plans for insert to authenticated
  with check (auth.uid() = user_id);

create policy "weekly_meal_plans_update_own"
  on public.weekly_meal_plans for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "weekly_meal_plans_delete_own"
  on public.weekly_meal_plans for delete to authenticated
  using (auth.uid() = user_id);

-- food_log_entries
create policy "food_log_entries_select_own"
  on public.food_log_entries for select to authenticated
  using (auth.uid() = user_id);

create policy "food_log_entries_insert_own"
  on public.food_log_entries for insert to authenticated
  with check (auth.uid() = user_id);

create policy "food_log_entries_update_own"
  on public.food_log_entries for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "food_log_entries_delete_own"
  on public.food_log_entries for delete to authenticated
  using (auth.uid() = user_id);

-- logging_streaks
create policy "logging_streaks_select_own"
  on public.logging_streaks for select to authenticated
  using (auth.uid() = user_id);

create policy "logging_streaks_insert_own"
  on public.logging_streaks for insert to authenticated
  with check (auth.uid() = user_id);

create policy "logging_streaks_update_own"
  on public.logging_streaks for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "logging_streaks_delete_own"
  on public.logging_streaks for delete to authenticated
  using (auth.uid() = user_id);
