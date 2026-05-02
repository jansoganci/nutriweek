import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Haptics from "expo-haptics";
import { router, useFocusEffect } from "expo-router";
import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  Alert,
  Animated,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import MacroRing from "@/components/MacroRing";
import { SkeletonPlanCard } from "@/components/SkeletonLoader";
import colors from "@/constants/colors";
import type { UserProfile } from "@/constants/types";
import calculateAll, { type CalculationResults } from "@/services/calculations";
import { generateWeeklyPlan, type MockWeeklyPlan, type MockDayPlan } from "@/services/gemma";
import { loadStreak, updateStreak } from "@/services/storage";
import { loadTodayLog, sumMacros } from "@/services/usda";

const C = colors.light;

function ScalePressable({
  style,
  onPress,
  toScale = 0.95,
  children,
  hitSlop,
}: {
  style?: object | object[];
  onPress?: () => void;
  toScale?: number;
  children: React.ReactNode;
  hitSlop?: number;
}) {
  const scale = useRef(new Animated.Value(1)).current;
  return (
    <Pressable
      onPress={onPress}
      hitSlop={hitSlop}
      onPressIn={() =>
        Animated.spring(scale, {
          toValue: toScale,
          useNativeDriver: true,
          damping: 15,
          stiffness: 400,
        }).start()
      }
      onPressOut={() =>
        Animated.spring(scale, {
          toValue: 1,
          useNativeDriver: true,
          damping: 15,
          stiffness: 300,
        }).start()
      }
    >
      <Animated.View style={[style, { transform: [{ scale }] }]}>
        {children}
      </Animated.View>
    </Pressable>
  );
}

const FUN_FACTS = [
  "Raccoons can open locks! 🦝🔓",
  "A raccoon's hands have 5 fingers — just like yours 🦝🖐️",
  "Raccoons sleep up to 16 hours a day. Goals. 🦝💤",
  "Protein keeps you full for longer than carbs or fat! 💪",
  "Drinking water before meals can reduce calorie intake by up to 13%! 💧",
  "Muscle burns 3× more calories than fat at rest! 🔥",
  "Eating slowly helps you eat 10-15% fewer calories! 🍽️",
  "Rocky fact: raccoons wash their food before eating 🦝🚿",
  "Sleep deprivation increases hunger hormones by up to 24%! 😴",
  "Protein has the highest thermic effect — you burn calories digesting it! 🥩",
];

function getGreeting(): string {
  const hour = new Date().getHours();
  if (hour >= 5 && hour < 11) return "Good morning!";
  if (hour >= 11 && hour < 17) return "Good afternoon!";
  if (hour >= 17 && hour < 22) return "Good evening!";
  return "Still up? 🦝";
}

function getTodayStr(): string {
  return new Date().toISOString().slice(0, 10);
}

function formatDate(dateStr: string): string {
  const d = new Date(dateStr + "T00:00:00");
  return d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

interface FirstLaunchModalProps {
  visible: boolean;
  onGenerate: () => void;
  onDismiss: () => void;
}
function FirstLaunchModal({ visible, onGenerate, onDismiss }: FirstLaunchModalProps) {
  return (
    <Modal visible={visible} transparent animationType="fade">
      <View style={styles.modalOverlay}>
        <View style={styles.modalCard}>
          <Text style={styles.modalRocky}>🦝</Text>
          <Text style={styles.modalTitle}>Ready to build your first meal plan?</Text>
          <Text style={styles.modalSubtitle}>
            I'll create a personalized 7-day plan based on your goals 🎯
          </Text>
          <ScalePressable
            style={styles.modalPrimary}
            onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium); onGenerate(); }}
          >
            <Text style={styles.modalPrimaryText}>Let's go! 🦝</Text>
          </ScalePressable>
          <Pressable style={styles.modalSecondary} onPress={onDismiss}>
            <Text style={styles.modalSecondaryText}>Maybe later</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
}

interface ConsumedMacros { calories: number; protein: number; carbs: number; fat: number; }

interface MacroSummaryCardProps {
  targets: CalculationResults | null;
  consumed: ConsumedMacros;
}
function MacroSummaryCard({ targets, consumed }: MacroSummaryCardProps) {
  const targetCals = targets?.targetCalories ?? 0;
  const targetProtein = targets?.macros.protein ?? 0;
  const targetCarbs = targets?.macros.carbs ?? 0;
  const targetFat = targets?.macros.fat ?? 0;

  const remaining = targetCals - consumed.calories;
  const remainingText = targetCals === 0
    ? "Complete onboarding to see targets"
    : remaining >= 0
      ? `${remaining} kcal remaining`
      : `${Math.abs(remaining)} kcal over target 🦝😅`;

  return (
    <View style={styles.card}>
      <Text style={styles.cardTitle}>Today's Progress</Text>
      <View style={styles.macroRingRow}>
        <MacroRing label="Calories" current={consumed.calories} target={targetCals} unit="kcal" color={C.primary} size={72} strokeWidth={7} />
        <MacroRing label="Protein" current={consumed.protein} target={targetProtein} unit="g" color={C.macroProtein} size={72} strokeWidth={7} />
        <MacroRing label="Carbs" current={consumed.carbs} target={targetCarbs} unit="g" color="#2196F3" size={72} strokeWidth={7} />
        <MacroRing label="Fat" current={consumed.fat} target={targetFat} unit="g" color={C.macroFat} size={72} strokeWidth={7} />
      </View>
      <Text style={[styles.remainingText, remaining < 0 && targetCals > 0 && { color: C.destructive }]}>
        {remainingText}
      </Text>
    </View>
  );
}

interface MealRowProps {
  meal: { type: string; name: string; calories: number; emoji: string };
}
function MealRow({ meal }: MealRowProps) {
  return (
    <View style={styles.mealRow}>
      <Text style={styles.mealEmoji}>{meal.emoji}</Text>
      <View style={styles.mealInfo}>
        <Text style={styles.mealType}>{meal.type}</Text>
        <Text style={styles.mealName}>{meal.name}</Text>
      </View>
      <Text style={styles.mealCals}>{meal.calories} kcal</Text>
    </View>
  );
}

interface DayCardProps {
  day: MockDayPlan;
  isToday: boolean;
  isExpanded: boolean;
  onToggle: () => void;
}
function DayCard({ day, isToday, isExpanded, onToggle }: DayCardProps) {
  const mainMeals = day.meals.filter((m) => m.type !== "Snack");
  const shownMeals = isExpanded ? day.meals : mainMeals.slice(0, 3);

  return (
    <ScalePressable
      style={[styles.dayCard, isToday && styles.dayCardToday]}
      toScale={0.98}
      onPress={() => { Haptics.selectionAsync(); onToggle(); }}
    >
      {isToday && <View style={styles.todayBorder} />}
      <View style={styles.dayCardHeader}>
        <View style={styles.dayCardLeft}>
          <Text style={[styles.dayName, isToday && styles.dayNameToday]}>{day.day}</Text>
          <Text style={styles.dayDate}>{formatDate(day.date)}</Text>
        </View>
        <View style={styles.dayCardRight}>
          {isToday && (
            <View style={styles.todayBadge}>
              <Text style={styles.todayBadgeText}>Today</Text>
            </View>
          )}
          <Text style={styles.dayTotalCals}>{day.totalCalories} kcal</Text>
          <Text style={styles.expandChevron}>{isExpanded ? "▲" : "▼"}</Text>
        </View>
      </View>

      <View style={styles.mealsContainer}>
        {shownMeals.map((meal, i) => (
          <View key={i}>
            {i > 0 && <View style={styles.mealDivider} />}
            <MealRow meal={meal} />
          </View>
        ))}
        {!isExpanded && day.meals.some((m) => m.type === "Snack") && (
          <Text style={styles.moreText}>+ snack · tap to expand</Text>
        )}
      </View>
    </ScalePressable>
  );
}

