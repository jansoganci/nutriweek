-- Smart Meal Cache with read-through generation support.

create or replace function public.normalize_meal_name(input text)
returns text
language sql
immutable
as $$
  select trim(regexp_replace(regexp_replace(lower(coalesce(input, '')), '[^a-z0-9\s]+', ' ', 'g'), '\s+', ' ', 'g'));
$$;

create table public.cached_meals (
  id uuid primary key default gen_random_uuid(),

  name text not null,
  normalized_name text not null,
  meal_type text not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),

  calories numeric(8,2) not null check (calories > 0),
  protein_g numeric(8,2) not null check (protein_g >= 0),
  carbs_g numeric(8,2) not null check (carbs_g >= 0),
  fat_g numeric(8,2) not null check (fat_g >= 0),

  dietary_tags text[] not null default '{}'::text[],
  dietary_tags_key text not null default '',
  cuisine text,
  ingredients text[] not null default '{}'::text[],

  source text not null default 'seed' check (source in ('seed', 'gemini', 'admin')),
  scalable boolean not null default true,
  min_scale numeric(4,2) not null default 0.80,
  max_scale numeric(4,2) not null default 1.20,

  usage_count integer not null default 0 check (usage_count >= 0),
  last_used_at timestamptz,

  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  check (min_scale > 0 and max_scale >= min_scale),
  check (dietary_tags <@ array[
    'vegan',
    'vegetarian',
    'halal',
    'kosher',
    'gluten_free',
    'dairy_free',
    'nut_free',
    'keto',
    'paleo',
    'low_sodium',
    'high_protein',
    'low_carb'
  ]::text[])
);

create or replace function public.set_cached_meal_derived_fields()
returns trigger
language plpgsql
as $$
begin
  new.meal_type = lower(new.meal_type);
  new.normalized_name = public.normalize_meal_name(new.name);

  select coalesce(array_agg(tag order by tag), '{}'::text[])
    into new.dietary_tags
  from (
    select distinct lower(trim(tag)) as tag
    from unnest(coalesce(new.dietary_tags, '{}'::text[])) as tags(tag)
    where trim(tag) <> ''
    union
    select 'vegetarian'
    where exists (
      select 1
      from unnest(coalesce(new.dietary_tags, '{}'::text[])) as tags(tag)
      where lower(trim(tag)) = 'vegan'
    )
    union
    select 'dairy_free'
    where exists (
      select 1
      from unnest(coalesce(new.dietary_tags, '{}'::text[])) as tags(tag)
      where lower(trim(tag)) = 'vegan'
    )
  ) normalized_tags;

  new.dietary_tags_key = array_to_string(new.dietary_tags, ',');
  new.updated_at = now();
  return new;
end;
$$;

create trigger cached_meals_set_derived_fields
  before insert or update on public.cached_meals
  for each row
  execute function public.set_cached_meal_derived_fields();

create unique index cached_meals_dedupe_idx
  on public.cached_meals (normalized_name, meal_type, dietary_tags_key);

create index cached_meals_type_calories_idx
  on public.cached_meals (meal_type, calories)
  where is_active = true;

create index cached_meals_usage_idx
  on public.cached_meals (usage_count, last_used_at)
  where is_active = true;

create index cached_meals_dietary_tags_gin_idx
  on public.cached_meals using gin (dietary_tags);

create index cached_meals_ingredients_gin_idx
  on public.cached_meals using gin (ingredients);

create or replace function public.touch_cached_meal_usage(meal_ids uuid[])
returns void
language sql
security definer
set search_path = public
as $$
  update public.cached_meals
  set
    usage_count = usage_count + 1,
    last_used_at = now(),
    updated_at = now()
  where id = any(meal_ids);
$$;

alter table public.cached_meals enable row level security;

create policy "cached_meals_service_role_all"
  on public.cached_meals
  for all
  to service_role
  using (true)
  with check (true);
