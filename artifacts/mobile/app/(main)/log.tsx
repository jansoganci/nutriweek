import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import MacroRing from "@/components/MacroRing";
import { useColors } from "@/hooks/useColors";
import type { MealEntry } from "@/constants/types";

export default function LogScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();

  return (
    <ScrollView
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={[
        styles.container,
        { paddingTop: insets.top + 16 },
      ]}
    >
      <Text style={[styles.title, { color: colors.text }]}>Food Log</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 24,
    gap: 16,
  },
  title: {
    fontSize: 28,
    fontWeight: "700" as const,
  },
});
