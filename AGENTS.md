# NutriWeek Planner — Codex Notes

## Project Overview
iOS meal planning app (SwiftUI + Supabase). The mobile codebase is in `iOS/NutriWeek/`. The `artifacts/` directory contains archived Expo/React Native code — do not modify it.

## Architecture

### iOS App (`iOS/NutriWeek/`)
- **SwiftUI** with coordinator-based navigation (`AppCoordinator`)
- **Supabase** for auth, database, and edge functions
- **Dependency injection** via `AppContainer`
- **MVVM** pattern throughout

### Supabase Edge Functions (`supabase/functions/`)
- `gemma-generate-day` — single-day meal plan via Gemini 3 Flash Preview
- `gemma-generate-week` — full week meal plan via Gemini 3 Flash Preview
- `usda-search` — USDA food database search proxy
- `_shared/http.ts` — shared error/JSON response helpers

### AI Integration
- **Model:** `gemini-3-flash-preview` (Google Gemini REST API)
- **Endpoint:** `https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent`
- **Auth:** `GEMINI_API_KEY` Supabase secret
- **JSON mode:** `responseMimeType: "application/json"` — no manual JSON coercion needed
- Edge functions call Gemini directly via native `fetch()` (Deno runtime)

### Required Supabase Secrets
```
GEMINI_API_KEY    — Google Gemini API key
USDA_API_KEY      — USDA FoodData Central API key
SUPABASE_URL      — auto-injected
SUPABASE_ANON_KEY — auto-injected
```

## Key Files
- `iOS/NutriWeek/NutriWeek/Data/EdgeFunctions/GemmaEdgeService.swift` — iOS edge function client
- `iOS/NutriWeek/NutriWeek/Data/Mappers/MealPlanMapper.swift` — DTO → domain mapping
- `iOS/NutriWeek/NutriWeek/Domain/Services/Protocols/MealPlanRepositoryProtocol.swift` — meal plan interface
- `iOS/NutriWeek/NutriWeek/DI/AppContainer.swift` — dependency wiring
- `supabase/functions/gemma-generate-day/index.ts` — day plan edge function
- `supabase/functions/gemma-generate-week/index.ts` — week plan edge function

## Development Notes
- Build target: iOS 17+, Swift 5.9+
- The `artifacts/` directory is historical (old Expo app) — do not edit
- `docs/` contains migration plans and developer conventions
- iOS function names (`gemma-generate-day`, `gemma-generate-week`) are kept for backwards compatibility even though the AI backend is now Gemini
