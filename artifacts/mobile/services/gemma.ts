import AsyncStorage from "@react-native-async-storage/async-storage";
import { Alert } from "react-native";

import type { UserProfile } from "@/constants/types";
import calculateAll, { type CalculationResults } from "@/services/calculations";

// ─── Types ────────────────────────────────────────────────────────────────────

export interface MockMeal {
  type: string;
  name: string;
  calories: number;
  emoji: string;
  protein: number;
  carbs: number;
  fat: number;
}

export interface MockDayPlan {
  day: string;
  date: string;
  totalCalories: number;
  meals: MockMeal[];
}

export interface MockWeeklyPlan {
  weekOf: string;
  days: MockDayPlan[];
}

// ─── Config ───────────────────────────────────────────────────────────────────

const OLLAMA_BASE_URL = "https://nutriweek.emlakcrm.app";
const MODEL = "gemma4:e4b";
const TIMEOUT_MS = 120_000;

const NGROK_HEADERS = {
  "Content-Type": "application/json",
};

// ─── Fallback mock plan ────────────────────────────────────────────────────────

const MOCK_PLAN: MockWeeklyPlan = {
  weekOf: "2026-05-04",
  days: [
    {
      day: "Monday",
      date: "2026-05-04",
      totalCalories: 2100,
      meals: [
        { type: "Breakfast", name: "Oatmeal with Berries", calories: 380, emoji: "🥣", protein: 12, carbs: 62, fat: 7 },
        { type: "Lunch", name: "Grilled Chicken Salad", calories: 520, emoji: "🥗", protein: 42, carbs: 28, fat: 16 },
        { type: "Dinner", name: "Salmon with Vegetables", calories: 680, emoji: "🐟", protein: 48, carbs: 38, fat: 26 },
        { type: "Snack", name: "Greek Yogurt", calories: 150, emoji: "🥛", protein: 15, carbs: 12, fat: 3 },
      ],
    },
    {
      day: "Tuesday",
      date: "2026-05-05",
      totalCalories: 2080,
      meals: [
        { type: "Breakfast", name: "Scrambled Eggs & Toast", calories: 420, emoji: "🍳", protein: 22, carbs: 38, fat: 18 },
        { type: "Lunch", name: "Turkey Wrap", calories: 490, emoji: "🌯", protein: 35, carbs: 48, fat: 14 },
        { type: "Dinner", name: "Beef Stir Fry with Rice", calories: 720, emoji: "🥩", protein: 45, carbs: 72, fat: 22 },
        { type: "Snack", name: "Apple with Almond Butter", calories: 180, emoji: "🍎", protein: 5, carbs: 22, fat: 9 },
      ],
    },
    {
      day: "Wednesday",
      date: "2026-05-06",
      totalCalories: 2150,
      meals: [
        { type: "Breakfast", name: "Protein Smoothie", calories: 350, emoji: "🥤", protein: 30, carbs: 42, fat: 6 },
        { type: "Lunch", name: "Quinoa Buddha Bowl", calories: 580, emoji: "🥙", protein: 22, carbs: 78, fat: 18 },
        { type: "Dinner", name: "Grilled Chicken & Sweet Potato", calories: 650, emoji: "🍗", protein: 50, carbs: 58, fat: 16 },
        { type: "Snack", name: "Mixed Nuts", calories: 200, emoji: "🥜", protein: 6, carbs: 8, fat: 18 },
      ],
    },
    {
      day: "Thursday",
      date: "2026-05-07",
      totalCalories: 2090,
      meals: [
        { type: "Breakfast", name: "Avocado Toast & Eggs", calories: 440, emoji: "🥑", protein: 18, carbs: 38, fat: 22 },
        { type: "Lunch", name: "Lentil Soup", calories: 460, emoji: "🍲", protein: 24, carbs: 68, fat: 8 },
        { type: "Dinner", name: "Tuna Pasta", calories: 620, emoji: "🍝", protein: 40, carbs: 72, fat: 14 },
        { type: "Snack", name: "Cottage Cheese", calories: 140, emoji: "🧀", protein: 18, carbs: 6, fat: 4 },
      ],
    },
    {
      day: "Friday",
      date: "2026-05-08",
      totalCalories: 2120,
      meals: [
        { type: "Breakfast", name: "Banana Pancakes", calories: 410, emoji: "🥞", protein: 14, carbs: 68, fat: 10 },
        { type: "Lunch", name: "Caesar Salad with Chicken", calories: 510, emoji: "🥗", protein: 38, carbs: 22, fat: 26 },
        { type: "Dinner", name: "Shrimp Tacos", calories: 680, emoji: "🌮", protein: 42, carbs: 65, fat: 20 },
        { type: "Snack", name: "Protein Bar", calories: 220, emoji: "🍫", protein: 20, carbs: 24, fat: 8 },
      ],
    },
    {
      day: "Saturday",
      date: "2026-05-09",
      totalCalories: 2200,
      meals: [
        { type: "Breakfast", name: "Full English Breakfast", calories: 520, emoji: "🍳", protein: 28, carbs: 30, fat: 28 },
        { type: "Lunch", name: "Burger & Side Salad", calories: 620, emoji: "🍔", protein: 36, carbs: 56, fat: 26 },
        { type: "Dinner", name: "Grilled Steak & Veggies", calories: 750, emoji: "🥩", protein: 58, carbs: 32, fat: 36 },
        { type: "Snack", name: "Dark Chocolate", calories: 160, emoji: "🍫", protein: 2, carbs: 18, fat: 10 },
      ],
    },
    {
      day: "Sunday",
      date: "2026-05-10",
      totalCalories: 2050,
      meals: [
        { type: "Breakfast", name: "Overnight Oats", calories: 380, emoji: "🥣", protein: 14, carbs: 60, fat: 8 },
        { type: "Lunch", name: "Vegetable Curry & Rice", calories: 540, emoji: "🍛", protein: 16, carbs: 88, fat: 12 },
        { type: "Dinner", name: "Baked Cod & Salad", calories: 580, emoji: "🐟", protein: 48, carbs: 38, fat: 18 },
        { type: "Snack", name: "Hummus & Veggies", calories: 170, emoji: "🥕", protein: 6, carbs: 20, fat: 8 },
      ],
    },
  ],
};

