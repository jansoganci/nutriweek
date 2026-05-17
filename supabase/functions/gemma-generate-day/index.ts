import { jsonResponse } from "../_shared/http.ts";

type MealType = "Breakfast" | "Lunch" | "Dinner" | "Snack";
type MealTypeKey = "breakfast" | "lunch" | "dinner" | "snack";

type MacroTargets = {
  protein: number;
  carbs: number;
  fat: number;
};

type GenerateDayPayload = {
  profile: Record<string, unknown>;
  targetCalories: number;
  macros: MacroTargets;
  dayName: string;
  date: string;
  excludeMealNames?: string[];
};

type DayMeal = {
  type: MealType;
  name: string;
  calories: number;
  emoji: string;
  protein: number;
  carbs: number;
  fat: number;
  dietary_tags: string[];
  cuisine: string;
  ingredients: string[];
  cachedMealId?: string;
  cacheScore?: number;
};

type DayPlan = {
  day: string;
  dayName?: string;
  date: string;
  totalCalories: number;
  meals: DayMeal[];
};

type CachedMealRow = {
  id: string;
  name: string;
  normalized_name: string;
  meal_type: MealTypeKey;
  calories: number | string;
  protein_g: number | string;
  carbs_g: number | string;
  fat_g: number | string;
  dietary_tags: string[];
  cuisine: string | null;
  ingredients: string[];
  usage_count: number | null;
  last_used_at: string | null;
  scalable: boolean;
  min_scale: number | string;
  max_scale: number | string;
};

type ScoredMeal = {
  row: CachedMealRow;
  meal: DayMeal;
  score: number;
};

type MealTarget = {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
};

const GEMINI_MODEL = "gemini-3-flash-preview";
const TIMEOUT_MS = 30_000;
const FUNCTION_NAME = "gemma-generate-day";
const MEAL_TYPES: MealType[] = ["Breakfast", "Lunch", "Dinner", "Snack"];
const MEAL_TYPE_TO_KEY: Record<MealType, MealTypeKey> = {
  Breakfast: "breakfast",
  Lunch: "lunch",
  Dinner: "dinner",
  Snack: "snack",
};
const MEAL_DISTRIBUTION: Record<MealType, number> = {
  Breakfast: 0.25,
  Lunch: 0.30,
  Dinner: 0.35,
  Snack: 0.10,
};
const HARD_DIETARY_TAGS = [
  "vegan",
  "vegetarian",
  "halal",
  "kosher",
  "gluten_free",
  "dairy_free",
  "nut_free",
] as const;
const SOFT_DIETARY_TAGS = [
  "keto",
  "paleo",
  "low_sodium",
  "high_protein",
  "low_carb",
] as const;
const ALL_DIETARY_TAGS = [...HARD_DIETARY_TAGS, ...SOFT_DIETARY_TAGS];
const CALORIE_TOLERANCE = 50;
const MACRO_TOLERANCE = 5;
const MAX_CACHE_CANDIDATES_PER_TYPE = 8;
const MAX_ACCEPTABLE_MEAL_SCORE = 4.5;

function dayPlanResponseJsonSchema(mealTypes: MealType[], exactMealCount: number) {
  return {
    type: "object",
    additionalProperties: false,
    properties: {
      day: { type: "string" },
      date: { type: "string", format: "date" },
      totalCalories: { type: "number" },
      meals: {
        type: "array",
        minItems: exactMealCount,
        maxItems: exactMealCount,
        items: {
          type: "object",
          additionalProperties: false,
          properties: {
            type: { type: "string", enum: mealTypes },
            name: { type: "string" },
            calories: { type: "number" },
            emoji: { type: "string" },
            protein: { type: "number" },
            carbs: { type: "number" },
            fat: { type: "number" },
            dietary_tags: {
              type: "array",
              items: { type: "string", enum: ALL_DIETARY_TAGS },
            },
            cuisine: { type: "string" },
            ingredients: {
              type: "array",
              items: { type: "string" },
            },
          },
          required: [
            "type",
            "name",
            "calories",
            "emoji",
            "protein",
            "carbs",
            "fat",
            "dietary_tags",
            "cuisine",
            "ingredients",
          ],
        },
      },
    },
    required: ["day", "date", "totalCalories", "meals"],
  };
}

function roundWhole(value: number): number {
  return Math.round(value);
}

function round1(value: number): number {
  return Math.round(value * 10) / 10;
}

function toNumber(value: number | string | null | undefined): number {
  if (typeof value === "number") return value;
  if (typeof value === "string") return Number(value);
  return 0;
}

function normalizeName(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9\s]+/g, " ").replace(/\s+/g, " ").trim();
}

function normalizeTag(value: string): string {
  return value.trim().toLowerCase();
}

function uniqueSortedTags(tags: unknown): string[] {
  if (!Array.isArray(tags)) return [];
  const normalized = [...new Set(
    tags
      .filter((tag): tag is string => typeof tag === "string")
      .map(normalizeTag)
      .filter((tag) => ALL_DIETARY_TAGS.includes(tag as typeof ALL_DIETARY_TAGS[number])),
  )];
  if (normalized.includes("vegan")) {
    normalized.push("vegetarian", "dairy_free");
  }
  return [...new Set(normalized)].sort();
}

function tagsKey(tags: string[]): string {
  return [...new Set(tags.map(normalizeTag).filter(Boolean))].sort().join(",");
}

function profileDietaryTags(profile: Record<string, unknown>): { hardTags: string[]; softTags: string[] } {
  const raw = profile.dietaryPreferences ?? profile.dietary_preferences;
  const tags = uniqueSortedTags(raw);
  return {
    hardTags: tags.filter((tag) => HARD_DIETARY_TAGS.includes(tag as typeof HARD_DIETARY_TAGS[number])),
    softTags: tags.filter((tag) => SOFT_DIETARY_TAGS.includes(tag as typeof SOFT_DIETARY_TAGS[number])),
  };
}

function buildMealTargets(input: GenerateDayPayload): Record<MealType, MealTarget> {
  return Object.fromEntries(MEAL_TYPES.map((type) => {
    const pct = MEAL_DISTRIBUTION[type];
    return [type, {
      calories: input.targetCalories * pct,
      protein: input.macros.protein * pct,
      carbs: input.macros.carbs * pct,
      fat: input.macros.fat * pct,
    }];
  })) as Record<MealType, MealTarget>;
}

function formatDietaryLine(hardTags: string[], softTags: string[]): string {
  const hard = hardTags.length ? hardTags.join(", ") : "none";
  const soft = softTags.length ? softTags.join(", ") : "none";
  return `Hard dietary constraints: ${hard}. Soft preferences: ${soft}.`;
}

function formatExcludedLine(excludeNames: Set<string>): string {
  if (!excludeNames.size) return "No excluded meal names.";
  return `Do not use these meal names or close duplicates: ${[...excludeNames].join(", ")}.`;
}

function buildFullDayPrompt(
  input: GenerateDayPayload,
  hardTags: string[],
  softTags: string[],
  excludeNames: Set<string>,
): string {
  return `You are a nutritionist. Return JSON only.
Meal names must be traditional Turkish dish names written in Turkish. Prefer Turkish cuisine and authentic Turkish meals.
Generate one day meal plan for ${input.dayName} (${input.date}).

Daily targets:
- calories: ${input.targetCalories} kcal (must be within +/- ${CALORIE_TOLERANCE})
- protein: ${input.macros.protein}g, carbs: ${input.macros.carbs}g, fat: ${input.macros.fat}g (each within +/- ${MACRO_TOLERANCE}g)
- exactly 4 meals: Breakfast, Lunch, Dinner, Snack
- meal distribution: Breakfast 25%, Lunch 30%, Dinner 35%, Snack 10%

${formatDietaryLine(hardTags, softTags)}
${formatExcludedLine(excludeNames)}

Every meal must include:
- type, name, calories, emoji, protein, carbs, fat
- dietary_tags using only: ${ALL_DIETARY_TAGS.join(", ")}
- cuisine
- ingredients as an array of food names

If any hard dietary constraints are listed, every meal must comply and include those tags.
Return this shape:
{"day":"${input.dayName}","date":"${input.date}","totalCalories":${input.targetCalories},"meals":[...]}`;
}

function buildPartialMealsPrompt(
  input: GenerateDayPayload,
  existingMeals: DayMeal[],
  missingMealTypes: MealType[],
  remaining: MealTarget,
  perTypeTargets: Record<MealType, MealTarget>,
  hardTags: string[],
  softTags: string[],
  excludeNames: Set<string>,
): string {
  const existing = existingMeals.map((meal) =>
    `- ${meal.type}: ${meal.name}, ${meal.calories} kcal, ${meal.protein}g protein, ${meal.carbs}g carbs, ${meal.fat}g fat`
  ).join("\n");
  const missingTargets = missingMealTypes.map((type) => {
    const target = perTypeTargets[type];
    return `- ${type}: ${roundWhole(target.calories)} kcal, ${round1(target.protein)}g protein, ${round1(target.carbs)}g carbs, ${round1(target.fat)}g fat`;
  }).join("\n");

  return `You are a nutritionist. Return JSON only.
Meal names must be traditional Turkish dish names written in Turkish. Prefer Turkish cuisine and authentic Turkish meals.
Generate only these missing meal types for ${input.dayName} (${input.date}): ${missingMealTypes.join(", ")}.

Existing meals already selected:
${existing || "- none"}

Remaining combined targets for the missing meals:
- calories: ${roundWhole(remaining.calories)} kcal
- protein: ${round1(remaining.protein)}g
- carbs: ${round1(remaining.carbs)}g
- fat: ${round1(remaining.fat)}g

Per missing meal target guide:
${missingTargets}

${formatDietaryLine(hardTags, softTags)}
${formatExcludedLine(excludeNames)}

Do not duplicate existing meals or excluded meal names.
Every generated meal must include:
- type, name, calories, emoji, protein, carbs, fat
- dietary_tags using only: ${ALL_DIETARY_TAGS.join(", ")}
- cuisine
- ingredients as an array of food names

Return this shape with exactly ${missingMealTypes.length} meals:
{"day":"${input.dayName}","date":"${input.date}","totalCalories":${roundWhole(remaining.calories)},"meals":[...]}`;
}

/** Gemini sometimes wraps JSON in markdown fences; MAX_OUTPUT can truncate — extract first JSON object. */
function extractJsonObjectText(raw: string): string {
  let t = raw.trim();
  const fenced = /^```(?:json)?\s*([\s\S]*?)```$/im.exec(t);
  if (fenced) t = fenced[1].trim();
  const start = t.indexOf("{");
  const end = t.lastIndexOf("}");
  if (start >= 0 && end > start) return t.slice(start, end + 1);
  return t;
}

async function callGemini(
  prompt: string,
  apiKey: string,
  signal: AbortSignal,
  maxOutputTokens: number,
  mealTypes: MealType[],
): Promise<{ text: string | undefined; finishReason?: string }> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{
          parts: [{ text: prompt }],
        }],
        generationConfig: {
          responseMimeType: "application/json",
          responseJsonSchema: dayPlanResponseJsonSchema(mealTypes, mealTypes.length),
          temperature: 0.7,
          maxOutputTokens,
        },
      }),
      signal,
    },
  );

  if (response.status === 429) {
    throw Object.assign(new Error("rate limited"), { status: 429 });
  }
  if (!response.ok) {
    throw Object.assign(new Error(`upstream ${response.status}`), { status: 502 });
  }

  const data = await response.json();
  const candidate = data?.candidates?.[0];
  const text = candidate?.content?.parts?.[0]?.text as string | undefined;
  const finishReason = candidate?.finishReason as string | undefined;
  return { text, finishReason };
}

function logEvent(event: string, data: Record<string, unknown>): void {
  console.log(JSON.stringify({
    fn: FUNCTION_NAME,
    event,
    ...data,
  }));
}

function stageError(
  code:
    | "BAD_REQUEST"
    | "AI_TIMEOUT"
    | "AI_UNAVAILABLE"
    | "AI_SCHEMA_INVALID"
    | "AI_RATE_LIMITED"
    | "INTERNAL",
  message: string,
  status: number,
  stage: string,
  details?: string,
): Response {
  return jsonResponse({ error: code, message, stage, details }, status);
}

function stripInternalMealFields(meal: DayMeal): DayMeal {
  const { cachedMealId: _cachedMealId, cacheScore: _cacheScore, ...publicMeal } = meal;
  return publicMeal;
}

function publicDayPlan(input: GenerateDayPayload, meals: DayMeal[]): DayPlan {
  const publicMeals = sortMeals(meals).map(stripInternalMealFields);
  return {
    day: input.dayName,
    dayName: input.dayName,
    date: input.date,
    totalCalories: roundWhole(publicMeals.reduce((total, meal) => total + meal.calories, 0)),
    meals: publicMeals,
  };
}

function parseAndValidateDayPlan(
  text: string,
  input: GenerateDayPayload,
  expectedMealTypes: MealType[],
  hardTags: string[],
  excludeNames: Set<string>,
): DayPlan {
  const parsed = JSON.parse(extractJsonObjectText(text));
  const normalized = normalizeParsedDayPlan(parsed);
  validateDayPlanShape(normalized, input, expectedMealTypes, hardTags, excludeNames);
  return normalized;
}

function normalizeParsedDayPlan(parsed: unknown): DayPlan {
  if (typeof parsed !== "object" || parsed === null) {
    throw new Error("response is not an object");
  }
  const object = { ...(parsed as Record<string, unknown>) };
  const dayName = object.dayName;
  const day = object.day;

  if (typeof dayName === "string" && !day) {
    object.day = dayName;
  } else if (typeof day === "string" && !dayName) {
    object.dayName = day;
  }

  return object as DayPlan;
}

function validateDayPlanShape(
  plan: DayPlan,
  input: GenerateDayPayload,
  expectedMealTypes: MealType[],
  hardTags: string[],
  excludeNames: Set<string>,
): void {
  if (typeof plan.day !== "string" || typeof plan.date !== "string") {
    throw new Error("day and date are required");
  }
  if (plan.date !== input.date) {
    throw new Error("date mismatch");
  }
  if (!Array.isArray(plan.meals) || plan.meals.length !== expectedMealTypes.length) {
    throw new Error(`expected ${expectedMealTypes.length} meals`);
  }

  const expected = new Set(expectedMealTypes);
  const seen = new Set<string>();
  for (const meal of plan.meals) {
    validateMealShape(meal, hardTags);
    if (!expected.has(meal.type)) {
      throw new Error(`unexpected meal type ${meal.type}`);
    }
    if (seen.has(meal.type)) {
      throw new Error(`duplicate meal type ${meal.type}`);
    }
    seen.add(meal.type);
    if (excludeNames.has(normalizeName(meal.name))) {
      throw new Error(`excluded meal returned: ${meal.name}`);
    }
  }
}

function validateMealShape(meal: DayMeal, hardTags: string[]): void {
  if (!MEAL_TYPES.includes(meal.type)) throw new Error("invalid meal type");
  if (typeof meal.name !== "string" || !meal.name.trim()) throw new Error("meal name required");
  if (typeof meal.emoji !== "string" || !meal.emoji.trim()) throw new Error("meal emoji required");
  for (const field of ["calories", "protein", "carbs", "fat"] as const) {
    if (typeof meal[field] !== "number" || Number.isNaN(meal[field]) || meal[field] < 0) {
      throw new Error(`invalid meal ${field}`);
    }
  }
  meal.dietary_tags = uniqueSortedTags(meal.dietary_tags);
  meal.ingredients = Array.isArray(meal.ingredients)
    ? meal.ingredients.filter((ingredient): ingredient is string => typeof ingredient === "string" && ingredient.trim().length > 0)
    : [];
  meal.cuisine = typeof meal.cuisine === "string" && meal.cuisine.trim() ? meal.cuisine.trim() : "general";
  for (const tag of hardTags) {
    if (!meal.dietary_tags.includes(tag)) {
      throw new Error(`missing hard dietary tag ${tag}`);
    }
  }
}

function dayTotals(meals: DayMeal[]): MealTarget {
  return meals.reduce((total, meal) => ({
    calories: total.calories + meal.calories,
    protein: total.protein + meal.protein,
    carbs: total.carbs + meal.carbs,
    fat: total.fat + meal.fat,
  }), { calories: 0, protein: 0, carbs: 0, fat: 0 });
}

function isWithinDayTolerance(meals: DayMeal[], input: GenerateDayPayload): boolean {
  const totals = dayTotals(meals);
  return Math.abs(totals.calories - input.targetCalories) <= CALORIE_TOLERANCE &&
    Math.abs(totals.protein - input.macros.protein) <= MACRO_TOLERANCE &&
    Math.abs(totals.carbs - input.macros.carbs) <= MACRO_TOLERANCE &&
    Math.abs(totals.fat - input.macros.fat) <= MACRO_TOLERANCE;
}

function sortMeals(meals: DayMeal[]): DayMeal[] {
  return [...meals].sort((a, b) => MEAL_TYPES.indexOf(a.type) - MEAL_TYPES.indexOf(b.type));
}

function cacheHeaders(serviceRoleKey: string): HeadersInit {
  return {
    "Content-Type": "application/json",
    "apikey": serviceRoleKey,
    "Authorization": `Bearer ${serviceRoleKey}`,
  };
}

function cacheConfig(): { supabaseUrl: string; serviceRoleKey: string } | null {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) return null;
  return { supabaseUrl, serviceRoleKey };
}

async function fetchCachedCandidates(
  type: MealType,
  target: MealTarget,
  hardTags: string[],
  softTags: string[],
  excludeNames: Set<string>,
): Promise<ScoredMeal[]> {
  const config = cacheConfig();
  if (!config) {
    logEvent("cache_unavailable", { reason: "missing_supabase_service_config" });
    return [];
  }

  const low = Math.floor(target.calories / 1.2);
  const high = Math.ceil(target.calories / 0.8);
  const params = new URLSearchParams({
    select: "*",
    is_active: "eq.true",
    meal_type: `eq.${MEAL_TYPE_TO_KEY[type]}`,
    calories: `gte.${low}`,
    order: "usage_count.asc.nullsfirst,last_used_at.asc.nullsfirst",
    limit: "50",
  });
  params.append("calories", `lte.${high}`);

  try {
    const response = await fetch(`${config.supabaseUrl}/rest/v1/cached_meals?${params}`, {
      headers: cacheHeaders(config.serviceRoleKey),
    });
    if (!response.ok) {
      logEvent("cache_lookup_failure", { mealType: type, status: response.status });
      return [];
    }
    const rows = (await response.json()) as CachedMealRow[];
    const scored = rows
      .filter((row) => {
        const rowTags = uniqueSortedTags(row.dietary_tags);
        return hardTags.every((tag) => rowTags.includes(tag));
      })
      .filter((row) => !excludeNames.has(row.normalized_name))
      .map((row) => scoreCachedMeal(row, type, target, softTags))
      .filter((candidate): candidate is ScoredMeal => candidate !== null)
      .sort((a, b) => a.score - b.score)
      .slice(0, MAX_CACHE_CANDIDATES_PER_TYPE);
    logEvent("cache_candidates_found", {
      mealType: type,
      candidateCount: scored.length,
      hardTagCount: hardTags.length,
    });
    return scored;
  } catch (error) {
    logEvent("cache_lookup_failure", {
      mealType: type,
      error: error instanceof Error ? error.message : String(error),
    });
    return [];
  }
}

