import { Stack, useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { ActivityIndicator, View } from "react-native";

import { useColors } from "@/hooks/useColors";
import { supabase } from "@/services/supabaseClient";

export default function AuthLayout() {
  console.log("[AuthLayout] render start");
  const colors = useColors();
  const router = useRouter();
  const [checkingSession, setCheckingSession] = useState(true);

  useEffect(() => {
    let isMounted = true;

    async function checkSession() {
      try {
        const { data } = await supabase.auth.getSession();
        const session = data.session;

        if (!session) {
          if (isMounted) setCheckingSession(false);
          return;
        }

        const { data: profile, error } = await supabase
          .from("profiles")
          .select("onboarding_complete")
          .eq("user_id", session.user.id)
          .maybeSingle();

        if (error) {
          console.warn("[NutriWeek] Failed to read profile onboarding status:", error.message);
        }

        const onboardingComplete = Boolean(profile?.onboarding_complete);
        router.replace(onboardingComplete ? "/(main)" : "/(onboarding)/step1");
      } catch (error) {
        console.error("[AuthLayout] checkSession crashed:", error);
        if (isMounted) setCheckingSession(false);
      }
    }

    checkSession().finally(() => {
      if (isMounted) setCheckingSession(false);
    });

    return () => {
      isMounted = false;
    };
  }, [router]);

  if (checkingSession) {
    return (
      <View
        style={{
          flex: 1,
          alignItems: "center",
          justifyContent: "center",
          backgroundColor: colors.background,
        }}
      >
        <ActivityIndicator size="small" color={colors.primary} />
      </View>
    );
  }

  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: colors.background },
        animation: "slide_from_right",
      }}
    >
      <Stack.Screen name="login" />
      <Stack.Screen name="register" />
    </Stack>
  );
}
