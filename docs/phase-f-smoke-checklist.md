# Phase F Smoke Checklist

## Preconditions

- `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set via `Secrets.xcconfig`.
- Supabase functions are deployed:
  - `usda-search`
  - `gemma-generate-week`
  - `gemma-generate-day`
- Function secrets exist:
  - `USDA_API_KEY`
  - `OLLAMA_BASE_URL`
  - `OLLAMA_MODEL` (optional)

## End-to-End Checks

1. Sign in with a test user.
2. Open Quick Log and search for `"chicken"`.
   - Expect non-empty results from edge function.
3. Add one food entry.
   - Expect success toast and entry in Today's Log.
4. Delete that food entry.
   - Expect entry removed and macros recalculated.
5. Open Meal Plan and generate weekly plan.
   - Expect days/meals rendered from edge function output.
6. Toggle offline mode (or force edge failure).
   - Expect stable retry/error state, no crash.
7. Restart app.
   - Expect cached weekly plan/log available when backend is temporarily unavailable.

## Result Template

- Build status:
- Quick Log search:
- Add/Delete log:
- Weekly generation:
- Error fallback:
- Cache fallback:
- Notes:

