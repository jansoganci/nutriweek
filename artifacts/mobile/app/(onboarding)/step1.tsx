import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Haptics from "expo-haptics";
import { router } from "expo-router";
import React, { useRef, useState } from "react";
import {
  Animated,
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
import type { ActivityLevel, Gender } from "@/constants/types";

const C = colors.light;

const ACTIVITY_OPTIONS: {
  value: ActivityLevel;
  label: string;
  description: string;
}[] = [
  {
    value: "sedentary",
    label: "Sedentary",
    description: "Little or no exercise",
  },
  {
    value: "lightly_active",
    label: "Lightly Active",
    description: "1–3 days/week",
  },
  {
    value: "moderately_active",
    label: "Moderately Active",
    description: "3–5 days/week",
  },
  {
    value: "very_active",
    label: "Very Active",
    description: "6–7 days/week",
  },
  {
    value: "extra_active",
    label: "Extra Active",
    description: "Physical job or 2×/day",
  },
];

const ROCKY_MESSAGES: Record<string, string> = {
  default: "Hey! I'm Rocky 🦝 Let's build your perfect meal plan!",
  sedentary: "No worries, we all start somewhere! 🦝",
  lightly_active: "Nice! I like your style 🦝",
  moderately_active: "Nice! I like your style 🦝",
  very_active: "Nice! I like your style 🦝",
  extra_active: "Wow, you're a machine! 🦝💪",
};

function shake(anim: Animated.Value) {
  Animated.sequence([
    Animated.timing(anim, {
      toValue: 8,
      duration: 60,
      useNativeDriver: true,
    }),
    Animated.timing(anim, {
      toValue: -8,
      duration: 60,
      useNativeDriver: true,
    }),
    Animated.timing(anim, {
      toValue: 6,
      duration: 50,
      useNativeDriver: true,
    }),
    Animated.timing(anim, {
      toValue: -6,
      duration: 50,
      useNativeDriver: true,
    }),
    Animated.timing(anim, {
      toValue: 0,
      duration: 40,
      useNativeDriver: true,
    }),
  ]).start();
}

export default function Step1Screen() {
  const insets = useSafeAreaInsets();

  const [gender, setGender] = useState<Gender | null>(null);
  const [age, setAge] = useState("");
  const [height, setHeight] = useState("");
  const [weight, setWeight] = useState("");
  const [activityLevel, setActivityLevel] = useState<ActivityLevel | null>(
    null
  );

  const rockyMessage =
    activityLevel !== null
      ? ROCKY_MESSAGES[activityLevel]
      : ROCKY_MESSAGES.default;

  const isComplete =
    gender !== null &&
    age.trim() !== "" &&
    height.trim() !== "" &&
    weight.trim() !== "" &&
    activityLevel !== null;

  const shakeGender = useRef(new Animated.Value(0)).current;
  const shakeAge = useRef(new Animated.Value(0)).current;
  const shakeHeight = useRef(new Animated.Value(0)).current;
  const shakeWeight = useRef(new Animated.Value(0)).current;
  const shakeActivity = useRef(new Animated.Value(0)).current;

  const handleContinue = async () => {
    if (!isComplete) {
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
      if (gender === null) shake(shakeGender);
      if (age.trim() === "") shake(shakeAge);
      if (height.trim() === "") shake(shakeHeight);
      if (weight.trim() === "") shake(shakeWeight);
      if (activityLevel === null) shake(shakeActivity);
      return;
    }

    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);

    const existing = await AsyncStorage.getItem("userProfile");
    const parsed = existing ? JSON.parse(existing) : {};
    await AsyncStorage.setItem(
      "userProfile",
      JSON.stringify({
        ...parsed,
        gender,
        age: Number(age),
        height: Number(height),
        weight: Number(weight),
        activityLevel,
      })
    );

    router.push("/(onboarding)/step2");
  };

  const handleActivitySelect = (value: ActivityLevel) => {
    setActivityLevel(value);
    Haptics.selectionAsync();
  };

  const handleGenderSelect = (value: Gender) => {
    setGender(value);
    Haptics.selectionAsync();
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
        <StepProgress currentStep={1} totalSteps={4} />

        <View style={styles.mascotRow}>
          <RockyMascot mood="happy" size={64} message={rockyMessage} />
        </View>

        <Text style={styles.sectionLabel}>Gender</Text>
        <Animated.View
          style={{ transform: [{ translateX: shakeGender }] }}
        >
          <View style={styles.pillRow}>
            {(["male", "female", "other"] as Gender[]).map((g) => {
              const isSelected = gender === g;
              return (
                <Pressable
                  key={g}
                  style={[
                    styles.pill,
                    isSelected && styles.pillSelected,
                  ]}
                  onPress={() => handleGenderSelect(g)}
                >
                  <Text
                    style={[
                      styles.pillText,
                      isSelected && styles.pillTextSelected,
                    ]}
                  >
                    {g.charAt(0).toUpperCase() + g.slice(1)}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        </Animated.View>

        <Text style={styles.sectionLabel}>Age</Text>
        <Animated.View style={{ transform: [{ translateX: shakeAge }] }}>
          <TextInput
            style={styles.input}
            placeholder="25"
            placeholderTextColor={C.textTertiary}
            keyboardType="number-pad"
            value={age}
            onChangeText={setAge}
            maxLength={3}
          />
        </Animated.View>

        <Text style={styles.sectionLabel}>Height (cm)</Text>
        <Animated.View style={{ transform: [{ translateX: shakeHeight }] }}>
          <TextInput
            style={styles.input}
            placeholder="175"
            placeholderTextColor={C.textTertiary}
            keyboardType="decimal-pad"
            value={height}
            onChangeText={setHeight}
            maxLength={5}
          />
        </Animated.View>

        <Text style={styles.sectionLabel}>Weight (kg)</Text>
        <Animated.View style={{ transform: [{ translateX: shakeWeight }] }}>
          <TextInput
            style={styles.input}
            placeholder="70"
            placeholderTextColor={C.textTertiary}
            keyboardType="decimal-pad"
            value={weight}
            onChangeText={setWeight}
            maxLength={5}
          />
        </Animated.View>

        <Text style={styles.sectionLabel}>Activity Level</Text>
        <Animated.View
          style={{ transform: [{ translateX: shakeActivity }] }}
        >
          {ACTIVITY_OPTIONS.map((opt) => {
            const isSelected = activityLevel === opt.value;
            return (
              <Pressable
                key={opt.value}
                style={[
                  styles.activityCard,
                  isSelected && styles.activityCardSelected,
                ]}
                onPress={() => handleActivitySelect(opt.value)}
              >
                <View style={styles.activityCardInner}>
                  <View
                    style={[
                      styles.activityRadio,
                      isSelected && styles.activityRadioSelected,
                    ]}
                  >
                    {isSelected && <View style={styles.activityRadioDot} />}
                  </View>
                  <View style={styles.activityTextWrap}>
                    <Text
                      style={[
                        styles.activityLabel,
                        isSelected && { color: C.primary },
                      ]}
                    >
                      {opt.label}
                    </Text>
                    <Text style={styles.activityDesc}>{opt.description}</Text>
                  </View>
                </View>
              </Pressable>
            );
          })}
        </Animated.View>

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
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 20,
    gap: 0,
  },
  mascotRow: {
    alignItems: "center",
    marginTop: 20,
    marginBottom: 28,
  },
  sectionLabel: {
    fontSize: 13,
    fontWeight: "600" as const,
    color: C.textSecondary,
    textTransform: "uppercase",
    letterSpacing: 0.8,
    marginBottom: 8,
    marginTop: 20,
  },
  pillRow: {
    flexDirection: "row",
    gap: 10,
  },
  pill: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 12,
    backgroundColor: C.card,
    alignItems: "center",
    borderWidth: 1.5,
    borderColor: C.border,
    shadowColor: C.shadowColor,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 1,
  },
  pillSelected: {
    backgroundColor: "#FFF3EE",
    borderColor: C.primary,
  },
  pillText: {
    fontSize: 14,
    fontWeight: "600" as const,
    color: C.textSecondary,
  },
  pillTextSelected: {
    color: C.primary,
  },
  input: {
    backgroundColor: C.card,
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: C.border,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 16,
    color: C.text,
    shadowColor: C.shadowColor,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 1,
  },
  activityCard: {
    backgroundColor: C.card,
    borderRadius: 14,
    borderWidth: 1.5,
    borderColor: C.border,
    marginBottom: 10,
    shadowColor: C.shadowColor,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 1,
  },
  activityCardSelected: {
    borderColor: C.primary,
    backgroundColor: "#FFF3EE",
  },
  activityCardInner: {
    flexDirection: "row",
    alignItems: "center",
    padding: 14,
    gap: 12,
  },
  activityRadio: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 2,
    borderColor: C.border,
    alignItems: "center",
    justifyContent: "center",
  },
  activityRadioSelected: {
    borderColor: C.primary,
  },
  activityRadioDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: C.primary,
  },
  activityTextWrap: {
    flex: 1,
  },
  activityLabel: {
    fontSize: 15,
    fontWeight: "600" as const,
    color: C.text,
  },
  activityDesc: {
    fontSize: 13,
    color: C.textSecondary,
    marginTop: 1,
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
