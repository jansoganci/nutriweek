# Home Reorganization Implementation Plan

## Scope
Reorganize `MealPlanHomeView` so Home keeps only the day-to-day meal planning surface, while longer-horizon progress and check-in UI moves into Profile and workout adherence moves into Activity.

This is a planning document only. No application files were changed while preparing it.

## Files Read
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift`
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift`
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift`
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView.swift`
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ActivityLogView.swift`
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/ActivityLogView+Logic.swift`
- `iOS/NutriWeek/NutriWeek/Features/Main/Views/MainTabView.swift`
- `iOS/NutriWeek/NutriWeek/Navigation/MainTabCoordinator.swift`
- `iOS/NutriWeek/NutriWeek/DI/AppContainer.swift`
- `iOS/NutriWeek/NutriWeek/DI/RepositoryFactory.swift`

## Current Baseline

### Home currently contains
- Header: `MealPlanHomeView.swift:151-175`
- Streak chip: `177-194`
- Macro summary + activity CTA: `196-252`
- Personal progress chip grid: `254-301`
- Personal trends insertion: `76-77`
- Weekly summary insertion: `78` plus implementation at `340-475`
- Weekly check-in card: `304-320`
- Recovery check-in card: `322-338`
- Check-in sheets: `122-142`
- Weekly meal plan section: `477-585`
- Generate prompt sheet and toasts: `88-120`, `587-627`

### Profile currently contains
- Title, avatar, stat row, daily targets, personal info, measurements, settings in `ProfileView+Subviews.swift:27-38`
- `ProfileView` has no injected repositories and only owns profile/editing/measurement state: `ProfileView.swift:12-34`
- `loadProfile()` only fetches profile and latest measurements: `ProfileView+Logic.swift:5-85`

### Activity currently contains
- Today card plus two stat cards for week/month in `ActivityLogView.swift:59-74`
- Data load only computes today/week/month calories and entries in `ActivityLogView+Logic.swift:5-33`

## Desired Final Structure

### Home
- Keep:
  - Header
  - Streak chip
  - Macro summary card with rings and remaining calories
  - Activity summary CTA
  - Weekly meal plan section
  - Toast overlays
  - Generate prompt sheet
- Remove:
  - Personal progress section
  - Weekly summary section
  - Personal trends section
  - Weekly and recovery check-in sheets

### Profile
Top-to-bottom order should become:
1. Profile header / avatar
2. Stats row
3. Daily Targets
4. Weekly Summary
5. Personal Trends
6. Weekly Check-in
7. Recovery Check-in
8. Personal Info
9. Body Measurements
10. Settings

### Activity
- Keep the large “today” card
- Expand the secondary stat row to three cards:
  - This Week: kcal
  - This Month: kcal
  - Weekly Goal: `X/Y workouts`

## Cross-Cutting Wiring Changes

### ProfileView constructor must change
Current `ProfileView()` is parameterless at `ProfileView.swift:4-71`.

Add three stored properties:
- `let activityLogRepository: ActivityLogRepositoryProtocol`
- `let foodLogRepository: FoodLogRepositoryProtocol`
- `let mealPlanRepository: MealPlanRepositoryProtocol`

Add a custom init near `ProfileView.swift` before `body`:
- Exact insertion target: after state declarations at `ProfileView.swift:34`, before `body` at `36`

Reason:
- `activityLogRepository` is needed for weekly workout count and weekly burn stats
- `foodLogRepository` is needed for weekly calorie intake and trend snapshot
- `mealPlanRepository` is requested for goal-related data parity, although goal still currently comes from `profiles`; in practice this repository is most useful to keep Profile aligned with Home’s injected dependencies and future-proof plan-derived goal/target reads

### MainTabView must pass repositories into ProfileView
Current profile tab creation: `MainTabView.swift:55-59`

Replace `ProfileView()` with:
- `ProfileView(activityLogRepository: coordinator.activityLogRepository, foodLogRepository: coordinator.foodLogRepository, mealPlanRepository: coordinator.mealPlanRepository)`

### MainTabCoordinator
No new stored properties are required because it already owns all three repositories at `MainTabCoordinator.swift:15-18`.

