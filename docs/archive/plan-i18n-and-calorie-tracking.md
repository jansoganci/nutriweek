# NutriWeek Implementation Plan: i18n, Turkish Meal Names, and Calorie Tracking

## Scope and constraints

This document is a planning artifact only. It reflects the current state of the codebase as inspected on 2026-05-16 and does not propose any source edits in this file itself.

Relevant context reviewed:

- [docs/analysis-2026-05-15.md](/Users/jans/Downloads/NutriWeek-Planner/docs/analysis-2026-05-15.md)
- [MealPlanHomeView.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift)
- [ProfileView+Subviews.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift)
- [ProfileView+Logic.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift)
- [LogView+Subviews.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Subviews.swift)
- [MealPlanMapper.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Data/Mappers/MealPlanMapper.swift)
- [GemmaEdgeService.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Data/EdgeFunctions/GemmaEdgeService.swift)
- [supabase/functions/gemma-generate-day/index.ts](/Users/jans/Downloads/NutriWeek-Planner/supabase/functions/gemma-generate-day/index.ts)
- [OnboardingStep2View.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift)
- [AppContainer.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/DI/AppContainer.swift)

## Current state summary

The project currently has no Turkish localization configured at the Xcode project level. `developmentRegion = en` and `knownRegions = (en, Base)` are present in [project.pbxproj](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek.xcodeproj/project.pbxproj:137), with no `tr` region declared.

Meal names are rendered verbatim from the backend in [MealPlanHomeView.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:668). The day-generation edge function prompt is written in English and currently does not require Turkish dish names in either `buildFullDayPrompt()` or `buildPartialMealsPrompt()` in [index.ts](/Users/jans/Downloads/NutriWeek-Planner/supabase/functions/gemma-generate-day/index.ts:238) and [index.ts](/Users/jans/Downloads/NutriWeek-Planner/supabase/functions/gemma-generate-day/index.ts:267). The mapper also only recognizes English meal type tokens in [MealPlanMapper.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Data/Mappers/MealPlanMapper.swift:90).

Calorie targets are currently system-derived from onboarding/profile data and displayed in the home view. There is no user-owned override field in the profile fetch/upsert path in [ProfileView+Logic.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:11), no corresponding input in [ProfileView+Subviews.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:108), and no override field in the `GemmaPlanTargets` or `GemmaGenerateDayRequest` payloads in [GemmaEdgeService.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Data/EdgeFunctions/GemmaEdgeService.swift:3).

## Delivery strategy

Implement in two phases:

1. Phase 1: i18n foundation plus Turkish meal-name consistency.
2. Phase 2: calorie target lock, persistence, and tracking.

This order matters. Phase 1 stabilizes user-facing copy and backend language consistency before Phase 2 adds new profile state and logic that would otherwise require a second pass through the localization work.

## Phase 1: i18n + Meal Name Language Fix

### Objectives

- Add Turkish (`tr`) to the iOS project.
- Move user-facing strings into a string catalog.
- Replace raw SwiftUI copy with localization-aware keys.
- Force generated meal names to be Turkish dishes, not generic English meals.
- Prevent meal type classification regressions when Turkish labels appear in model output or cached data.

### A. Xcode localization setup

#### Planned changes

1. Update [project.pbxproj](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek.xcodeproj/project.pbxproj:137) to add `tr` to `knownRegions`.
2. Keep `developmentRegion = en` for now unless the product decision is to make Turkish the development language. Changing `developmentRegion` is higher risk and not required for adding Turkish support.
3. Add one source-of-truth string catalog, preferably `Localizable.xcstrings`, under the iOS target.
4. Ensure the catalog is included in the NutriWeek app target and committed as a regular project resource.
5. Migrate hardcoded `Text`, `Button`, `Alert`, placeholder, toast title, toast subtitle, and validation/error message strings to localized entries.

#### Migration rule set

- Use `LocalizedStringKey` for SwiftUI `Text`, `Button`, alert titles, and short labels.
- Use `String(localized:)` for dynamic strings built in logic, error messages, and toast messages that are not direct `Text("...")` literals.
- Replace concatenated English display text where pluralization or interpolation is needed with format-style localized keys.
- Do not localize persisted enum raw values, Supabase payload field names, or backend meal `type` protocol values unless the client and edge function are deliberately updated together.

#### Broader audit note

The files reviewed below already contain a large amount of hardcoded English. The implementation pass should also run a repo-wide audit across `iOS/NutriWeek/NutriWeek/` for `Text("`, `Button("`, `placeholder:`, `NSLocalizedDescriptionKey`, `validationAlertMessage =`, and `showToastMessage(` to catch strings outside this initial review set.

