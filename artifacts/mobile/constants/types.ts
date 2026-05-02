export type Gender = "male" | "female" | "other";

export type ActivityLevel =
  | "sedentary"
  | "lightly_active"
  | "moderately_active"
  | "very_active"
  | "extra_active";

export type Goal = "cut" | "bulk" | "maintain";

export type DietaryPreference =
  | "vegetarian"
  | "vegan"
  | "gluten_free"
  | "dairy_free"
  | "keto"
  | "paleo"
  | "halal"
  | "kosher"
  | "nut_free"
  | "low_sodium";

export interface BodyMeasurements {
  chest?: number;
  waist?: number;
  hips?: number;
  thighs?: number;
  arms?: number;
}

export interface UserProfile {
  gender: Gender;
  age: number;
  height: number;
  weight: number;
  activityLevel: ActivityLevel;
  goal: Goal;
  measurements?: BodyMeasurements;
  dietaryPreferences: DietaryPreference[];
  onboardingComplete: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface DailyMacros {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber?: number;
}

export interface MealEntry {
  id: string;
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber?: number;
  servingSize?: string;
  mealType: "breakfast" | "lunch" | "dinner" | "snack";
  loggedAt: string;
}

export interface DayPlan {
  date: string;
  meals: MealEntry[];
  targetMacros: DailyMacros;
  loggedMacros: DailyMacros;
}

export interface WeeklyPlan {
  id: string;
  weekStartDate: string;
  days: DayPlan[];
  generatedAt: string;
  notes?: string;
}

export interface CalculationResults {
  bmi: number;
  bmiCategory: "underweight" | "normal" | "overweight" | "obese";
  bmr: number;
  tdee: number;
  targetCalories: number;
  macros: DailyMacros;
}
