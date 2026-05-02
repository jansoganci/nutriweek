import AsyncStorage from "@react-native-async-storage/async-storage";

import type { UserProfile, WeeklyPlan } from "@/constants/types";

const KEYS = {
  USER_PROFILE: "@nutriweek/user_profile",
  WEEKLY_PLAN: "@nutriweek/weekly_plan",
  ONBOARDING_COMPLETE: "@nutriweek/onboarding_complete",
} as const;

export async function saveUserProfile(_profile: UserProfile): Promise<void> {
  await AsyncStorage.setItem(KEYS.USER_PROFILE, JSON.stringify(_profile));
}

export async function loadUserProfile(): Promise<UserProfile | null> {
  const raw = await AsyncStorage.getItem(KEYS.USER_PROFILE);
  if (!raw) return null;
  return JSON.parse(raw) as UserProfile;
}

export async function saveWeeklyPlan(_plan: WeeklyPlan): Promise<void> {
  await AsyncStorage.setItem(KEYS.WEEKLY_PLAN, JSON.stringify(_plan));
}

export async function loadWeeklyPlan(): Promise<WeeklyPlan | null> {
  const raw = await AsyncStorage.getItem(KEYS.WEEKLY_PLAN);
  if (!raw) return null;
  return JSON.parse(raw) as WeeklyPlan;
}

export async function clearAll(): Promise<void> {
  await AsyncStorage.multiRemove(Object.values(KEYS));
}

export async function isOnboardingComplete(): Promise<boolean> {
  const val = await AsyncStorage.getItem(KEYS.ONBOARDING_COMPLETE);
  return val === "true";
}

export async function setOnboardingComplete(): Promise<void> {
  await AsyncStorage.setItem(KEYS.ONBOARDING_COMPLETE, "true");
}
