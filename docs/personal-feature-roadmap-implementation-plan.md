# NutriWeek Personal Feature Roadmap Implementation Plan

## Purpose

This document turns [personal-feature-roadmap.md](personal-feature-roadmap.md) into an execution plan.

It assumes the current codebase state as of 2026-05-17:

- meal planning exists
- food logging exists
- activity logging exists
- measurements and profile tracking exist
- Turkish localization has already been cleaned up

The goal here is to add the personal-use features in three phases, from fastest to longest.

## Principles

- Reuse existing data and UI patterns before adding new schema.
- Prefer local aggregation over new backend work when the data already exists.
- Keep everything useful for a personal fitness notebook, not a commercial product.
- Do not add HealthKit in this plan. That is tracked separately.

## Phase 1: Fast Wins

This phase should be implementable with the least structural change.

### 1. Weekly Check-In Card

#### What it should do

- Show a weekly snapshot of:
  - weight
  - waist measurement
  - number of workouts this week
  - energy level
  - motivation level
- Keep input lightweight.
- Make it quick enough to fill in once per week.

#### Files to change

- `iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift`
  - add a weekly check-in card near the top of the home dashboard
  - wire it to existing profile, measurement, and activity data
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView.swift`
  - add an entry point for editing the check-in values if needed
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift`
  - compute or fetch the current weekly snapshot inputs
- `iOS/NutriWeek/NutriWeek/Localizable.xcstrings`
  - add labels for weekly check-in title, subtitle, and inputs

#### Data / schema impact

- No new migration required if the check-in is derived from existing data and a simple local note model is not needed.
- If weekly check-in values are stored, add a small new table later in Phase 3 rather than blocking Phase 1.

#### API / service impact

- No new remote API required for a derived version.
- If stored weekly check-ins are added, introduce a small repository protocol and Supabase implementation.

### 2. Hedef Cipsi

#### What it should do

- Show goal chips such as:
  - workout target
  - protein target
  - water target
  - sleep target
- Keep them readable at a glance on the main screen.

#### Files to change

- `iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift`
  - add chips next to the summary or progress area
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift`
  - reuse profile goal values when available
- `iOS/NutriWeek/NutriWeek/Domain/Models/UserProfile.swift`
  - no schema change unless we add user-editable goal preferences
- `iOS/NutriWeek/NutriWeek/Localizable.xcstrings`
  - add chip labels and short goal strings

#### Data / schema impact

- No migration required if chips are derived from existing onboarding/profile targets.

#### API / service impact

- No API changes required for the derived version.

### 3. Recovery Check-In

#### What it should do

- Capture a short self-assessment:
  - sleep
  - soreness
  - energy
  - hunger
  - stress
- Present it as a quick daily or post-workout check-in.

#### Files to change

- `iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift`
  - add a quick recovery card or callout
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ActivityLogView.swift`
  - optionally add a “how do you feel?” quick action from the activity area
- `iOS/NutriWeek/NutriWeek/Localizable.xcstrings`
  - add labels and short response phrases

#### Data / schema impact

- No migration required if treated as a UI-only prompt.
- If persisted, add a small note/check-in table in Phase 3.

#### API / service impact

- No API changes required for the UI-only version.

## Phase 2: Medium Effort, High Value

These features are still practical, but they need more UI/state work than Phase 1.

### 4. Trend Graphs

#### What it should do

- Visualize:
  - 7-day weight average
  - waist trend
  - weekly workout count
  - daily calorie average
  - protein compliance

#### Files to change

