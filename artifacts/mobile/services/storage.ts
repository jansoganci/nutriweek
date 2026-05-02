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

export async function safeGetItem(key: string): Promise<string | null> {
  try {
    return await AsyncStorage.getItem(key);
  } catch (err) {
    console.error(`[Storage] Failed to read "${key}":`, err);
    return null;
  }
}

export async function safeSetItem(key: string, value: string): Promise<boolean> {
  try {
    await AsyncStorage.setItem(key, value);
    return true;
  } catch (err) {
    console.error(`[Storage] Failed to write "${key}":`, err);
    return false;
  }
}

export async function safeRemoveItem(key: string): Promise<boolean> {
  try {
    await AsyncStorage.removeItem(key);
    return true;
  } catch (err) {
    console.error(`[Storage] Failed to remove "${key}":`, err);
    return false;
  }
}

export async function safeClearAll(): Promise<boolean> {
  try {
    await AsyncStorage.clear();
    return true;
  } catch (err) {
    console.error("[Storage] Failed to clear storage:", err);
    return false;
  }
}

const STREAK_KEY = "streak";

interface StreakData {
  count: number;
  lastLogDate: string;
}

function getTodayStr(): string {
  return new Date().toISOString().slice(0, 10);
}

function getYesterdayStr(): string {
  return new Date(Date.now() - 86400000).toISOString().slice(0, 10);
}

export async function loadStreak(): Promise<number> {
  try {
    const raw = await AsyncStorage.getItem(STREAK_KEY);
    if (!raw) return 0;
    const data: StreakData = JSON.parse(raw);
    const today = getTodayStr();
    const yesterday = getYesterdayStr();
    if (data.lastLogDate !== today && data.lastLogDate !== yesterday) return 0;
    return data.count;
  } catch {
    return 0;
  }
}

export async function updateStreak(): Promise<number> {
  try {
    const today = getTodayStr();
    const yesterday = getYesterdayStr();
    const raw = await AsyncStorage.getItem(STREAK_KEY);
    const data: StreakData = raw
      ? (JSON.parse(raw) as StreakData)
      : { count: 0, lastLogDate: "" };

    if (data.lastLogDate === today) return data.count;

    const newCount = data.lastLogDate === yesterday ? data.count + 1 : 1;
    await AsyncStorage.setItem(
      STREAK_KEY,
      JSON.stringify({ count: newCount, lastLogDate: today })
    );
    return newCount;
  } catch {
    return 0;
  }
}