Suggested audit commands during implementation:

```bash
rg -n 'Text\\("|Button\\("|placeholder: "|NSLocalizedDescriptionKey: "|validationAlertMessage = "|showToastMessage\\("' iOS/NutriWeek/NutriWeek
rg -n 'return "' iOS/NutriWeek/NutriWeek
```

### B. String extraction plan by file

The table below focuses on the user-specified key areas plus adjacent strings in the reviewed files that should be migrated in the same pass.

#### 1. MealPlanHomeView.swift

| Current string | Reference | Turkish translation | Proposed key |
|---|---|---|---|
| `Plan updated` | [MealPlanHomeView.swift:78](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:78) | `Plan guncellendi` | `meal_plan.toast.updated_title` |
| `Your new weekly plan is ready.` | [MealPlanHomeView.swift:79](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:79) | `Yeni haftalik planin hazir.` | `meal_plan.toast.updated_subtitle` |
| `Rocky says...` | [MealPlanHomeView.swift:89](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:89) | `Rocky diyor ki...` | `meal_plan.alert.rocky_title` |
| `OK` | [MealPlanHomeView.swift:90](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:90) | `Tamam` | `common.ok` |
| `Hey there! 👊` | [MealPlanHomeView.swift:112](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:112) | `Merhaba! 👊` | `meal_plan.header.subtitle` |
| `Rocky says hi!` | [MealPlanHomeView.swift:118](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:118) | `Rocky selam soyluyor!` | `meal_plan.fun_fact.fallback` |
| `🔥 %d day streak` | [MealPlanHomeView.swift:135](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:135) | `🔥 %d gunluk seri` | `meal_plan.streak.days` |
| `🌱 Start your streak today!` | [MealPlanHomeView.swift:135](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:135) | `🌱 Serine bugun basla!` | `meal_plan.streak.empty` |
| `Complete onboarding to see targets` | [MealPlanHomeView.swift:158](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:158) | `Hedefleri gormek icin kaydi tamamla` | `meal_plan.targets.complete_onboarding` |
| `%d kcal remaining` | [MealPlanHomeView.swift:159](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:159) | `%d kcal kaldi` | `meal_plan.targets.remaining` |
| `%d kcal over target 😅` | [MealPlanHomeView.swift:160](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:160) | `Hedefin %d kcal uzerindesin 😅` | `meal_plan.targets.over` |
| `Today's Progress` | [MealPlanHomeView.swift:164](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:164) | `Bugunun Ilerlemesi` | `meal_plan.progress.title` |
| `Calories` | [MealPlanHomeView.swift:171](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:171) | `Kalori` | `macro.calories` |
| `Protein` | [MealPlanHomeView.swift:172](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:172) | `Protein` | `macro.protein` |
| `Carbs` | [MealPlanHomeView.swift:173](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:173) | `Karbonhidrat` | `macro.carbs` |
| `Fat` | [MealPlanHomeView.swift:174](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:174) | `Yag` | `macro.fat` |
| `This Week` | [MealPlanHomeView.swift:198](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:198) | `Bu Hafta` | `meal_plan.week.title` |
| `%d/7 days ready` | [MealPlanHomeView.swift:214](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:214) | `%d/7 gun hazir` | `meal_plan.week.progress` |
| `Could not load your plan` | [MealPlanHomeView.swift:236](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:236) | `Planin yuklenemedi` | `meal_plan.error.load_title` |
| `Retry` | [MealPlanHomeView.swift:238](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:238) | `Tekrar Dene` | `common.retry` |
| `No plan yet!` | [MealPlanHomeView.swift:258](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:258) | `Henuz plan yok!` | `meal_plan.empty.title` |
| `Let Rocky build your personalized 7-day meal plan` | [MealPlanHomeView.swift:261](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:261) | `Rocky sana ozel 7 gunluk yemek planini hazirlasin` | `meal_plan.empty.subtitle` |
| `Generate My Plan` | [MealPlanHomeView.swift:268](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:268) | `Planimi Olustur` | `meal_plan.empty.generate_button` |
| `Ready to build your first meal plan?` | [MealPlanHomeView.swift:302](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:302) | `Ilk yemek planini hazirlamaya hazir misin?` | `meal_plan.sheet.title` |
| `I'll create a personalized 7-day plan based on your goals 🎯` | [MealPlanHomeView.swift:306](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:306) | `Hedeflerine gore sana ozel 7 gunluk plan hazirlayacagim 🎯` | `meal_plan.sheet.subtitle` |
| `Let's go!` | [MealPlanHomeView.swift:315](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:315) | `Baslayalim!` | `meal_plan.sheet.confirm` |
| `Maybe later` | [MealPlanHomeView.swift:326](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:326) | `Belki sonra` | `meal_plan.sheet.cancel` |
| `Today` | [MealPlanHomeView.swift:562](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:562) | `Bugun` | `common.today` |
| `🍎 Snack ▾` | [MealPlanHomeView.swift:590](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:590) | `🍎 Ara Ogun ▾` | `meal_plan.card.snack_collapsed` |
| `Breakfast` | [MealPlanHomeView.swift:683](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:683) | `Kahvalti` | `meal_type.breakfast` |
| `Lunch` | [MealPlanHomeView.swift:684](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:684) | `Ogle Yemegi` | `meal_type.lunch` |
| `Dinner` | [MealPlanHomeView.swift:685](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:685) | `Aksam Yemegi` | `meal_type.dinner` |
| `Snack` | [MealPlanHomeView.swift:686](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:686) | `Ara Ogun` | `meal_type.snack` |

