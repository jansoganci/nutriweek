-- ---------------------------------------------------------------------------
-- Expand activity log for strength-focused workout tracking
-- ---------------------------------------------------------------------------
alter table public.activity_log
  add column if not exists activity_type text,
  add column if not exists sets integer,
  add column if not exists reps integer,
  add column if not exists weight_kg numeric(8,2);

alter table public.activity_log
  add constraint activity_log_sets_positive check (sets is null or sets > 0),
  add constraint activity_log_reps_positive check (reps is null or reps > 0),
  add constraint activity_log_weight_positive check (weight_kg is null or weight_kg > 0);
