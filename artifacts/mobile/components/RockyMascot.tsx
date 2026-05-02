import React from "react";
import { StyleSheet, Text, View } from "react-native";

import { useColors } from "@/hooks/useColors";

export type RockyMood = "happy" | "thinking" | "celebrating" | "encouraging";

interface RockyMascotProps {
  mood?: RockyMood;
  size?: number;
  message?: string;
}

export default function RockyMascot({
  mood = "happy",
  size = 64,
  message,
}: RockyMascotProps) {
  const colors = useColors();

  return (
    <View style={styles.container}>
      <Text style={[styles.emoji, { fontSize: size }]}>🦝</Text>
      {message ? (
        <View
          style={[
            styles.bubble,
            {
              backgroundColor: colors.card,
              borderColor: colors.border,
            },
          ]}
        >
          <Text style={[styles.bubbleText, { color: colors.text }]}>
            {message}
          </Text>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: "center",
    gap: 8,
  },
  emoji: {
    lineHeight: undefined,
  },
  bubble: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 16,
    borderWidth: 1,
    maxWidth: 240,
  },
  bubbleText: {
    fontSize: 14,
    lineHeight: 20,
    textAlign: "center",
  },
});
