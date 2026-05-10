# NutriWeek Developer Conventions

> **Source:** `~/.hermes/skills/software-development/nutriweek-developer/SKILL.md`
> **Purpose:** Project conventions and development workflow for NutriWeek-Planner.

## Tech Stack

| Layer | Tech | Status |
|-------|------|--------|
| Mobile | Native iOS (Swift) — Clean Architecture | ✅ Active |
| ~~Expo~~ | ~~React Native~~ | ❌ Abandoned |
| Backend | Express 5 + Supabase + Drizzle ORM | ✅ Active |
| API Design | OpenAPI spec (`lib/api-spec`) + Orval codegen (`lib/api-client-react`) | ✅ |
| Validation | Zod v3 (`lib/api-zod`) | ✅ |
| DB Schema | Drizzle (`lib/db`) | ✅ |
| Monorepo | pnpm workspaces (root + lib/* + artifacts/*) | ✅ |
| Build | esbuild (server) | ✅ |
| Hosting | Replit (server) + Supabase (DB + auth) | ✅ |

## Project Structure

```
NutriWeek-Planner/
├── iOS/                         # NATIVE iOS APP (active)
│   └── NutriWeek/
│       ├── NutriWeek/           # Source code root
│       │   ├── Features/        # Auth, Main, Onboarding
│       │   ├── Core/            # Components, Extensions, Haptics, Theme
│       │   ├── Domain/          # Enums, Models, Services (business logic)
│       │   ├── Data/            # Supabase, Mappers, Persistence
│       │   ├── DI/              # AppContainer, RepositoryFactory
│       │   ├── Navigation/
│       │   └── DesignTokens/
│       ├── NutriWeek.xcodeproj
│       ├── NutriWeekTests/
│       └── Support/
├── lib/                         # Shared packages
│   ├── api-client-react/        # Orval-generated API client
│   ├── api-spec/                # OpenAPI spec source
│   ├── api-zod/                 # Zod v3 schemas
│   └── db/                      # Drizzle ORM schema
├── artifacts/
│   ├── api-server/              # Express API server
│   ├── mobile/                  # OLD Expo project (no longer used)
│   └── mockup-sandbox/          # UI mockup environment
├── supabase/                    # Supabase migrations + edge functions
├── docs/
├── replit.md
└── pnpm-lock.yaml
```

## iOS Architecture Layers

| Layer | Content | Rule |
|-------|---------|------|
| Features/ | Auth, Main, Onboarding screens | View/ViewModel/Model split |
| Core/ | Shared components, extensions | May depend on UIKit |
| Domain/ | Enums, Models, Service protocols | **No platform imports allowed** |
| Data/ | Supabase client, mappers, persistence | Implements Domain interfaces |
| DI/ | AppContainer, RepositoryFactory | All dependencies registered here |

## iOS Dev Notes
- SwiftUI preferred, UIKit only when necessary
- MVVM + Combine for reactive patterns
- Async/await for networking
- Supabase Swift client for auth + data
- DesignTokens define colors/typography/spacing — no hardcoding
- Tests in NutriWeekTests/

## Workflow

1. Analyze the task
2. Split into batches (3-8 files each, independent)
3. Write a plan
4. Feed to Cursor Agent CLI: `agent -p "prompt" --model auto -f`
5. Verify with typecheck/build
6. Report results

## Agent CLI Patterns

```bash
# Implementation
agent -p "prompt" --model auto -f

# Analysis (read-only)
agent -p "Analyze... Do NOT modify files." --model gpt-5.3-codex-xhigh -f

# Quick fix
agent -p "Fix..." --model composer-2-fast -f
```

## Pitfalls

1. Don't touch `artifacts/mobile/` — it's the old Expo project
2. iOS and API server changes are independent — update both separately
3. Use pnpm, not npm/yarn
4. Verify files are from the active iOS project, not old Expo code
5. After changing `lib/api-spec`, run Orval codegen to regenerate `lib/api-client-react`
