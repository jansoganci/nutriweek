import { errorResponse, jsonResponse } from "../_shared/http.ts";

type GenerateWeekPayload = {
  profile: Record<string, unknown>;
  targetCalories: number;
  macros: { protein: number; carbs: number; fat: number };
  weekStartDate?: string;
};

const GEMINI_MODEL = "gemini-3-flash-preview";
const TIMEOUT_MS = 60_000;

function buildPrompt(input: GenerateWeekPayload): string {
  const weekStart = input.weekStartDate ?? new Date().toISOString().slice(0, 10);
  return `You are a nutritionist. Return JSON only.
Generate weekly meal plan.
Constraints:
- weekOf should be ${weekStart}
- each day should include Breakfast, Lunch, Dinner, Snack
- calories around ${input.targetCalories}
- macros around protein ${input.macros.protein}g carbs ${input.macros.carbs}g fat ${input.macros.fat}g
Output schema:
{"weekOf":"${weekStart}","days":[{"day":"Monday","date":"${weekStart}","totalCalories":${input.targetCalories},"meals":[{"type":"Breakfast","name":"...","calories":100,"emoji":"🥣","protein":10,"carbs":10,"fat":10}]}]}`;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return errorResponse("BAD_REQUEST", "POST required", 405);
  }

  let payload: GenerateWeekPayload;
  try {
    payload = await req.json();
  } catch {
    return errorResponse("BAD_REQUEST", "Invalid JSON body", 400);
  }

  if (!payload.profile || typeof payload.profile !== "object") {
    return errorResponse("BAD_REQUEST", "profile is required", 400);
  }
  if (typeof payload.targetCalories !== "number" || Number.isNaN(payload.targetCalories)) {
    return errorResponse("BAD_REQUEST", "targetCalories is required", 400);
  }
  const m = payload.macros;
  if (
    !m ||
    typeof m.protein !== "number" ||
    typeof m.carbs !== "number" ||
    typeof m.fat !== "number"
  ) {
    return errorResponse(
      "BAD_REQUEST",
      "macros with numeric protein, carbs, and fat are required",
      400,
    );
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return errorResponse("AI_UNAVAILABLE", "Missing GEMINI_API_KEY secret", 500);
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{
            parts: [{ text: buildPrompt(payload) }],
          }],
          generationConfig: {
            responseMimeType: "application/json",
            temperature: 0.7,
            maxOutputTokens: 4096,
          },
        }),
        signal: controller.signal,
      },
    );

    if (response.status === 429) {
      return errorResponse("AI_RATE_LIMITED", "Gemini rate limited request", 429);
    }
    if (!response.ok) {
      return errorResponse("AI_UNAVAILABLE", `Gemini upstream status ${response.status}`, 502);
    }

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      return errorResponse("AI_SCHEMA_INVALID", "Gemini returned empty response", 422);
    }

    const parsed = JSON.parse(text);
    return jsonResponse(parsed);
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      return errorResponse("AI_TIMEOUT", "Gemini request timed out", 504);
    }
    if (error instanceof SyntaxError) {
      return errorResponse("AI_SCHEMA_INVALID", "Gemini returned non-JSON response", 422);
    }
    return errorResponse("AI_UNAVAILABLE", "Gemini is unreachable", 502);
  } finally {
    clearTimeout(timer);
  }
});