function LoadingState() {
  const pulse = useRef(new Animated.Value(0.4)).current;

  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, { toValue: 1, duration: 800, useNativeDriver: true }),
        Animated.timing(pulse, { toValue: 0.4, duration: 800, useNativeDriver: true }),
      ])
    ).start();
  }, [pulse]);

  const progressAnim = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(progressAnim, { toValue: 1, duration: 1200, useNativeDriver: false }),
        Animated.timing(progressAnim, { toValue: 0, duration: 0, useNativeDriver: false }),
      ])
    ).start();
  }, [progressAnim]);

  const progressWidth = progressAnim.interpolate({ inputRange: [0, 1], outputRange: ["0%", "100%"] });

  return (
    <View style={styles.loadingCard}>
      <Animated.Text style={[styles.loadingRocky, { opacity: pulse }]}>🦝</Animated.Text>
      <Text style={styles.loadingTitle}>Rocky is cooking your plan... 🍳</Text>
      <Text style={styles.loadingSubtitle}>This takes about 30 seconds</Text>
      <View style={styles.progressTrack}>
        <Animated.View style={[styles.progressBar, { width: progressWidth }]} />
      </View>
    </View>
  );
}

interface EmptyStateProps { onGenerate: () => void; }
function EmptyState({ onGenerate }: EmptyStateProps) {
  return (
    <View style={styles.emptyCard}>
      <Text style={styles.emptyRocky}>🦝</Text>
      <Text style={styles.emptyTitle}>No plan yet!</Text>
      <Text style={styles.emptySubtitle}>Let Rocky build your personalized 7-day meal plan</Text>
      <ScalePressable style={styles.emptyBtn} onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium); onGenerate(); }}>
        <Text style={styles.emptyBtnText}>Generate My Plan 🦝</Text>
      </ScalePressable>
    </View>
  );
}

type PlanError = "OLLAMA_OFFLINE" | "OLLAMA_TIMEOUT" | null;

interface PlanErrorCardProps { error: PlanError; onRetry: () => void; }
function PlanErrorCard({ error, onRetry }: PlanErrorCardProps) {
  if (!error) return null;
  const isOffline = error === "OLLAMA_OFFLINE";
  return (
    <View style={styles.planErrorCard}>
      <Text style={styles.planErrorRocky}>{isOffline ? "😴" : "🦝"}</Text>
      <Text style={styles.planErrorTitle}>
        {isOffline
          ? "Rocky is napping... Make sure Ollama is running on your Mac! 🦝💤"
          : "Taking too long... Gemma is thinking hard! Try again? 🦝"}
      </Text>
      <ScalePressable style={styles.planErrorBtn} onPress={onRetry}>
        <Text style={styles.planErrorBtnText}>Try Again</Text>
      </ScalePressable>
    </View>
  );
}

const ZERO_MACROS: ConsumedMacros = { calories: 0, protein: 0, carbs: 0, fat: 0 };

