import type { ActivityLevel, Gender, Goal, UserProfile } from "@/constants/types";

export interface BMICategory {
  label: string;
  color: string;
}

export interface MacroGrams {
  protein: number;
  carbs: number;
  fat: number;
}

export interface MacroPercentages {
  protein: number;
  carbs: number;
  fat: number;
}

export interface CalculationResults {
  bmi: number;
  bmiCategory: BMICategory;
  bmr: number;
  tdee: number;
  targetCalories: number;
  macros: MacroGrams;
  macroPercentages: MacroPercentages;
}

/**
 * Calculates Body Mass Index.
 * Formula: weight(kg) / height(m)²
 * Source: WHO standard BMI formula
 */
export function calculateBMI(weight: number, height: number): number {
  const heightM = height / 100;
  return Math.round((weight / (heightM * heightM)) * 10) / 10;
}

/**
 * Returns BMI category label and color based on WHO classification.
 * Source: WHO BMI classification table
 */
export function getBMICategory(bmi: number): BMICategory {
  if (bmi < 18.5) return { label: "Underweight", color: "#FFB300" };
  if (bmi < 25)   return { label: "Healthy",     color: "#4CAF50" };
  if (bmi < 30)   return { label: "Overweight",  color: "#FFB300" };
  return           { label: "Obese",             color: "#FF4444" };
}

/**
 * Calculates Basal Metabolic Rate using the Mifflin-St Jeor equation.
 * Source: Mifflin MD, et al. (1990) — most accurate for general population.
 * Male:   (10 × kg) + (6.25 × cm) − (5 × age) + 5
 * Female: (10 × kg) + (6.25 × cm) − (5 × age) − 161
 * Other:  average of male and female results
 */
export function calculateBMR(
  weight: number,
  height: number,
  age: number,
  gender: Gender | string
): number {
  const base = 10 * weight + 6.25 * height - 5 * age;
  if (gender === "male") return Math.round(base + 5);
  if (gender === "female") return Math.round(base - 161);
  // "other" → average
  return Math.round((base + 5 + (base - 161)) / 2);
}

/**
 * Returns the activity multiplier for TDEE calculation.
 * Source: Harris-Benedict activity factor table (widely adopted standard)
 */
export function getActivityMultiplier(activityLevel: ActivityLevel | string): number {
  const multipliers: Record<string, number> = {
    sedentary:         1.2,
    lightly_active:    1.375,
    moderately_active: 1.55,
    very_active:       1.725,
    extra_active:      1.9,
  };
  return multipliers[activityLevel] ?? 1.2;
}

/**
 * Calculates Total Daily Energy Expenditure.
 * Formula: BMR × activity multiplier
 * Source: Harris-Benedict equation revised by Roza & Shizgal (1984)
 */
export function calculateTDEE(bmr: number, activityLevel: ActivityLevel | string): number {
  return Math.round(bmr * getActivityMultiplier(activityLevel));
}

/**
 * Adjusts TDEE based on goal to get target calorie intake.
 * Cut:      TDEE − 500 kcal (≈0.5 kg/week fat loss)
 * Bulk:     TDEE + 300 kcal (lean bulk, minimise fat gain)
 * Maintain: TDEE (no adjustment)
 */
export function calculateTargetCalories(tdee: number, goal: Goal | string): number {
  if (goal === "cut")  return tdee - 500;
  if (goal === "bulk") return tdee + 300;
  return tdee;
}

/**
 * Calculates macro split in grams from target calories and body weight.
 *
 * Protein (sports science consensus):
 *   Cut: 2.2 g/kg — high protein to preserve lean mass in deficit
 *   Bulk: 2.0 g/kg — high protein to support muscle synthesis
 *   Maintain: 1.8 g/kg
 *
 * Fat: 25% of total calories ÷ 9 kcal/g (supports hormonal health)
 *
 * Carbs: remaining calories ÷ 4 kcal/g (flexible macro)
 *
 * Source: ISSN Position Stand on Protein (Stokes et al. 2018)
 */
export function calculateMacros(
  targetCalories: number,
  weight: number,
  goal: Goal | string
): MacroGrams {
  const proteinMultiplier = goal === "cut" ? 2.2 : goal === "bulk" ? 2.0 : 1.8;
  const protein = Math.round(weight * proteinMultiplier);

  const fat = Math.round((targetCalories * 0.25) / 9);

  const proteinCalories = protein * 4;
  const fatCalories = fat * 9;
  const carbCalories = targetCalories - proteinCalories - fatCalories;
  const carbs = Math.max(0, Math.round(carbCalories / 4));

  return { protein, carbs, fat };
}

/**
 * Master calculation function — takes a full UserProfile and returns
 * all derived health and nutrition metrics in a single object.
 */
export function calculateAll(profile: UserProfile): CalculationResults {
  const { weight, height, age, gender, activityLevel, goal } = profile;

  const bmi = calculateBMI(weight, height);
  const bmiCategory = getBMICategory(bmi);
  const bmr = calculateBMR(weight, height, age, gender);
  const tdee = calculateTDEE(bmr, activityLevel);
  const targetCalories = calculateTargetCalories(tdee, goal);
  const macros = calculateMacros(targetCalories, weight, goal);

  const macroPercentages: MacroPercentages = {
    protein: Math.round(((macros.protein * 4) / targetCalories) * 1000) / 10,
    carbs:   Math.round(((macros.carbs   * 4) / targetCalories) * 1000) / 10,
    fat:     Math.round(((macros.fat     * 9) / targetCalories) * 1000) / 10,
  };

  return { bmi, bmiCategory, bmr, tdee, targetCalories, macros, macroPercentages };
}

export default calculateAll;
