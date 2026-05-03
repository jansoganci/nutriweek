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

const OLLAMA_BASE_URL =
  "https://introducing-match-history-remember.trycloudflare.com";
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
        {
          type: "Breakfast",
          name: "Oatmeal with Berries",
          calories: 380,
          emoji: "🥣",
          protein: 12,
          carbs: 62,
          fat: 7,
        },
        {
          type: "Lunch",
          name: "Grilled Chicken Salad",
          calories: 520,
          emoji: "🥗",
          protein: 42,
          carbs: 28,
          fat: 16,
        },
        {
          type: "Dinner",
          name: "Salmon with Vegetables",
          calories: 680,
          emoji: "🐟",
          protein: 48,
          carbs: 38,
          fat: 26,
        },
        {
          type: "Snack",
          name: "Greek Yogurt",
          calories: 150,
          emoji: "🥛",
          protein: 15,
          carbs: 12,
          fat: 3,
        },
      ],
    },
    {
      day: "Tuesday",
      date: "2026-05-05",
      totalCalories: 2080,
      meals: [
        {
          type: "Breakfast",
          name: "Scrambled Eggs & Toast",
          calories: 420,
          emoji: "🍳",
          protein: 22,
          carbs: 38,
          fat: 18,
        },
        {
          type: "Lunch",
          name: "Turkey Wrap",
          calories: 490,
          emoji: "🌯",
          protein: 35,
          carbs: 48,
          fat: 14,
        },
        {
          type: "Dinner",
          name: "Beef Stir Fry with Rice",
          calories: 720,
          emoji: "🥩",
          protein: 45,
          carbs: 72,
          fat: 22,
        },
        {
          type: "Snack",
          name: "Apple with Almond Butter",
          calories: 180,
          emoji: "🍎",
          protein: 5,
          carbs: 22,
          fat: 9,
        },
      ],
    },
    {
      day: "Wednesday",
      date: "2026-05-06",
      totalCalories: 2150,
      meals: [
        {
          type: "Breakfast",
          name: "Protein Smoothie",
          calories: 350,
          emoji: "🥤",
          protein: 30,
          carbs: 42,
          fat: 6,
        },
        {
          type: "Lunch",
          name: "Quinoa Buddha Bowl",
          calories: 580,
          emoji: "🥙",
          protein: 22,
          carbs: 78,
          fat: 18,
        },
        {
          type: "Dinner",
          name: "Grilled Chicken & Sweet Potato",
          calories: 650,
          emoji: "🍗",
          protein: 50,
          carbs: 58,
          fat: 16,
        },
        {
          type: "Snack",
          name: "Mixed Nuts",
          calories: 200,
          emoji: "🥜",
          protein: 6,
          carbs: 8,
          fat: 18,
        },
      ],
    },
    {
      day: "Thursday",
      date: "2026-05-07",
      totalCalories: 2090,
      meals: [
        {
          type: "Breakfast",
          name: "Avocado Toast & Eggs",
          calories: 440,
          emoji: "🥑",
          protein: 18,
          carbs: 38,
          fat: 22,
        },
        {
          type: "Lunch",
          name: "Lentil Soup",
          calories: 460,
          emoji: "🍲",
          protein: 24,
          carbs: 68,
          fat: 8,
        },
        {
          type: "Dinner",
          name: "Tuna Pasta",
          calories: 620,
          emoji: "🍝",
          protein: 40,
          carbs: 72,
          fat: 14,
        },
        {
          type: "Snack",
          name: "Cottage Cheese",
          calories: 140,
          emoji: "🧀",
          protein: 18,
          carbs: 6,
          fat: 4,
        },
      ],
    },
    {
      day: "Friday",
      date: "2026-05-08",
      totalCalories: 2120,
      meals: [
        {
          type: "Breakfast",
          name: "Banana Pancakes",
          calories: 410,
          emoji: "🥞",
          protein: 14,
          carbs: 68,
          fat: 10,
        },
        {
          type: "Lunch",
          name: "Caesar Salad with Chicken",
          calories: 510,
          emoji: "🥗",
          protein: 38,
          carbs: 22,
          fat: 26,
        },
        {
          type: "Dinner",
          name: "Shrimp Tacos",
          calories: 680,
          emoji: "🌮",
          protein: 42,
          carbs: 65,
          fat: 20,
        },
        {
          type: "Snack",
          name: "Protein Bar",
          calories: 220,
          emoji: "🍫",
          protein: 20,
          carbs: 24,
          fat: 8,
        },
      ],
    },
    {
      day: "Saturday",
      date: "2026-05-09",
      totalCalories: 2200,
      meals: [
        {
          type: "Breakfast",
          name: "Full English Breakfast",
          calories: 520,
          emoji: "🍳",
          protein: 28,
          carbs: 30,
          fat: 28,
        },
        {
          type: "Lunch",
          name: "Burger & Side Salad",
          calories: 620,
          emoji: "🍔",
          protein: 36,
          carbs: 56,
          fat: 26,
        },
        {
          type: "Dinner",
          name: "Grilled Steak & Veggies",
          calories: 750,
          emoji: "🥩",
          protein: 58,
          carbs: 32,
          fat: 36,
        },
        {
          type: "Snack",
          name: "Dark Chocolate",
          calories: 160,
          emoji: "🍫",
          protein: 2,
          carbs: 18,
          fat: 10,
        },
      ],
    },
    {
      day: "Sunday",
      date: "2026-05-10",
      totalCalories: 2050,
      meals: [
        {
          type: "Breakfast",
          name: "Overnight Oats",
          calories: 380,
          emoji: "🥣",
          protein: 14,
          carbs: 60,
          fat: 8,
        },
        {
          type: "Lunch",
          name: "Vegetable Curry & Rice",
          calories: 540,
          emoji: "🍛",
          protein: 16,
          carbs: 88,
          fat: 12,
        },
        {
          type: "Dinner",
          name: "Baked Cod & Salad",
          calories: 580,
          emoji: "🐟",
          protein: 48,
          carbs: 38,
          fat: 18,
        },
        {
          type: "Snack",
          name: "Hummus & Veggies",
          calories: 170,
          emoji: "🥕",
          protein: 6,
          carbs: 20,
          fat: 8,
        },
      ],
    },
  ],
};

// ─── Prompt builders ──────────────────────────────────────────────────────────

function sharedConstraints(calc: CalculationResults, dietStr: string): string {
  return `Constraints:
- Total daily calories MUST be exactly ${calc.targetCalories} kcal (±50 kcal tolerance)
- Daily protein MUST be ${calc.macros.protein}g (±5g), carbs ${calc.macros.carbs}g (±5g), fat ${calc.macros.fat}g (±5g)
- The four meals MUST sum to the daily totals within the above tolerances
- Follow FDA 2025 priority: lean protein → dairy → vegetables → whole grains → fruits
- Meal names MUST be descriptive (e.g., "Grilled Chicken & Quinoa Bowl" not just "Chicken")
- Include an appropriate food emoji for each meal
- Exactly 4 meals: Breakfast, Lunch, Dinner, Snack
- Portion distribution: Breakfast ~25%, Lunch ~30%, Dinner ~35%, Snack ~10% of daily calories${dietStr !== "none" ? `\n- Dietary restrictions: ${dietStr}. All meals must comply.` : ""}`;
}

function buildSingleDayPrompt(
  profile: UserProfile,
  calc: CalculationResults,
  dayName: string,
  date: string,
): string {
  const dietStr =
    profile.dietaryPreferences.length > 0
      ? profile.dietaryPreferences.join(", ")
      : "none";

  return `You are a nutritionist. Generate a meal plan for ONE day only.
Return a single valid JSON object. No markdown, no code fences, no extra text. The entire response must pass JSON.parse().

${sharedConstraints(calc, dietStr)}

User: ${profile.age}yo ${profile.gender}, ${profile.weight}kg, ${profile.height}cm, goal: ${profile.goal}, activity: ${profile.activityLevel}

Generate ONLY for ${dayName} (${date}). Return this exact structure:
{
  "day": "${dayName}",
  "date": "${date}",
  "totalCalories": ${calc.targetCalories},
  "meals": [
    {"type": "Breakfast", "name": "MEAL NAME HERE", "calories": NUMBER, "emoji": "EMOJI", "protein": NUMBER, "carbs": NUMBER, "fat": NUMBER},
    {"type": "Lunch", "name": "MEAL NAME HERE", "calories": NUMBER, "emoji": "EMOJI", "protein": NUMBER, "carbs": NUMBER, "fat": NUMBER},
    {"type": "Dinner", "name": "MEAL NAME HERE", "calories": NUMBER, "emoji": "EMOJI", "protein": NUMBER, "carbs": NUMBER, "fat": NUMBER},
    {"type": "Snack", "name": "MEAL NAME HERE", "calories": NUMBER, "emoji": "EMOJI", "protein": NUMBER, "carbs": NUMBER, "fat": NUMBER}
  ]
}

IMPORTANT: Replace MEAL NAME HERE, NUMBER, EMOJI with actual values. Do NOT copy the placeholder text.`;
}

function buildMultiDayPrompt(
  profile: UserProfile,
  calc: CalculationResults,
  dayNames: string[],
  dates: string[],
): string {
  const dietStr =
    profile.dietaryPreferences.length > 0
      ? profile.dietaryPreferences.join(", ")
      : "none";

  const dayList = dayNames.map((d, i) => `- ${d} (${dates[i]})`).join("\n");
  const exampleEntry = `{"day":"DAY_NAME","date":"DATE","totalCalories":${calc.targetCalories},"meals":[{"type":"Breakfast","name":"MEAL NAME","calories":NUMBER,"emoji":"EMOJI","protein":NUMBER,"carbs":NUMBER,"fat":NUMBER},{"type":"Lunch","name":"MEAL NAME","calories":NUMBER,"emoji":"EMOJI","protein":NUMBER,"carbs":NUMBER,"fat":NUMBER},{"type":"Dinner","name":"MEAL NAME","calories":NUMBER,"emoji":"EMOJI","protein":NUMBER,"carbs":NUMBER,"fat":NUMBER},{"type":"Snack","name":"MEAL NAME","calories":NUMBER,"emoji":"EMOJI","protein":NUMBER,"carbs":NUMBER,"fat":NUMBER}]}`;

  return `You are a nutritionist. Generate meal plans for EXACTLY ${dayNames.length} days.
Return a single valid JSON object. No markdown, no code fences, no extra text. The entire response must pass JSON.parse().

${sharedConstraints(calc, dietStr)}

User: ${profile.age}yo ${profile.gender}, ${profile.weight}kg, ${profile.height}cm, goal: ${profile.goal}, activity: ${profile.activityLevel}

Generate ONLY for these days:
${dayList}

Return this exact structure with ${dayNames.length} entries in the "days" array:
{"days":[${Array(dayNames.length).fill(exampleEntry).join(",")}]}

IMPORTANT: Replace DAY_NAME, DATE, MEAL NAME, NUMBER, EMOJI with actual values for each day. Do NOT copy placeholder text.`;
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
      body: JSON.stringify({
        model: MODEL,
        prompt,
        stream: false,
        options: { num_predict: 4096 },
      }),
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
      console.error(
        "[askGemma] CATCH name:",
        err.name,
        "| message:",
        err.message,
      );
      console.error("Full error:", JSON.stringify(err));
      if (err.name === "AbortError") throw new Error("OLLAMA_TIMEOUT");
      if (err.message === "OLLAMA_OFFLINE" || err.message === "OLLAMA_TIMEOUT")
        throw err;
    } else {
      console.error("[askGemma] CATCH unknown error:", err);
      console.error("Full error:", JSON.stringify(err));
    }
    throw new Error("OLLAMA_OFFLINE");
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function normalizeMeals(meals: MockMeal[]): MockMeal[] {
  return (meals ?? []).map((meal) => ({
    ...meal,
    protein: meal.protein ?? 0,
    carbs: meal.carbs ?? 0,
    fat: meal.fat ?? 0,
  }));
}

function getMockDay(dayName: string, date: string): MockDayPlan {
  const found = MOCK_PLAN.days.find((d) => d.day === dayName);
  if (found) return { ...found, date };
  return {
    day: dayName,
    date,
    totalCalories: 2000,
    meals: [
      { type: "Breakfast", name: "Oatmeal & Berries", calories: 400, emoji: "🥣", protein: 15, carbs: 65, fat: 8 },
      { type: "Lunch", name: "Grilled Chicken Salad", calories: 500, emoji: "🥗", protein: 40, carbs: 30, fat: 15 },
      { type: "Dinner", name: "Salmon & Vegetables", calories: 650, emoji: "🐟", protein: 45, carbs: 40, fat: 22 },
      { type: "Snack", name: "Greek Yogurt", calories: 150, emoji: "🥛", protein: 15, carbs: 12, fat: 3 },
    ],
  };
}

// ─── Parse functions ──────────────────────────────────────────────────────────