export default function MealPlanScreen() {
  const insets = useSafeAreaInsets();
  const [targets, setTargets] = useState<CalculationResults | null>(null);
  const [consumed, setConsumed] = useState<ConsumedMacros>(ZERO_MACROS);
  const [weeklyPlan, setWeeklyPlan] = useState<MockWeeklyPlan | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [isGenerating, setIsGenerating] = useState(false);
  const [planError, setPlanError] = useState<PlanError>(null);
  const [showEmpty, setShowEmpty] = useState(false);
  const [expandedDay, setExpandedDay] = useState<string | null>(null);
  const [loaded, setLoaded] = useState(false);
  const [streak, setStreak] = useState<number | null>(null);

  useEffect(() => {
    async function init() {
      const profileRaw = await AsyncStorage.getItem("userProfile");
      if (profileRaw) {
        const profile = JSON.parse(profileRaw) as UserProfile;
        if (profile.weight && profile.height && profile.age && profile.gender && profile.activityLevel && profile.goal) {
          setTargets(calculateAll(profile));
        }
      }

      const planRaw = await AsyncStorage.getItem("weeklyPlan");
      if (planRaw) {
        setWeeklyPlan(JSON.parse(planRaw) as MockWeeklyPlan);
      } else {
        setShowModal(true);
      }
      setLoaded(true);
    }
    init();
  }, []);

  useFocusEffect(
    useCallback(() => {
      loadTodayLog().then(async (entries) => {
        setConsumed(sumMacros(entries));
        if (entries.length > 0) {
          const s = await updateStreak();
          setStreak(s);
        } else {
          const s = await loadStreak();
          setStreak(s);
        }
      });
    }, [])
  );

  const handleGenerate = useCallback(async () => {
    setShowModal(false);
    setShowEmpty(false);
    setPlanError(null);
    setIsGenerating(true);
    try {
      const plan = await generateWeeklyPlan();
      setWeeklyPlan(plan);
    } catch (err) {
      const msg = err instanceof Error ? err.message : "";
      if (msg === "OLLAMA_OFFLINE") {
        setPlanError("OLLAMA_OFFLINE");
      } else if (msg === "OLLAMA_TIMEOUT") {
        setPlanError("OLLAMA_TIMEOUT");
      } else {
        Alert.alert("Oops!", "Rocky had trouble generating your plan. Try again!");
        setShowEmpty(true);
      }
    } finally {
      setIsGenerating(false);
    }
  }, []);

  const handleDismiss = useCallback(() => {
    setShowModal(false);
    setShowEmpty(true);
  }, []);

  const handleFunFact = useCallback(() => {
    const fact = FUN_FACTS[Math.floor(Math.random() * FUN_FACTS.length)];
    Haptics.selectionAsync();
    Alert.alert("Rocky says... 🦝", fact);
  }, []);

  const toggleDay = useCallback((date: string) => {
    setExpandedDay((prev) => (prev === date ? null : date));
  }, []);

  const today = getTodayStr();

  return (
    <View style={{ flex: 1, backgroundColor: C.background }}>
      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={[
          styles.container,
          { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 100 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <View>
            <Text style={styles.greeting}>{getGreeting()}</Text>
            <Text style={styles.userName}>Champion 👊</Text>
          </View>
          <Pressable style={styles.funFactBtn} onPress={handleFunFact}>
            <Text style={styles.funFactEmoji}>🦝</Text>
          </Pressable>
        </View>

        {/* Streak row */}
        {streak !== null && (
          <View style={styles.streakRow}>
            {streak > 0 ? (
              <Text style={styles.streakText}>🔥 {streak} day streak</Text>
            ) : (
              <Text style={styles.streakText}>🌱 Start your streak today!</Text>
            )}
          </View>
        )}

        {/* Macro Summary */}
        {loaded && <MacroSummaryCard targets={targets} consumed={consumed} />}

        {/* Weekly Plan Section */}
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>This Week</Text>
          {weeklyPlan && !isGenerating && (
            <Pressable
              onPress={handleGenerate}
              hitSlop={8}
              style={styles.refreshBtn}
            >
              <Text style={styles.refreshIcon}>↻</Text>
            </Pressable>
          )}
        </View>

        {isGenerating && (
          <View style={styles.skeletonWrap}>
            <Text style={styles.skeletonTitle}>Rocky is cooking your plan... 🍳</Text>
            <SkeletonPlanCard />
            <SkeletonPlanCard />
            <SkeletonPlanCard />
          </View>
        )}

        {!isGenerating && planError && (
          <PlanErrorCard error={planError} onRetry={handleGenerate} />
        )}

        {!isGenerating && !planError && weeklyPlan && (
          <View style={styles.dayList}>
            {weeklyPlan.days.map((day) => (
              <DayCard
                key={day.date}
                day={day}
                isToday={day.date === today}
                isExpanded={expandedDay === day.date}
                onToggle={() => toggleDay(day.date)}
              />
            ))}
          </View>
        )}

        {!isGenerating && !planError && !weeklyPlan && loaded && showEmpty && (
          <EmptyState onGenerate={() => setShowModal(true)} />
        )}
      </ScrollView>

      {/* Floating + button */}
      <ScalePressable
        style={[styles.fab, { bottom: insets.bottom + 68 }]}
        onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); router.push("/(main)/log"); }}
      >
        <Text style={styles.fabIcon}>+</Text>
      </ScalePressable>

      <FirstLaunchModal
        visible={showModal}
        onGenerate={handleGenerate}
        onDismiss={handleDismiss}
      />
    </View>
  );
}