- `iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift`
  - add an overview section that links to graphs
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift`
  - optionally surface trends in profile stats
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/MeasurementLogSheet.swift`
  - no core change required unless adding extra trend anchors
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ActivityLogView.swift`
  - optionally add a small history/trend entry point
- `iOS/NutriWeek/NutriWeek/Localizable.xcstrings`
  - add chart titles and axis labels

#### Data / schema impact

- No migration required for the first version because the app already has:
  - weight / body measurements
  - meal logs
  - activity logs

#### API / service impact

- No new API required.
- Charts can be built from locally loaded data.

#### Likely implementation note

- Use Swift Charts if possible.
- Start with simple line charts and bar charts.

### 5. Tekrar Eklenen Öğünler

#### What it should do

- Allow frequently eaten foods or meals to be re-added quickly.
- Reduce friction for repetitive logging.

#### Files to change

- `iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView.swift`
  - add a favorite/recent shortcut area
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Logic.swift`
  - store and reuse recent quick picks
- `iOS/NutriWeek/NutriWeek/Data/Persistence/DailyLogCacheStore.swift`
  - optionally store recent food picks locally
- `iOS/NutriWeek/NutriWeek/Localizable.xcstrings`
  - add labels for favorites/recent items

#### Data / schema impact

- No migration required for a local-recent-items version.
- If a server-backed favorites table is preferred later, add it in Phase 3.

#### API / service impact

- No API changes required for a local-only version.

### 6. Basit Workout Log Genişletmesi

#### What it should do

- Expand the current activity log into a more strength-oriented tracker:
  - exercise name
  - sets
  - reps
  - weight
  - effort note

#### Files to change

- `iOS/NutriWeek/NutriWeek/Domain/Models/ActivityLogEntry.swift`
  - add optional workout fields, or define a separate workout entry model
- `iOS/NutriWeek/NutriWeek/Domain/Services/Protocols/ActivityLogRepositoryProtocol.swift`
  - extend the protocol if the same table is reused
- `iOS/NutriWeek/NutriWeek/Data/Supabase/SupabaseActivityLogRepository.swift`
  - map the new fields
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ActivityLogEntrySheet.swift`
  - add the new form controls
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ActivityLogView.swift`
  - show the extra metadata in row cards
- `iOS/NutriWeek/NutriWeek/Localizable.xcstrings`
  - add labels for sets, reps, weight, and effort

#### Data / schema impact

- This likely needs a migration.
- Best options:
  - extend `activity_log` with nullable workout columns, or
  - introduce a separate `workout_log` table

#### API / service impact

- If the current activity model is extended, repository methods need updates.
- If a new table is introduced, add a new repository and UI view path.

## Phase 3: Heaviest / Most Structural

These are the most expensive features and should be left for last.

### 7. Weekly Summary

#### What it should do

- Generate a weekly summary card that combines:
  - calorie average
  - protein target adherence
  - workout count
  - weight change
  - waist change
  - streak status

#### Files to change

- `iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift`
  - add a weekly summary section
- `iOS/NutriWeek/NutriWeek/Data/Services/PersonalInsightsService.swift`
  - compute summary values from profile, measurements, and logs
- `iOS/NutriWeek/NutriWeek/Data/Persistence/*`
  - optional cache for summary snapshots if performance needs it
- `iOS/NutriWeek/NutriWeek/Localizable.xcstrings`
  - add summary labels and helper copy

#### Data / schema impact

- No migration required if the summary is fully derived.
- If a historical summary snapshot is needed, add a new cache table later.

#### API / service impact

- No new API required for a derived summary.
- Optional new service layer can be added to centralize summary math.

## Recommended Build Order

If the goal is to deliver quickly with low risk:

1. Weekly check-in card
2. Hedef çipleri
3. Recovery check-in
4. Trend graphs
5. Tekrar eklenen öğünler
6. Basit workout log genişletmesi
7. Weekly summary

## Decision Points Before Implementation

Before coding, decide these items:

- Should weekly check-in values be fully derived or user-edited and persisted?
- Should the workout log be extended inside `activity_log` or split into a new table?
- Should favorites/recent meals be local-only or synced to Supabase?
- Should the weekly summary be just a visual aggregate or a stored snapshot?

## Definition of done

This roadmap is complete when:

- the implementation plan is frozen into phases
- each phase has a clear file list and schema impact
- the team can execute phase-by-phase without inventing architecture mid-way