Implementation note: `greetingText` in [MealPlanHomeView.swift:340](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:340) currently returns hardcoded English variants (`Good morning!`, `Good afternoon!`, `Good evening!`, `Still up?`). Those should be localized even though they were not in the original required list.

#### 2. ProfileView+Subviews.swift

| Current string | Reference | Turkish translation | Proposed key |
|---|---|---|---|
| `Profile failed to load` | [ProfileView+Subviews.swift:8](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:8) | `Profil yuklenemedi` | `profile.error.load_title` |
| `Retry` | [ProfileView+Subviews.swift:10](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:10) | `Tekrar Dene` | `common.retry` |
| `My Profile` | [ProfileView+Subviews.swift:31](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:31) | `Profilim` | `profile.title` |
| `BMI` | [ProfileView+Subviews.swift:71](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:71) | `VKI` | `profile.stats.bmi` |
| `Daily Calories` | [ProfileView+Subviews.swift:72](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:72) | `Gunluk Kalori` | `profile.stats.daily_calories` |
| `Goal` | [ProfileView+Subviews.swift:73](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:73) | `Hedef` | `profile.stats.goal` |
| `Daily Targets` | [ProfileView+Subviews.swift:88](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:88) | `Gunluk Hedefler` | `profile.targets.title` |
| `Calories` | [ProfileView+Subviews.swift:89](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:89) | `Kalori` | `macro.calories` |
| `Protein` | [ProfileView+Subviews.swift:91](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:91) | `Protein` | `macro.protein` |
| `Carbs` | [ProfileView+Subviews.swift:93](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:93) | `Karbonhidrat` | `macro.carbs` |
| `Fat` | [ProfileView+Subviews.swift:95](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:95) | `Yag` | `macro.fat` |
| `Personal Info` | [ProfileView+Subviews.swift:111](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:111) | `Kisisel Bilgiler` | `profile.personal_info.title` |
| `Cancel` | [ProfileView+Subviews.swift:115](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:115) | `Iptal` | `common.cancel` |
| `Save` | [ProfileView+Subviews.swift:117](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:117) | `Kaydet` | `common.save` |
| `Edit` | [ProfileView+Subviews.swift:121](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:121) | `Duzenle` | `common.edit` |
| `Age` | [ProfileView+Subviews.swift:126](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:126) | `Yas` | `profile.field.age` |
| `e.g. 28` | [ProfileView+Subviews.swift:126](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:126) | `ornek 28` | `profile.placeholder.age` |
| `Gender` | [ProfileView+Subviews.swift:127](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:127) | `Cinsiyet` | `profile.field.gender` |
| `male / female / other` | [ProfileView+Subviews.swift:127](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:127) | `erkek / kadin / diger` | `profile.placeholder.gender` |
| `Height (cm)` | [ProfileView+Subviews.swift:128](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:128) | `Boy (cm)` | `profile.field.height_cm` |
| `e.g. 175` | [ProfileView+Subviews.swift:128](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:128) | `ornek 175` | `profile.placeholder.height_cm` |
| `Activity Level` | [ProfileView+Subviews.swift:129](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:129) | `Aktivite Duzeyi` | `profile.field.activity_level` |
| `sedentary / lightly_active / moderately_active / very_active / extra_active` | [ProfileView+Subviews.swift:129](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:129) | `sedanter / hafif_aktif / orta_aktif / cok_aktif / ekstra_aktif` | `profile.placeholder.activity_level` |
| `Dietary Prefs` | [ProfileView+Subviews.swift:136](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:136) | `Beslenme Tercihleri` | `profile.field.dietary_preferences` |
| `None` | [ProfileView+Subviews.swift:138](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:138) | `Yok` | `common.none` |
| `Body Measurements` | [ProfileView+Subviews.swift:149](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:149) | `Vucut Olculeri` | `profile.measurements.title` |
| `+ Log New` | [ProfileView+Subviews.swift:151](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:151) | `+ Yeni Kayit` | `profile.measurements.log_new` |
| `Weight` | [ProfileView+Subviews.swift:154](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:154) | `Kilo` | `profile.measurements.weight` |
| `Waist` | [ProfileView+Subviews.swift:156](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:156) | `Bel` | `profile.measurements.waist` |
| `Hips` | [ProfileView+Subviews.swift:157](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:157) | `Kalca` | `profile.measurements.hips` |
| `Chest` | [ProfileView+Subviews.swift:158](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:158) | `Gogus` | `profile.measurements.chest` |
| `Left Arm` | [ProfileView+Subviews.swift:159](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:159) | `Sol Kol` | `profile.measurements.left_arm` |
| `Left Leg` | [ProfileView+Subviews.swift:160](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:160) | `Sol Bacak` | `profile.measurements.left_leg` |
| `Add measurements to track your progress over time` | [ProfileView+Subviews.swift:162](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:162) | `Ilerlemeni zaman icinde takip etmek icin olcu ekle` | `profile.measurements.empty` |
| `Settings` | [ProfileView+Subviews.swift:169](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:169) | `Ayarlar` | `profile.settings.title` |
| `Reset Weekly Plan` | [ProfileView+Subviews.swift:170](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:170) | `Haftalik Plani Sifirla` | `profile.settings.reset_weekly_plan` |
| `Reset All Data 🗑️` | [ProfileView+Subviews.swift:174](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:174) | `Tum Verileri Sifirla 🗑️` | `profile.settings.reset_all_data` |
| `Delete Account` | [ProfileView+Subviews.swift:178](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:178) | `Hesabi Sil` | `profile.settings.delete_account` |

