# NutriWeek Implementation Plan: Activity / Calorie Burn Tracking

## Scope and constraints

This is a planning artifact only. It reflects the codebase as inspected on 2026-05-17 and does not make source changes itself.

Relevant context reviewed:

- [MainTabCoordinator.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Navigation/MainTabCoordinator.swift)
- [MainTabView.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MainTabView.swift)
- [AppContainer.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/DI/AppContainer.swift)
- [RepositoryFactory.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/DI/RepositoryFactory.swift)
- [nutriweek_v1.sql](/Users/jans/Downloads/NutriWeek-Planner/supabase/migrations/20260504194500_nutriweek_v1.sql)
- [MealPlanHomeView.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift)
- [SupabaseFoodLogRepository.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Data/Supabase/SupabaseFoodLogRepository.swift)
- [FoodLogRepositoryProtocol.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Domain/Services/Protocols/FoodLogRepositoryProtocol.swift)
- [LogView.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView.swift)
- [MeasurementLogSheet.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MeasurementLogSheet.swift)
- [Localizable.xcstrings](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Localizable.xcstrings)

## Goal

Add a first-class Activity tab and data model so users can:

- Log activities with `activity_name`, `duration_minutes`, `calories_burned`, `logged_at`, and optional `notes`
- See today's burned calories
- Browse a descending history list of activity entries
- See weekly and monthly totals
- Open the Activity area directly from the Meal Plan home screen

The implementation should follow the existing SwiftUI + Supabase architecture and reuse the current design system tokens and shared components.

## Current architecture implications

The app currently uses:

- `MainTabCoordinator.Tab` with `mealPlan`, `quickLog`, and `profile`
- `MainTabView` as the actual `TabView`
- `RepositoryFactory` as the central repository wiring point
- `AppContainer` to assemble the coordinator graph
- Supabase repository implementations that follow a simple `requireUserId()` pattern and query the user-owned table directly

The existing food log implementation is the closest template. The new activity feature should mirror that structure rather than introducing a different pattern.

## Data model and database plan

### Proposed table

Create a new migration:

- `supabase/migrations/20260517120000_activity_log.sql`

Use the same schema conventions as the rest of the project:

- `id uuid primary key default gen_random_uuid()`
- `user_id uuid not null references auth.users(id) on delete cascade`
- `activity_name text not null`
- `duration_minutes integer not null`
- `calories_burned numeric not null`
- `notes text null`
- `logged_at date not null default current_date`
- `created_at timestamptz not null default now()`

### RLS and indexing

Add the same own-row policies used by the other user-owned tables:

- `select` own rows
- `insert` own rows
- `update` own rows
- `delete` own rows

Add an index for the common access pattern:

- `(user_id, logged_at desc)`

### Validation rules

The database migration should enforce the shape, but the UI must also validate:

- `activity_name` is required and free text, not a fixed enum
- `duration_minutes` must be an integer greater than 0
- `calories_burned` must be greater than 0
- `logged_at` defaults to today but can be edited
- `notes` remains optional

## iOS architecture plan

Follow the same split that `LogView` already uses:

- `ActivityLogView.swift` for the container screen
- `ActivityLogView+Logic.swift` for async loading, filtering, totals, and CRUD actions
- `ActivityLogEntrySheet.swift` for the add/edit form

Keep the domain and repository layers parallel to the food log pattern:

- `ActivityLogEntry.swift`
- `ActivityLogRepositoryProtocol.swift`
- `SupabaseActivityLogRepository.swift`

Do not introduce a fixed enum for activities. This should stay free text from day one.

## UI and behavior plan

### Activity screen

The Activity tab should feel like the existing Log screen:

- A centered title/header
- A lightweight search/filter bar for activity name and notes
- A summary block for today, week, and month
- A descending history list grouped by date or sorted strictly by `logged_at desc`
- A floating or prominent add button to create a new entry
- Error handling via `ErrorStateView`
- Success feedback via `ToastView`

The screen should use the same visual language as the rest of the app:

- `TypographyToken`
- `ColorToken`
- `SpacingToken`
- existing card, border, and shadow treatment

### Filtering and totals

The simplest implementation is:

- Load the user's activity entries ordered by `logged_at desc, created_at desc`
- Compute today, week, and month totals in memory from the loaded entries
- Apply the search filter locally

This keeps the repository surface small and matches the current food log style. If the team later sees large histories, pagination or server-side date-range queries can be added without changing the UI contract.

### Add/edit sheet

The form should include:

- `activity_name` text field
- `duration_minutes` numeric field
- `calories_burned` numeric field
- `logged_at` date picker
- optional `notes` multi-line field