function parseSingleDay(text: string, dayName: string, date: string): MockDayPlan {
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) throw new Error("PARSE_ERROR");

  const parsed = JSON.parse(match[0]) as Record<string, unknown>;

  let day: MockDayPlan;
  if (parsed.days && Array.isArray(parsed.days) && parsed.days.length > 0) {
    day = parsed.days[0] as MockDayPlan;
  } else if (Array.isArray(parsed.meals)) {
    day = parsed as unknown as MockDayPlan;
  } else {
    throw new Error("PARSE_ERROR");
  }

  return {
    day: (day.day as string) || dayName,
    date: (day.date as string) || date,
    totalCalories: (day.totalCalories as number) || 0,
    meals: normalizeMeals(day.meals as MockMeal[]),
  };
}

function parseMultiDays(text: string, dayNames: string[], dates: string[]): MockDayPlan[] {
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) throw new Error("PARSE_ERROR");

  const parsed = JSON.parse(match[0]) as { days?: MockDayPlan[] };
  if (!parsed.days || !Array.isArray(parsed.days)) throw new Error("PARSE_ERROR");

  return parsed.days.map((day, i) => ({
    day: day.day || dayNames[i] || "Unknown",
    date: day.date || dates[i] || "",
    totalCalories: day.totalCalories || 0,
    meals: normalizeMeals(day.meals),
  }));
}

// ─── Per-day generators ───────────────────────────────────────────────────────

export async function generateSingleDay(
  profile: UserProfile,
  calc: CalculationResults,
  dayName: string,
  date: string,
): Promise<MockDayPlan> {
  try {
    const prompt = buildSingleDayPrompt(profile, calc, dayName, date);
    const rawText = await askGemma(prompt);
    return parseSingleDay(rawText, dayName, date);
  } catch (err) {
    console.warn(`[generateSingleDay] Failed for ${dayName}, using mock:`, err);
    return getMockDay(dayName, date);
  }
}

export async function generateMultiDays(
  profile: UserProfile,
  calc: CalculationResults,
  dayNames: string[],
  dates: string[],
): Promise<MockDayPlan[]> {
  try {
    const prompt = buildMultiDayPrompt(profile, calc, dayNames, dates);
    const rawText = await askGemma(prompt);
    const days = parseMultiDays(rawText, dayNames, dates);
    while (days.length < dayNames.length) {
      const i = days.length;
      days.push(getMockDay(dayNames[i], dates[i]));
    }
    return days;
  } catch (err) {
    console.warn(`[generateMultiDays] Failed for ${dayNames.join(", ")}, using mocks:`, err);
    return dayNames.map((name, i) => getMockDay(name, dates[i]));
  }
}

// ─── Main export ──────────────────────────────────────────────────────────────

export async function generateWeeklyPlan(
  userProfile?: UserProfile,
  calculations?: CalculationResults,
  onProgress?: (days: MockDayPlan[]) => void,
): Promise<MockWeeklyPlan> {
  let profile = userProfile;
  let calc = calculations;

  if (!profile || !calc) {
    try {
      const raw = await AsyncStorage.getItem("userProfile");
      if (!raw) {
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

  const today = new Date();
  const monday = new Date(today);
  monday.setDate(today.getDate() - today.getDay() + 1);
  const DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  const dates = DAY_NAMES.map((_, i) => {
    const d = new Date(monday);
    d.setDate(monday.getDate() + i);
    return d.toISOString().slice(0, 10);
  });

  const accumulated: MockDayPlan[] = [];
  function handleProgress(newDays: MockDayPlan[]) {
    newDays.forEach((day) => {
      const idx = accumulated.findIndex((d) => d.day === day.day);
      if (idx >= 0) accumulated[idx] = day;
      else accumulated.push(day);
    });
    accumulated.sort((a, b) => DAY_NAMES.indexOf(a.day) - DAY_NAMES.indexOf(b.day));
    onProgress?.([...accumulated]);
  }

  const [mon, tue, wedToSun] = await Promise.all([
    generateSingleDay(profile, calc, "Monday", dates[0]).then((day) => { handleProgress([day]); return day; }),
    generateSingleDay(profile, calc, "Tuesday", dates[1]).then((day) => { handleProgress([day]); return day; }),
    generateMultiDays(profile, calc, DAY_NAMES.slice(2), dates.slice(2)).then((days) => { handleProgress(days); return days; }),
  ]);

  const allDays: MockDayPlan[] = [mon, tue, ...wedToSun];
  allDays.sort((a, b) => DAY_NAMES.indexOf(a.day) - DAY_NAMES.indexOf(b.day));

  const plan: MockWeeklyPlan = { weekOf: dates[0], days: allDays };
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