#### 3. ProfileView+Logic.swift

These strings are not all direct SwiftUI literals, but they are user-facing and must be localized through `String(localized:)` or equivalent.

| Current string | Reference | Turkish translation | Proposed key |
|---|---|---|---|
| `Profile not found. Please complete onboarding again.` | [ProfileView+Logic.swift:39](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:39) | `Profil bulunamadi. Lutfen kaydi yeniden tamamla.` | `profile.error.not_found` |
| `Age must be between 10 and 120` | [ProfileView+Logic.swift:99](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:99) | `Yas 10 ile 120 arasinda olmali` | `profile.validation.age_range` |
| `Height must be between 50 and 300 cm` | [ProfileView+Logic.swift:100](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:100) | `Boy 50 ile 300 cm arasinda olmali` | `profile.validation.height_range` |
| `Gender and activity level are required.` | [ProfileView+Logic.swift:103](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:103) | `Cinsiyet ve aktivite duzeyi zorunludur.` | `profile.validation.gender_activity_required` |
| `Profile updated! ✅` | [ProfileView+Logic.swift:134](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:134) | `Profil guncellendi! ✅` | `profile.toast.updated` |
| `Save failed: %@` | [ProfileView+Logic.swift:136](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:136) | `Kaydetme basarisiz: %@` | `profile.error.save_failed` |
| `All local data reset. Please reopen app.` | [ProfileView+Logic.swift:149](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:149) | `Tum yerel veriler sifirlandi. Lutfen uygulamayi yeniden ac.` | `profile.toast.reset_all_done` |
| `Reset failed: %@` | [ProfileView+Logic.swift:151](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:151) | `Sifirlama basarisiz: %@` | `profile.error.reset_failed` |
| `Could not delete your account. Please try again.` | [ProfileView+Logic.swift:163](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:163) | `Hesabin silinemedi. Lutfen tekrar dene.` | `profile.error.delete_failed_generic` |
| `Delete account failed: %@` | [ProfileView+Logic.swift:169](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:169) | `Hesap silme basarisiz: %@` | `profile.error.delete_failed` |
| `Lose Fat 🔥` | [ProfileView+Logic.swift:183](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:183) | `Yag Yak 🔥` | `goal.cut` |
| `Build Muscle 💪` | [ProfileView+Logic.swift:183](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:183) | `Kas Kazan 💪` | `goal.bulk` |
| `Stay Balanced ⚖️` | [ProfileView+Logic.swift:183](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:183) | `Dengede Kal ⚖️` | `goal.maintain` |
| `Sedentary` | [ProfileView+Logic.swift:187](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:187) | `Sedanter` | `activity.sedentary` |
| `Lightly Active` | [ProfileView+Logic.swift:188](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:188) | `Hafif Aktif` | `activity.lightly_active` |
| `Moderately Active` | [ProfileView+Logic.swift:189](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:189) | `Orta Aktif` | `activity.moderately_active` |
| `Very Active` | [ProfileView+Logic.swift:190](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:190) | `Cok Aktif` | `activity.very_active` |
| `Extra Active` | [ProfileView+Logic.swift:191](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:191) | `Ekstra Aktif` | `activity.extra_active` |