// ─── Prompt builder ───────────────────────────────────────────────────────────

function buildMealPlanPrompt(profile: UserProfile, calc: CalculationResults): string {
  const dietStr =
    profile.dietaryPreferences.length > 0
      ? profile.dietaryPreferences.join(", ")
      : "none";

  const today = new Date();
  const monday = new Date(today);
  monday.setDate(today.getDate() - today.getDay() + 1);
  const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  const dates = days.map((_, i) => {
    const d = new Date(monday);
    d.setDate(monday.getDate() + i);
    return d.toISOString().slice(0, 10);
  });

  const exampleDays = days.map((day, i) => ({
    day,
    date: dates[i],
    totalCalories: calc.targetCalories,
    meals: [
      { type: "Breakfast", name: "meal name", calories: Math.round(calc.targetCalories * 0.2), emoji: "🥣", protein: Math.round(calc.macros.protein * 0.2), carbs: Math.round(calc.macros.carbs * 0.2), fat: Math.round(calc.macros.fat * 0.2) },
      { type: "Lunch", name: "meal name", calories: Math.round(calc.targetCalories * 0.3), emoji: "🥗", protein: Math.round(calc.macros.protein * 0.3), carbs: Math.round(calc.macros.carbs * 0.3), fat: Math.round(calc.macros.fat * 0.3) },
      { type: "Dinner", name: "meal name", calories: Math.round(calc.targetCalories * 0.35), emoji: "🍗", protein: Math.round(calc.macros.protein * 0.35), carbs: Math.round(calc.macros.carbs * 0.35), fat: Math.round(calc.macros.fat * 0.35) },
      { type: "Snack", name: "meal name", calories: Math.round(calc.targetCalories * 0.1), emoji: "🍎", protein: Math.round(calc.macros.protein * 0.1), carbs: Math.round(calc.macros.carbs * 0.1), fat: Math.round(calc.macros.fat * 0.1) },
    ],
  }));

  return `You are a nutritionist. Generate a 7-day meal plan.
Return a single valid JSON object. No markdown, no code fences, no text before or after the JSON. The entire response must pass JSON.parse().

Constraints:
- Total daily calories MUST be exactly ${calc.targetCalories} kcal (±50 kcal tolerance)
- Daily protein MUST be ${calc.macros.protein}g (±5g), carbs ${calc.macros.carbs}g (±5g), fat ${calc.macros.fat}g (±5g)
- The four meals (Breakfast, Lunch, Dinner, Snack) MUST sum to the daily totals within the above tolerances
- Follow FDA 2025 priority: lean protein → dairy → vegetables → whole grains → fruits
- Meal names MUST be descriptive (e.g., "Grilled Chicken & Quinoa Bowl" not just "Chicken")
- Include an appropriate food emoji for each meal
- Each day must have exactly 4 meals: Breakfast, Lunch, Dinner, Snack
- Portion distribution: Breakfast ~25%, Lunch ~30%, Dinner ~35%, Snack ~10% of daily calories

${dietStr !== "none" ? `- Dietary restrictions: ${dietStr}. All meals must comply.` : ""}

User: ${profile.age}yo ${profile.gender}, ${profile.weight}kg, ${profile.height}cm, goal: ${profile.goal}, activity: ${profile.activityLevel}

Week starts Monday ${dates[0]}. Generate all 7 days (${days.join(", ")}).

Required JSON structure:
{
  "weekOf": "${dates[0]}",
  "days": [
    {
      "day": "Monday",
      "date": "${dates[0]}",
      "totalCalories": ${calc.targetCalories},
      "meals": [
        {"type": "Breakfast", "name": "MEAL NAME HERE", "calories": NUMBER, "emoji": "EMOJI", "protein": NUMBER, "carbs": NUMBER, "fat": NUMBER},
        {"type": "Lunch", "name": "MEAL NAME HERE", "calories": NUMBER, "emoji": "EMOJI", "protein": NUMBER, "carbs": NUMBER, "fat": NUMBER},
        {"type": "Dinner", "name": "MEAL NAME HERE", "calories": NUMBER, "emoji": "EMOJI", "protein": NUMBER, "carbs": NUMBER, "fat": NUMBER},
        {"type": "Snack", "name": "MEAL NAME HERE", "calories": NUMBER, "emoji": "EMOJI", "protein": NUMBER, "carbs": NUMBER, "fat": NUMBER}
      ]
    }
  ]
}

IMPORTANT: Replace MEAL NAME HERE, NUMBER, EMOJI with actual values. Do NOT copy the placeholder text.`;
}

