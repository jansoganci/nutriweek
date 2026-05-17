# NutriWeek iOS Migration — Prioritized Work Queue

This document captures the full prioritized queue of the remaining migration work items, grouped by execution phases.

Total remaining items: **21**

---

## Phase A — Foundation Architecture (6 items)

1. Set up `Config.xcconfig` and `Secrets.xcconfig` and prepare removal of hardcoded runtime config.
2. Add `AuthRepositoryProtocol`.
3. Add `OnboardingRepositoryProtocol`.
4. Implement `SupabaseAuthRepository`.
5. Implement `SupabaseOnboardingRepository`.
6. Add dependency wiring with `DI/AppContainer` and `RepositoryFactory`.

### Why Phase A is first

Everything else depends on stable contracts and dependency injection boundaries.  
Without this phase, feature work would continue to be tightly coupled and harder to integrate/test.

---

## Phase B — Navigation and Bootstrap Stabilization (2 items)

7. Split coordinator responsibilities into `AuthCoordinator`, `OnboardingCoordinator`, and `MainTabCoordinator`.
8. Stabilize launch/bootstrap behavior with auth state stream handling and reliable first-route resolution.

### Why Phase B comes second

After core architecture exists, navigation state ownership must be made deterministic.  
A stable bootstrap path is required before integrating real APIs and edge services.

---

## Phase C — Edge Integration Layer (4 items)

9. Add `Data/EdgeFunctions/EdgeFunctionClient`.
10. Add `USDAEdgeService`.
11. Add `GemmaEdgeService`.
12. Connect repositories to edge services (replace direct view-level fallback dependencies).

### Why Phase C comes third

Phase C enables real backend integration points.  
This must happen before removing mocks in feature screens.

---

## Phase D — Feature Real Data Cutover (3 items)

13. Replace Quick Log `mockFoods` flow with real `usda-search` repository flow.
14. Replace Meal Plan `previewWeeklyPlan` flow with real Gemma weekly generation.
15. Add caching/persistence layer: `CacheStore`, `WeeklyPlanCacheStore`, `DailyLogCacheStore`.

### Why Phase D comes fourth

Only after service clients and repositories are available can screens be fully cut over to real data.  
Caching should be added during cutover to keep UX stable and reduce regression risk.

---

## Phase E — UI Parity and Reusable Polish Components (3 items)

16. Extract reusable `LoadingSkeletonView`.
17. Extract reusable `ErrorStateView` and `ToastView`.
18. Upgrade Rocky mascot implementation to asset-based variant system (mood + size), replacing emoji-only baseline.

### Why Phase E comes fifth

UI parity and polish should be finalized after data behavior is stable.  
This avoids rework when feature logic changes during integration.

---

## Phase F — Backend Hardening, Quality, and Demo Readiness (3 items)

19. Implement edge functions: `usda-search`, `gemma-generate-day`, `gemma-generate-week` (optional `nutrition-calc`).
20. Add Gemma response hardening: strict schema validation and stable error code mapping (`AI_TIMEOUT`, `AI_UNAVAILABLE`, `AI_SCHEMA_INVALID`, `AI_RATE_LIMITED`).
21. Add test and demo readiness package:
   - `NutritionCalculationServiceTests`
   - repository tests
   - smoke test checklist and demo run script

### Why Phase F is last

Hardening and test completion are most efficient after architecture, integration, and UI behavior have settled.  
This phase finalizes reliability for demo and delivery.

---

## Execution and Reporting Protocol

After each phase completes, report:

- Completed items (by item number)
- Files changed
- Build status
- Remaining item count

This format keeps progress measurable and ensures deterministic execution.
