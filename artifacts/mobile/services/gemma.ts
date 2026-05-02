import AsyncStorage from "@react-native-async-storage/async-storage";

import type { DailyMacros, DietaryPreference, Goal } from "@/constants/types";

export interface MockMeal {
  type: string;
  name: string;
  calories: number;
  emoji: string;
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

const MOCK_PLAN: MockWeeklyPlan = {
  weekOf: "2026-05-04",
  days: [
    {
      day: "Monday",
      date: "2026-05-04",
      totalCalories: 2100,
      meals: [
        { type: "Breakfast", name: "Oatmeal with Berries", calories: 380, emoji: "🥣" },
        { type: "Lunch", name: "Grilled Chicken Salad", calories: 520, emoji: "🥗" },
        { type: "Dinner", name: "Salmon with Vegetables", calories: 680, emoji: "🐟" },
        { type: "Snack", name: "Greek Yogurt", calories: 150, emoji: "🥛" },
      ],
    },
    {
      day: "Tuesday",
      date: "2026-05-05",
      totalCalories: 2080,
      meals: [
        { type: "Breakfast", name: "Scrambled Eggs & Toast", calories: 420, emoji: "🍳" },
        { type: "Lunch", name: "Turkey Wrap", calories: 490, emoji: "🌯" },
        { type: "Dinner", name: "Beef Stir Fry with Rice", calories: 720, emoji: "🥩" },
        { type: "Snack", name: "Apple with Almond Butter", calories: 180, emoji: "🍎" },
      ],
    },
    {
      day: "Wednesday",
      date: "2026-05-06",
      totalCalories: 2150,
      meals: [
        { type: "Breakfast", name: "Protein Smoothie", calories: 350, emoji: "🥤" },
        { type: "Lunch", name: "Quinoa Buddha Bowl", calories: 580, emoji: "🥙" },
        { type: "Dinner", name: "Grilled Chicken & Sweet Potato", calories: 650, emoji: "🍗" },
        { type: "Snack", name: "Mixed Nuts", calories: 200, emoji: "🥜" },
      ],
    },
    {
      day: "Thursday",
      date: "2026-05-07",
      totalCalories: 2090,
      meals: [
        { type: "Breakfast", name: "Avocado Toast & Eggs", calories: 440, emoji: "🥑" },
        { type: "Lunch", name: "Lentil Soup", calories: 460, emoji: "🍲" },
        { type: "Dinner", name: "Tuna Pasta", calories: 620, emoji: "🍝" },
        { type: "Snack", name: "Cottage Cheese", calories: 140, emoji: "🧀" },
      ],
    },
    {
      day: "Friday",
      date: "2026-05-08",
      totalCalories: 2120,
      meals: [
        { type: "Breakfast", name: "Banana Pancakes", calories: 410, emoji: "🥞" },
        { type: "Lunch", name: "Caesar Salad with Chicken", calories: 510, emoji: "🥗" },
        { type: "Dinner", name: "Shrimp Tacos", calories: 680, emoji: "🌮" },
        { type: "Snack", name: "Protein Bar", calories: 220, emoji: "🍫" },
      ],
    },
    {
      day: "Saturday",
      date: "2026-05-09",
      totalCalories: 2200,
      meals: [
        { type: "Breakfast", name: "Full English Breakfast", calories: 520, emoji: "🍳" },
        { type: "Lunch", name: "Burger & Side Salad", calories: 620, emoji: "🍔" },
        { type: "Dinner", name: "Grilled Steak & Veggies", calories: 750, emoji: "🥩" },
        { type: "Snack", name: "Dark Chocolate", calories: 160, emoji: "🍫" },
      ],
    },
    {
      day: "Sunday",
      date: "2026-05-10",
      totalCalories: 2050,
      meals: [
        { type: "Breakfast", name: "Overnight Oats", calories: 380, emoji: "🥣" },
        { type: "Lunch", name: "Vegetable Curry & Rice", calories: 540, emoji: "🍛" },
        { type: "Dinner", name: "Baked Cod & Salad", calories: 580, emoji: "🐟" },
        { type: "Snack", name: "Hummus & Veggies", calories: 170, emoji: "🥕" },
      ],
    },
  ],
};

export async function generateWeeklyPlan(): Promise<MockWeeklyPlan> {
  const TIMEOUT_MS = 60_000;

  const ollamaCheck = await Promise.race<boolean>([
    fetch("http://localhost:11434/api/tags")
      .then((r) => r.ok)
      .catch(() => false),
    new Promise<boolean>((resolve) =>
      setTimeout(() => resolve(false), 5_000)
    ),
  ]);

  if (!ollamaCheck) {
    const timeout = new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error("OLLAMA_TIMEOUT")), TIMEOUT_MS)
    );
    const planGeneration = (async () => {
      await new Promise((resolve) => setTimeout(resolve, 2500));
      await AsyncStorage.setItem("weeklyPlan", JSON.stringify(MOCK_PLAN));
      return MOCK_PLAN;
    })();

    try {
      return await Promise.race([planGeneration, timeout]);
    } catch (err) {
      if (err instanceof Error && err.message === "OLLAMA_TIMEOUT") {
        throw err;
      }
      throw new Error("OLLAMA_OFFLINE");
    }
  }

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), TIMEOUT_MS);
    const resp = await fetch("http://localhost:11434/api/generate", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ model: "gemma", prompt: "Generate a weekly meal plan." }),
      signal: controller.signal,
    });
    clearTimeout(timeoutId);
    if (!resp.ok) throw new Error("OLLAMA_OFFLINE");
  } catch (err) {
    if (err instanceof Error && err.message === "OLLAMA_TIMEOUT") throw err;
    if (err instanceof Error && err.name === "AbortError") throw new Error("OLLAMA_TIMEOUT");
    throw new Error("OLLAMA_OFFLINE");
  }

  await AsyncStorage.setItem("weeklyPlan", JSON.stringify(MOCK_PLAN));
  return MOCK_PLAN;
}

export interface GenerateMealPlanParams {
  goal: Goal;
  targetMacros: DailyMacros;
  dietaryPreferences: DietaryPreference[];
}

export async function askNutritionQuestion(_question: string): Promise<string> {
  return "";
}

export async function isOllamaAvailable(): Promise<boolean> {
  try {
    const response = await fetch("http://localhost:11434/api/tags");
    return response.ok;
  } catch {
    return false;
  }
}