Impact:
- `MainTabCoordinator` init does not need a signature change
- only the `ProfileView` call site in `MainTabView` changes

### AppContainer and RepositoryFactory
- `AppContainer.swift:20-29` needs no structural change
- `RepositoryFactory.swift:3-16` needs no structural change

## Profile State And Logic Additions

Add to `ProfileView.swift` state block after existing measurement-related state:
- `@State var currentUserId: String?`
- `@State var latestWeeklyCheckIn: WeeklyCheckInRecord?`
- `@State var latestRecoveryCheckIn: RecoveryCheckInRecord?`
- `@State var personalInsightsSnapshot: PersonalInsightsSnapshot?`
- `@State var weeklyActivityCount = 0`
- `@State var weeklyBurnedCalories: Double = 0`
- `@State var showWeeklyCheckInSheet = false`
- `@State var showRecoveryCheckInSheet = false`

Add private helpers to `ProfileView`:
- `private let personalProgressStore = PersonalProgressStore()`
- `private let personalInsightsService: PersonalInsightsService`

Implementation note:
- mirror the Home pattern from `MealPlanHomeView.swift:40-41` and `50-66`
- initialize `personalInsightsService` in the new `ProfileView` init using injected repositories

Extend `.sheet` modifiers in `ProfileView.swift` after the measurement sheet:
- add weekly check-in sheet using the current Home implementation from `MealPlanHomeView.swift:122-131`
- add recovery check-in sheet using the current Home implementation from `133-142`

Extend `loadProfile()` or add a sibling `loadProgressData()` in `ProfileView+Logic.swift`:
- best structure is to keep `loadProfile()` for profile fetch and then call `await loadProgressData(profile:)` after `profile` and `results` are set
- that avoids overloading the profile fetch path with unrelated logic

Recommended new logic methods to add to `ProfileView+Logic.swift`:
- `func loadProgressData() async`
- `func presentWeeklyCheckInSheet()`
- `func presentRecoveryCheckInSheet()`
- helper formatting methods migrated or duplicated from Home:
  - `goalDisplayText`
  - `weeklyWorkoutTarget`
  - `weeklyCheckInDetailText`
  - `recoveryCheckInDetailText`
  - `averageTrendValue(_:)`
  - `weightDeltaText(_:)`
  - `summaryCopy(snapshot:)`
  - `goalSpecificSummary()`

Data sources to reuse:
- Home already computes user id, latest check-ins, trend snapshot, weekly activity count, and weekly burn in `MealPlanHomeView.swift:730-758`
- `PersonalInsightsService.loadSnapshot(days:)` already uses `foodLogRepository.loadEntries(from:to:)` and `activityLogRepository.loadEntries(from:to:)`
- `ActivityLogRepositoryProtocol` already exposes the required weekly range APIs
- `FoodLogRepositoryProtocol` already exposes the required weekly range API

## Move 1: Goal/Target Chips From Home To Profile Daily Targets

### Source to remove from Home
Remove the chip grid entries that correspond to goal/calories/protein from `MealPlanHomeView.swift:266-281`.

Specifically remove:
- goal chip: `267-271`
- calories chip: `272-276`
- protein chip: `277-281`

Do not remove the weekly workout chips here yet if implementing in sequence; those belong to Move 2:
- keep `282-296` until Activity is updated

After Move 2 is complete, remove the remaining workout chips and then delete the whole `personalProgressSection` container.

### Target location in Profile
Modify `dailyTargetsCard(results:)` in `ProfileView+Subviews.swift:86-97`.

Exact insertion target:
- replace the single header `Text(...)` at `88`
- insert a header `HStack` there with:
  - left: `profile.targets.title`
  - right: goal chip/badge using `goalDisplayText`

Then keep macro rows, but confirm the calories and protein rows remain the canonical place for those values:
- calories row already exists at `89`
- protein row already exists at `91`

### State/init changes
- Yes, `ProfileView` init must change because the goal badge logic should use the loaded profile and the section will now also coexist with other moved progress content that depends on repositories

### Data flow implications
- Goal text can come from `profile.goal` after `loadProfile()`, same as Home’s `goalDisplayText`
- Calories/protein values already come from `results.targetCalories` and `results.macros.protein`
- No new repository call is needed specifically for this move

### Recommended UI shape
- Use a compact capsule in the Daily Targets header rather than another full `ProgressChipView`
- Keep macro rows as rows; do not reintroduce the Home chip grid inside Profile

## Move 2: Weekly Workout Adherence Chips To Activity

### Source to remove from Home
Remove these chip entries from `MealPlanHomeView.swift:282-296`:
- weekly target chip: `282-286`
- weekly done chip: `287-291`
- weekly burn chip: `292-296`

Once Moves 1-4 are completed, delete the entire `personalProgressSection` implementation at `254-301`.

Also remove the underlying weekly state from Home after the section is gone:
- `weeklyActivityCount`: `32`
- `weeklyBurnedCalories`: `33`
- the weekly count/burn calculation inside `loadPersonalProgress()`: `740-748`, and matching reset lines `755-756`

### Target location in Activity
Update `summarySection` in `ActivityLogView.swift:59-74`.

Exact insertion target:
- replace the two-card `HStack` at `63-72` with a three-card layout
- append a third `statCard` after the month card for weekly goal progress

Expected text:
- `Weekly Goal: X/Y workouts`

### State/init changes
Add new Activity state in `ActivityLogView.swift` near existing summary state:
- `@State var weeklyWorkoutCount = 0`
- `@State var weeklyWorkoutGoal = 0`

No Activity init signature change is required if the goal is derived from user profile loaded inside Activity.

### Data flow implications
Activity needs two pieces of data:
- actual weekly workout count: derive from `repository.loadEntries(from:to:)`
- target weekly workout goal: derive from the current user profile activity level, using the same mapping Home uses in `MealPlanHomeView.swift:936-948`

Recommended implementation in `ActivityLogView+Logic.swift`:
- after loading weekly entries, assign `weeklyWorkoutCount = entries.count`
- fetch the profile activity level through `OnboardingService.fetchOnboardingProfile()` or the same profile source used by Home/Profile, then map:
  - sedentary -> 2
  - lightlyActive -> 3
  - moderatelyActive -> 4
  - veryActive / extraActive -> 5

Reason for not passing this from Home:
- Activity should own its own summary state
- avoids cross-tab state coupling

## Move 3: Weekly Check-In Card And Sheet To Profile

### Source to remove from Home
Remove:
- body sheet modifier: `MealPlanHomeView.swift:122-131`
- card view: `304-320`
- presentation helper: `760-763`
- state:
  - `latestWeeklyCheckIn`: `34`
  - `showWeeklyCheckInSheet`: `37`

Do not remove `currentUserId` yet if Recovery also still depends on it.

### Target location in Profile
Insert a new section in `ProfileView+Subviews.swift` inside `content(profile:results:)`.

Exact insertion target in the content stack:
- current order is `34` daily targets, `35` personal info, `36` measurements
- insert the Weekly Check-in section after Daily Targets and before Personal Info

Once Weekly Summary and Trends are also added, the final placement should be:
- after Weekly Summary and Personal Trends
- before Recovery Check-in if following the exact requested final order

Recommended approach:
- add a dedicated `weeklyCheckInCard` view method in `ProfileView+Subviews.swift`
- reuse the Home card design by migrating `progressActionCard(...)` from `MealPlanHomeView.swift:431-475`

### State/init changes
- Yes, `ProfileView` needs new sheet state and `currentUserId`
- `ProfileView` init change is not caused only by this move, but this move relies on the broader Profile state expansion

### Data flow implications
- `ProfileView` needs `currentUserId` populated when loading
- `latestWeeklyCheckIn` should be loaded via `PersonalProgressStore.latestWeeklyCheckIn(userId:)`
- saving from `WeeklyCheckInSheet` should refresh Profile progress data, not just basic profile data

Recommended sheet callback:
- `onSaved: { await loadProgressData() }`

## Move 4: Recovery Check-In Card And Sheet To Profile

### Source to remove from Home
Remove:
- body sheet modifier: `MealPlanHomeView.swift:133-142`
- card view: `322-338`
- presentation helper: `765-768`
- state:
  - `latestRecoveryCheckIn`: `35`
  - `showRecoveryCheckInSheet`: `38`

