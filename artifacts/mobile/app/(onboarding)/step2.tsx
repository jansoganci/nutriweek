import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Haptics from "expo-haptics";
import { router } from "expo-router";
import React, { useState } from "react";
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import RockyMascot from "@/components/RockyMascot";
import StepProgress from "@/components/StepProgress";
import colors from "@/constants/colors";
import type { Goal } from "@/constants/types";

const C = colors.light;

const GOAL_CARDS: {
  value: Goal;
  emoji: string;
  title: string;
  subtitle: string;
}[] = [
  {
    value: "cut",
    emoji: "🔥",
    title: "Lose Fat",
    subtitle: "Calorie deficit · Look lean · Feel light",
  },
  {
    value: "bulk",
    emoji: "💪",
    title: "Build Muscle",
    subtitle: "Calorie surplus · Get strong · Grow",
  },
  {
    value: "maintain",
    emoji: "⚖️",
    title: "Stay Balanced",
    subtitle: "Eat at maintenance · Keep what you have",
  },
];

const ROCKY_MESSAGES: Record<string, string> = {
  default: "What's the mission? 🦝 Choose your goal!",
  cut: "Let's get shredded! I'll keep the snacks away 🦝🔥",
  bulk: "Eating more? My favorite goal! 🦝🍗",
  maintain: "Balance is everything. Very zen 🦝☯️",
};

export default function Step2Screen() {
  const insets = useSafeAreaInsets();
  const [goal, setGoal] = useState<Goal | null>(null);

  const rockyMessage = goal ? ROCKY_MESSAGES[goal] : ROCKY_MESSAGES.default;
  const isComplete = goal !== null;

  const handleSelect = (value: Goal) => {
    setGoal(value);
    Haptics.selectionAsync();
  };

  const handleContinue = async () => {
    if (!isComplete) return;

    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);

    const existing = await AsyncStorage.getItem("userProfile");
    const parsed = existing ? JSON.parse(existing) : {};
    await AsyncStorage.setItem(
      "userProfile",
      JSON.stringify({ ...parsed, goal })
    );

    router.push("/(onboarding)/step3");
  };

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: C.background }}
      contentContainerStyle={[
        styles.container,
        { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 24 },
      ]}
      showsVerticalScrollIndicator={false}
    >
      <StepProgress currentStep={2} totalSteps={4} />

      <View style={styles.mascotRow}>
        <RockyMascot mood="happy" size={64} message={rockyMessage} />
      </View>

      <Text style={styles.heading}>Your Goal</Text>

      <View style={styles.cardsWrap}>
        {GOAL_CARDS.map((card) => {
          const isSelected = goal === card.value;
          return (
            <Pressable
              key={card.value}
              style={[styles.card, isSelected && styles.cardSelected]}
              onPress={() => handleSelect(card.value)}
            >
              {isSelected && (
                <View style={styles.checkBadge}>
                  <Text style={styles.checkText}>✓</Text>
                </View>
              )}
              <Text style={styles.cardEmoji}>{card.emoji}</Text>
              <Text
                style={[styles.cardTitle, isSelected && { color: C.primary }]}
              >
                {card.title}
              </Text>
              <Text style={styles.cardSubtitle}>{card.subtitle}</Text>
            </Pressable>
          );
        })}
      </View>

      <Pressable
        style={[
          styles.continueBtn,
          { backgroundColor: isComplete ? C.primary : "#CCCCCC" },
        ]}
        onPress={handleContinue}
      >
        <Text style={styles.continueBtnText}>Continue</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 20,
  },
  mascotRow: {
    alignItems: "center",
    marginTop: 20,
    marginBottom: 28,
  },
  heading: {
    fontSize: 26,
    fontWeight: "700" as const,
    color: C.text,
    marginBottom: 20,
  },
  cardsWrap: {
    gap: 14,
  },
  card: {
    backgroundColor: C.card,
    borderRadius: 18,
    borderWidth: 2,
    borderColor: "#E0E0E0",
    padding: 22,
    shadowColor: C.shadowColor,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.07,
    shadowRadius: 8,
    elevation: 2,
  },
  cardSelected: {
    backgroundColor: "#FFF3EE",
    borderColor: C.primary,
  },
  checkBadge: {
    position: "absolute",
    top: 14,
    right: 14,
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: C.primary,
    alignItems: "center",
    justifyContent: "center",
  },
  checkText: {
    color: "#FFFFFF",
    fontSize: 13,
    fontWeight: "700" as const,
  },
  cardEmoji: {
    fontSize: 36,
    marginBottom: 10,
  },
  cardTitle: {
    fontSize: 20,
    fontWeight: "700" as const,
    color: C.text,
    marginBottom: 4,
  },
  cardSubtitle: {
    fontSize: 14,
    color: C.textSecondary,
    lineHeight: 20,
  },
  continueBtn: {
    marginTop: 32,
    borderRadius: 16,
    paddingVertical: 16,
    alignItems: "center",
  },
  continueBtnText: {
    fontSize: 16,
    fontWeight: "700" as const,
    color: "#FFFFFF",
  },
});