// ─── Generic Gemma helper ─────────────────────────────────────────────────────

export async function askGemma(prompt: string): Promise<string> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), TIMEOUT_MS);

  const url = `${OLLAMA_BASE_URL}/api/generate`;
  console.log("Fetching from:", OLLAMA_BASE_URL);

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: NGROK_HEADERS,
      body: JSON.stringify({ model: MODEL, prompt, stream: false, options: { num_predict: 2048 } }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    console.log("Response status:", response.status);

    if (!response.ok) {
      const body = await response.text().catch((error) => {
        console.error("Full error:", JSON.stringify(error));
        console.error("[askGemma] Non-OK body read error:", error);
        return "(unreadable body)";
      });
      console.error("[askGemma] Non-OK response body:", body);
      throw new Error("OLLAMA_OFFLINE");
    }

    const data = (await response.json()) as { response?: string };
    const text = data.response ?? "";
    console.log("[askGemma] Raw response structure:", JSON.stringify(data));
    console.log("[askGemma] Response length:", text.length, "chars");
    Alert.alert("RAW RESPONSE (first 500):\n" + text.substring(0, 500));
    return text;
  } catch (err) {
    clearTimeout(timeoutId);
    if (err instanceof Error) {
      console.error("[askGemma] CATCH name:", err.name, "| message:", err.message);
      console.error("Full error:", JSON.stringify(err));
      if (err.name === "AbortError") throw new Error("OLLAMA_TIMEOUT");
      if (err.message === "OLLAMA_OFFLINE" || err.message === "OLLAMA_TIMEOUT") throw err;
    } else {
      console.error("[askGemma] CATCH unknown error:", err);
      console.error("Full error:", JSON.stringify(err));
    }
    throw new Error("OLLAMA_OFFLINE");
  }
}

