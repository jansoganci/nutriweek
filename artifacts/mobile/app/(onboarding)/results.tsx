import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Haptics from "expo-haptics";
import { router } from "expo-router";
import React, { useEffect, useState } from "react";
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import RockyMascot from "@/components/RockyMascot";
import colors from "@/constants/colors";
import type { Goal, UserProfile } from "@/constants/types";
import calculateAll, { type CalculationResults } from "@/services/calculations";

const C = colors.light;

// Fallback shown while AsyncStorage loads
const FALLBACK_RESULTS: CalculationResults = {
  bmi: 0,
  bmiCategory: { label: "Healthy", color: "#4CAF50" },
  bmr: 0,
  tdee: 0,
  targetCalories: 0,
  macros: { protein: 0, carbs: 0, fat: 0 },
  macroPercentages: { protein: 30, carbs: 45, fat: 25 },
};

function getRockyMessage(bmiLabel: string): string {
  switch (bmiLabel) {
    case "Healthy":
      return "Looking good! Now let's eat right 🦝✨";
    case "Underweight":
      return "We'll get you fueled up properly! 🦝💪";
    case "Overweight":
      return "No worries, Rocky's got your back! 🦝❤️";
    default:
      return "Every journey starts with one step. Let's go! 🦝🌟";
  }
}

const GOAL_META: Record<Goal, { emoji: string; title: string; desc: string }> =
  {
    cut: { emoji: "🔥", title: "Lose Fat", desc: "500 kcal daily deficit" },
    bulk: {
      emoji: "💪",
      title: "Build Muscle",
      desc: "300 kcal daily surplus",
    },
    maintain: {
      emoji: "⚖️",
      title: "Stay Balanced",
      desc: "Eating at maintenance",
    },
  };

interface StatRowProps {
  emoji: string;
  label: string;
  value: string;
}
function StatRow({ emoji, label, value }: StatRowProps) {
  return (
    <View style={styles.statRow}>
      <Text style={styles.statEmoji}>{emoji}</Text>
      <Text style={styles.statLabel}>{label}</Text>
      <Text style={styles.statValue}>{value}</Text>
    </View>
  );
}

interface MacroBarProps {
  label: string;
  grams: number;
  totalCalories: number;
  calsPerGram: number;
  color: string;
}
function MacroBar({ label, grams, totalCalories, calsPerGram, color }: MacroBarProps) {
  const pct = totalCalories > 0 ? Math.round((grams * calsPerGram * 100) / totalCalories) : 0;
  return (
    <View style={styles.macroBarWrap}>
      <View style={styles.macroBarHeader}>
        <Text style={styles.macroBarLabel}>{label}</Text>
        <Text style={styles.macroBarMeta}>
          {pct}% · {grams}g
        </Text>
      </View>
      <View style={styles.macroBarTrack}>
        <View
          style={[
            styles.macroBarFill,
            { width: `${pct}%` as unknown as number, backgroundColor: color },
          ]}
        />
      </View>
    </View>
  );
}

