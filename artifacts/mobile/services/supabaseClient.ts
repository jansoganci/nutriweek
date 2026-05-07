import AsyncStorage from "@react-native-async-storage/async-storage";
import { createClient } from "@supabase/supabase-js";

const rawSupabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL ?? "";
const supabaseUrl = rawSupabaseUrl.trim().replace(/\/+$/, "");
const supabaseAnonKey = (process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY ?? "").trim();

export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseAnonKey);
const isSupabaseUrlFormatValid = /^https:\/\/[a-zA-Z0-9-]+\.supabase\.co$/.test(supabaseUrl);

if (__DEV__) {
  console.log("[NutriWeek] Supabase URL:", supabaseUrl || "(empty)");
  console.log("[NutriWeek] Supabase Anon Key:", supabaseAnonKey || "(empty)");
}

if (__DEV__ && !isSupabaseConfigured) {
  console.warn(
    "[NutriWeek] Supabase is not configured. Set EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_ANON_KEY.",
  );
}

if (__DEV__ && isSupabaseConfigured && !isSupabaseUrlFormatValid) {
  console.warn(
    "[NutriWeek] Supabase URL format looks invalid. Expected: https://xxxxx.supabase.co (no trailing slash).",
  );
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});

export async function testSupabaseConnection(): Promise<boolean> {
  if (!isSupabaseConfigured) {
    console.warn("[NutriWeek] testSupabaseConnection skipped: missing env config.");
    return false;
  }

  try {
    const response = await fetch(`${supabaseUrl}/auth/v1/settings`, {
      method: "GET",
      headers: {
        apikey: supabaseAnonKey,
      },
    });

    if (!response.ok) {
      console.error(
        `[NutriWeek] Supabase ping failed with status ${response.status} ${response.statusText}`,
      );
      return false;
    }

    console.log("[NutriWeek] Supabase ping success.");
    return true;
  } catch (error) {
    console.error("[NutriWeek] Supabase ping network error:", error);
    return false;
  }
}
