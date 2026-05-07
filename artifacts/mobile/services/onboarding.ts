import { supabase } from "@/services/supabaseClient";

export interface Step1Payload {
  gender: "male" | "female" | "other";
  age: number;
  heightCm: number;
  weightKg: number;
  activityLevel: "sedentary" | "lightly_active" | "moderately_active" | "very_active" | "extra_active";
}

export interface Step3Payload {
  waistCm?: number;
  hipsCm?: number;
  chestCm?: number;
  leftArmCm?: number;
  leftLegCm?: number;
}

export interface NutritionTargetsPayload {
  bmi: number;
  bmiCategory: string;
  bmr: number;
  tdee: number;
  targetCalories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  proteinPct: number;
  carbsPct: number;
  fatPct: number;
}

async function requireUserId(): Promise<string> {
  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) {
    throw new Error("AUTH_REQUIRED");
  }
  return data.user.id;
}

export async function fetchOnboardingProfile() {
  const userId = await requireUserId();
  const { data, error } = await supabase
    .from("profiles")
    .select(
      "gender, age, height_cm, weight_kg, activity_level, goal, dietary_preferences, onboarding_complete, onboarding_step",
    )
    .eq("user_id", userId)
    .maybeSingle();

  if (error) throw new Error(error.message);
  return data;
}

export async function saveStep1(payload: Step1Payload): Promise<void> {
  const userId = await requireUserId();
  const { error } = await supabase.from("profiles").upsert(
    {
      user_id: userId,
      gender: payload.gender,
      age: payload.age,
      height_cm: payload.heightCm,
      weight_kg: payload.weightKg,
      activity_level: payload.activityLevel,
      onboarding_step: 1,
    },
    { onConflict: "user_id" },
  );
  if (error) throw new Error(error.message);
}

export async function saveStep2(goal: "cut" | "bulk" | "maintain"): Promise<void> {
  const userId = await requireUserId();
  const { error } = await supabase
    .from("profiles")
    .upsert({ user_id: userId, goal, onboarding_step: 2 }, { onConflict: "user_id" });
  if (error) throw new Error(error.message);
}

export async function saveStep3(payload: Step3Payload): Promise<void> {
  const userId = await requireUserId();
  const hasMeasurement = Object.values(payload).some((v) => typeof v === "number" && !Number.isNaN(v));

  if (hasMeasurement) {
    const { error: measurementError } = await supabase.from("body_measurements").insert({
      user_id: userId,
      waist_cm: payload.waistCm ?? null,
      hips_cm: payload.hipsCm ?? null,
      chest_cm: payload.chestCm ?? null,
      left_arm_cm: payload.leftArmCm ?? null,
      left_leg_cm: payload.leftLegCm ?? null,
    });
    if (measurementError) throw new Error(measurementError.message);
  }

  const { error: profileError } = await supabase
    .from("profiles")
    .upsert({ user_id: userId, onboarding_step: 3 }, { onConflict: "user_id" });
  if (profileError) throw new Error(profileError.message);
}

export async function saveStep4(dietaryPreferences: string[]): Promise<void> {
  const userId = await requireUserId();
  const { error } = await supabase.from("profiles").upsert(
    {
      user_id: userId,
      dietary_preferences: dietaryPreferences,
      onboarding_step: 4,
    },
    { onConflict: "user_id" },
  );
  if (error) throw new Error(error.message);
}

export async function saveResults(payload: NutritionTargetsPayload): Promise<void> {
  const userId = await requireUserId();

  const { error: targetsError } = await supabase.from("nutrition_targets").upsert(
    {
      user_id: userId,
      bmi: payload.bmi,
      bmi_category: payload.bmiCategory,
      bmr: payload.bmr,
      tdee: payload.tdee,
      target_calories: payload.targetCalories,
      protein_g: payload.proteinG,
      carbs_g: payload.carbsG,
      fat_g: payload.fatG,
      protein_pct: payload.proteinPct,
      carbs_pct: payload.carbsPct,
      fat_pct: payload.fatPct,
      calculated_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
    { onConflict: "user_id" },
  );
  if (targetsError) throw new Error(targetsError.message);

  const { error: profileError } = await supabase.from("profiles").upsert(
    {
      user_id: userId,
      onboarding_complete: true,
      onboarding_step: 5,
    },
    { onConflict: "user_id" },
  );
  if (profileError) throw new Error(profileError.message);
}