// ─── Parse Gemma JSON response ────────────────────────────────────────────────

function parseWeeklyPlan(text: string): MockWeeklyPlan {
  const match = text.match(/\{[\s\S]*\}/);
  console.log("[parseWeeklyPlan] regex match success:", !!match);
  if (!match) throw new Error("PARSE_ERROR");

  let parsed: MockWeeklyPlan;
  try {
    parsed = JSON.parse(match[0]) as MockWeeklyPlan;
  } catch (error) {
    console.error("[parseWeeklyPlan] JSON.parse failed:", error);
    throw new Error("PARSE_ERROR");
  }

  if (!parsed.days || !Array.isArray(parsed.days) || parsed.days.length === 0) {
    throw new Error("PARSE_ERROR");
  }
  console.log("[parseWeeklyPlan] parsed days length:", parsed.days.length);

  // Normalise any missing numeric meal fields to 0
  parsed.days = parsed.days.map((day) => ({
    ...day,
    meals: (day.meals ?? []).map((meal) => ({
      ...meal,
      protein: (meal as MockMeal).protein ?? 0,
      carbs: (meal as MockMeal).carbs ?? 0,
      fat: (meal as MockMeal).fat ?? 0,
    })),
  }));

  return parsed;
}

// ─── Main export ──────────────────────────────────────────────────────────────

export async function generateWeeklyPlan(
  userProfile?: UserProfile,
  calculations?: CalculationResults
): Promise<MockWeeklyPlan> {
  // Load profile + calculations from AsyncStorage if not provided
  let profile = userProfile;
  let calc = calculations;

  if (!profile || !calc) {
    try {
      const raw = await AsyncStorage.getItem("userProfile");
      if (!raw) {
        // No profile yet — return mock
        await AsyncStorage.setItem("weeklyPlan", JSON.stringify(MOCK_PLAN));
        return MOCK_PLAN;
      }
      profile = JSON.parse(raw) as UserProfile;
      calc = calculateAll(profile);
    } catch (error) {
      console.error("Full error:", JSON.stringify(error));
      throw new Error("PROFILE_LOAD_ERROR");
    }
  }

  const prompt = buildMealPlanPrompt(profile, calc);

  let rawText: string;
  try {
    rawText = await askGemma(prompt);
    await AsyncStorage.setItem("debugRaw", rawText);
  } catch (err) {
    console.error("[generateWeeklyPlan] askGemma failed:", err);
    throw err;
  }

  let plan: MockWeeklyPlan;
  try {
    plan = parseWeeklyPlan(rawText);
  } catch (error) {
    console.error("Full error:", JSON.stringify(error));
    console.warn("[gemma] Failed to parse Gemma response — falling back to mock plan");
    console.warn("[gemma] Raw response:", rawText);
    plan = MOCK_PLAN;
  }

  await AsyncStorage.setItem("weeklyPlan", JSON.stringify(plan));
  console.log("[generateWeeklyPlan] weeklyPlan saved to AsyncStorage successfully");
  return plan;
}

// ─── Legacy exports (kept for compatibility) ──────────────────────────────────

export interface GenerateMealPlanParams {
  goal: import("@/constants/types").Goal;
  targetMacros: import("@/constants/types").DailyMacros;
  dietaryPreferences: import("@/constants/types").DietaryPreference[];
}

export async function askNutritionQuestion(_question: string): Promise<string> {
  return "";
}

export async function isOllamaAvailable(): Promise<boolean> {
  try {
    const response = await fetch(`${OLLAMA_BASE_URL}/api/tags`, {
      headers: NGROK_HEADERS,
    });
    return response.ok;
  } catch {
    return false;
  }
}