function scoreCachedMeal(
  row: CachedMealRow,
  type: MealType,
  target: MealTarget,
  softTags: string[],
): ScoredMeal | null {
  const calories = toNumber(row.calories);
  if (calories <= 0) return null;
  const minScale = row.scalable ? toNumber(row.min_scale) || 0.8 : 1;
  const maxScale = row.scalable ? toNumber(row.max_scale) || 1.2 : 1;
  const scale = Math.min(maxScale, Math.max(minScale, target.calories / calories));
  const meal: DayMeal = {
    type,
    name: row.name,
    calories: roundWhole(calories * scale),
    emoji: emojiForMealType(type),
    protein: round1(toNumber(row.protein_g) * scale),
    carbs: round1(toNumber(row.carbs_g) * scale),
    fat: round1(toNumber(row.fat_g) * scale),
    dietary_tags: uniqueSortedTags(row.dietary_tags),
    cuisine: row.cuisine ?? "general",
    ingredients: Array.isArray(row.ingredients) ? row.ingredients : [],
    cachedMealId: row.id,
  };
  const usagePenalty = Math.min((row.usage_count ?? 0) * 0.04, 1.2);
  const softTagBonus = softTags.filter((tag) => meal.dietary_tags.includes(tag)).length * 0.2;
  const score =
    Math.abs(meal.calories - target.calories) / CALORIE_TOLERANCE +
    Math.abs(meal.protein - target.protein) / MACRO_TOLERANCE +
    Math.abs(meal.carbs - target.carbs) / MACRO_TOLERANCE +
    Math.abs(meal.fat - target.fat) / MACRO_TOLERANCE +
    usagePenalty -
    softTagBonus;
  meal.cacheScore = round1(score);
  return { row, meal, score };
}

function emojiForMealType(type: MealType): string {
  switch (type) {
    case "Breakfast":
      return "🥣";
    case "Lunch":
      return "🥗";
    case "Dinner":
      return "🍽️";
    case "Snack":
      return "🍎";
  }
}

async function assembleCachedMeals(
  input: GenerateDayPayload,
  hardTags: string[],
  softTags: string[],
  excludeNames: Set<string>,
): Promise<DayMeal[]> {
  const targets = buildMealTargets(input);
  const selected: DayMeal[] = [];
  const selectedNames = new Set<string>();
  for (const type of MEAL_TYPES) {
    logEvent("cache_lookup_start", { dayName: input.dayName, mealType: type });
    const candidates = await fetchCachedCandidates(type, targets[type], hardTags, softTags, excludeNames);
    const hit = candidates.find((candidate) =>
      candidate.score <= MAX_ACCEPTABLE_MEAL_SCORE &&
      !selectedNames.has(normalizeName(candidate.meal.name))
    );
    if (hit) {
      selected.push(hit.meal);
      selectedNames.add(normalizeName(hit.meal.name));
    }
  }

  while (selected.length === MEAL_TYPES.length && !isWithinDayTolerance(selected, input)) {
    const worst = selected.reduce((worstIndex, meal, index, meals) =>
      (meal.cacheScore ?? 0) > (meals[worstIndex].cacheScore ?? 0) ? index : worstIndex, 0);
    selected.splice(worst, 1);
  }

  logEvent("cache_assembly_selected", {
    dayName: input.dayName,
    cachedMealCount: selected.length,
    score: round1(selected.reduce((sum, meal) => sum + (meal.cacheScore ?? 0), 0)),
  });
  return selected;
}