#### 4. LogView+Subviews.swift

| Current string | Reference | Turkish translation | Proposed key |
|---|---|---|---|
| `Quick Log` | [LogView+Subviews.swift:8](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Subviews.swift:8) | `Hizli Kayit` | `log.title` |
| `📋 Today` | [LogView+Subviews.swift:16](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Subviews.swift:16) | `📋 Bugun` | `log.today_button` |
| `Search food... (e.g. chicken breast)` | [LogView+Subviews.swift:37](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Subviews.swift:37) | `Yemek ara... (ornek tavuk gogsu)` | `log.search.placeholder` |
| `No internet connection` | [LogView+Subviews.swift:70](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Subviews.swift:70) | `Internet baglantisi yok` | `log.error.network_title` |
| `Something went wrong` | [LogView+Subviews.swift:70](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Subviews.swift:70) | `Bir seyler ters gitti` | `common.error.generic_title` |
| `Please check your connection and try again.` | [LogView+Subviews.swift:71](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Subviews.swift:71) | `Lutfen baglantini kontrol edip tekrar dene.` | `log.error.network_message` |
| `We could not search foods right now.` | [LogView+Subviews.swift:71](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Subviews.swift:71) | `Su anda yemek aramasi yapamiyoruz.` | `log.error.search_message` |
| `Retry` | [LogView+Subviews.swift:72](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Subviews.swift:72) | `Tekrar Dene` | `common.retry` |
| `Per 100g:` | [LogView+Subviews.swift:107](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Subviews.swift:107) | `100 g icin:` | `log.food.per_100g` |
| `Search for any food above!` | [LogView+Subviews.swift:137](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Subviews.swift:137) | `Yukaridan herhangi bir yemek ara!` | `log.empty.title` |
| `Hmm, couldn't find that one` | [LogView+Subviews.swift:167](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Subviews.swift:167) | `Hmm, bunu bulamadim` | `log.no_results.title` |
| `Try different keywords` | [LogView+Subviews.swift:171](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/LogView+Subviews.swift:171) | `Farkli anahtar kelimeler dene` | `log.no_results.subtitle` |

#### 5. OnboardingStep2View.swift

| Current string | Reference | Turkish translation | Proposed key |
|---|---|---|---|
| `Lose Fat` | [OnboardingStep2View.swift:11](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift:11) | `Yag Yak` | `goal.cut.short` |
| `Calorie deficit · Look lean · Feel light` | [OnboardingStep2View.swift:11](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift:11) | `Kalori acigi · Daha fit gorun · Hafif hisset` | `goal.cut.subtitle` |
| `Build Muscle` | [OnboardingStep2View.swift:12](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift:12) | `Kas Kazan` | `goal.bulk.short` |
| `Calorie surplus · Get strong · Grow` | [OnboardingStep2View.swift:12](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift:12) | `Kalori fazlasi · Guclen · Buyu` | `goal.bulk.subtitle` |
| `Stay Balanced` | [OnboardingStep2View.swift:13](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift:13) | `Dengede Kal` | `goal.maintain.short` |
| `Eat at maintenance · Keep what you have` | [OnboardingStep2View.swift:13](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift:13) | `Koruma kalorisinde ye · Elindekini koru` | `goal.maintain.subtitle` |
| `What's the mission? Choose your goal!` | [OnboardingStep2View.swift:18](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift:18) | `Hedef ne? Amacini sec!` | `onboarding.goal.prompt` |
| `Let's get shredded! I'll keep the snacks away 🔥` | [OnboardingStep2View.swift:21](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift:21) | `Sikilasmaya baslayalim! Atistirmalari kontrol ederim 🔥` | `onboarding.goal.rocky.cut` |
| `Eating more? My favorite goal! 🍗` | [OnboardingStep2View.swift:22](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift:22) | `Daha fazla yemek mi? En sevdigim hedef! 🍗` | `onboarding.goal.rocky.bulk` |
| `Balance is everything. Very zen ☯️` | [OnboardingStep2View.swift:23](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift:23) | `Denge her seydir. Cok zen ☯️` | `onboarding.goal.rocky.maintain` |
| `Your Goal` | [OnboardingStep2View.swift:41](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift:41) | `Hedefin` | `onboarding.goal.title` |
| `Continue` | [OnboardingStep2View.swift:53](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift:53) | `Devam Et` | `common.continue` |

### C. Gemini prompt fix

