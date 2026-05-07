import * as Haptics from "expo-haptics";
import { router } from "expo-router";
import React, { useState } from "react";
import {
  ActivityIndicator,
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
import { saveStep4 } from "@/services/onboarding";

const C = colors.light;

type DietKey =
  | "everything"
  | "vegetarian"
  | "vegan"
  | "gluten_free"
  | "lactose_free"
  | "halal"
  | "no_pork"
  | "no_seafood";

const OPTIONS: { key: DietKey; emoji: string; label: string }[] = [
  { key: "everything", emoji: "🥩", label: "Everything" },
  { key: "vegetarian", emoji: "🥬", label: "Vegetarian" },
  { key: "vegan", emoji: "🌱", label: "Vegan" },
  { key: "gluten_free", emoji: "🌾", label: "Gluten Free" },
  { key: "lactose_free", emoji: "🥛", label: "Lactose Free" },
  { key: "halal", emoji: "✅", label: "Halal" },
  { key: "no_pork", emoji: "🐷", label: "No Pork" },
  { key: "no_seafood", emoji: "🐟", label: "No Seafood" },
];

function getRockyMessage(selected: DietKey[]): string {
  if (selected.length === 0) return "Any food rules I should know about? 🦝🍽️";
  if (selected.includes("everything")) return "My kind of human! 🦝🍕🍗🥗";
  if (selected.includes("vegan")) return "A fellow plant lover! 🦝🌱";
  if (selected.includes("gluten_free")) return "Got it, no bread crimes! 🦝🌾";
  if (selected.includes("halal")) return "Noted! Clean eating all the way 🦝✅";
  if (selected.length > 1) return "Complex taste! I respect it 🦝";
  return "Any food rules I should know about? 🦝🍽️";
}

export default function Step4Screen() {
  const insets = useSafeAreaInsets();
  const [selected, setSelected] = useState<DietKey[]>([]);
  const [saving, setSaving] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const rockyMessage = getRockyMessage(selected);

  const toggle = (key: DietKey) => {
    Haptics.selectionAsync();
    if (key === "everything") {
      setSelected(selected.includes("everything") ? [] : ["everything"]);
      return;
    }
    setSelected((prev) => {
      const without = prev.filter((k) => k !== "everything");
      return without.includes(key)
        ? without.filter((k) => k !== key)
        : [...without, key];
    });
  };

  const handleContinue = async () => {
    if (saving) return;
    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setErrorMessage(null);
    setSaving(true);
    try {
      await saveStep4(selected);
      router.push("/(onboarding)/results");
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to save step 4.";
      setErrorMessage(message);
    } finally {
      setSaving(false);
    }
  };

  // Split options into rows of 2
  const rows: (typeof OPTIONS)[] = [];
  for (let i = 0; i < OPTIONS.length; i += 2) {
    rows.push(OPTIONS.slice(i, i + 2));
  }

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: C.background }}
      contentContainerStyle={[
        styles.container,
        { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 24 },
      ]}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.headerRow}>
        <Pressable onPress={() => router.back()} hitSlop={12} style={styles.backBtn}>
          <Text style={styles.backText}>‹</Text>
        </Pressable>
        <View style={styles.progressWrap}>
          <StepProgress currentStep={4} totalSteps={4} />
        </View>
        <View style={styles.rightSlot} />
      </View>

      <View style={styles.mascotRow}>
        <RockyMascot mood="happy" size={64} message={rockyMessage} />
      </View>

      <Text style={styles.heading}>Dietary Preferences</Text>
      <Text style={styles.subheading}>Select all that apply</Text>

      <View style={styles.grid}>
        {rows.map((row, ri) => (
          <View key={ri} style={styles.row}>
            {row.map((opt) => {
              const isSelected = selected.includes(opt.key);
              return (
                <Pressable
                  key={opt.key}
                  style={[styles.pill, isSelected && styles.pillSelected]}
                  onPress={() => toggle(opt.key)}
                >
                  <Text style={styles.pillEmoji}>{opt.emoji}</Text>
                  <Text
                    style={[
                      styles.pillText,
                      isSelected && styles.pillTextSelected,
                    ]}
                  >
                    {opt.label}
                  </Text>
                </Pressable>
              );
            })}
            {/* fill empty slot if odd row */}
            {row.length < 2 && <View style={styles.pillPlaceholder} />}
          </View>
        ))}
      </View>

      <Pressable
        style={[styles.continueBtn, { backgroundColor: C.primary }]}
        onPress={handleContinue}
        disabled={saving}
      >
        {saving ? (
          <ActivityIndicator color="#FFFFFF" />
        ) : (
          <Text style={styles.continueBtnText}>See My Results</Text>
        )}
      </Pressable>
      {errorMessage ? <Text style={styles.errorText}>{errorMessage}</Text> : null}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 20,
  },
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
  },
  backBtn: {
    width: 40,
    alignItems: "flex-start",
  },
  backText: {
    fontSize: 28,
    fontWeight: "600" as const,
    color: C.text,
    lineHeight: 32,
  },
  progressWrap: {
    flex: 1,
    alignItems: "center",
  },
  rightSlot: {
    width: 60,
  },
  mascotRow: {
    alignItems: "center",
    marginTop: 20,
    marginBottom: 24,
  },
  heading: {
    fontSize: 26,
    fontWeight: "700" as const,
    color: C.text,
    marginBottom: 4,
  },
  subheading: {
    fontSize: 14,
    color: C.textSecondary,
    marginBottom: 20,
  },
  grid: {
    gap: 12,
  },
  row: {
    flexDirection: "row",
    gap: 12,
  },
  pill: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderRadius: 14,
    backgroundColor: C.card,
    borderWidth: 1.5,
    borderColor: "#E0E0E0",
    shadowColor: C.shadowColor,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 1,
  },
  pillSelected: {
    backgroundColor: C.primary,
    borderColor: C.primary,
  },
  pillPlaceholder: {
    flex: 1,
  },
  pillEmoji: {
    fontSize: 18,
  },
  pillText: {
    fontSize: 14,
    fontWeight: "600" as const,
    color: C.text,
  },
  pillTextSelected: {
    color: "#FFFFFF",
  },
  continueBtn: {
    marginTop: 28,
    borderRadius: 16,
    paddingVertical: 16,
    alignItems: "center",
  },
  continueBtnText: {
    fontSize: 16,
    fontWeight: "700" as const,
    color: "#FFFFFF",
  },
  errorText: {
    marginTop: 12,
    textAlign: "center",
    color: C.destructive,
    fontSize: 13,
  },
});