### Target location in Profile
Insert a new Recovery Check-in section in `ProfileView+Subviews.swift`.

Exact insertion target:
- below the new Weekly Check-in section
- above Personal Info in the intermediate implementation
- in the final structure, keep it below Weekly Check-in and above Personal Info

Implementation approach:
- add `recoveryCheckInCard` beside `weeklyCheckInCard`
- reuse `progressActionCard(...)` styling from Home

### State/init changes
- Same Profile sheet/state expansion as Move 3

### Data flow implications
- `latestRecoveryCheckIn` comes from `PersonalProgressStore.latestRecoveryCheckIn(userId:)`
- save callback should refresh only progress-related state, though `loadProfile()` is acceptable if simplicity is preferred

## Move 5: Weekly Summary Section To Profile

### Source to remove from Home
Remove:
- body insertion from Home stack: `MealPlanHomeView.swift:78`
- summary view implementation: `340-397`
- summary helper methods:
  - `summaryCopy(snapshot:)`: `399-414`
  - `goalSpecificSummary()`: `416-429`
  - `averageTrendValue(_:)`: `972-976`
  - `weightDeltaText(_:)`: `978-985`

Keep `oneDecimal(_:)` somewhere shared or duplicate it in Profile; Home still needs its own local formatter for other uses.

### Target location in Profile
Insert a new `weeklySummarySection(snapshot:)` into `ProfileView+Subviews.swift`.

Exact insertion target in the content stack:
- after `dailyTargetsCard(results: results)` at current line `34`
- before Personal Info at current line `35`

After all moves settle, reorder to:
- `dailyTargetsCard`
- `weeklySummarySection`
- `PersonalTrendSectionView`
- `weeklyCheckInCard`
- `recoveryCheckInCard`

### State/init changes
- Requires `@State var personalInsightsSnapshot`
- Requires weekly workout count/burn state in Profile
- Requires `personalInsightsService` initialization in `ProfileView`

### Data flow implications
The summary currently depends on two data sources:
- `personalInsightsSnapshot` for avg intake, avg burn, and weight trend
- `weeklyActivityCount` and `weeklyWorkoutTarget` for the “on track / behind” copy and workout stat

That can be recreated in Profile without any new repository methods:
- `PersonalInsightsService.loadSnapshot(days: 7)` already provides the trend snapshot
- `activityLogRepository.loadEntries(from:to:)` provides the weekly workout count

## Move 6: Personal Trends To Profile

### Source to remove from Home
Remove the body insertion from `MealPlanHomeView.swift:76-77`.

No helper code needs to move because `PersonalTrendSectionView` already exists elsewhere.

### Target location in Profile
Insert `PersonalTrendSectionView(snapshot: personalInsightsSnapshot)` in `ProfileView+Subviews.swift` content stack.

Exact insertion target:
- after the new Weekly Summary section
- before Weekly Check-in

### State/init changes
- none beyond the same `personalInsightsSnapshot` state required for Move 5

### Data flow implications
- no extra calls beyond `PersonalInsightsService.loadSnapshot(days: 7)`

## Home Cleanup After All Moves

### Remove from Home body
Delete these stack entries from `MealPlanHomeView.swift:75-79`:
- `personalProgressSection`
- `if let personalInsightsSnapshot { ... }`

After cleanup, Home stack should read:
- `header`
- `streakRow`
- `macroSummary`
- `weeklySection`

### Remove from Home sheets
Delete these `.sheet` blocks:
- weekly check-in sheet: `122-131`
- recovery check-in sheet: `133-142`

Keep:
- generate prompt sheet: `117-121`

### Remove from Home state and services
Delete if no longer referenced:
- `currentUserId`: `31`
- `weeklyActivityCount`: `32`
- `weeklyBurnedCalories`: `33`
- `latestWeeklyCheckIn`: `34`
- `latestRecoveryCheckIn`: `35`
- `personalInsightsSnapshot`: `36`
- `showWeeklyCheckInSheet`: `37`
- `showRecoveryCheckInSheet`: `38`
- `personalProgressStore`: `40`
- `personalInsightsService`: `41`

