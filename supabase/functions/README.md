# Supabase Edge Functions

Functions added for iOS Phase F:

- `usda-search`
- `gemma-generate-day`
- `gemma-generate-week`

Required secrets:

- `USDA_API_KEY`
- `OLLAMA_BASE_URL`
- `OLLAMA_MODEL` (optional, defaults to `gemma4:e4b`)

Deploy example:

```bash
supabase functions deploy usda-search
supabase functions deploy gemma-generate-day
supabase functions deploy gemma-generate-week
```