#### Current backend behavior

The two relevant prompt builders are:

- `buildFullDayPrompt()` in [index.ts:238](/Users/jans/Downloads/NutriWeek-Planner/supabase/functions/gemma-generate-day/index.ts:238)
- `buildPartialMealsPrompt()` in [index.ts:267](/Users/jans/Downloads/NutriWeek-Planner/supabase/functions/gemma-generate-day/index.ts:267)

They currently instruct the model to return JSON only and define nutrition constraints, but they do not constrain output language or cuisine naming.

#### Planned prompt changes

Add explicit constraints to both prompt builders:

1. Output meal `name` values as traditional Turkish dish names.
2. Keep `type` values in the existing API contract format: `Breakfast`, `Lunch`, `Dinner`, `Snack`.
3. Prefer Turkish cuisine unless dietary constraints force a narrow substitute.
4. Keep `cuisine` semantically useful, for example `Turkish`, not generic `general`, when the meal is Turkish.
5. Keep ingredients readable and food-realistic for Turkish dishes.

Suggested wording for both prompts:

```text
Meal names must be traditional Turkish dish names written in Turkish.
Prefer authentic Turkish meals and ingredients unless a dietary restriction makes that impossible.
Keep the meal type field exactly as one of: Breakfast, Lunch, Dinner, Snack.
Set cuisine to Turkish whenever the meal is a Turkish dish.
```

#### Why this is needed

- The UI renders `meal.name` directly in [MealPlanHomeView.swift:668](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:668).
- Cached seed data is Turkish per the existing analysis, but Gemini fallback generations are not constrained.
- If partial generation is left unchanged, mixed-language weeks will still happen when cache fills only some meal slots.

#### Cuisine reasoning safeguard

The prompt should prefer Turkish dishes without requiring every meal to literally have `cuisine = Turkish` when a strict dietary combination makes that unrealistic. The safer rule is:

- Prefer Turkish dishes first.
- Require Turkish meal names.
- Allow cuisine metadata to remain non-Turkish only when necessary for dietary compliance, but document this as an exception path.

### D. `mealType()` mapper update

#### Current risk

`mealType(from:)` in [MealPlanMapper.swift:90](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Data/Mappers/MealPlanMapper.swift:90) only handles lowercased English values:

- `breakfast`
- `lunch`
- `dinner`
- default -> `.snack`

That fallback is unsafe because any unexpected Turkish or alternate label silently becomes snack.

#### Recommended approach

Keep the wire contract English for now and harden the mapper defensively.

Planned mapper behavior:

1. Continue treating `Breakfast`, `Lunch`, `Dinner`, `Snack` as the canonical API values.
2. Add support for Turkish synonyms in the mapper as a compatibility layer, for example:
   - `kahvalti`
   - `ogle`
   - `ogle yemegi`
   - `aksam`
   - `aksam yemegi`
   - `ara ogun`
   - `snack`
3. Log or assert on unknown meal types in debug builds rather than silently mapping to snack.

Why this is optional but recommended:

- If prompts are followed exactly, the edge function should still return English protocol types.
- Cached data or future backend changes may introduce Turkish type labels.
- Defensive mapping reduces a class of silent UI corruption bugs.

### Phase 1 implementation sequence

1. Add `tr` region to the Xcode project and create `Localizable.xcstrings`.
2. Extract strings in the reviewed files first.
3. Run repo-wide i18n audit and capture remaining strings.
4. Replace raw strings with localization-aware APIs.
5. Update day-generation prompts in both full and partial builders.
6. Harden `mealType()` parsing.
7. Verify one full plan generation path and one partial-cache generation path produce Turkish meal names.

## Phase 2: Calorie Target Lock and Tracking

### Objectives

- Allow users to keep the current calculated calorie target or lock a custom manual target.
- Persist that choice in the data model.
- Use the effective target consistently in home progress, plan generation, and future tracking surfaces.

### A. Data layer

#### Recommended schema direction

Add new nullable profile fields to `profiles` rather than creating a separate table.

Recommended columns:

- `custom_target_calories INT NULL`
- `calorie_target_mode TEXT NOT NULL DEFAULT 'auto'`

Suggested allowed values for `calorie_target_mode`:

- `auto`
- `custom`

Why this design is preferred over a separate table:

- The target is a user profile preference, not a historical event.
- The current profile fetch/upsert path is already concentrated in [ProfileView+Logic.swift:32](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:32).
- Keeping this in `profiles` avoids a second read just to render the home screen target.

#### Optional future-proof extension

If product scope later expands to historical target changes, coaching, or effective-date targets, a dedicated `calorie_targets` table may become justified. That is not necessary for the requested feature.

#### iOS model changes required later