function remainingTargets(input: GenerateDayPayload, selected: DayMeal[], missingTypes: MealType[]): {
  combined: MealTarget;
  perType: Record<MealType, MealTarget>;
} {
  const totals = dayTotals(selected);
  const distributionTotal = missingTypes.reduce((sum, type) => sum + MEAL_DISTRIBUTION[type], 0) || 1;
  const combined = {
    calories: Math.max(0, input.targetCalories - totals.calories),
    protein: Math.max(0, input.macros.protein - totals.protein),
    carbs: Math.max(0, input.macros.carbs - totals.carbs),
    fat: Math.max(0, input.macros.fat - totals.fat),
  };
  const perType = Object.fromEntries(MEAL_TYPES.map((type) => {
    const weight = missingTypes.includes(type) ? MEAL_DISTRIBUTION[type] / distributionTotal : 0;
    return [type, {
      calories: combined.calories * weight,
      protein: combined.protein * weight,
      carbs: combined.carbs * weight,
      fat: combined.fat * weight,
    }];
  })) as Record<MealType, MealTarget>;
  return { combined, perType };
}

async function generateWithGemini(
  input: GenerateDayPayload,
  apiKey: string,
  signal: AbortSignal,
  prompt: string,
  expectedMealTypes: MealType[],
  hardTags: string[],
  excludeNames: Set<string>,
  eventName: string,
): Promise<DayPlan> {
  let lastParseError: string | undefined;
  logEvent(eventName, {
    dayName: input.dayName,
    mealTypes: expectedMealTypes,
    promptLength: prompt.length,
  });

  for (let attempt = 0; attempt < 2; attempt++) {
    const maxTokens = attempt === 0 ? 4096 : 8192;
    const { text, finishReason } = await callGemini(
      prompt,
      apiKey,
      signal,
      maxTokens,
      expectedMealTypes,
    );
    logEvent("gemini_response_received", {
      dayName: input.dayName,
      attempt,
      finishReason: finishReason ?? null,
      expectedMealCount: expectedMealTypes.length,
    });

    if (!text?.trim()) {
      lastParseError = finishReason
        ? `Gemini returned empty text (finishReason: ${finishReason})`
        : "Gemini returned empty text";
      logEvent("gemini_empty_text", {
        dayName: input.dayName,
        attempt,
        finishReason: finishReason ?? null,
      });
      continue;
    }

    try {
      const parseStartedMs = Date.now();
      const parsed = parseAndValidateDayPlan(text, input, expectedMealTypes, hardTags, excludeNames);
      const parseDurationMs = Date.now() - parseStartedMs;
      logEvent("parse_success", {
        dayName: input.dayName,
        attempt,
        parseDurationMs,
        expectedMealCount: expectedMealTypes.length,
      });
      return parsed;
    } catch (e) {
      lastParseError = e instanceof Error ? e.message : String(e);
      logEvent("parse_failure", {
        dayName: input.dayName,
        attempt,
        error: lastParseError,
      });
    }
  }

  throw Object.assign(new Error(lastParseError ?? "Gemini returned invalid JSON"), { status: 422 });
}

