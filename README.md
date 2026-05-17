# NutriWeek Planner

AI-powered weekly meal planning iOS app.

## Features

- **AI meal planning** — Generate personalized daily or weekly meal plans powered by Google Gemini 3 Flash Preview
- **Nutritional targets** — Plans respect your calorie and macro goals
- **Progressive loading** — Week plan generates day-by-day for fast first results
- **Food logging** — Quick log of meals against your targets
- **Activity logging** — Log workouts and energy expenditure (synced via Supabase)
- **Personal insights** — Progress and trend snapshots on the home experience
- **USDA food search** — Search real food nutrition data
- **Supabase backend** — Auth, database, and serverless edge functions
- **Localization** — String Catalog (`Localizable.xcstrings`) for translated UI

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
iOS/NutriWeek/              — iOS SwiftUI app
supabase/
  functions/                — Deno edge functions
    gemma-generate-day/     — Single-day meal plan (Gemini)
    gemma-generate-week/    — Full-week meal plan (Gemini)
    usda-search/            — USDA food search proxy
    delete-account/         — Authenticated account deletion (admin API)
  migrations/               — Postgres schema (apply with Supabase CLI / dashboard)
docs/                       — Developer docs + App Store static pages (GitHub Pages)
artifacts/                  — Archived Expo prototype (historical; do not modify)
```

## Setup

### Supabase Secrets

```bash
supabase secrets set GEMINI_API_KEY=your_gemini_api_key
supabase secrets set USDA_API_KEY=your_usda_api_key
```

The `delete-account` function uses `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`, which Supabase provides in the Edge Functions runtime when deployed to your project.

### Database

Apply SQL in `supabase/migrations/` to your Supabase Postgres instance (e.g. `supabase db push` or run migrations from the dashboard) so tables such as food logs and activity logs exist before relying on those features.

### Deploy Edge Functions

```bash
supabase functions deploy gemma-generate-day
supabase functions deploy gemma-generate-week
supabase functions deploy usda-search
supabase functions deploy delete-account
```

### iOS App

Open `iOS/NutriWeek/NutriWeek.xcodeproj` in Xcode. Configure your Supabase URL and anon key in the app settings, then build and run.

### App Store static site (GitHub Pages)

Minimal Turkish HTML pages for App Store Connect:

| Alan | Yerel dosya | Yayınlanan URL şablonu (örnek) |
|------|-------------|-------------------------------|
| **Marketing URL** | `docs/index.html` | `https://<github-kullanıcı-adı>.github.io/<repo-adı>/` |
| **Privacy Policy URL** | `docs/privacy/index.html` | `https://<github-kullanıcı-adı>.github.io/<repo-adı>/privacy/` |
| **Support URL** | `docs/support/index.html` | `https://<github-kullanıcı-adı>.github.io/<repo-adı>/support/` |

**Önerilen site dosya yapısı (`docs/`):**

```
docs/
├── .nojekyll                 — Jekyll’i kapatır (tam statik çıktı)
├── index.html                — Pazarlama / özette giriş
├── css/
│   └── app-store-site.css    — Okunabilir tipografi (harici izleme yok)
├── privacy/
│   └── index.html            — Gizlilik politikası
└── support/
    └── index.html            — Destek ve iletişim
```

**GitHub Pages’i açma (ksa):**

1. GitHub’da repo → **Settings** → **Pages**.
2. **Build and deployment** kaynağı: **Deploy from a branch**.
3. Branch **main** (veya kullandığınız dal), klasör **`/ docs`** seçin → **Save**.
4. Birkaç dakika sonra site `https://<github-kullanıcı-adı>.github.io/<repo-adı>/` adresinden yayına girer.
5. `docs/support/index.html` ve `docs/privacy/index.html` içinde **`destek@ORNEK-ALAN-ADI.tld`** ifadesini kendi e-postanız ile değiştirin; çıktılarınız doğru olsun.
6. Uygulama App Store’a çıkınca `docs/index.html` içindeki App Store bağlantısını güncelleyin.

Bu metinler hukuki danışmanlığın yerine geçmez; App Store/KVKK uyumu için gerekiyorsa avukattan destek alın.

## Architecture

The iOS app uses SwiftUI with coordinator-based navigation and dependency injection via `AppContainer`. Edge functions run on Deno (Supabase) and call the Gemini REST API directly using `fetch()` with `responseMimeType: "application/json"` for reliable structured output.

Conventions and deeper notes: `docs/DEVELOPER_CONVENTIONS.md`.
