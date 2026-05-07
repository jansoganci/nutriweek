import {
  Inter_400Regular,
  Inter_500Medium,
  Inter_600SemiBold,
  Inter_700Bold,
  useFonts,
} from "@expo-google-fonts/inter";
import type { Session } from "@supabase/supabase-js";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Stack, useRouter, useSegments } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import React, { useCallback, useEffect, useState } from "react";
import { ActivityIndicator, View } from "react-native";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { KeyboardProvider } from "react-native-keyboard-controller";
import { SafeAreaProvider } from "react-native-safe-area-context";

import { ErrorBoundary } from "@/components/ErrorBoundary";
import colors from "@/constants/colors";
import { supabase } from "@/services/supabaseClient";

SplashScreen.preventAutoHideAsync().catch((error) => {
  console.warn("[RootLayout] preventAutoHideAsync failed:", error);
});

const queryClient = new QueryClient();
const C = colors.light;

async function resolveTargetPath(session: Session | null): Promise<"/login" | "/(onboarding)/step1" | "/(main)"> {
  if (!session) return "/login";

  try {
    const { data: profile, error } = await supabase
      .from("profiles")
      .select("onboarding_complete")
      .eq("user_id", session.user.id)
      .maybeSingle();

    if (error) {
      console.warn("[NutriWeek] Failed to read onboarding status:", error.message);
      return "/(onboarding)/step1";
    }

    return profile?.onboarding_complete ? "/(main)" : "/(onboarding)/step1";
  } catch (error) {
    console.error("[NutriWeek] resolveTargetPath crashed:", error);
    return "/(onboarding)/step1";
  }
}

function RootLayoutNav() {
  console.log("[RootLayoutNav] render start");
  const router = useRouter();
  const segments = useSegments();
  const [bootstrapped, setBootstrapped] = useState(false);

  const routeIfNeeded = useCallback(
    (target: "/login" | "/(onboarding)/step1" | "/(main)") => {
      const currentGroup = String(segments[0] ?? "");
      if (target === "/(main)" && currentGroup === "(main)") return;
      if (target === "/(onboarding)/step1" && currentGroup === "(onboarding)") return;
      if (target === "/login" && (currentGroup === "(auth)" || currentGroup === "login" || currentGroup === "register")) return;
      router.replace(target as never);
    },
    [router, segments],
  );

  useEffect(() => {
    let isMounted = true;

    async function bootstrap() {
      try {
        const { data } = await supabase.auth.getSession();
        const target = await resolveTargetPath(data.session);
        if (isMounted) {
          routeIfNeeded(target);
          setBootstrapped(true);
        }
      } catch (error) {
        console.error("[RootLayoutNav] bootstrap crashed:", error);
        if (isMounted) {
          routeIfNeeded("/login");
          setBootstrapped(true);
        }
      }
    }

    bootstrap();

    let subscription: { unsubscribe: () => void } | null = null;
    try {
      const authState = supabase.auth.onAuthStateChange(async (_event, session) => {
        try {
          const target = await resolveTargetPath(session);
          routeIfNeeded(target);
        } catch (error) {
          console.error("[RootLayoutNav] onAuthStateChange callback crashed:", error);
        }
      });
      subscription = authState.data.subscription;
    } catch (error) {
      console.error("[RootLayoutNav] onAuthStateChange registration crashed:", error);
    }

    return () => {
      isMounted = false;
      subscription?.unsubscribe();
    };
  }, [routeIfNeeded]);

  if (!bootstrapped) {
    return (
      <View
        style={{
          flex: 1,
          alignItems: "center",
          justifyContent: "center",
          backgroundColor: C.background,
        }}
      >
        <ActivityIndicator size="small" color={C.primary} />
      </View>
    );
  }

  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="(auth)" options={{ animation: "none" }} />
      <Stack.Screen name="(onboarding)" options={{ animation: "none" }} />
      <Stack.Screen name="(main)" options={{ animation: "none" }} />
      <Stack.Screen name="+not-found" />
    </Stack>
  );
}

export default function RootLayout() {
  console.log("[RootLayout] render start");
  const [fontsLoaded, fontError] = useFonts({
    Inter_400Regular,
    Inter_500Medium,
    Inter_600SemiBold,
    Inter_700Bold,
  });

  useEffect(() => {
    if (fontsLoaded || fontError) {
      SplashScreen.hideAsync().catch((error) => {
        console.warn("[RootLayout] hideAsync failed:", error);
      });
    }
  }, [fontsLoaded, fontError]);

  if (!fontsLoaded && !fontError) return null;

  return (
    <SafeAreaProvider>
      <ErrorBoundary>
        <QueryClientProvider client={queryClient}>
          <GestureHandlerRootView>
            <KeyboardProvider>
              <RootLayoutNav />
            </KeyboardProvider>
          </GestureHandlerRootView>
        </QueryClientProvider>
      </ErrorBoundary>
    </SafeAreaProvider>
  );
}