async function upsertGeminiMeals(meals: DayMeal[]): Promise<void> {
  if (!meals.length) return;
  const config = cacheConfig();
  if (!config) return;

  const rows = meals.map((meal) => ({
    name: meal.name,
    meal_type: MEAL_TYPE_TO_KEY[meal.type],
    calories: meal.calories,
    protein_g: meal.protein,
    carbs_g: meal.carbs,
    fat_g: meal.fat,
    dietary_tags: uniqueSortedTags(meal.dietary_tags),
    dietary_tags_key: tagsKey(meal.dietary_tags),
    cuisine: meal.cuisine,
    ingredients: meal.ingredients,
    source: "gemini",
    scalable: true,
    min_scale: 0.80,
    max_scale: 1.20,
  }));

  try {
    const response = await fetch(
      `${config.supabaseUrl}/rest/v1/cached_meals?on_conflict=normalized_name,meal_type,dietary_tags_key`,
      {
        method: "POST",
        headers: {
          ...cacheHeaders(config.serviceRoleKey),
          "Prefer": "resolution=merge-duplicates",
        },
        body: JSON.stringify(rows),
      },
    );
    if (!response.ok) {
      logEvent("cache_write_failure", { status: response.status, mealCount: rows.length });
      return;
    }
    logEvent("cache_write_success", { mealCount: rows.length });
  } catch (error) {
    logEvent("cache_write_failure", {
      mealCount: rows.length,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

async function touchCachedMealUsage(meals: DayMeal[]): Promise<void> {
  const ids = meals.map((meal) => meal.cachedMealId).filter((id): id is string => Boolean(id));
  if (!ids.length) return;
  const config = cacheConfig();
  if (!config) return;
  try {
    await fetch(`${config.supabaseUrl}/rest/v1/rpc/touch_cached_meal_usage`, {
      method: "POST",
      headers: cacheHeaders(config.serviceRoleKey),
      body: JSON.stringify({ meal_ids: ids }),
    });
  } catch (error) {
    logEvent("cache_usage_touch_failure", {
      mealCount: ids.length,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

async function validateJwt(req: Request): Promise<{ userId: string | null }> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.trim()) {
    logEvent("auth_warning", { reason: "missing_authorization", detail: "anonymous request; using client profile" });
    return { userId: null };
  }

  const jwt = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!jwt) {
    logEvent("auth_warning", { reason: "empty_bearer_token", detail: "anonymous request; using client profile" });
    return { userId: null };
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    logEvent("auth_warning", {
      reason: "missing_supabase_env",
      detail: "cannot validate JWT; using client profile",
    });
    return { userId: null };
  }

  try {
    const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: {
        "apikey": serviceRoleKey,
        "Authorization": `Bearer ${jwt}`,
      },
    });

    if (!userResponse.ok) {
      logEvent("auth_warning", {
        reason: "invalid_token",
        status: userResponse.status,
        detail: "anonymous request; using client profile",
      });
      return { userId: null };
    }

    const userData = (await userResponse.json()) as { id?: string };
    const userId = userData.id;
    if (!userId) {
      logEvent("auth_warning", { reason: "no_user_id", detail: "anonymous request; using client profile" });
      return { userId: null };
    }

    return { userId };
  } catch (error) {
    logEvent("auth_warning", {
      reason: "auth_request_failed",
      error: error instanceof Error ? error.message : String(error),
      detail: "anonymous request; using client profile",
    });
    return { userId: null };
  }
}

async function fetchProfileDietaryPreferencesFromDb(userId: string): Promise<unknown[] | null> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) return null;

  try {
    const params = new URLSearchParams({
      select: "dietary_preferences",
      user_id: `eq.${userId}`,
      limit: "1",
    });
    const response = await fetch(`${supabaseUrl}/rest/v1/profiles?${params}`, {
      headers: cacheHeaders(serviceRoleKey),
    });
    if (!response.ok) {
      logEvent("profile_fetch_failure", { userId, status: response.status });
      return null;
    }
    const rows = (await response.json()) as { dietary_preferences?: unknown }[];
    if (!Array.isArray(rows) || rows.length === 0) return null;
    const raw = rows[0]?.dietary_preferences;
    if (!Array.isArray(raw) || raw.length === 0) return null;
    return raw;
  } catch (error) {
    logEvent("profile_fetch_failure", {
      userId,
      error: error instanceof Error ? error.message : String(error),
    });
    return null;
  }
}

Deno.serve(async (req) => {
  const requestStartedMs = Date.now();
  const requestStartedAt = new Date(requestStartedMs).toISOString();
  let payload: GenerateDayPayload;

  if (req.method !== "POST") {
    return stageError("BAD_REQUEST", "POST required", 405, "invalid_method");
  }

  const { userId } = await validateJwt(req);

  try {
    payload = await req.json();
  } catch {
    return stageError("BAD_REQUEST", "Invalid JSON body", 400, "invalid_json_body");
  }

  logEvent("request_start", {
    at: requestStartedAt,
    dayName: payload.dayName ?? null,
    excludeMealNameCount: Array.isArray(payload.excludeMealNames) ? payload.excludeMealNames.length : 0,
  });

  if (!payload.profile || typeof payload.profile !== "object") {
    return stageError("BAD_REQUEST", "profile is required", 400, "missing_profile");
  }
  if (typeof payload.targetCalories !== "number" || Number.isNaN(payload.targetCalories)) {
    return stageError("BAD_REQUEST", "targetCalories is required", 400, "missing_target_calories");
  }
  const m = payload.macros;
  if (
    !m ||
    typeof m.protein !== "number" ||
    typeof m.carbs !== "number" ||
    typeof m.fat !== "number"
  ) {
    return stageError(
      "BAD_REQUEST",
      "macros with numeric protein, carbs, and fat are required",
      400,
      "missing_macros",
    );
  }

  if (!payload.dayName || !payload.date) {
    return stageError("BAD_REQUEST", "dayName and date are required", 400, "missing_day_or_date");
  }

  if (userId) {
    const dbPrefs = await fetchProfileDietaryPreferencesFromDb(userId);
    if (dbPrefs !== null) {
      const tags = uniqueSortedTags(dbPrefs);
      if (tags.length > 0) {
        payload.profile = { ...payload.profile, dietaryPreferences: tags };
        logEvent("profile_dietary_override", { userId, tagCount: tags.length });
      }
    }
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return stageError(
      "AI_UNAVAILABLE",
      "Missing GEMINI_API_KEY secret",
      500,
      "missing_api_key",
    );
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const { hardTags, softTags } = profileDietaryTags(payload.profile);
    const excludeNames = new Set((payload.excludeMealNames ?? []).map(normalizeName).filter(Boolean));
    const cachedMeals = await assembleCachedMeals(payload, hardTags, softTags, excludeNames);
    const selectedTypes = new Set(cachedMeals.map((meal) => meal.type));
    const missingTypes = MEAL_TYPES.filter((type) => !selectedTypes.has(type));

    if (!missingTypes.length && isWithinDayTolerance(cachedMeals, payload)) {
      logEvent("cache_hit_full_day", {
        dayName: payload.dayName,
        cachedMealCount: cachedMeals.length,
      });
      await touchCachedMealUsage(cachedMeals);
      return jsonResponse(publicDayPlan(payload, cachedMeals));
    }

    let freshMeals: DayMeal[] = [];
    if (cachedMeals.length) {
      logEvent("cache_hit_partial_day", {
        dayName: payload.dayName,
        cachedMealCount: cachedMeals.length,
        missingMealCount: missingTypes.length,
      });
      const targets = remainingTargets(payload, cachedMeals, missingTypes);
      const prompt = buildPartialMealsPrompt(
        payload,
        cachedMeals,
        missingTypes,
        targets.combined,
        targets.perType,
        hardTags,
        softTags,
        excludeNames,
      );
      try {
        const partial = await generateWithGemini(
          payload,
          apiKey,
          controller.signal,
          prompt,
          missingTypes,
          hardTags,
          new Set([...excludeNames, ...cachedMeals.map((meal) => normalizeName(meal.name))]),
          "gemini_partial_request",
        );
        freshMeals = partial.meals;
      } catch (error) {
        logEvent("gemini_full_fallback", {
          dayName: payload.dayName,
          reason: error instanceof Error ? error.message : String(error),
        });
        const prompt = buildFullDayPrompt(payload, hardTags, softTags, excludeNames);
        const full = await generateWithGemini(
          payload,
          apiKey,
          controller.signal,
          prompt,
          MEAL_TYPES,
          hardTags,
          excludeNames,
          "gemini_full_request",
        );
        freshMeals = full.meals;
        cachedMeals.splice(0, cachedMeals.length);
      }
    } else {
      logEvent("cache_miss", { dayName: payload.dayName });
      const prompt = buildFullDayPrompt(payload, hardTags, softTags, excludeNames);
      const full = await generateWithGemini(
        payload,
        apiKey,
        controller.signal,
        prompt,
        MEAL_TYPES,
        hardTags,
        excludeNames,
        "gemini_full_request",
      );
      freshMeals = full.meals;
    }

    const combinedMeals = sortMeals([...cachedMeals, ...freshMeals]);
    try {
      validateDayPlanShape(
        { day: payload.dayName, date: payload.date, totalCalories: payload.targetCalories, meals: combinedMeals },
        payload,
        MEAL_TYPES,
        hardTags,
        excludeNames,
      );
      if (!isWithinDayTolerance(combinedMeals, payload)) {
        throw new Error("combined day outside target tolerance");
      }
    } catch (error) {
      logEvent("final_validation_failure", {
        dayName: payload.dayName,
        error: error instanceof Error ? error.message : String(error),
      });
      const prompt = buildFullDayPrompt(payload, hardTags, softTags, excludeNames);
      const full = await generateWithGemini(
        payload,
        apiKey,
        controller.signal,
        prompt,
        MEAL_TYPES,
        hardTags,
        excludeNames,
        "gemini_full_request",
      );
      if (!isWithinDayTolerance(full.meals, payload)) {
        throw Object.assign(new Error("full-day fallback outside target tolerance"), { status: 422 });
      }
      await upsertGeminiMeals(full.meals);
      return jsonResponse(publicDayPlan(payload, full.meals));
    }

    await Promise.all([
      upsertGeminiMeals(freshMeals),
      touchCachedMealUsage(cachedMeals),
    ]);
    return jsonResponse(publicDayPlan(payload, combinedMeals));
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      return stageError("AI_TIMEOUT", "Gemini request timed out", 504, "gemini_timeout");
    }
    const status = (error as { status?: number }).status;
    if (status === 429) {
      return stageError("AI_RATE_LIMITED", "Gemini rate limited request", 429, "gemini_rate_limited");
    }
    if (status === 422) {
      return stageError(
        "AI_SCHEMA_INVALID",
        error instanceof Error ? error.message : "Gemini returned invalid JSON",
        422,
        "gemini_parse_error",
      );
    }
    if (status === 502) {
      return stageError("AI_UNAVAILABLE", "Gemini upstream error", 502, "gemini_upstream_error");
    }
    return stageError("AI_UNAVAILABLE", "Gemini is unreachable", 502, "gemini_unreachable");
  } finally {
    clearTimeout(timer);
    logEvent("request_complete", {
      dayName: payload.dayName,
      totalExecutionMs: Date.now() - requestStartedMs,
    });
  }
});
