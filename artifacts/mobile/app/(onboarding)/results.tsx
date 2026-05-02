import { router } from "expo-router";
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";

import MacroRing from "@/components/MacroRing";
import RockyMascot from "@/components/RockyMascot";
import type { CalculationResults } from "@/constants/types";
import { useColors } from "@/hooks/useColors";

export default function ResultsScreen() {
  const colors = useColors();

  return (
    <ScrollView
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={styles.container}
    >
      <RockyMascot mood="celebrating" size={72} />
      <Text style={[styles.title, { color: colors.text }]}>
        Your Results
      </Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 24,
    alignItems: "center",
    gap: 16,
  },
  title: {
    fontSize: 28,
    fontWeight: "700" as const,
    marginTop: 8,
  },
});