The following structures will need to carry the new state:

- profile row decoder in [ProfileView+Logic.swift:11](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:11)
- profile upsert struct in [ProfileView+Logic.swift:116](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Logic.swift:116)
- any profile domain model used by `NutritionCalculationService`
- `GemmaPlanTargets` in [GemmaEdgeService.swift:4](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Data/EdgeFunctions/GemmaEdgeService.swift:4)

#### Effective target rule

Define one shared rule:

```text
effectiveTargetCalories =
  calorie_target_mode == "custom" && custom_target_calories != nil
    ? custom_target_calories
    : calculatedTargetCalories
```

This rule must be used everywhere target calories are displayed or sent to plan generation.

### B. UI layer

#### Profile screen changes

The current edit surface is `personalInfoCard(profile:)` in [ProfileView+Subviews.swift:108](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/ProfileView+Subviews.swift:108).

Planned additions:

1. Add a calorie target section inside Personal Info or as a dedicated card immediately below Daily Targets.
2. Show:
   - calculated target
   - mode toggle: `Use Calculated Target` vs `Use Custom Target`
   - text field for custom calories when custom mode is enabled
3. Validation:
   - integer only
   - reasonable range, for example 800 to 6000 kcal
4. Editing behavior:
   - when custom mode is off, persist `auto` and null out `custom_target_calories`
   - when custom mode is on, require a valid numeric custom target before save

Recommended UX layout:

- Read-only row: `Calculated Target`
- Toggle or segmented control: `Target Mode`
- Conditional field: `Custom Daily Calories`
- Supporting helper text: `This target will be used for plan generation and daily remaining calories.`

#### Home screen changes

The home progress section uses `targets?.targetCalories` directly in [MealPlanHomeView.swift:152](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:152).

Planned update:

1. Stop reading only `NutritionCalculationService.calculateAll(profile:)`.
2. Introduce an effective target source that merges calculated results with profile override state.
3. Update remaining-calories text and macro ring calorie target to use the effective target.
4. If the user is on custom mode, optionally show a small label such as `Custom target` near the calorie summary to avoid confusion.

#### Onboarding considerations

[OnboardingStep2View.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Onboarding/Views/OnboardingStep2View.swift) does not currently own calorie target input. Keep onboarding unchanged for the first implementation unless product explicitly wants custom target during onboarding. The requested scope points to Profile-based editing, which is lower-risk.

### C. Edge function

#### Current client request path

`GemmaGenerateDayRequest` currently sends:

- `profile`
- `targetCalories`
- `macros`
- `dayName`
- `date`
- `excludeMealNames`

See [GemmaEdgeService.swift:59](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Data/EdgeFunctions/GemmaEdgeService.swift:59).

#### Planned contract update

There are two viable options:

##### Option 1: Reuse `targetCalories` only

The client computes effective target calories and continues sending them in the existing `targetCalories` field. No new backend field is required for the day-generation edge function.

Pros:

- Smallest API change.
- No backward-compatibility issues.
- Home UI and plan generation can be aligned entirely on the client.

Cons:

- The backend cannot distinguish whether a target is auto or user-locked.

##### Option 2: Add explicit override metadata

Add optional fields such as:

- `customTargetCalories?: number`
- `targetMode?: "auto" | "custom"`

Pros:

- Better observability.
- Future rules can branch on target mode.

Cons:

- More schema and API surface than the current requirement actually needs.

#### Recommendation

Use Option 1 first. The user goal is to accept a custom override, not to expose target provenance in the edge function. The plan generation edge only needs the final target calories number. If analytics or server-side profile reconciliation becomes important later, add explicit metadata in a second pass.

#### Weekly function alignment

Even though the request calls out `gemma-generate-day`, the same rule should be checked for `gemma-generate-week` to avoid a split behavior between single-day and weekly generation paths.

## Cross-cutting architecture notes

### AppContainer and dependency flow

[AppContainer.swift](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/DI/AppContainer.swift:4) is minimal and likely does not need structural changes. The main architectural concern is to avoid duplicating target resolution logic across:

- `ProfileView`
- `MealPlanHomeView`
- meal plan repository calls
- future log summaries

Recommended approach:

- Add a small shared target-resolution helper or view-model utility.
- Keep one canonical function for calculating the effective calorie target.

### Meal generation and tracking coupling

Current generation uses `targets?.targetCalories` in [MealPlanHomeView.swift:394](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:394). If Phase 2 is done without centralizing target resolution, the app can easily display one target on the home card but generate plans using another. The implementation must treat these as a single source-of-truth problem.

## Risks

### Phase 1 risks

#### Localization coverage risk

Adding `tr` and a string catalog but missing strings in logic code will leave mixed Turkish/English UI. The largest risk areas are:

