# Smart Meal Cache With Read-Through Strategy

## Goal

Reduce Gemini API calls and improve meal-plan generation speed by adding a global Supabase-backed meal cache behind `gemma-generate-day`.

The iOS app will continue generating weekly plans with seven sequential daily calls. Each daily call will first try to assemble meals from `cached_meals`, call Gemini only for missing meals, save newly generated meals back into the cache, and return the same user-facing day-plan shape.

Cache source details stay in Edge Function logs only. The UI must not expose whether meals came from cache or fresh AI.

## Current Architecture

- iOS weekly generation lives in `iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift`.
- The weekly flow calls `generateDay` seven times sequentially.
- `iOS/NutriWeek/NutriWeek/Data/EdgeFunctions/GemmaEdgeService.swift` invokes `gemma-generate-day`.
- `supabase/functions/gemma-generate-day/index.ts` currently calls Gemini directly for every day.
- `weekly_meal_plans` stores complete weekly plans as JSON, but there is no meal-level cache table.
- `gemma-generate-week` is deprecated for this feature and should remain untouched for now.

## Final Design Decisions

- `cached_meals` is global across all users.
- iOS does not directly access `cached_meals`.
- Edge Functions access `cached_meals` with the Supabase service role.
- iOS sends `excludeMealNames` to prevent repeats in the same generated week.
- `gemma-generate-day` checks cache first and calls Gemini only for missing meal types.
- Mixed-source days are allowed.
- Portion scaling is allowed from `0.80x` to `1.20x`.
- Dietary hard constraints block cache reuse.
- Dietary soft preferences influence scoring but do not block reuse.
- Cache/source data is logged server-side only and is never returned to the UI.
- Manual seed data will be inserted through the Supabase SQL editor.

## Dietary Tags

Hard constraints:

- `vegan`
- `vegetarian`
- `halal`
- `kosher`
- `gluten_free`
- `dairy_free`
- `nut_free`

Soft preferences:

- `keto`
- `paleo`
- `low_sodium`
- `high_protein`
- `low_carb`

## Database Changes

Add a migration:

`supabase/migrations/20260513HHMMSS_smart_meal_cache.sql`

Use the actual timestamp at implementation time.

### `cached_meals`

Planned DDL:

```sql
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
    'vegan','vegetarian','halal','kosher','gluten_free','dairy_free','nut_free',
    'keto','paleo','low_sodium','high_protein','low_carb'
  ]::text[])
);
```

### Indexes

```sql
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
```

### RLS

Enable RLS and allow service-role access only:

```sql
alter table public.cached_meals enable row level security;

create policy "cached_meals_service_role_all"
  on public.cached_meals
  for all
  to service_role
  using (true)
  with check (true);
```

Do not add `authenticated` or `anon` policies.

### Database Helpers

Add helpers in the same migration:

- `public.normalize_meal_name(text)`
  - Lowercase.
  - Trim.
  - Collapse whitespace.
  - Strip punctuation.
- A `before insert or update` trigger on `cached_meals`
  - Sets `normalized_name`.
  - Lowercases, sorts, and deduplicates `dietary_tags`.
  - Sets `dietary_tags_key`.
  - Sets `updated_at`.
- `public.touch_cached_meal_usage(uuid[])`
  - Increments `usage_count`.
  - Sets `last_used_at = now()`.
  - Updates `updated_at`.

## Edge Function Changes

Modify:

`supabase/functions/gemma-generate-day/index.ts`

No new Edge Function is required.

### Request Contract

Add `excludeMealNames`:

```ts
type GenerateDayPayload = {
  profile: Record<string, unknown>;
  targetCalories: number;
  macros: { protein: number; carbs: number; fat: number };
  dayName: string;
  date: string;
  excludeMealNames?: string[];
};
```

### Response Contract

Keep the day response compatible with existing UI, but add metadata fields to each meal:

```ts
{
  day: string,
  date: string,
  totalCalories: number,
  meals: [{
    type: "Breakfast" | "Lunch" | "Dinner" | "Snack",
    name: string,
    calories: number,
    emoji: string,
    protein: number,
    carbs: number,
    fat: number,
    dietary_tags: string[],
    cuisine: string,
    ingredients: string[]
  }]
}
```

Do not include cache source, cache hit state, or scoring details in the response.

### JSON Schema Updates

Update `DAY_PLAN_RESPONSE_JSON_SCHEMA`:

- Require exactly four meals for full-day generation.
- Require only requested missing meal types for partial generation.
- Add meal fields:
  - `dietary_tags`: string array.
  - `cuisine`: string.
  - `ingredients`: string array.
- Keep `additionalProperties: false`.

### Prompt Template

Update `buildPrompt` into separate prompt builders:

- `buildFullDayPrompt(input)`
- `buildPartialMealsPrompt(input, existingMeals, missingMealTypes, remainingTargets)`

Prompt requirements:

- Return JSON only.
- Include `day`, `date`, `totalCalories`, and `meals`.
- Include `dietary_tags`, `cuisine`, and `ingredients` for every meal.
- Respect hard dietary preferences from `profile.dietaryPreferences`.
- Avoid all names in `excludeMealNames`.
- For partial generation, generate only missing meal types.
- For partial generation, include the existing cached meals in the prompt as context and tell Gemini not to duplicate them.
- Use the remaining calorie and macro targets after cached meals have been selected.

### Cache Lookup

Add a Supabase REST helper using:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

Cache errors should be fail-open:

- Log cache lookup/write errors.
- Continue to Gemini generation instead of failing the request.

Candidate query per meal type:

- `is_active = true`
- matching `meal_type`
- hard dietary tags are all present
- name is not in `excludeMealNames`
- calories are compatible with scaling:
  - `targetCaloriesForMeal / 1.20 <= calories`
  - `calories <= targetCaloriesForMeal / 0.80`

Fetch a bounded number of candidates per meal type, then score in TypeScript.

### Meal Type Targets

Use fixed distribution:

- Breakfast: 25%
- Lunch: 30%
- Dinner: 35%
- Snack: 10%

Apply the same distribution to calories, protein, carbs, and fat.

### Portion Scaling

Scale cached meals mathematically, not with Gemini.

For each cached candidate:

```ts
scale = clamp(typeTargetCalories / meal.calories, meal.min_scale, meal.max_scale)
scaledCalories = round(meal.calories * scale)
scaledProtein = round1(meal.protein_g * scale)
scaledCarbs = round1(meal.carbs_g * scale)
scaledFat = round1(meal.fat_g * scale)
```

Reasoning:

- Deterministic.
- Cheap.
- Bounded by realistic serving-size changes.
- Avoids extra AI calls just to resize known meals.

### Scoring Algorithm

Candidate score:

```text
score =
  abs(calorie_error) / 50
+ abs(protein_error) / 5
+ abs(carbs_error) / 5
+ abs(fat_error) / 5
+ usage_penalty
- soft_tag_bonus
```

Guidelines:

- Lower score is better.
- Hard tags are filters, not score terms.
- Soft tag bonus should be small.
- Usage penalty should gently prefer less-used meals without overriding nutrition fit.
- Excluded meal names get filtered before scoring.

### Mixed Assembly Logic

Algorithm:

1. Validate request body.
2. Normalize `excludeMealNames`.
3. Extract hard and soft dietary preferences from profile.
4. Compute meal-type macro targets.
5. Query and score cached candidates for each meal type.
6. Pick the best cached meal per type where candidate quality is acceptable.
7. Avoid duplicate normalized names within the same day.
8. Evaluate the cached partial day.
9. If all four cached meals satisfy final day tolerance, return the cached day.
10. If one to three meal types are missing, compute remaining calorie and macro targets.
11. Call Gemini only for the missing meal types.
12. Combine cached and Gemini meals in Breakfast, Lunch, Dinner, Snack order.
13. Validate final day:
    - exactly four meals,
    - one of each meal type,
    - total calories within ±50 kcal,
    - protein/carbs/fat within ±5g,
    - hard dietary tags present where required,
    - no excluded names.
14. If final validation fails, retry once with full-day Gemini.
15. Save validated Gemini meals into `cached_meals`.
16. Touch usage for cached meal IDs.
17. Return normalized day DTO.

### Gemini Partial Prompt

When cache provides two meals and two are missing, use a prompt like:

```text
Generate only these missing meal types: Lunch, Snack.

Existing meals already selected:
- Breakfast: Oatmeal Berry Bowl, 410 kcal, 22g protein, 55g carbs, 10g fat
- Dinner: Salmon Rice Plate, 690 kcal, 44g protein, 70g carbs, 22g fat

Remaining daily targets for missing meals combined:
- calories: 700 kcal
- protein: 44g
- carbs: 88g
- fat: 18g

Do not duplicate existing meals or excluded meal names.
Return a JSON object with only the missing meals in the meals array.
```

The Edge Function combines the result with cached meals.

### Cache Writes

After successful Gemini validation:

- Normalize meal name.
- Convert meal type to lowercase.
- Lowercase/sort/dedupe dietary tags.
- Upsert using `(normalized_name, meal_type, dietary_tags_key)`.
- Use `source = 'gemini'`.
- Store calories/macros exactly as returned by Gemini.
- Store `cuisine` and `ingredients`.

### Logging

Add structured logs through existing `logEvent` style:

- `cache_lookup_start`
- `cache_candidates_found`
- `cache_assembly_selected`
- `cache_hit_full_day`
- `cache_hit_partial_day`
- `cache_miss`
- `gemini_partial_request`
- `gemini_full_request`
- `gemini_full_fallback`
- `cache_write_success`
- `cache_write_failure`
- `final_validation_failure`
- `request_complete`

