export type MealType = "Breakfast" | "Lunch" | "Dinner" | "Snack";

export type GemmaMeal = {
  type: MealType;
  name: string;
  calories: number;
  emoji: string;
  protein: number;
  carbs: number;
  fat: number;
};

export type GemmaDay = {
  day: string;
  date: string;
  totalCalories: number;
  meals: GemmaMeal[];
};

export type GemmaWeek = {
  weekOf: string;
  days: GemmaDay[];
};

function isFiniteNumber(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value);
}

function isMealType(value: unknown): value is MealType {
  return value === "Breakfast" || value === "Lunch" || value === "Dinner" || value === "Snack";
}

export function isGemmaMeal(value: unknown): value is GemmaMeal {
  if (!value || typeof value !== "object") return false;
  const v = value as Record<string, unknown>;
  return (
    isMealType(v.type) &&
    typeof v.name === "string" &&
    typeof v.emoji === "string" &&
    isFiniteNumber(v.calories) &&
    isFiniteNumber(v.protein) &&
    isFiniteNumber(v.carbs) &&
    isFiniteNumber(v.fat)
  );
}

export function isGemmaDay(value: unknown): value is GemmaDay {
  if (!value || typeof value !== "object") return false;
  const v = value as Record<string, unknown>;
  return (
    typeof v.day === "string" &&
    typeof v.date === "string" &&
    isFiniteNumber(v.totalCalories) &&
    Array.isArray(v.meals) &&
    v.meals.every(isGemmaMeal)
  );
}

export function isGemmaWeek(value: unknown): value is GemmaWeek {
  if (!value || typeof value !== "object") return false;
  const v = value as Record<string, unknown>;
  return typeof v.weekOf === "string" && Array.isArray(v.days) && v.days.every(isGemmaDay);
}

export function coerceJsonObject(raw: string): unknown {
  const trimmed = raw.trim();
  const start = trimmed.indexOf("{");
  const end = trimmed.lastIndexOf("}");
  if (start < 0 || end <= start) {
    throw new Error("AI_SCHEMA_INVALID");
  }
  const jsonChunk = trimmed.slice(start, end + 1);
  return JSON.parse(jsonChunk);
}