- computed properties returning strings
- validation messages
- toast messages
- error titles and retry labels
- any additional files not in the reviewed set

#### Format and interpolation risk

Strings like `%d kcal remaining`, `%d/7 days ready`, and streak text need proper localized formatting, not string concatenation. Poor migration can break grammar or formatting in Turkish.

#### Backend prompt drift risk

If the prompt is updated only in `buildFullDayPrompt()` and not `buildPartialMealsPrompt()`, mixed-language meal plans will continue when cache fills only some meals.

#### Meal type regression risk

If Turkish names are added but meal `type` handling is not hardened, any future type variation can silently become `.snack` in [MealPlanMapper.swift:95](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Data/Mappers/MealPlanMapper.swift:95).

### Phase 2 risks

#### Target inconsistency risk

The biggest functional risk is using one target for:

- UI display
- plan generation
- future log comparisons

and a different target in another layer.

#### Data migration risk

If new `profiles` columns are added without backfill/default handling, existing users can get nil or invalid states. The migration should make `calorie_target_mode` default to `auto` and tolerate null `custom_target_calories`.

#### Validation risk

If the custom target field accepts free text without strict validation, invalid values can propagate to plan generation and cause low-quality or unrealistic meal plans.

## Rollback strategy

### Phase 1 rollback

1. If localization introduces rendering issues, keep the string catalog file but temporarily revert individual view migrations while preserving `tr` project support.
2. If prompt changes degrade Gemini output quality, revert prompt-only changes first while keeping i18n work intact.
3. If mapper hardening causes parsing issues, fall back to canonical English API meal types while preserving debug logging for investigation.

### Phase 2 rollback

1. Disable custom mode in the UI while leaving nullable schema columns in place.
2. Continue computing and using auto targets only.
3. Ignore any stored `custom_target_calories` values until the feature is re-enabled.

This is why nullable additive schema changes are preferable. They are easy to leave dormant without a destructive migration.

## Testing approach

### Phase 1 testing

#### Manual i18n verification

1. Launch app in English and Turkish.
2. Verify navigation-critical screens:
   - Home
   - Profile
   - Quick Log
   - Onboarding step 2
3. Confirm no reviewed string remains in English when device/app locale is Turkish.
4. Confirm text still fits in buttons, pills, alerts, and cards.

#### Meal-generation verification

1. Generate a fresh weekly plan with low cache availability.
2. Generate a plan with partial cache availability.
3. Confirm `meal.name` values shown in [MealPlanHomeView.swift:668](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Features/Main/Views/MealPlanHomeView.swift:668) are Turkish.
4. Confirm meal labels shown by `mealTypeLabel` remain correctly mapped.
5. Confirm no meal is misclassified as snack due to type parsing.

#### Automated tests to add later

- Mapper tests for English and Turkish meal type aliases.
- Prompt-builder snapshot tests asserting Turkish meal-name instructions exist in both builders.
- Basic localization smoke checks if the project already has UI test coverage.

### Phase 2 testing

#### Data and persistence verification

1. Existing users with no override should continue to see calculated targets.
2. Turning custom mode on and saving a value should persist across relaunch.
3. Turning custom mode off should restore calculated targets immediately and after relaunch.

#### UI verification

1. Home calorie rings and remaining text should update from the effective target.
2. Profile screen should show the correct mode and value after save.
3. Invalid custom targets should block save and show localized validation.

#### Generation verification

1. Generate a plan in auto mode and record target calories used.
2. Generate a plan in custom mode and confirm the new effective target is used.
3. Confirm logs and remaining-calorie math use the same effective target as generation.

## Recommended implementation order

1. Add Turkish localization plumbing in Xcode and create the string catalog.
2. Migrate strings in the reviewed files.
3. Run repo-wide i18n audit and close any remaining hardcoded UI strings.
4. Update Gemini full and partial prompts for Turkish dish-name output.
5. Harden meal type mapping.
6. Add profile schema fields for custom calorie target mode and value.
7. Add profile edit UI and validation.
8. Centralize effective target resolution.
9. Switch home summary and generation requests to the effective target.
10. Verify both locales and both target modes end to end.

## Definition of done

Phase 1 is complete when:

- The iOS project includes Turkish localization support.
- Reviewed UI strings are served through localization APIs.
- Generated meal names are consistently Turkish in both cache-miss and partial-cache paths.
- Meal type mapping no longer silently misclassifies Turkish or alternate type labels.

Phase 2 is complete when:

- Users can choose calculated or custom calorie targets.
- The chosen target persists in Supabase.
- Home progress and plan generation use the same effective calorie target.
- Validation, errors, and any new UI copy are localized.
