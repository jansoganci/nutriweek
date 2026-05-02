import AsyncStorage from "@react-native-async-storage/async-storage";

function getApiBase(): string {
  const domain =
    (typeof process !== "undefined" && process.env?.EXPO_PUBLIC_DOMAIN) || "";
  return domain ? `https://${domain}/api` : "/api";
}

export interface FoodSearchResult {
  fdcId: number;
  description: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  servingSize: number;
}

export interface MacroResult {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
}

export interface LogEntry {
  id: string;
  foodName: string;
  grams: number;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  loggedAt: string;
  date: string;
}

function getNutrient(nutrients: { nutrientId?: number; nutrientNumber?: string; value?: number }[], id: number): number {
  const hit = nutrients.find(
    (n) => n.nutrientId === id || n.nutrientNumber === String(id)
  );
  return Math.round((hit?.value ?? 0) * 10) / 10;
}

export async function searchFoods(query: string): Promise<FoodSearchResult[]> {
  if (!query.trim()) return [];

  const url =
    `${getApiBase()}/foods/search` +
    `?query=${encodeURIComponent(query.trim())}` +
    `&pageSize=20`;

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Food search error ${response.status}`);
  }

  const data = (await response.json()) as { foods?: Record<string, unknown>[] };
  const foods = data.foods ?? [];

  return foods.map((food) => {
    const nutrients = (food.foodNutrients ?? []) as { nutrientId?: number; nutrientNumber?: string; value?: number }[];
    return {
      fdcId: food.fdcId as number,
      description: (food.description as string) ?? "Unknown food",
      calories: getNutrient(nutrients, 1008),
      protein: getNutrient(nutrients, 1003),
      carbs: getNutrient(nutrients, 1005),
      fat: getNutrient(nutrients, 1004),
      servingSize: 100,
    };
  });
}

export function calculateNutrients(food: FoodSearchResult, grams: number): MacroResult {
  const f = grams / 100;
  return {
    calories: Math.round(food.calories * f),
    protein: Math.round(food.protein * f * 10) / 10,
    carbs: Math.round(food.carbs * f * 10) / 10,
    fat: Math.round(food.fat * f * 10) / 10,
  };
}

export function getTodayKey(): string {
  return `dailyLog_${new Date().toISOString().slice(0, 10)}`;
}

export async function loadTodayLog(): Promise<LogEntry[]> {
  const raw = await AsyncStorage.getItem(getTodayKey());
  if (!raw) return [];
  return JSON.parse(raw) as LogEntry[];
}

export async function appendLogEntry(entry: LogEntry): Promise<void> {
  const existing = await loadTodayLog();
  await AsyncStorage.setItem(getTodayKey(), JSON.stringify([...existing, entry]));
}

export function sumMacros(entries: LogEntry[]): MacroResult {
  return entries.reduce(
    (acc, e) => ({
      calories: acc.calories + e.calories,
      protein: Math.round((acc.protein + e.protein) * 10) / 10,
      carbs: Math.round((acc.carbs + e.carbs) * 10) / 10,
      fat: Math.round((acc.fat + e.fat) * 10) / 10,
    }),
    { calories: 0, protein: 0, carbs: 0, fat: 0 }
  );
}