const CARD_SHADOW = {
  shadowColor: C.shadowColor,
  shadowOffset: { width: 0, height: 2 },
  shadowOpacity: 0.07,
  shadowRadius: 8,
  elevation: 2,
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 20,
    gap: 16,
  },

  // Header
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginBottom: 4,
  },
  greeting: {
    fontSize: 24,
    fontWeight: "700" as const,
    color: C.text,
  },
  userName: {
    fontSize: 14,
    color: C.textSecondary,
    marginTop: 2,
  },

  // Streak
  streakRow: {
    backgroundColor: C.card,
    borderRadius: 12,
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderWidth: 1,
    borderColor: C.border,
    alignSelf: "flex-start",
    ...CARD_SHADOW,
  },
  streakText: {
    fontSize: 14,
    fontWeight: "600" as const,
    color: C.text,
  },

  // Skeleton wrapper
  skeletonWrap: {
    gap: 10,
  },
  skeletonTitle: {
    fontSize: 15,
    fontWeight: "600" as const,
    color: C.textSecondary,
    textAlign: "center",
    marginBottom: 4,
  },
  funFactBtn: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: C.card,
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 1,
    borderColor: C.border,
    ...CARD_SHADOW,
  },
  funFactEmoji: {
    fontSize: 22,
  },

  // Card base
  card: {
    backgroundColor: C.card,
    borderRadius: 18,
    padding: 18,
    borderWidth: 1,
    borderColor: C.border,
    ...CARD_SHADOW,
  },
  cardTitle: {
    fontSize: 13,
    fontWeight: "600" as const,
    color: C.textSecondary,
    textTransform: "uppercase",
    letterSpacing: 0.8,
    marginBottom: 16,
  },

  // Macro rings
  macroRingRow: {
    flexDirection: "row",
    justifyContent: "space-around",
    alignItems: "flex-start",
    marginBottom: 12,
  },
  remainingText: {
    textAlign: "center",
    fontSize: 13,
    color: C.textSecondary,
  },

  // Section header
  sectionHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 4,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: "700" as const,
    color: C.text,
  },
  refreshBtn: {
    padding: 4,
  },
  refreshIcon: {
    fontSize: 22,
    color: C.primary,
    fontWeight: "600" as const,
  },

  // Day cards
  dayList: {
    gap: 10,
  },
  dayCard: {
    backgroundColor: C.card,
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: C.border,
    overflow: "hidden",
    ...CARD_SHADOW,
  },
  dayCardToday: {
    backgroundColor: "#FFF3EE",
    borderColor: C.primary,
  },
  todayBorder: {
    position: "absolute",
    left: 0,
    top: 0,
    bottom: 0,
    width: 4,
    backgroundColor: C.primary,
    borderTopLeftRadius: 16,
    borderBottomLeftRadius: 16,
  },
  dayCardHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginBottom: 12,
    paddingLeft: 8,
  },
  dayCardLeft: {
    gap: 2,
  },
  dayCardRight: {
    alignItems: "flex-end",
    gap: 4,
  },
  dayName: {
    fontSize: 16,
    fontWeight: "700" as const,
    color: C.text,
  },
  dayNameToday: {
    color: C.primary,
  },
  dayDate: {
    fontSize: 12,
    color: C.textSecondary,
  },
  todayBadge: {
    backgroundColor: C.primary,
    paddingHorizontal: 10,
    paddingVertical: 3,
    borderRadius: 99,
  },
  todayBadgeText: {
    color: "#FFFFFF",
    fontSize: 11,
    fontWeight: "700" as const,
  },
  dayTotalCals: {
    fontSize: 13,
    fontWeight: "600" as const,
    color: C.textSecondary,
  },
  expandChevron: {
    fontSize: 10,
    color: C.textTertiary,
  },

  // Meals
  mealsContainer: {
    paddingLeft: 8,
    gap: 0,
  },
  mealRow: {
    flexDirection: "row",
    alignItems: "center",
    paddingVertical: 7,
    gap: 10,
  },
  mealEmoji: {
    fontSize: 18,
    width: 26,
    textAlign: "center",
  },
  mealInfo: {
    flex: 1,
    gap: 1,
  },
  mealType: {
    fontSize: 11,
    color: C.textTertiary,
    fontWeight: "500" as const,
    textTransform: "uppercase",
    letterSpacing: 0.5,
  },
  mealName: {
    fontSize: 14,
    color: C.text,
    fontWeight: "500" as const,
  },
  mealCals: {
    fontSize: 13,
    color: C.textSecondary,
    fontWeight: "600" as const,
  },
  mealDivider: {
    height: 1,
    backgroundColor: C.border,
    marginLeft: 36,
  },
  moreText: {
    fontSize: 12,
    color: C.primary,
    paddingTop: 6,
    paddingLeft: 36,
  },

  // Loading state
  loadingCard: {
    backgroundColor: C.card,
    borderRadius: 18,
    padding: 32,
    alignItems: "center",
    gap: 12,
    borderWidth: 1,
    borderColor: C.border,
    ...CARD_SHADOW,
  },
  loadingRocky: {
    fontSize: 64,
    marginBottom: 4,
  },
  loadingTitle: {
    fontSize: 18,
    fontWeight: "700" as const,
    color: C.text,
    textAlign: "center",
  },
  loadingSubtitle: {
    fontSize: 14,
    color: C.textSecondary,
    textAlign: "center",
  },
  progressTrack: {
    width: "100%",
    height: 6,
    backgroundColor: C.muted,
    borderRadius: 3,
    overflow: "hidden",
    marginTop: 8,
  },
  progressBar: {
    height: 6,
    backgroundColor: C.primary,
    borderRadius: 3,
  },

  // Empty state
  emptyCard: {
    backgroundColor: C.card,
    borderRadius: 18,
    padding: 32,
    alignItems: "center",
    gap: 10,
    borderWidth: 1,
    borderColor: C.border,
    ...CARD_SHADOW,
  },
  emptyRocky: {
    fontSize: 56,
    marginBottom: 4,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: "700" as const,
    color: C.text,
  },
  emptySubtitle: {
    fontSize: 14,
    color: C.textSecondary,
    textAlign: "center",
    lineHeight: 20,
  },
  emptyBtn: {
    backgroundColor: C.primary,
    borderRadius: 14,
    paddingVertical: 14,
    paddingHorizontal: 28,
    marginTop: 8,
  },
  emptyBtnText: {
    color: "#FFFFFF",
    fontSize: 16,
    fontWeight: "700" as const,
  },

  // Modal
  modalOverlay: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.55)",
    alignItems: "center",
    justifyContent: "center",
    padding: 28,
  },
  modalCard: {
    backgroundColor: C.card,
    borderRadius: 24,
    padding: 28,
    alignItems: "center",
    width: "100%",
    gap: 12,
  },
  modalRocky: {
    fontSize: 72,
    marginBottom: 4,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: "700" as const,
    color: C.text,
    textAlign: "center",
    lineHeight: 26,
  },
  modalSubtitle: {
    fontSize: 14,
    color: C.textSecondary,
    textAlign: "center",
    lineHeight: 20,
    marginBottom: 4,
  },
  modalPrimary: {
    backgroundColor: C.primary,
    borderRadius: 16,
    paddingVertical: 16,
    width: "100%",
    alignItems: "center",
  },
  modalPrimaryText: {
    color: "#FFFFFF",
    fontSize: 17,
    fontWeight: "700" as const,
  },
  modalSecondary: {
    paddingVertical: 10,
  },
  modalSecondaryText: {
    color: C.text,
    fontSize: 15,
  },

  // Plan error card
  planErrorCard: {
    backgroundColor: C.card,
    borderRadius: 18,
    padding: 28,
    alignItems: "center",
    gap: 12,
    borderWidth: 1,
    borderColor: C.destructiveLight,
    ...CARD_SHADOW,
  },
  planErrorRocky: {
    fontSize: 56,
    marginBottom: 4,
  },
  planErrorTitle: {
    fontSize: 15,
    color: C.text,
    textAlign: "center",
    lineHeight: 22,
    fontWeight: "500" as const,
  },
  planErrorBtn: {
    backgroundColor: C.primary,
    borderRadius: 14,
    paddingVertical: 12,
    paddingHorizontal: 28,
    marginTop: 4,
  },
  planErrorBtnText: {
    color: "#fff",
    fontSize: 15,
    fontWeight: "700" as const,
  },

  // FAB
  fab: {
    position: "absolute",
    right: 20,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: C.primary,
    alignItems: "center",
    justifyContent: "center",
    shadowColor: C.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.35,
    shadowRadius: 10,
    elevation: 6,
  },
  fabIcon: {
    color: "#FFFFFF",
    fontSize: 30,
    lineHeight: 34,
    fontWeight: "300" as const,
  },
});