### Remove from Home helper views and methods
Delete if fully migrated:
- `personalProgressSection`: `254-301`
- `weeklyCheckInCard`: `304-320`
- `recoveryCheckInCard`: `322-338`
- `weeklySummarySection`: `340-397`
- `summaryCopy(snapshot:)`: `399-414`
- `goalSpecificSummary()`: `416-429`
- `progressActionCard(...)`: `431-475`
- `loadPersonalProgress()`: `730-758`
- `presentWeeklyCheckInSheet()`: `760-763`
- `presentRecoveryCheckInSheet()`: `765-768`
- `goalDisplayText`: `912-924`
- `targetCaloriesText`: `926-929`
- `proteinTargetText`: `931-934`
- `weeklyWorkoutTarget`: `936-948`
- `weeklyCheckInDetailText`: `950-957`
- `recoveryCheckInDetailText`: `959-966`
- `averageTrendValue(_:)`: `972-976`
- `weightDeltaText(_:)`: `978-985`
- `averageNumericValue(_:)`: `987-990`

### Home initialization change
Update `initialize()` in `MealPlanHomeView.swift:646-653`:
- remove `await loadPersonalProgress()` at `651`

## Recommended Profile Content Order Update

Update `ProfileView+Subviews.swift:30-37` from:
- title
- avatar
- stats
- daily targets
- personal info
- measurements
- settings

To:
- title
- avatar
- stats
- daily targets
- weekly summary
- personal trends
- weekly check-in
- recovery check-in
- personal info
- measurements
- settings

## Recommended Activity Logic Update

Update `ActivityLogView+Logic.swift:10-30` so the weekly calculation path does not recompute from separate sources.

Suggested pattern:
1. derive `weekInterval`
2. fetch `weekEntries = repository.loadEntries(from: weekInterval.start, to: weekInterval.end)`
3. assign:
   - `weeklyWorkoutCount = weekEntries.count`
   - `weeklyCalories = weekEntries.reduce(0) { $0 + $1.caloriesBurned }`
4. derive `weeklyWorkoutGoal` from profile activity level

This avoids two separate weekly fetches just to get count and total.

## Sequencing Plan

1. Expand `ProfileView` init and state.
2. Add Profile progress-loading logic and sheet support.
3. Move Weekly Summary and Personal Trends into Profile.
4. Move Weekly Check-in and Recovery Check-in cards and sheets into Profile.
5. Add the Activity weekly goal card and logic.
6. Remove remaining Home progress UI, state, and helpers.
7. Verify final section order in Profile.

Reason for this order:
- it keeps the moved UI functional before deleting the Home source
- it minimizes temporary broken references

## Risks And Decisions

### Risk: duplicate weekly goal mapping
Current weekly workout target logic only exists in Home at `MealPlanHomeView.swift:936-948`.

Recommendation:
- extract this mapping into a small shared helper later if it starts being used by both Profile and Activity
- for the reorganization change itself, duplication is acceptable if kept local and identical

### Risk: mixed profile sources
Home currently gets `currentProfile` through `OnboardingService.fetchOnboardingProfile()` while Profile builds `UserProfile` directly from Supabase rows.

Recommendation:
- use Profile’s already-loaded `profile` as the authoritative source for goal/activity level inside Profile
- use the same Supabase/onboarding-derived activity-level mapping inside Activity
- do not make Profile depend on `mealPlanRepository` for goal display unless a later cleanup intentionally centralizes profile derivation

### Risk: stale progress after sheet save
If the save callbacks call only `loadProfile()`, the check-in cards may refresh but do extra work.

Recommendation:
- prefer a dedicated `loadProgressData()` callback for check-in sheets
- keep `loadProfile()` for measurement/profile edits

## Verification Checklist
- Home shows only header, streak, macro summary, weekly plan, toasts, and generate prompt sheet
- Profile shows weekly summary, trends, weekly check-in, and recovery check-in in the requested order
- Profile Daily Targets header includes the goal badge
- Activity shows a third summary stat card with `X/Y workouts`
- Weekly check-in and recovery sheets still open and refresh correctly from Profile
- No Home references remain to moved check-in/trend/weekly-summary state
