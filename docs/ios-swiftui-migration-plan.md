# NutriWeek Native iOS Rebuild Plan (SwiftUI, 13-Day Hackathon)

## Executive Context

This document defines the full implementation plan to rebuild the React Native app in `artifacts/mobile/` as a native iOS app in `/iOS/`, without modifying the existing RN code.  
Architecture decisions already fixed: SwiftUI + MVVM + Coordinator, Supabase for auth/database, Supabase Edge Functions for USDA and AI routing, iOS 17 minimum.  
The plan is optimized for a demo-ready MVP in 13 days with controlled technical risk.

---

## 1. Project Structure

### Proposed folder/file tree

```text
/iOS/
  NutriWeek.xcodeproj
  /NutriWeekApp/
    /App/
      NutriWeekApp.swift
      AppDelegate.swift
      RootView.swift
    /Core/
      /Theme/
        AppColors.swift
        Typography.swift
        Spacing.swift
        Radius.swift
        Shadows.swift
      /Components/
        NWButton.swift
        NWCard.swift
        NWTextField.swift
        MacroRingView.swift
        StepProgressView.swift
        RockyMascotView.swift
        LoadingSkeletonView.swift
        ErrorStateView.swift
        ToastView.swift
      /Extensions/
        Date+Format.swift
        Number+Format.swift
      /Resources/
        /Assets.xcassets
          Colors.colorset
          Rocky.imageset
          AppIcon.appiconset
        /Fonts/
          Inter-Regular.ttf
          Inter-Medium.ttf
          Inter-SemiBold.ttf
          Inter-Bold.ttf
      /Constants/
        AppConstants.swift
        ValidationRules.swift
    /Domain/
      /Models/
        UserProfile.swift
        BodyMeasurements.swift
        DailyMacros.swift
        MealEntry.swift
        DayPlan.swift
        WeeklyPlan.swift
        FoodSearchResult.swift
        LogEntry.swift
        CalculationResults.swift
      /Enums/
        Gender.swift
        ActivityLevel.swift
        Goal.swift
        DietaryPreference.swift
        MealType.swift
      /Protocols/
        AuthRepositoryProtocol.swift
        OnboardingRepositoryProtocol.swift
        MealPlanRepositoryProtocol.swift
        FoodLogRepositoryProtocol.swift
      /Services/
        NutritionCalculationService.swift
    /Data/
      /Supabase/
        SupabaseClientFactory.swift
        SupabaseAuthRepository.swift
        SupabaseOnboardingRepository.swift
        SupabaseProfileRepository.swift
      /EdgeFunctions/
        EdgeFunctionClient.swift
        USDAEdgeService.swift
        GemmaEdgeService.swift
      /Persistence/
        CacheStore.swift
        WeeklyPlanCacheStore.swift
        DailyLogCacheStore.swift
      /Mappers/
        ProfileMapper.swift
        MealPlanMapper.swift
        FoodLogMapper.swift
    /Navigation/
      AppCoordinator.swift
      AuthCoordinator.swift
      OnboardingCoordinator.swift
      MainTabCoordinator.swift
      /Routes/
        AppRoute.swift
        OnboardingRoute.swift
    /Features/
      /Auth/
        /Views/
          LoginView.swift
          RegisterView.swift
        /ViewModels/
          LoginViewModel.swift
          RegisterViewModel.swift
      /Onboarding/
        /Views/
          Step1View.swift
          Step2View.swift
          Step3View.swift
          Step4View.swift
          ResultsView.swift
        /ViewModels/
          OnboardingStep1ViewModel.swift
          OnboardingStep2ViewModel.swift
          OnboardingStep3ViewModel.swift
          OnboardingStep4ViewModel.swift
          OnboardingResultsViewModel.swift
      /MealPlan/
        /Views/
          MealPlanHomeView.swift
          DayPlanCardView.swift
          GenerationProgressView.swift
        /ViewModels/
          MealPlanHomeViewModel.swift
      /QuickLog/
        /Views/
          QuickLogView.swift
          FoodSearchResultRow.swift
          PortionSheetView.swift
          TodayLogSheetView.swift
        /ViewModels/
          QuickLogViewModel.swift
      /Profile/
        /Views/
          ProfileView.swift
          EditMeasurementsSheet.swift
        /ViewModels/
          ProfileViewModel.swift
    /DI/
      AppContainer.swift
      RepositoryFactory.swift
    /Support/
      Info.plist
      NutriWeek.entitlements
      Config.xcconfig
      Secrets.xcconfig
  /NutriWeekTests/
    NutritionCalculationServiceTests.swift
    PromptSchemaTests.swift
    RepositoryTests.swift
```

### What goes where and why

- `Core/`: design system + reusable visual primitives, mirroring `artifacts/mobile/components/` and `artifacts/mobile/constants/colors.ts`.
- `Domain/`: pure business contracts and models ported from `artifacts/mobile/constants/types.ts` and `services/calculations.ts`.
- `Data/`: all external IO (Supabase + Edge Functions + local cache), so screens remain testable.
- `Navigation/`: coordinator-based route ownership (replaces Expo router in `artifacts/mobile/app/_layout.tsx`).
- `Features/`: each screen module owns View + ViewModel only.
- `DI/`: wiring dependencies once, avoiding singleton sprawl.

---

## 2. Dependencies

Use Swift Package Manager in Xcode.

| Package | URL | Suggested version rule | Why needed |
|---|---|---|---|
| Supabase Swift | `https://github.com/supabase/supabase-swift` | Up to next major from latest stable (2.x) | Auth, PostgREST, Edge Function invocation |
| SDWebImageSwiftUI (optional) | `https://github.com/SDWebImage/SDWebImageSwiftUI` | Up to next major from latest stable | Only if Rocky/remote media needs async loading |
| swift-snapshot-testing (dev/test optional) | `https://github.com/pointfreeco/swift-snapshot-testing` | Up to next major from latest stable | Fast visual regressions before demo |

No heavy architecture package is required because MVVM + Coordinator is already chosen.

---

## 3. Design System

### Color tokens (ported from `artifacts/mobile/constants/colors.ts`)

- Background: `#FAFAFA`
- Foreground/Text: `#2D2D2D`
- Card: `#FFFFFF`
- Primary/Accent: `#FF6B35`
- Secondary bg: `#FFF3EE`
- Muted: `#F0F0F0`
- Border: `#EFEFEF`
- Success: `#4CAF50`
- Warning: `#FFB300`
- Destructive: `#EF5350`
- Macro colors: Carb `#FF6B35`, Protein `#4CAF50`, Fat `#FFB300`

### Typography

- Font family: Inter (same four weights used in `artifacts/mobile/app/_layout.tsx`).
- Type scale:
  - Display: 32/Bold
  - Title1: 28/SemiBold
  - Title2: 24/SemiBold
  - Heading: 20/SemiBold
  - Body: 16/Regular
  - BodyStrong: 16/Medium
  - Caption: 13/Regular

### Spacing + radius

- Spacing tokens: 4, 8, 12, 16, 20, 24, 32.
- Radius: 8 (`radiusSm`), 16 (`radius`), 24 (`radiusLg`), full pill (`radiusFull`).

### Rocky mascot approach

- Source parity from `artifacts/mobile/components/RockyMascot.tsx`.
- Store Rocky as asset set + optional simple animation (bounce/fade via SwiftUI `withAnimation`).
- Provide one reusable `RockyMascotView` with:
  - `mood` (happy/neutral/encouraging),
  - optional speech bubble text,
  - size variants (small/hero).

### Reusable component list

- `NWButton` (primary, secondary, destructive, loading state)
- `NWCard` (shadow + rounded card shell)
- `NWTextField` (styled text entry + validation message)
- `MacroRingView` (ported visual from `components/MacroRing.tsx`)
- `StepProgressView` (ported from `components/StepProgress.tsx`)
- `LoadingSkeletonView` (ported from `components/SkeletonLoader.tsx`)
- `ErrorStateView` + `ToastView`

---

## 4. Data Layer

### Swift models to create (port from `artifacts/mobile/constants/types.ts`)

- Enums: `Gender`, `ActivityLevel`, `Goal`, `DietaryPreference`, `MealType`
- Structs:
  - `BodyMeasurements`
  - `UserProfile`
  - `DailyMacros`
  - `MealEntry`
  - `DayPlan`
  - `WeeklyPlan`
  - `FoodSearchResult` (from `services/usda.ts`)
  - `LogEntry` (from `services/usda.ts`)
  - `CalculationResults`, `BMICategory`, `MacroGrams`, `MacroPercentages` (from `services/calculations.ts`)

### Repository pattern

- `AuthRepositoryProtocol`
  - signIn, signUp, signOut, currentSession, authStateStream
- `OnboardingRepositoryProtocol`
  - fetchOnboardingProfile, saveStep1/2/3/4, saveResults
- `MealPlanRepositoryProtocol`
  - generateWeeklyPlanViaEdge, loadWeeklyPlan, saveWeeklyPlan
- `FoodLogRepositoryProtocol`
  - searchFoodsViaEdge, addLogEntry, removeLogEntry, loadTodayLog, aggregateMacros

Concrete repos:

- `SupabaseAuthRepository`
- `SupabaseOnboardingRepository`
- `SupabaseProfileRepository`
- `GemmaEdgeService` (through Supabase Function invoke)
- `USDAEdgeService` (through Supabase Function invoke)

### Edge functions needed (high-level)

- `usda-search`
- `gemma-generate-day`
- `gemma-generate-week`
- `nutrition-calc` (optional; keep formulas client-side for now)

---

## 5. Navigation Architecture

### Flow diagram

```text
App Launch
  -> Bootstrap Session
    -> No session -> AuthCoordinator
      -> Login
      -> Register
    -> Session exists -> Check profiles.onboarding_complete
      -> false -> OnboardingCoordinator
        -> Step1 -> Step2 -> Step3 -> Step4 -> Results -> MainTabCoordinator
      -> true -> MainTabCoordinator
        -> Tab: Meal Plan
        -> Tab: Quick Log
        -> Tab: Profile
```

This mirrors behavior in `artifacts/mobile/app/_layout.tsx`, `app/(auth)/_layout.tsx`, and `app/(main)/_layout.tsx`.

### Coordinator implementation plan

- `AppCoordinator`: owns bootstrap and route switching.
- `AuthCoordinator`: login/register stack only.
- `OnboardingCoordinator`: step-by-step path, back/forward logic, completion handoff.
- `MainTabCoordinator`: root `TabView` with three tabs.
- Each coordinator exposes route state to SwiftUI via `@Observable` / `ObservableObject`.

---

## 6. Feature Phases (Day-by-Day)

## Phase 1: Foundation (Day 1-2)

- Create `/iOS/` project and folder skeleton.
- Add dependencies + env config (`Config.xcconfig`, `Secrets.xcconfig`).
- Implement design tokens from `constants/colors.ts`.
- Port calculation engine from `services/calculations.ts` + unit tests.
- Build base coordinators + app bootstrap shell.

**Exit criteria:** app launches, root coordinator works, shared UI kit compiles.

## Phase 2: Auth (Day 3)

- Implement login/register flows from:
  - `app/(auth)/login.tsx`
  - `app/(auth)/register.tsx`
- Hook Supabase auth session listener.
- Route post-auth based on `profiles.onboarding_complete`.

**Exit criteria:** can create account, log in, and route correctly.

## Phase 3: Onboarding (Day 4-5)

- Build Step1-4 + Results from:
  - `app/(onboarding)/step1.tsx`
  - `step2.tsx`
  - `step3.tsx`
  - `step4.tsx`
  - `results.tsx`
- Port validation rules and haptic-equivalent feedback (light impact optional).
- Save all data through onboarding repository into existing schema.

**Exit criteria:** full onboarding completion writes profile + targets + flags.

## Phase 4: Main Screens (Day 6-9)

- Implement tab shell equivalent of `app/(main)/_layout.tsx`.
- Meal Plan screen from `app/(main)/index.tsx` with generation state cards.
- Quick Log screen shell from `app/(main)/log.tsx` (UI + view model, no final API wiring yet).
- Profile screen from `app/(main)/profile.tsx` with read/edit and reset controls.

**Exit criteria:** all three tabs functional with placeholder/real local state.

## Phase 5: AI + USDA Integration (Day 10-11)

- Connect Quick Log to `usda-search` edge function.
- Connect Meal Plan generation to Gemma edge function(s), schema-validated response.
- Replace AsyncStorage-style logic with cache + Supabase-backed persistence path.

**Exit criteria:** meal plans generate from cloud AI, food search/log works end-to-end.

## Phase 6: Polish + Demo (Day 12-13)

- Error states, retries, loading polish, empty states.
- Rocky mascot pass across auth/onboarding/main for brand consistency.
- Regression testing + demo script + smoke test on real device.

**Exit criteria:** stable demo flow from sign-up to meal plan + food log.

---

## 7. Supabase Edge Functions Plan

### 1) `usda-search`

- **Replaces:** current `/api/foods/search` path used in `artifacts/mobile/services/usda.ts`.
- **Input:** `{ query: string, pageSize?: number }`
- **Output:** `{ foods: [{ fdcId, description, foodNutrients[] }] }` or normalized macro fields.
- **Notes:** holds USDA API key on server only; enforce rate limit + timeout.

### 2) `gemma-generate-day`

- **Replaces:** single-day part of `generateSingleDay` in `artifacts/mobile/services/gemma.ts`.
- **Input:** `{ profile, targetCalories, macros, dayName, date }`
- **Output:** `{ day, date, totalCalories, meals[] }`
- **Notes:** strict JSON schema validation before returning.

### 3) `gemma-generate-week`

