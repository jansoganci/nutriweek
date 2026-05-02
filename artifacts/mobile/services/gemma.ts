import type { DailyMacros, DietaryPreference, Goal, WeeklyPlan } from "@/constants/types";

const OLLAMA_BASE_URL = "http://localhost:11434";
const MODEL = "gemma3";

export interface GenerateMealPlanParams {
  goal: Goal;
  targetMacros: DailyMacros;
  dietaryPreferences: DietaryPreference[];
}

export async function generateMealPlan(
  _params: GenerateMealPlanParams
): Promise<WeeklyPlan | null> {
  return null;
}

export async function askNutritionQuestion(
  _question: string
): Promise<string> {
  return "";
}

export async function isOllamaAvailable(): Promise<boolean> {
  try {
    const response = await fetch(`${OLLAMA_BASE_URL}/api/tags`);
    return response.ok;
  } catch {
    return false;
  }
}

export async function streamCompletion(
  _prompt: string,
  _onChunk: (text: string) => void
): Promise<void> {
  void _onChunk;
}

export { OLLAMA_BASE_URL, MODEL };
