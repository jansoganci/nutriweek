# NutriWeek Planner

AI-powered weekly meal planning iOS app.

## Features

- **AI Meal Planning** — Generate personalized daily or weekly meal plans powered by Google Gemini 3 Flash Preview
- **Nutritional Targets** — Plans respect your calorie and macro goals
- **Progressive Loading** — Week plan generates day-by-day for fast first results
- **USDA Food Search** — Search real food nutrition data
- **Supabase Backend** — Auth, database, and serverless edge functions

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS App | SwiftUI, Swift 5.9+ |
| Backend | Supabase (Postgres + Edge Functions) |
| AI | Google Gemini 3 Flash Preview |
| Food Data | USDA FoodData Central API |
| Auth | Supabase Auth |

## Project Structure

```
iOS/NutriWeek/          — iOS SwiftUI app
supabase/functions/     — Deno edge functions
  gemma-generate-day/   — Single-day meal plan (Gemini)
  gemma-generate-week/  — Full-week meal plan (Gemini)
  usda-search/          — USDA food search proxy
docs/                   — Developer documentation
artifacts/              — Archived Expo prototype (historical)
```

## Setup

### Supabase Secrets

```bash
supabase secrets set GEMINI_API_KEY=your_gemini_api_key
supabase secrets set USDA_API_KEY=your_usda_api_key
```

### Deploy Edge Functions

```bash
supabase functions deploy gemma-generate-day
supabase functions deploy gemma-generate-week
supabase functions deploy usda-search
```

### iOS App

Open `iOS/NutriWeek/NutriWeek.xcodeproj` in Xcode. Configure your Supabase URL and anon key in the app settings, then build and run.

## Architecture

The iOS app uses SwiftUI with coordinator-based navigation and dependency injection via `AppContainer`. Edge functions run on Deno (Supabase) and call the Gemini REST API directly using `fetch()` with `responseMimeType: "application/json"` for reliable structured output.