export default function ResultsScreen() {
  const insets = useSafeAreaInsets();
  const [results, setResults] = useState<CalculationResults>(FALLBACK_RESULTS);
  const [goal, setGoal] = useState<Goal>("maintain");
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    if (loaded && results.bmi === 0) {
      router.replace("/(onboarding)/step1");
    }
  }, [loaded, results.bmi]);

  useEffect(() => {
    AsyncStorage.getItem("userProfile").then((raw) => {
      console.log("[NutriWeek] userProfile raw:", raw);

      if (raw) {
        const profile = JSON.parse(raw) as UserProfile;
        console.log("[NutriWeek] userProfile parsed:", JSON.stringify(profile, null, 2));

        if (
          profile.weight &&
          profile.height &&
          profile.age &&
          profile.gender &&
          profile.activityLevel &&
          profile.goal
        ) {
          const calc = calculateAll(profile);
          console.log("[NutriWeek] calculationResults:", JSON.stringify(calc, null, 2));
          setResults(calc);
          setGoal(profile.goal as Goal);
        } else {
          console.warn("[NutriWeek] Guard failed — missing required fields:", {
            weight: profile.weight,
            height: profile.height,
            age: profile.age,
            gender: profile.gender,
            activityLevel: profile.activityLevel,
            goal: profile.goal,
          });
        }
      } else {
        console.warn("[NutriWeek] No userProfile found in AsyncStorage");
      }
      setLoaded(true);
    });
  }, []);

  const { bmi, bmiCategory, targetCalories, macros, macroPercentages } = results;
  const { label: bmiLabel, color: bmiColor } = bmiCategory;
  const rockyMessage = getRockyMessage(bmiLabel);

  // BMI scale position: clamp between 15 and 40 for display
  const bmiMin = 15;
  const bmiMax = 40;
  const bmiPct = Math.min(
    Math.max(((bmi - bmiMin) / (bmiMax - bmiMin)) * 100, 2),
    98
  );

  const goalMeta = GOAL_META[goal];

  if (!loaded) {
    return (
      <View style={{ flex: 1, backgroundColor: C.background, alignItems: "center", justifyContent: "center" }}>
        <Text style={{ fontSize: 40 }}>🦝</Text>
        <Text style={{ color: C.textSecondary, marginTop: 12, fontSize: 15 }}>
          Crunching your numbers…
        </Text>
      </View>
    );
  }

  const handleStart = async () => {
    await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    router.replace("/(main)");
  };

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: C.background }}
      contentContainerStyle={[
        styles.container,
        { paddingTop: insets.top + 20, paddingBottom: insets.bottom + 32 },
      ]}
      showsVerticalScrollIndicator={false}
    >
      {/* Rocky celebration */}
      <View style={styles.celebrationWrap}>
        <RockyMascot mood="celebrating" size={88} message={rockyMessage} />
      </View>

      <Text style={styles.headline}>Your plan is ready!</Text>
      <Text style={styles.subline}>Here's what we calculated for you</Text>

      {/* BMI Card */}
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Your BMI</Text>
        <View style={styles.bmiCenter}>
          <Text style={styles.bmiNumber}>{bmi.toFixed(1)}</Text>
          <View style={[styles.bmiLabel, { backgroundColor: bmiColor + "22" }]}>
            <Text style={[styles.bmiLabelText, { color: bmiColor }]}>
              {bmiLabel}
            </Text>
          </View>
        </View>

        {/* BMI scale bar */}
        <View style={styles.bmiScaleWrap}>
          <View style={styles.bmiTrack}>
            <View style={[styles.bmiSegment, { backgroundColor: "#FFB300", flex: 1 }]} />
            <View style={[styles.bmiSegment, { backgroundColor: "#4CAF50", flex: 2 }]} />
            <View style={[styles.bmiSegment, { backgroundColor: "#FFB300", flex: 1.5 }]} />
            <View style={[styles.bmiSegment, { backgroundColor: "#FF4444", flex: 2 }]} />
          </View>
          <View
            style={[
              styles.bmiIndicator,
              { left: `${bmiPct}%` as unknown as number },
            ]}
          >
            <View style={styles.bmiIndicatorDot} />
          </View>
          <View style={styles.bmiScaleLabels}>
            <Text style={styles.bmiScaleLabel}>15</Text>
            <Text style={styles.bmiScaleLabel}>18.5</Text>
            <Text style={styles.bmiScaleLabel}>25</Text>
            <Text style={styles.bmiScaleLabel}>30</Text>
            <Text style={styles.bmiScaleLabel}>40</Text>
          </View>
        </View>
      </View>

      {/* Daily Targets Card */}
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Your Daily Targets</Text>
        <View style={styles.statList}>
          <StatRow emoji="🔥" label="Calories" value={`${targetCalories} kcal`} />
          <View style={styles.divider} />
          <StatRow emoji="🥩" label="Protein" value={`${macros.protein} g`} />
          <View style={styles.divider} />
          <StatRow emoji="🍚" label="Carbs" value={`${macros.carbs} g`} />
          <View style={styles.divider} />
          <StatRow emoji="🥑" label="Fat" value={`${macros.fat} g`} />
        </View>
      </View>

      {/* Macro Split Card */}
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Macro Split</Text>
        <View style={styles.macroBars}>
          <MacroBar
            label="Protein"
            grams={macros.protein}
            totalCalories={targetCalories}
            calsPerGram={4}
            color={C.primary}
          />
          <MacroBar
            label="Carbs"
            grams={macros.carbs}
            totalCalories={targetCalories}
            calsPerGram={4}
            color={C.success}
          />
          <MacroBar
            label="Fat"
            grams={macros.fat}
            totalCalories={targetCalories}
            calsPerGram={9}
            color={C.warning}
          />
        </View>
      </View>

      {/* Goal Summary Card */}
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Your Goal</Text>
        <View style={styles.goalRow}>
          <Text style={styles.goalEmoji}>{goalMeta.emoji}</Text>
          <View style={styles.goalText}>
            <Text style={styles.goalTitle}>{goalMeta.title}</Text>
            <Text style={styles.goalDesc}>{goalMeta.desc}</Text>
          </View>
        </View>
      </View>

      {/* CTA */}
      <Pressable style={styles.cta} onPress={handleStart}>
        <Text style={styles.ctaText}>Let's Start! 🦝</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 20,
    gap: 14,
  },
  celebrationWrap: {
    alignItems: "center",
    gap: 8,
    marginBottom: 4,
  },
  confettiRow: {
    flexDirection: "row",
    gap: 16,
  },
  confetti: {
    fontSize: 24,
  },
  headline: {
    fontSize: 28,
    fontWeight: "700" as const,
    color: C.text,
    textAlign: "center",
  },
  subline: {
    fontSize: 15,
    color: C.textSecondary,
    textAlign: "center",
    marginBottom: 4,
  },
  card: {
    backgroundColor: C.card,
    borderRadius: 18,
    padding: 20,
    shadowColor: C.shadowColor,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.07,
    shadowRadius: 8,
    elevation: 2,
    borderWidth: 1,
    borderColor: C.border,
  },
  cardTitle: {
    fontSize: 13,
    fontWeight: "600" as const,
    color: C.textSecondary,
    textTransform: "uppercase",
    letterSpacing: 0.8,
    marginBottom: 14,
  },

  // BMI
  bmiCenter: {
    alignItems: "center",
    gap: 8,
    marginBottom: 20,
  },
  bmiNumber: {
    fontSize: 52,
    fontWeight: "700" as const,
    color: C.text,
    lineHeight: 56,
  },
  bmiLabel: {
    paddingHorizontal: 14,
    paddingVertical: 4,
    borderRadius: 20,
  },
  bmiLabelText: {
    fontSize: 14,
    fontWeight: "700" as const,
  },
  bmiScaleWrap: {
    position: "relative",
  },
  bmiTrack: {
    flexDirection: "row",
    height: 10,
    borderRadius: 6,
    overflow: "hidden",
  },
  bmiSegment: {
    height: 10,
  },
  bmiIndicator: {
    position: "absolute",
    top: -4,
    marginLeft: -9,
    alignItems: "center",
  },
  bmiIndicatorDot: {
    width: 18,
    height: 18,
    borderRadius: 9,
    backgroundColor: C.text,
    borderWidth: 3,
    borderColor: C.card,
    shadowColor: C.shadowColor,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.2,
    shadowRadius: 3,
    elevation: 3,
  },
  bmiScaleLabels: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 6,
  },
  bmiScaleLabel: {
    fontSize: 10,
    color: C.textTertiary,
  },

  // Stat rows
  statList: {
    gap: 0,
  },
  statRow: {
    flexDirection: "row",
    alignItems: "center",
    paddingVertical: 10,
    gap: 10,
  },
  statEmoji: {
    fontSize: 20,
    width: 28,
  },
  statLabel: {
    flex: 1,
    fontSize: 15,
    color: C.text,
    fontWeight: "500" as const,
  },
  statValue: {
    fontSize: 16,
    fontWeight: "700" as const,
    color: C.text,
  },
  divider: {
    height: 1,
    backgroundColor: C.border,
  },

  // Macro bars
  macroBars: {
    gap: 14,
  },
  macroBarWrap: {
    gap: 6,
  },
  macroBarHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  macroBarLabel: {
    fontSize: 14,
    fontWeight: "600" as const,
    color: C.text,
  },
  macroBarMeta: {
    fontSize: 13,
    color: C.textSecondary,
  },
  macroBarTrack: {
    height: 10,
    backgroundColor: C.muted,
    borderRadius: 6,
    overflow: "hidden",
  },
  macroBarFill: {
    height: 10,
    borderRadius: 6,
  },

  // Goal
  goalRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
  },
  goalEmoji: {
    fontSize: 36,
  },
  goalText: {
    flex: 1,
  },
  goalTitle: {
    fontSize: 17,
    fontWeight: "700" as const,
    color: C.text,
  },
  goalDesc: {
    fontSize: 13,
    color: C.textSecondary,
    marginTop: 2,
  },

  // CTA
  cta: {
    backgroundColor: C.primary,
    borderRadius: 18,
    paddingVertical: 18,
    alignItems: "center",
    marginTop: 6,
    shadowColor: C.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 10,
    elevation: 4,
  },
  ctaText: {
    fontSize: 18,
    fontWeight: "700" as const,
    color: "#FFFFFF",
  },
});