- **Replaces:** `generateMultiDays` and combined weekly orchestration in `gemma.ts`.
- **Input:** `{ profile, targetCalories, macros, weekStartDate }`
- **Output:** `{ weekOf, days[] }`
- **Notes:** optionally generate server-side in parallel for stability.

### 4) `nutrition-calc` (optional)

- **Replaces:** none mandatory (client already computes via `calculations.ts` logic).
- **Input:** raw profile fields.
- **Output:** bmi/tdee/targets/macros.
- **Use only if:** you need server-authoritative calculations for consistency.

---

## 8. Gemma API Integration Plan

### Model choice

- Start with hosted Gemma endpoint compatible with reliable latency and JSON output controls.
- Keep model config server-side (edge function env var), not in iOS bundle.

### Prompt template strategy

Port constraints from `artifacts/mobile/services/gemma.ts`:

- exact daily calorie target with tolerance,
- macro gram tolerances,
- exactly 4 meals (Breakfast/Lunch/Dinner/Snack),
- dietary restrictions compliance,
- descriptive meal names and emoji,
- strict JSON-only response.

### JSON response schema (canonical)

- Weekly:
  - `weekOf: string`
  - `days: DayPlan[]`
- DayPlan:
  - `day: string`
  - `date: string`
  - `totalCalories: number`
  - `meals: Meal[]`
- Meal:
  - `type: "Breakfast" | "Lunch" | "Dinner" | "Snack"`
  - `name: string`
  - `calories: number`
  - `emoji: string`
  - `protein: number`
  - `carbs: number`
  - `fat: number`

### Error handling strategy

- Edge function wraps provider errors into stable app codes:
  - `AI_TIMEOUT`
  - `AI_UNAVAILABLE`
  - `AI_SCHEMA_INVALID`
  - `AI_RATE_LIMITED`
- iOS fallback:
  - show retry UI,
  - keep last successful plan in cache,
  - optional deterministic fallback day templates (similar intent to `MOCK_PLAN` in `gemma.ts`).

---

## 9. Risk Assessment

| Risk | Impact | Mitigation |
|---|---|---|
| AI response breaks JSON schema | Meal plan generation fails | Validate server-side with strict schema, retry once with repair prompt |
| Edge Function latency spikes | Poor UX during demo | Add loading/progress UI + timeout and graceful retry |
| Supabase auth/session race at launch | Wrong first screen | App bootstrap gate mirrors RN flow in `app/_layout.tsx` |
| Data inconsistency between cache and Supabase | Confusing user state | Define Supabase as source of truth; cache is read-through only |
| USDA quota/rate limit | Search unavailable | Add debounced search + query min length + fallback error copy |
| Scope creep in UI polish | Timeline slip | Freeze MVP UI parity by Day 9, polish only Day 12-13 |
| Real-device env misconfiguration | Demo blocker | Day-1 setup checklist + tested `Secrets.xcconfig` template |

---

## 10. MVP Definition

### Must-have (hackathon demo)

- Auth: sign up, sign in, persistent session.
- Onboarding steps 1-4 + results calculations.
- Meal plan generation via Gemma Edge Function.
- Quick Log food search via USDA Edge Function + add/delete entries.
- Profile read/edit for core fields and measurements.
- Stable navigation flow and branded Rocky presence.

### Nice-to-have

- Advanced streak analytics parity from local RN helpers.
- Rich animations and haptics on every flow.
- Extra nutrition education/fun-fact interactions.

### Definitely defer

- Any local model/Ollama runtime path.
- Complex offline-first bi-directional sync engine.
- Non-essential settings and account management extras.
- Major architecture abstractions beyond MVVM + Coordinator.

---

## Source Mapping References (RN)

- Navigation/bootstrap: `artifacts/mobile/app/_layout.tsx`, `app/(auth)/_layout.tsx`, `app/(main)/_layout.tsx`
- Auth screens: `artifacts/mobile/app/(auth)/login.tsx`, `register.tsx`
- Onboarding screens: `artifacts/mobile/app/(onboarding)/step1.tsx` to `results.tsx`
- Main tabs: `artifacts/mobile/app/(main)/index.tsx`, `log.tsx`, `profile.tsx`
- Core types: `artifacts/mobile/constants/types.ts`
- Design tokens: `artifacts/mobile/constants/colors.ts`
- Calculations: `artifacts/mobile/services/calculations.ts`
- USDA client: `artifacts/mobile/services/usda.ts`
- AI planning: `artifacts/mobile/services/gemma.ts`
- Supabase client/onboarding: `artifacts/mobile/services/supabaseClient.ts`, `services/onboarding.ts`
- DB schema: `artifacts/mobile/supabase/migrations/20260504194500_nutriweek_v1.sql`
