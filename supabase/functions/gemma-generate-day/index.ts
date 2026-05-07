import { coerceJsonObject, isGemmaDay } from "../_shared/ai.ts";
import { errorResponse, jsonResponse } from "../_shared/http.ts";

type GenerateDayPayload = {
  profile: Record<string, unknown>;
  targetCalories: number;
  macros: { protein: number; carbs: number; fat: number };
  dayName: string;
  date: string;
};

const TIMEOUT_MS = 120_000;

function buildPrompt(input: GenerateDayPayload): string {
  return `You are a nutritionist. Return JSON only.
Generate one day meal plan for ${input.dayName} (${input.date}).
Constraints:
- totalCalories around ${input.targetCalories}
- macros around protein ${input.macros.protein}g carbs ${input.macros.carbs}g fat ${input.macros.fat}g
- exactly 4 meals: Breakfast, Lunch, Dinner, Snack
Output schema:
{"day":"${input.dayName}","date":"${input.date}","totalCalories":${input.targetCalories},"meals":[{"type":"Breakfast","name":"...","calories":100,"emoji":"🥣","protein":10,"carbs":10,"fat":10}]}`;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return errorResponse("BAD_REQUEST", "POST required", 405);
  }

  let payload: GenerateDayPayload;
  try {
    payload = await req.json();
  } catch {
    return errorResponse("BAD_REQUEST", "Invalid JSON body", 400);
  }

  if (!payload.dayName || !payload.date) {
    return errorResponse("BAD_REQUEST", "dayName and date are required", 400);
  }

  const baseUrl = Deno.env.get("OLLAMA_BASE_URL");
  const model = Deno.env.get("OLLAMA_MODEL") ?? "gemma4:e4b";
  if (!baseUrl) {
    return errorResponse("AI_UNAVAILABLE", "Missing OLLAMA_BASE_URL secret", 500);
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const upstream = await fetch(`${baseUrl}/api/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model,
        prompt: buildPrompt(payload),
        stream: false,
        options: { num_predict: 2048 },
      }),
      signal: controller.signal,
    });

    if (upstream.status === 429) {
      return errorResponse("AI_RATE_LIMITED", "Gemma rate limited request", 429);
    }
    if (!upstream.ok) {
      return errorResponse("AI_UNAVAILABLE", `Gemma upstream status ${upstream.status}`, 502);
    }

    const body = (await upstream.json()) as { response?: string };
    const parsed = coerceJsonObject(body.response ?? "");
    if (!isGemmaDay(parsed)) {
      return errorResponse("AI_SCHEMA_INVALID", "Gemma response does not match day schema", 422);
    }
    return jsonResponse(parsed);
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      return errorResponse("AI_TIMEOUT", "Gemma request timed out", 504);
    }
    return errorResponse("AI_UNAVAILABLE", "Gemma is unreachable", 502);
  } finally {
    clearTimeout(timer);
  }
});

