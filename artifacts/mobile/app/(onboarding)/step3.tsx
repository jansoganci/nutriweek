import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Haptics from "expo-haptics";
import { router } from "expo-router";
import React, { useState } from "react";
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import RockyMascot from "@/components/RockyMascot";
import StepProgress from "@/components/StepProgress";
import colors from "@/constants/colors";

const C = colors.light;

const FIELDS: {
  key: "waist" | "hips" | "chest" | "arm" | "leg";
  label: string;
  placeholder: string;
}[] = [
  { key: "waist", label: "Waist", placeholder: "80" },
  { key: "hips", label: "Hips", placeholder: "95" },
  { key: "chest", label: "Chest", placeholder: "90" },
  { key: "arm", label: "Left Arm", placeholder: "35" },
  { key: "leg", label: "Left Leg", placeholder: "55" },
];

type MeasurementKey = "waist" | "hips" | "chest" | "arm" | "leg";
type Measurements = Partial<Record<MeasurementKey, string>>;

export default function Step3Screen() {
  const insets = useSafeAreaInsets();
  const [values, setValues] = useState<Measurements>({});
  const [hasTyped, setHasTyped] = useState(false);

  const hasAnyValue = Object.values(values).some((v) => v && v.trim() !== "");
  const rockyMessage = hasTyped
    ? "Look at you, being all precise! 🦝📏"
    : "Don't worry, these are just for YOU. No judging here! 🦝";

  const handleChange = (key: MeasurementKey, text: string) => {
    setValues((prev) => ({ ...prev, [key]: text }));
    if (!hasTyped) setHasTyped(true);
  };

  const saveAndNavigate = async () => {
    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);

    const existing = await AsyncStorage.getItem("userProfile");
    const parsed = existing ? JSON.parse(existing) : {};

    const measurements: Record<string, number> = {};
    for (const field of FIELDS) {
      const val = values[field.key];
      if (val && val.trim() !== "") {
        measurements[field.key] = Number(val);
      }
    }

    const updated = {
      ...parsed,
      ...(Object.keys(measurements).length > 0 ? { measurements } : {}),
    };

    await AsyncStorage.setItem("userProfile", JSON.stringify(updated));
    router.push("/(onboarding)/step4");
  };

  const handleSkip = () => {
    Haptics.selectionAsync();
    router.push("/(onboarding)/step4");
  };

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: C.background }}
      behavior={Platform.OS === "ios" ? "padding" : "height"}
    >
      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={[
          styles.container,
          { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 24 },
        ]}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        {/* Header row: progress + skip */}
        <View style={styles.headerRow}>
          <StepProgress currentStep={3} totalSteps={4} />
          <Pressable onPress={handleSkip} hitSlop={12}>
            <Text style={styles.skipText}>Skip for now</Text>
          </Pressable>
        </View>

        <View style={styles.mascotRow}>
          <RockyMascot mood="encouraging" size={64} message={rockyMessage} />
        </View>

        <Text style={styles.heading}>Body Measurements</Text>
        <Text style={styles.subheading}>All optional — skip if you prefer</Text>

        <View style={styles.cardsWrap}>
          {FIELDS.map((field) => (
            <View key={field.key} style={styles.card}>
              <Text style={styles.cardLabel}>{field.label}</Text>
              <View style={styles.inputRow}>
                <TextInput
                  style={styles.input}
                  placeholder={field.placeholder}
                  placeholderTextColor={C.textTertiary}
                  keyboardType="decimal-pad"
                  value={values[field.key] ?? ""}
                  onChangeText={(text) => handleChange(field.key, text)}
                  maxLength={5}
                />
                <Text style={styles.unit}>cm</Text>
              </View>
            </View>
          ))}
        </View>

        <Pressable
          style={[styles.continueBtn, { backgroundColor: C.primary }]}
          onPress={saveAndNavigate}
        >
          <Text style={styles.continueBtnText}>Continue</Text>
        </Pressable>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 20,
  },
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  skipText: {
    fontSize: 15,
    fontWeight: "600" as const,
    color: C.primary,
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
  cardsWrap: {
    gap: 12,
  },
  card: {
    backgroundColor: C.card,
    borderRadius: 14,
    borderWidth: 1.5,
    borderColor: C.border,
    paddingHorizontal: 18,
    paddingVertical: 14,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    shadowColor: C.shadowColor,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 6,
    elevation: 1,
  },
  cardLabel: {
    fontSize: 15,
    fontWeight: "600" as const,
    color: C.text,
    flex: 1,
  },
  inputRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  input: {
    fontSize: 16,
    fontWeight: "600" as const,
    color: C.text,
    textAlign: "right",
    minWidth: 60,
    paddingVertical: 4,
    paddingHorizontal: 8,
    backgroundColor: C.input,
    borderRadius: 8,
  },
  unit: {
    fontSize: 14,
    color: C.textSecondary,
    fontWeight: "500" as const,
    width: 24,
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
});
