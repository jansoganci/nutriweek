import React, { useEffect, useRef } from "react";
import { Animated, StyleSheet, Text, View } from "react-native";

import { useColors } from "@/hooks/useColors";

export type RockyMood = "happy" | "thinking" | "celebrating" | "encouraging";
export type RockyVariant = "idle" | "celebrate" | "thinking";

interface RockyMascotProps {
  mood?: RockyMood;
  size?: number;
  message?: string;
  variant?: RockyVariant;
}

export default function RockyMascot({
  mood = "happy",
  size = 64,
  message,
  variant = "idle",
}: RockyMascotProps) {
  const colors = useColors();

  const floatAnim = useRef(new Animated.Value(0)).current;
  const scaleAnim = useRef(new Animated.Value(1)).current;
  const opacityAnim = useRef(new Animated.Value(1)).current;
  const bubbleScale = useRef(new Animated.Value(0.8)).current;

  useEffect(() => {
    floatAnim.stopAnimation();
    scaleAnim.stopAnimation();
    opacityAnim.stopAnimation();

    if (variant === "idle") {
      Animated.loop(
        Animated.sequence([
          Animated.timing(floatAnim, {
            toValue: -6,
            duration: 1000,
            useNativeDriver: true,
          }),
          Animated.timing(floatAnim, {
            toValue: 6,
            duration: 1000,
            useNativeDriver: true,
          }),
        ])
      ).start();
    } else if (variant === "celebrate") {
      Animated.loop(
        Animated.sequence([
          Animated.spring(scaleAnim, {
            toValue: 1.18,
            useNativeDriver: true,
            damping: 6,
            stiffness: 300,
          }),
          Animated.spring(scaleAnim, {
            toValue: 0.88,
            useNativeDriver: true,
            damping: 6,
            stiffness: 300,
          }),
          Animated.spring(scaleAnim, {
            toValue: 1.0,
            useNativeDriver: true,
            damping: 10,
            stiffness: 200,
          }),
        ])
      ).start();
    } else if (variant === "thinking") {
      Animated.loop(
        Animated.sequence([
          Animated.timing(opacityAnim, {
            toValue: 0.35,
            duration: 900,
            useNativeDriver: true,
          }),
          Animated.timing(opacityAnim, {
            toValue: 1.0,
            duration: 900,
            useNativeDriver: true,
          }),
        ])
      ).start();
    }
  }, [variant, floatAnim, scaleAnim, opacityAnim]);

  useEffect(() => {
    if (message) {
      bubbleScale.setValue(0.8);
      Animated.spring(bubbleScale, {
        toValue: 1.0,
        useNativeDriver: true,
        damping: 14,
        stiffness: 220,
      }).start();
    }
  }, [message, bubbleScale]);

  const emojiTransform =
    variant === "idle"
      ? [{ translateY: floatAnim }]
      : variant === "celebrate"
      ? [{ scale: scaleAnim }]
      : [];

  return (
    <View style={styles.container}>
      <Animated.View
        style={[
          variant === "thinking" && { opacity: opacityAnim },
          { transform: emojiTransform },
        ]}
      >
        <Text style={[styles.emoji, { fontSize: size }]}>🦝</Text>
      </Animated.View>
      {message ? (
        <Animated.View
          style={[
            styles.bubble,
            {
              backgroundColor: colors.card,
              borderColor: colors.border,
              transform: [{ scale: bubbleScale }],
            },
          ]}
        >
          <Text style={[styles.bubbleText, { color: colors.text }]}>
            {message}
          </Text>
        </Animated.View>
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
