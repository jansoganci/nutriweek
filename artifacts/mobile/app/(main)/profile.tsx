import AsyncStorage from "@react-native-async-storage/async-storage";
import { router } from "expo-router";
import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  Alert,
  Animated,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import colors from "@/constants/colors";
import type {
  ActivityLevel,
  BodyMeasurements,
  DietaryPreference,
  Goal,
  UserProfile,
} from "@/constants/types";
import calculateAll, { type CalculationResults } from "@/services/calculations";

const C = colors.light;

const ACTIVITY_LABELS: Record<ActivityLevel, string> = {
  sedentary: "Sedentary",
  lightly_active: "Lightly Active",
  moderately_active: "Moderately Active",
  very_active: "Very Active",
  extra_active: "Extra Active",
};

const GOAL_LABELS: Record<Goal, string> = {
  cut: "Lose Fat 🔥",
  bulk: "Build Muscle 💪",
  maintain: "Stay Balanced ⚖️",
};

const ROCKY_MESSAGES: Record<Goal, string> = {
  cut: "Stay in that deficit! You've got this 🦝🔥",
  bulk: "Eat big, lift big! Let's grow 🦝💪",
  maintain: "Balance is the key 🦝⚖️",
};

const DIETARY_LABELS: Record<DietaryPreference, string> = {
  vegetarian: "Vegetarian",
  vegan: "Vegan",
  gluten_free: "Gluten Free",
  dairy_free: "Dairy Free",
  keto: "Keto",
  paleo: "Paleo",
  halal: "Halal",
  kosher: "Kosher",
  nut_free: "Nut Free",
  low_sodium: "Low Sodium",
};

function Toast({ message, visible }: { message: string; visible: boolean }) {
  const opacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (visible) {
      Animated.sequence([
        Animated.timing(opacity, { toValue: 1, duration: 200, useNativeDriver: true }),
        Animated.delay(1800),
        Animated.timing(opacity, { toValue: 0, duration: 300, useNativeDriver: true }),
      ]).start();
    }
  }, [visible]);

  return (
    <Animated.View style={[styles.toast, { opacity }]} pointerEvents="none">
      <Text style={styles.toastText}>{message}</Text>
    </Animated.View>
  );
}