Do not log personal profile details. Day name, meal counts, score, and source counts are acceptable.

## iOS Changes

### `GemmaEdgeService.swift`

Modify:

`iOS/NutriWeek/NutriWeek/Data/EdgeFunctions/GemmaEdgeService.swift`

Changes:

- Add `excludeMealNames: [String]` to `generateDay`.
- Add `excludeMealNames` to `GemmaGenerateDayRequest`.
- Extend `GemmaMealDTO`:
  - `dietaryTags: [String]?`
  - `cuisine: String?`
  - `ingredients: [String]?`
- Map snake_case `dietary_tags` using `CodingKeys`.
- Keep new metadata optional so previously saved `weekly_meal_plans.plan_json` can still decode.

### `MealPlanRepositoryProtocol.swift`

Modify:

`iOS/NutriWeek/NutriWeek/Domain/Services/Protocols/MealPlanRepositoryProtocol.swift`

Change:

- Add `excludeMealNames: [String]` to `generateDay`.

### `SupabaseMealPlanRepository.swift`

Modify:

`iOS/NutriWeek/NutriWeek/Data/Supabase/SupabaseMealPlanRepository.swift`

Change:

- Pass `excludeMealNames` from repository to `GemmaEdgeService.generateDay`.

### `MealPlanHomeView.swift`

Modify:

`iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift`

Changes:

- Maintain `usedMealNames` inside `handleGenerate`.
- Before each daily call, pass `Array(usedMealNames)` as `excludeMealNames`.
- After a day succeeds, insert all generated meal names into `usedMealNames`.
- Keep current retry behavior.
- Retries should use exclusions from previous successful days, not from the failed attempt.
- Do not show cache or AI source in the UI.

### `MealPlanMapper.swift`

Modify only if needed:

`iOS/NutriWeek/NutriWeek/Data/Mappers/MealPlanMapper.swift`

Expected behavior:

- Continue mapping nutrition values into `MealEntry`.
- Ignore cache metadata for domain/UI.
- Preserve decode compatibility by keeping metadata optional in DTOs.

No new visible UI components are needed.

## Data Flow

```text
MealPlanHomeView
  builds week slots
  maintains usedMealNames
  calls repository.generateDay(..., excludeMealNames)

SupabaseMealPlanRepository
  passes request to GemmaEdgeService

GemmaEdgeService
  invokes gemma-generate-day

gemma-generate-day
  validates payload
  queries cached_meals with service_role
  scores/scales candidates
  assembles cached partial day
  calls Gemini for missing meal types
  validates combined day
  writes Gemini meals to cached_meals
  touches cached meal usage
  returns day DTO

MealPlanHomeView
  merges returned day into partialDays
  adds meal names to usedMealNames
  saves final WeeklyPlan
```

## Implementation Order

1. Add `cached_meals` migration.
2. Deploy migration to Supabase.
3. Seed 300-400 meals manually through Supabase SQL editor.
4. Update `gemma-generate-day` schema validation and Gemini prompt to include metadata.
5. Add Supabase service-role REST helper to `gemma-generate-day`.
6. Add cache lookup, hard-tag filtering, candidate scoring, and portion scaling.
7. Add mixed assembly logic.
8. Add Gemini partial-meal prompt and parsing.
9. Add final day validation and full-day Gemini fallback.
10. Add cache write and usage-touch logic.
11. Deploy `gemma-generate-day`.
12. Update Swift DTOs/request payload in `GemmaEdgeService.swift`.
13. Update `MealPlanRepositoryProtocol.swift`.
14. Update `SupabaseMealPlanRepository.swift`.
15. Update `MealPlanHomeView.swift` to pass `excludeMealNames`.
16. Run smoke tests.

## Parallel Work

Can be done in parallel:

- DB migration design and seed meal preparation.
- Swift DTO/request plumbing.
- Edge Function prompt/schema updates.

Must be sequential:

- Cache reads require the migration to be deployed.
- Meaningful cache-hit testing requires seed data.
- iOS `excludeMealNames` requires the Edge Function request contract to accept it.

## Smoke Test Matrix

Test these scenarios before enabling cache reads broadly:

- Empty cache: full Gemini fallback works.
- Fully seeded cache: full-day cache hit works.
- Partial cache: mixed cached + Gemini day works.
- `excludeMealNames` prevents repeated meals across a generated week.
- Vegan hard constraint blocks non-vegan cached meals.
- Gluten-free and nut-free hard constraints block incompatible meals.
- Soft tags influence score but do not block generation.
- Cache write failures do not fail the user request.
- Gemini partial failure falls back to full-day Gemini.
- Existing saved weekly plans still decode on iOS.

## Call Frequency Decision

Keep seven daily calls for this implementation.

Reasons:

- The current UI already supports per-day progress.
- The existing retry behavior is day-level.
- `excludeMealNames` gives enough week-level context.
- Batching can be revisited later after cache quality is proven.

