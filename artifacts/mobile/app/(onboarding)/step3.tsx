import { router } from "expo-router";
import React from "react";
import { StyleSheet, Text, View } from "react-native";

import StepProgress from "@/components/StepProgress";
import { useColors } from "@/hooks/useColors";

export default function Step3Screen() {
  const colors = useColors();

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <StepProgress currentStep={3} totalSteps={4} />
      <Text style={[styles.title, { color: colors.text }]}>
        Body Measurements
      </Text>
      <Text style={[styles.subtitle, { color: colors.textSecondary }]}>
        Optional — you can skip this step
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 24,
  },
  title: {
    fontSize: 28,
    fontWeight: "700" as const,
    marginTop: 24,
  },
  subtitle: {
    fontSize: 15,
    marginTop: 8,
  },
});