function StatCard({
  label,
  value,
  sub,
  subColor,
}: {
  label: string;
  value: string;
  sub?: string;
  subColor?: string;
}) {
  return (
    <View style={styles.statCard}>
      <Text style={styles.statValue}>{value}</Text>
      {sub ? (
        <Text style={[styles.statSub, subColor ? { color: subColor } : {}]}>
          {sub}
        </Text>
      ) : null}
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

function MacroRow({
  emoji,
  label,
  value,
  unit = "g",
}: {
  emoji: string;
  label: string;
  value: number;
  unit?: string;
}) {
  return (
    <View style={styles.macroRow}>
      <Text style={styles.macroEmoji}>{emoji}</Text>
      <Text style={styles.macroLabel}>{label}</Text>
      <Text style={styles.macroValue}>
        {value} <Text style={styles.macroUnit}>{unit}</Text>
      </Text>
    </View>
  );
}

interface EditablePersonalInfo {
  age: string;
  gender: string;
  height: string;
  weight: string;
  activityLevel: string;
}

interface EditableMeasurements {
  waist: string;
  hips: string;
  chest: string;
  arms: string;
  thighs: string;
}

export default function ProfileScreen() {
  const insets = useSafeAreaInsets();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [results, setResults] = useState<CalculationResults | null>(null);

  const [editingInfo, setEditingInfo] = useState(false);
  const [infoFields, setInfoFields] = useState<EditablePersonalInfo>({
    age: "",
    gender: "",
    height: "",
    weight: "",
    activityLevel: "",
  });
  const [infoFieldsDraft, setInfoFieldsDraft] = useState<EditablePersonalInfo>(infoFields);

  const [editingMeasurements, setEditingMeasurements] = useState(false);
  const [measFields, setMeasFields] = useState<EditableMeasurements>({
    waist: "",
    hips: "",
    chest: "",
    arms: "",
    thighs: "",
  });
  const [measFieldsDraft, setMeasFieldsDraft] = useState<EditableMeasurements>(measFields);

  const [toastMsg, setToastMsg] = useState("");
  const [toastVisible, setToastVisible] = useState(false);
  const toastKey = useRef(0);
  const [fieldErrors, setFieldErrors] = useState<{ age?: string; height?: string; weight?: string }>({});

  function showToast(msg: string) {
    toastKey.current += 1;
    setToastMsg(msg);
    setToastVisible(false);
    setTimeout(() => setToastVisible(true), 10);
  }

  useEffect(() => {
    async function load() {
      const raw = await AsyncStorage.getItem("userProfile");
      if (!raw) return;
      const p = JSON.parse(raw) as UserProfile;
      setProfile(p);

      const calc = calculateAll(p);
      setResults(calc);

      const m = p.measurements ?? {};
      const fields: EditablePersonalInfo = {
        age: String(p.age),
        gender: p.gender,
        height: String(p.height),
        weight: String(p.weight),
        activityLevel: p.activityLevel,
      };
      const meas: EditableMeasurements = {
        waist: m.waist != null ? String(m.waist) : "",
        hips: m.hips != null ? String(m.hips) : "",
        chest: m.chest != null ? String(m.chest) : "",
        arms: m.arms != null ? String(m.arms) : "",
        thighs: m.thighs != null ? String(m.thighs) : "",
      };
      setInfoFields(fields);
      setInfoFieldsDraft(fields);
      setMeasFields(meas);
      setMeasFieldsDraft(meas);
    }
    load();
  }, []);

  const handleSaveInfo = useCallback(async () => {
    if (!profile) return;
    const { gender, activityLevel } = infoFieldsDraft;
    const ageNum = Number(infoFieldsDraft.age);
    const heightNum = Number(infoFieldsDraft.height);
    const weightNum = Number(infoFieldsDraft.weight);

    const errors: { age?: string; height?: string; weight?: string } = {};
    if (!infoFieldsDraft.age || isNaN(ageNum) || ageNum < 10 || ageNum > 120)
      errors.age = "Age must be between 10 and 120";
    if (!infoFieldsDraft.height || isNaN(heightNum) || heightNum < 50 || heightNum > 300)
      errors.height = "Height must be between 50 and 300 cm";
    if (!infoFieldsDraft.weight || isNaN(weightNum) || weightNum < 20 || weightNum > 500)
      errors.weight = "Weight must be between 20 and 500 kg";
    if (!gender || !activityLevel) {
      Alert.alert("Validation", "Gender and activity level are required.");
      return;
    }
    if (Object.keys(errors).length > 0) {
      setFieldErrors(errors);
      return;
    }
    setFieldErrors({});
    const updated: UserProfile = {
      ...profile,
      age: ageNum,
      gender: gender as UserProfile["gender"],
      height: heightNum,
      weight: weightNum,
      activityLevel: activityLevel as ActivityLevel,
      updatedAt: new Date().toISOString(),
    };
    const calc = calculateAll(updated);
    await AsyncStorage.setItem("userProfile", JSON.stringify(updated));
    await AsyncStorage.setItem("calculationResults", JSON.stringify(calc));
    setProfile(updated);
    setResults(calc);
    setInfoFields(infoFieldsDraft);
    setEditingInfo(false);
    showToast("Profile updated! 🦝✅");
  }, [profile, infoFieldsDraft]);

  const handleSaveMeasurements = useCallback(async () => {
    if (!profile) return;
    const m = measFieldsDraft;
    const measurements: BodyMeasurements = {
      waist: m.waist ? Number(m.waist) : undefined,
      hips: m.hips ? Number(m.hips) : undefined,
      chest: m.chest ? Number(m.chest) : undefined,
      arms: m.arms ? Number(m.arms) : undefined,
      thighs: m.thighs ? Number(m.thighs) : undefined,
    };
    const updated: UserProfile = {
      ...profile,
      measurements,
      updatedAt: new Date().toISOString(),
    };
    await AsyncStorage.setItem("userProfile", JSON.stringify(updated));
    setProfile(updated);
    setMeasFields(measFieldsDraft);
    setEditingMeasurements(false);
    showToast("Measurements saved! 🦝✅");
  }, [profile, measFieldsDraft]);

  const handleResetPlan = useCallback(async () => {
    await AsyncStorage.removeItem("weeklyPlan");
    router.replace("/(main)");
  }, []);

  const handleResetAll = useCallback(() => {
    Alert.alert(
      "Reset All Data",
      "Are you sure? This will delete everything.",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Delete Everything",
          style: "destructive",
          onPress: async () => {
            await AsyncStorage.clear();
            router.replace("/(onboarding)/step1");
          },
        },
      ]
    );
  }, []);

  if (!profile || !results) {
    return (
      <View style={[styles.centered, { paddingTop: insets.top }]}>
        <Text style={styles.loadingText}>Loading profile… 🦝</Text>
      </View>
    );
  }

  const rockyMessage = ROCKY_MESSAGES[profile.goal] ?? ROCKY_MESSAGES.maintain;
  const hasMeasurements =
    profile.measurements &&
    Object.values(profile.measurements).some((v) => v != null);

  return (
    <>
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={[
          styles.container,
          { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 100 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <Text style={styles.screenTitle}>My Profile</Text>
        <View style={styles.rockyContainer}>
          <Text style={styles.rockyEmoji}>🦝</Text>
          <View style={styles.rockySpeech}>
            <Text style={styles.rockySpeechText}>{rockyMessage}</Text>
          </View>
        </View>

        {/* Stats Row */}
        <View style={styles.statsRow}>
          <StatCard
            label="BMI"
            value={String(results.bmi)}
            sub={results.bmiCategory.label}
            subColor={results.bmiCategory.color}
          />
          <StatCard
            label="Daily Calories"
            value={String(results.targetCalories)}
            sub="kcal"
          />
          <StatCard
            label="Goal"
            value={GOAL_LABELS[profile.goal]}
          />
        </View>

        {/* Macro Targets */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Daily Targets</Text>
          <MacroRow emoji="🔥" label="Calories" value={results.targetCalories} unit="kcal" />
          <View style={styles.divider} />
          <MacroRow emoji="🥩" label="Protein" value={results.macros.protein} />
          <View style={styles.divider} />
          <MacroRow emoji="🍚" label="Carbs" value={results.macros.carbs} />
          <View style={styles.divider} />
          <MacroRow emoji="🥑" label="Fat" value={results.macros.fat} />
        </View>

        {/* Personal Info */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.cardTitle}>Personal Info</Text>
            {!editingInfo ? (
              <Pressable
                onPress={() => {
                  setInfoFieldsDraft(infoFields);
                  setEditingInfo(true);
                }}
                style={styles.editBtn}
              >
                <Text style={styles.editBtnText}>Edit</Text>
              </Pressable>
            ) : (
              <View style={styles.editActions}>
                <Pressable
                  onPress={() => {
                    setInfoFieldsDraft(infoFields);
                    setEditingInfo(false);
                  }}
                  style={styles.cancelBtn}
                >
                  <Text style={styles.cancelBtnText}>Cancel</Text>
                </Pressable>
                <Pressable onPress={handleSaveInfo} style={styles.saveBtn}>
                  <Text style={styles.saveBtnText}>Save</Text>
                </Pressable>
              </View>
            )}
          </View>

          {editingInfo ? (
            <>
              <InfoInput
                label="Age"
                value={infoFieldsDraft.age}
                onChangeText={(v) => { setInfoFieldsDraft((d) => ({ ...d, age: v })); setFieldErrors((e) => ({ ...e, age: undefined })); }}
                keyboardType="numeric"
                placeholder="e.g. 28"
                error={fieldErrors.age}
              />
              <InfoInput
                label="Gender"
                value={infoFieldsDraft.gender}
                onChangeText={(v) => setInfoFieldsDraft((d) => ({ ...d, gender: v }))}
                placeholder="male / female / other"
              />
              <InfoInput
                label="Height (cm)"
                value={infoFieldsDraft.height}
                onChangeText={(v) => { setInfoFieldsDraft((d) => ({ ...d, height: v })); setFieldErrors((e) => ({ ...e, height: undefined })); }}
                keyboardType="numeric"
                placeholder="e.g. 175"
                error={fieldErrors.height}
              />
              <InfoInput
                label="Weight (kg)"
                value={infoFieldsDraft.weight}
                onChangeText={(v) => { setInfoFieldsDraft((d) => ({ ...d, weight: v })); setFieldErrors((e) => ({ ...e, weight: undefined })); }}
                keyboardType="numeric"
                placeholder="e.g. 70"
                error={fieldErrors.weight}
              />
              <InfoInput
                label="Activity Level"
                value={infoFieldsDraft.activityLevel}
                onChangeText={(v) => setInfoFieldsDraft((d) => ({ ...d, activityLevel: v }))}
                placeholder="sedentary / lightly_active / moderately_active / very_active / extra_active"
              />
            </>
          ) : (
            <>
              <InfoRow label="Age" value={`${profile.age} yrs`} />
              <InfoRow label="Gender" value={profile.gender.charAt(0).toUpperCase() + profile.gender.slice(1)} />
              <InfoRow label="Height" value={`${profile.height} cm`} />
              <InfoRow label="Weight" value={`${profile.weight} kg`} />
              <InfoRow label="Activity Level" value={ACTIVITY_LABELS[profile.activityLevel] ?? profile.activityLevel} />
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Dietary Prefs</Text>
                <View style={styles.pillsRow}>
                  {profile.dietaryPreferences.length > 0 ? (
                    profile.dietaryPreferences.map((d) => (
                      <View key={d} style={styles.pill}>
                        <Text style={styles.pillText}>
                          {DIETARY_LABELS[d] ?? d}
                        </Text>
                      </View>
                    ))
                  ) : (
                    <Text style={styles.noneText}>None</Text>
                  )}
                </View>
              </View>
            </>
          )}
        </View>

        {/* Body Measurements */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.cardTitle}>Body Measurements</Text>
            {!editingMeasurements ? (
              <Pressable
                onPress={() => {
                  setMeasFieldsDraft(measFields);
                  setEditingMeasurements(true);
                }}
                style={styles.editBtn}
              >
                <Text style={styles.editBtnText}>Edit</Text>
              </Pressable>
            ) : (
              <View style={styles.editActions}>
                <Pressable
                  onPress={() => {
                    setMeasFieldsDraft(measFields);
                    setEditingMeasurements(false);
                  }}
                  style={styles.cancelBtn}
                >
                  <Text style={styles.cancelBtnText}>Cancel</Text>
                </Pressable>
                <Pressable onPress={handleSaveMeasurements} style={styles.saveBtn}>
                  <Text style={styles.saveBtnText}>Save</Text>
                </Pressable>
              </View>
            )}
          </View>

          {editingMeasurements ? (
            <>
              <InfoInput
                label="Waist (cm)"
                value={measFieldsDraft.waist}
                onChangeText={(v) => setMeasFieldsDraft((d) => ({ ...d, waist: v }))}
                keyboardType="numeric"
                placeholder="e.g. 82"
              />
              <InfoInput
                label="Hips (cm)"
                value={measFieldsDraft.hips}
                onChangeText={(v) => setMeasFieldsDraft((d) => ({ ...d, hips: v }))}
                keyboardType="numeric"
                placeholder="e.g. 96"
              />
              <InfoInput
                label="Chest (cm)"
                value={measFieldsDraft.chest}
                onChangeText={(v) => setMeasFieldsDraft((d) => ({ ...d, chest: v }))}
                keyboardType="numeric"
                placeholder="e.g. 100"
              />
              <InfoInput
                label="Left Arm (cm)"
                value={measFieldsDraft.arms}
                onChangeText={(v) => setMeasFieldsDraft((d) => ({ ...d, arms: v }))}
                keyboardType="numeric"
                placeholder="e.g. 33"
              />
              <InfoInput
                label="Left Leg (cm)"
                value={measFieldsDraft.thighs}
                onChangeText={(v) => setMeasFieldsDraft((d) => ({ ...d, thighs: v }))}
                keyboardType="numeric"
                placeholder="e.g. 55"
              />
            </>
          ) : hasMeasurements && profile.measurements ? (
            <>
              {profile.measurements.waist != null && (
                <InfoRow label="Waist" value={`${profile.measurements.waist} cm`} />
              )}
              {profile.measurements.hips != null && (
                <InfoRow label="Hips" value={`${profile.measurements.hips} cm`} />
              )}
              {profile.measurements.chest != null && (
                <InfoRow label="Chest" value={`${profile.measurements.chest} cm`} />
              )}
              {profile.measurements.arms != null && (
                <InfoRow label="Left Arm" value={`${profile.measurements.arms} cm`} />
              )}
              {profile.measurements.thighs != null && (
                <InfoRow label="Left Leg" value={`${profile.measurements.thighs} cm`} />
              )}
            </>
          ) : (
            <Text style={styles.placeholderText}>
              Add measurements to track your progress over time
            </Text>
          )}
        </View>

        {/* Settings / Danger Zone */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Settings</Text>
          <Pressable
            onPress={handleResetPlan}
            style={({ pressed }) => [styles.settingsBtn, pressed && styles.pressed]}
          >
            <Text style={styles.settingsBtnText}>Reset Weekly Plan 🔄</Text>
          </Pressable>
          <View style={styles.divider} />
          <Pressable
            onPress={handleResetAll}
            style={({ pressed }) => [styles.settingsBtn, styles.settingsBtnDestructive, pressed && styles.pressed]}
          >
            <Text style={[styles.settingsBtnText, styles.settingsBtnTextDestructive]}>
              Reset All Data 🗑️
            </Text>
          </Pressable>
        </View>
      </ScrollView>

      <Toast key={toastKey.current} message={toastMsg} visible={toastVisible} />
    </>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.infoRow}>
      <Text style={styles.infoLabel}>{label}</Text>
      <Text style={styles.infoValue}>{value}</Text>
    </View>
  );
}

function InfoInput({
  label,
  value,
  onChangeText,
  keyboardType,
  placeholder,
  error,
}: {
  label: string;
  value: string;
  onChangeText: (v: string) => void;
  keyboardType?: "default" | "numeric";
  placeholder?: string;
  error?: string;
}) {
  return (
    <View style={styles.inputRow}>
      <Text style={styles.inputLabel}>{label}</Text>
      <TextInput
        style={[styles.textInput, error ? { borderColor: C.destructive, borderWidth: 1.5 } : {}]}
        value={value}
        onChangeText={onChangeText}
        keyboardType={keyboardType ?? "default"}
        placeholder={placeholder}
        placeholderTextColor={C.textTertiary}
        autoCorrect={false}
        autoCapitalize="none"
      />
      {error ? <Text style={styles.fieldErrorText}>{error}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  scroll: {
    flex: 1,
    backgroundColor: C.background,
  },
  container: {
    paddingHorizontal: 20,
    gap: 16,
  },
  centered: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: C.background,
  },
  loadingText: {
    fontSize: 16,
    color: C.textSecondary,
  },

  screenTitle: {
    fontSize: 28,
    fontWeight: "700",
    color: C.text,
  },

  rockyContainer: {
    alignItems: "center",
    gap: 10,
  },
  rockyEmoji: {
    fontSize: 56,
  },
  rockySpeech: {
    backgroundColor: C.secondary,
    borderRadius: colors.radius,
    paddingHorizontal: 16,
    paddingVertical: 10,
    maxWidth: "90%",
  },
  rockySpeechText: {
    fontSize: 14,
    color: C.secondaryForeground,
    textAlign: "center",
    lineHeight: 20,
    fontWeight: "500",
  },

  statsRow: {
    flexDirection: "row",
    gap: 10,
  },
  statCard: {
    flex: 1,
    backgroundColor: C.card,
    borderRadius: colors.radius,
    padding: 12,
    alignItems: "center",
    gap: 2,
    shadowColor: C.shadowColor,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 1,
  },
  statValue: {
    fontSize: 13,
    fontWeight: "700",
    color: C.text,
    textAlign: "center",
  },
  statSub: {
    fontSize: 11,
    fontWeight: "600",
    color: C.textSecondary,
    textAlign: "center",
  },
  statLabel: {
    fontSize: 10,
    color: C.mutedForeground,
    textAlign: "center",
    marginTop: 2,
  },

  card: {
    backgroundColor: C.card,
    borderRadius: colors.radius,
    padding: 16,
    gap: 12,
    shadowColor: C.shadowColor,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.07,
    shadowRadius: 6,
    elevation: 2,
  },
  cardHeader: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: "700",
    color: C.text,
  },

  macroRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
  },
  macroEmoji: {
    fontSize: 18,
    width: 28,
    textAlign: "center",
  },
  macroLabel: {
    flex: 1,
    fontSize: 14,
    color: C.textSecondary,
  },
  macroValue: {
    fontSize: 15,
    fontWeight: "700",
    color: C.text,
  },
  macroUnit: {
    fontSize: 12,
    fontWeight: "400",
    color: C.mutedForeground,
  },

  divider: {
    height: 1,
    backgroundColor: C.border,
    marginVertical: -4,
  },

  editBtn: {
    backgroundColor: C.secondary,
    borderRadius: colors.radiusSm,
    paddingHorizontal: 14,
    paddingVertical: 5,
  },
  editBtnText: {
    fontSize: 13,
    fontWeight: "600",
    color: C.primary,
  },
  editActions: {
    flexDirection: "row",
    gap: 8,
  },
  cancelBtn: {
    backgroundColor: C.muted,
    borderRadius: colors.radiusSm,
    paddingHorizontal: 12,
    paddingVertical: 5,
  },
  cancelBtnText: {
    fontSize: 13,
    fontWeight: "600",
    color: C.textSecondary,
  },
  saveBtn: {
    backgroundColor: C.primary,
    borderRadius: colors.radiusSm,
    paddingHorizontal: 14,
    paddingVertical: 5,
  },
  saveBtnText: {
    fontSize: 13,
    fontWeight: "600",
    color: C.primaryForeground,
  },

  infoRow: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 8,
    minHeight: 24,
  },
  infoLabel: {
    width: 110,
    fontSize: 13,
    color: C.mutedForeground,
    paddingTop: 2,
  },
  infoValue: {
    flex: 1,
    fontSize: 13,
    fontWeight: "600",
    color: C.text,
  },
  pillsRow: {
    flex: 1,
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 6,
  },
  pill: {
    backgroundColor: C.secondary,
    borderRadius: colors.radiusFull,
    paddingHorizontal: 10,
    paddingVertical: 3,
  },
  pillText: {
    fontSize: 11,
    fontWeight: "600",
    color: C.primary,
  },
  noneText: {
    fontSize: 13,
    color: C.textTertiary,
    fontStyle: "italic",
  },

  inputRow: {
    gap: 4,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: "600",
    color: C.mutedForeground,
    textTransform: "uppercase",
    letterSpacing: 0.5,
  },
  textInput: {
    backgroundColor: C.input,
    borderRadius: colors.radiusSm,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
    color: C.inputForeground,
    borderWidth: 1,
    borderColor: C.border,
  },

  placeholderText: {
    fontSize: 13,
    color: C.textTertiary,
    fontStyle: "italic",
    textAlign: "center",
    paddingVertical: 8,
  },
  fieldErrorText: {
    fontSize: 12,
    color: C.destructive,
    marginTop: 2,
  },

  settingsBtn: {
    paddingVertical: 12,
    borderRadius: colors.radiusSm,
    backgroundColor: C.muted,
    alignItems: "center",
  },
  settingsBtnDestructive: {
    backgroundColor: C.destructiveLight,
  },
  settingsBtnText: {
    fontSize: 14,
    fontWeight: "600",
    color: C.text,
  },
  settingsBtnTextDestructive: {
    color: C.destructive,
  },
  pressed: {
    opacity: 0.7,
  },

  toast: {
    position: "absolute",
    bottom: 110,
    alignSelf: "center",
    backgroundColor: C.foreground,
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: colors.radiusFull,
    shadowColor: C.shadowColor,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 6,
  },
  toastText: {
    color: C.card,
    fontSize: 14,
    fontWeight: "600",
  },
});
