import React from "react";
import { StyleSheet, Text, View } from "react-native";

import { useColors } from "@/hooks/useColors";

interface StepProgressProps {
  currentStep: number;
  totalSteps: number;
  showLabel?: boolean;
}

export default function StepProgress({
  currentStep,
  totalSteps,
  showLabel = true,
}: StepProgressProps) {
  const colors = useColors();

  return (
    <View style={styles.container}>
      {showLabel && (
        <Text style={[styles.label, { color: colors.textSecondary }]}>
          {currentStep}/{totalSteps}
        </Text>
      )}
      <View style={styles.dots}>
        {Array.from({ length: totalSteps }).map((_, index) => {
          const isCompleted = index < currentStep - 1;
          const isActive = index === currentStep - 1;

          return (
            <View
              key={index}
              style={[
                styles.dot,
                {
                  backgroundColor: isActive
                    ? colors.primary
                    : isCompleted
                      ? colors.primary
                      : colors.muted,
                  width: isActive ? 24 : 8,
                  opacity: isCompleted ? 0.5 : 1,
                },
              ]}
            />
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: "center",
    gap: 8,
  },
  label: {
    fontSize: 13,
    fontWeight: "500" as const,
  },
  dots: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  dot: {
    height: 8,
    borderRadius: 4,
  },
});