Behavior requirements:

- Default the date to today
- Validate required fields before save
- Keep the form clean and simple
- Confirm discard on dismiss if the form has unsaved changes

The discard-confirmation behavior should be implemented in the sheet itself, not in the tab coordinator.

### Meal Plan home integration

`MealPlanHomeView` should show a small tappable summary such as:

- `🔥 X kcal burned today`

This summary should act as a shortcut to the Activity tab.

Keep the current quick action for Log if desired, but do not reuse the same button for both flows. The home screen should clearly separate:

- quick food logging
- activity summary / activity navigation

## Files to create

Create these new files:

- `supabase/migrations/20260517120000_activity_log.sql` - new `activity_log` table, RLS policies, and index
- `iOS/NutriWeek/NutriWeek/Domain/Models/ActivityLogEntry.swift` - domain model for a single activity record
- `iOS/NutriWeek/NutriWeek/Domain/Services/Protocols/ActivityLogRepositoryProtocol.swift` - repository interface for loading, adding, updating, deleting, and summarizing activity logs
- `iOS/NutriWeek/NutriWeek/Data/Supabase/SupabaseActivityLogRepository.swift` - Supabase-backed implementation that follows the `SupabaseFoodLogRepository` pattern
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ActivityLogView.swift` - Activity tab container view
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ActivityLogView+Logic.swift` - async loading, filtering, totals, add/edit/delete actions, and state management
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ActivityLogEntrySheet.swift` - add/edit modal with validation and unsaved-change confirmation

If the Xcode project does not automatically track new source files, the project file will also need to be updated to include these new Swift files in the NutriWeek target.

## Files to modify

Update the following existing files:

- `iOS/NutriWeek/NutriWeek/Navigation/MainTabCoordinator.swift`
  - Add the new `activity` tab case
  - Store an `activityLogRepository`
  - Extend the initializer to accept the new repository
  - Keep `quickLog` for the existing Log tab unless the team wants a rename pass

- `iOS/NutriWeek/NutriWeek/Features/Main/Views/MainTabView.swift`
  - Insert the Activity tab in the correct order: Meal Plan -> Log -> Activity -> Profile
  - Use a flame icon for the Activity tab
  - Wire the `ActivityLogView` to the new repository
  - Add the home-screen callback that switches to the Activity tab

- `iOS/NutriWeek/NutriWeek/DI/RepositoryFactory.swift`
  - Add `activityLogRepository` to the factory
  - Instantiate `SupabaseActivityLogRepository` in `static let live`

- `iOS/NutriWeek/NutriWeek/DI/AppContainer.swift`
  - Pass the activity repository through when constructing `AppCoordinator`

- `iOS/NutriWeek/NutriWeek/Navigation/AppCoordinator.swift`
  - Extend the initializer to accept the activity repository
  - Forward it into `MainTabCoordinator`

- `iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift`
  - Add a small, tappable today burned-calories summary
  - Add a new callback for switching to the Activity tab
  - Keep the current meal/log shortcut behavior intact

- `iOS/NutriWeek/NutriWeek/Localizable.xcstrings`
  - Add all Activity tab labels, field labels, validation strings, empty states, error states, toast messages, and summary copy
  - Add keys for the new home-screen summary text

- `iOS/NutriWeek/NutriWeek.xcodeproj/project.pbxproj`
  - Register the new Swift files and the migration-friendly target membership if the project is managed manually

## Localization plan

Add keys for the Activity feature in the existing string catalog rather than hardcoding English in the SwiftUI views.

Recommended key groups:

- `activity.title`
- `activity.today_summary`
- `activity.week_summary`
- `activity.month_summary`
- `activity.search.placeholder`
- `activity.empty.title`
- `activity.empty.subtitle`
- `activity.error.load_title`
- `activity.error.load_message`
- `activity.entry.title_add`
- `activity.entry.title_edit`
- `activity.entry.name_label`
- `activity.entry.duration_label`
- `activity.entry.calories_label`
- `activity.entry.date_label`
- `activity.entry.notes_label`
- `activity.entry.discard_title`
- `activity.entry.discard_message`
- `activity.toast.saved_title`
- `activity.toast.saved_subtitle`
- `activity.toast.updated_title`
- `activity.toast.updated_subtitle`
- `activity.toast.deleted_title`
- `activity.toast.deleted_subtitle`
- `activity.home_summary`

The exact key names can be adjusted to match the project's existing catalog style, but they should be consistent and descriptive.

## Implementation order

1. Database migration
   - Add the `activity_log` table, RLS policies, and `(user_id, logged_at desc)` index
   - Keep the schema aligned with existing user-owned tables

2. Domain models and protocol
   - Add `ActivityLogEntry`
   - Define `ActivityLogRepositoryProtocol`
   - Include the operations needed for list, add, edit, delete, and totals

3. Repository implementation
   - Implement `SupabaseActivityLogRepository`
   - Use the same `requireUserId()` pattern as `SupabaseFoodLogRepository`
   - Query rows ordered by date descending
   - Map Supabase rows to the domain model and back

4. Coordinator and DI updates
   - Update `RepositoryFactory`
   - Update `AppContainer`
   - Update `AppCoordinator`
   - Update `MainTabCoordinator`

5. Activity list view
   - Create `ActivityLogView`
   - Add view logic, totals, search/filter, loading, error handling, and delete flow
   - Match the list + search + add-button pattern used by `LogView`

6. Add entry sheet
   - Create `ActivityLogEntrySheet`
   - Add form validation for required fields and positive values
   - Implement unsaved-change confirmation before dismiss

7. Tab bar integration
   - Add the new Activity tab to `MainTabView`
   - Preserve the required order: Meal Plan -> Log -> Activity -> Profile

8. Home screen summary
   - Add the tappable "X kcal burned today" summary to `MealPlanHomeView`
   - Wire it to switch to the Activity tab

9. Localization
   - Add the new keys to `Localizable.xcstrings`
   - Replace any remaining hardcoded strings in the new feature files

10. Build verification
   - Confirm the app compiles on iOS 17+
   - Verify the tab order and icons
   - Verify activity create/edit/delete flows
   - Verify today/week/month totals refresh correctly
   - Verify RLS blocks cross-user access
   - Verify the home summary opens Activity

## Risks and notes

- `activity_name` should stay free text. Do not lock it to a predefined enum.
- `duration_minutes` and `calories_burned` are required and must be greater than zero on both client and database sides.
- `logged_at` should default to today, but the user must be allowed to change it.
- The dismiss flow for the entry sheet should protect against accidental data loss when the form is dirty.
- If history size becomes large, the initial "load all and aggregate locally" approach can be upgraded to paginated or date-range queries without changing the UI contract.

## Definition of done

The feature is complete when:

- The database migration exists and applies cleanly
- The iOS domain, repository, and UI layers compile
- The app shows a 4th Activity tab in the correct order
- Users can add, edit, delete, and browse activity entries
- The home screen shows today's burned calories and navigates to Activity
- Weekly and monthly totals are visible and correct
- All new strings are localized through `Localizable.xcstrings`
- The app still builds cleanly after the new files are added to the Xcode target

## Remaining Work, Fastest to Longest

### 1. Search / filter on the activity list

Why first:

- Smallest surface area
- Reuses the existing list view
- No schema changes
- No repo changes if filtering stays local

How to implement:

- Add `@State private var query = ""` in `ActivityLogView`
- Add a search bar near the summary cards
- Filter `entries` by `activityName` and `notes`
- Keep filtering local at first

Expected effort:

- low

### 2. Edit existing activity entries

Why second:

- `updateEntry(_:)` already exists in the protocol and repository
- You only need to wire UI access to a prefilled sheet
- This gives immediate value for fixing mistakes

How to implement:

- Add an edit swipe action or row tap
- Open `ActivityLogEntrySheet` in edit mode with an existing entry
- Reuse the same form for create and update
- Call `repository.updateEntry(_:)` when editing

Expected effort:

- low to medium

### 3. Unsaved changes confirmation

Why third:

- It is mostly UI state logic
- Important for preventing accidental data loss
- Depends on the edit/create sheet being reusable

How to implement:

- Track a draft copy of the entry form state
- Compare current inputs against the initial values
- If dirty, show a discard confirmation before dismiss

Expected effort:

- medium

### 4. Date grouping in the list

Why fourth:

- Improves readability once the list gets long
- Helpful for weekly review
- Slightly more work than simple sorting

How to implement:

- Group entries by `loggedAt` day
- Render section headers like `Today`, `Yesterday`, or full date
- Keep total calculations unchanged

Expected effort:

- medium

### 5. Strength-focused workout fields

Why fifth:

- Best for muscle gain tracking
- Useful, but not required for a first good version
- Expands the schema and form complexity

How to implement:

- Add optional fields such as `exercise_name`, `sets`, `reps`, `weight`
- Keep `activity_name` as the top-level label
- Decide whether this is a second table or an extended single table

Expected effort:

- medium to high

## Suggested Next Sprint

If you want the fastest useful improvement, do these in order:

1. Search / filter
2. Edit existing entries
3. Unsaved changes confirmation
4. Date grouping

That sequence gives you the most value with the least implementation risk.
