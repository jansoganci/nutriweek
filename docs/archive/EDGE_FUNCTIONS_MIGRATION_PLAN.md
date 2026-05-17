# Edge Functions Migration Plan

> **Date:** 2026-05-10
> **Goal:** Replace Ollama/Gemma 4 with Gemini API, fix USDA search for iOS

---

## Current State

### Edge Function Inventory

| Function | Purpose | Called From | Status |
|----------|---------|-------------|--------|
| `usda-search` | USDA food database search proxy | iOS only | ✅ Working |
| `gemma-generate-day` | Single-day meal plan via Gemini | iOS only | ✅ Migrated to Gemini |
| `gemma-generate-week` | Full week meal plan via Gemini | iOS only | ✅ Migrated to Gemini |

### Shared Modules
- `_shared/http.ts` — error/JSON response helpers
- `_shared/supabase-admin.ts` — Supabase admin client
- `_shared/cors.ts` — CORS headers

### How iOS Calls These

| | iOS |
|---|---|
| **Meal Plan** | Supabase Edge Functions → Gemini 3 Flash Preview |
| **USDA Search** | Supabase Edge Function → USDA API |

---

## Phase 1: Remove Ollama/Gemma ✅ COMPLETE

### Problem
- Gemma 4 required a powerful local machine with Ollama
- Ollama calls took 60-120 seconds per week
- `coerceJsonObject` brittle JSON parsing
- Cloudflare Tunnel URL in Expo code was stale

### What Replaced It
**Gemini 3 Flash Preview** — Google's lightweight, fast model:
- Enforced JSON output (`responseMimeType: "application/json"`)
- No more brittle `coerceJsonObject` parsing
- Sub-5 second response time
- ~$0.21/month for 100 users × 4 plans/month

### Files Modified

#### `supabase/functions/gemma-generate-day/index.ts` — COMPLETE
- Rewrote to call Gemini REST API via native `fetch()`
- Model: `gemini-3-flash-preview`
- Uses `responseMimeType: "application/json"` for native JSON output
- 30s timeout with AbortController

#### `supabase/functions/gemma-generate-week/index.ts` — COMPLETE
- Same pattern as day, generates full 7-day plan
- 60s timeout

#### `supabase/functions/_shared/ai.ts` — DELETED
- Removed: contained only Ollama/Gemma validation helpers (`coerceJsonObject`, `isGemmaDay`, `isGemmaWeek`)
- No longer needed: Gemini returns valid JSON natively

### Bugs Encountered During Migration
1. **Trailing comma in JSON prompt** — Gemini was strict about the output schema example having a trailing comma in the meals array. Fixed by cleaning up the prompt template.
2. **404 model not found** — Initial attempt used `gemini-2.0-flash` which returned 404. Switched to `gemini-3-flash-preview` which resolved the issue.

### Verification
- curl tests confirmed all 3 functions working:
  - `usda-search` — USDA food search returns results
  - `gemma-generate-day` — Returns valid single-day meal plan JSON
  - `gemma-generate-week` — Returns valid 7-day meal plan JSON
- iOS app loads meal plans successfully

### Cleanup TODO
- Run `supabase secrets unset OLLAMA_BASE_URL OLLAMA_MODEL` (manual — requires Supabase CLI auth)

### What Did NOT Change
- iOS `GemmaEdgeService.swift` — function names and call sites unchanged
- iOS `MealPlanRepositoryProtocol` — no changes
- Response DTOs (GemmaDayDTO, etc.) — identical shape
- Progressive generation logic — continues working as-is

---

## Phase 2: Fix USDA Search ✅ COMPLETE

### Root Cause
iOS calls the Supabase Edge Function `usda-search`, which required `USDA_API_KEY` as a Supabase secret.

### Fix
```bash
supabase secrets set USDA_API_KEY=your_api_key_here
supabase functions deploy usda-search
```

---

## Phase 3: Gemini Integration ✅ COMPLETE

### Model Used: Gemini 3 Flash Preview

| Feature | Gemini 3 Flash Preview | Ollama/Gemma 4 |
|---------|------------------------|----------------|
| Speed | ~3-5 seconds | ~60-120 seconds |
| JSON Mode | Native (`responseMimeType`) | Manual coercion |
| Cost | ~$0.21/month | Free (local) |
| Quality | Better | Good |
| Maintenance | Zero | Your machine + Ollama |

### Implementation
```typescript
const GEMINI_MODEL = "gemini-3-flash-preview";

const response = await fetch(
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`,
  {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.7,
        maxOutputTokens: 2048,
      },
    }),
    signal: controller.signal,
  },
);
```

### Secrets Required
```bash
supabase secrets set GEMINI_API_KEY=your_gemini_api_key
supabase secrets set USDA_API_KEY=your_usda_api_key
# Remove old secrets:
supabase secrets unset OLLAMA_BASE_URL OLLAMA_MODEL
```

---

## Cost Estimate

| Service | Cost | Notes |
|---------|------|-------|
| Gemini 3 Flash Preview | ~$0.21/month | 100 users × 4 plans/month |
| USDA API | Free | 1,000 req/hour free tier |
| Supabase Edge Functions | Free | Included in Supabase plan |
| **Total** | **~$0.21/month** | |
