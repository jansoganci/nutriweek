import type {
  ActivityLevel,
  CalculationResults,
  DailyMacros,
  Gender,
  Goal,
} from "@/constants/types";

export function calculateBMI(_weight: number, _height: number): number {
  return 0;
}

export function getBMICategory(
  _bmi: number
): "underweight" | "normal" | "overweight" | "obese" {
  return "normal";
}

export function calculateBMR(
  _gender: Gender,
  _weight: number,
  _height: number,
  _age: number
): number {
  return 0;
}

export function getActivityMultiplier(_activityLevel: ActivityLevel): number {
  return 1;
}

export function calculateTDEE(
  _bmr: number,
  _activityLevel: ActivityLevel
): number {
  return 0;
}

export function calculateTargetCalories(
  _tdee: number,
  _goal: Goal
): number {
  return 0;
}

export function calculateMacros(
  _targetCalories: number,
  _goal: Goal
): DailyMacros {
  return { calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0 };
}

export function calculateAll(params: {
  gender: Gender;
  age: number;
  height: number;
  weight: number;
  activityLevel: ActivityLevel;
  goal: Goal;
}): CalculationResults {
  const { gender, age, height, weight, activityLevel, goal } = params;
  const bmi = calculateBMI(weight, height);
  const bmiCategory = getBMICategory(bmi);
  const bmr = calculateBMR(gender, weight, height, age);
  const tdee = calculateTDEE(bmr, activityLevel);
  const targetCalories = calculateTargetCalories(tdee, goal);
  const macros = calculateMacros(targetCalories, goal);

  return { bmi, bmiCategory, bmr, tdee, targetCalories, macros };
}
