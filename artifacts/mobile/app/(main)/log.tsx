import * as Haptics from "expo-haptics";
import { router, useFocusEffect } from "expo-router";
import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  Animated,
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import colors from "@/constants/colors";
import {
  appendLogEntry,
  calculateNutrients,
  loadTodayLog,
  removeLogEntry,
  searchFoods,
  sumMacros,
  type FoodSearchResult,
  type LogEntry,
  type MacroResult,
} from "@/services/usda";

const C = colors.light;

const QUICK_PILLS = [
  { emoji: "🍗", label: "Chicken Breast" },
  { emoji: "🥚", label: "Eggs" },
  { emoji: "🍌", label: "Banana" },
  { emoji: "🥛", label: "Milk" },
  { emoji: "🍚", label: "Rice" },
  { emoji: "🥑", label: "Avocado" },
];

const CARD_SHADOW = {
  shadowColor: C.shadowColor,
  shadowOffset: { width: 0, height: 2 },
  shadowOpacity: 0.07,
  shadowRadius: 8,
  elevation: 2,
};

function formatTodayDate(): string {
  const now = new Date();
  return now.toLocaleDateString("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
  });
}

// ─── Macro tag (search results) ──────────────────────────────────────────────

function MacroTag({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <View style={[styles.macroTag, { backgroundColor: color + "18" }]}>
      <Text style={[styles.macroTagText, { color }]}>{value}</Text>
      <Text style={styles.macroTagLabel}>{label}</Text>
    </View>
  );
}

// ─── Summary macro card (log modal) ──────────────────────────────────────────

function SummaryCard({
  emoji,
  label,
  value,
  unit,
  color,
}: {
  emoji: string;
  label: string;
  value: number;
  unit: string;
  color: string;
}) {
  return (
    <View style={[styles.summaryCard, { borderTopColor: color, borderTopWidth: 3 }]}>
      <Text style={styles.summaryEmoji}>{emoji}</Text>
      <Text style={[styles.summaryValue, { color }]}>{value}</Text>
      <Text style={styles.summaryUnit}>{unit}</Text>
      <Text style={styles.summaryLabel}>{label}</Text>
    </View>
  );
}

// ─── Log entry row (log modal) ────────────────────────────────────────────────

function LogEntryRow({
  entry,
  onDelete,
}: {
  entry: LogEntry;
  onDelete: (entry: LogEntry) => void;
}) {
  return (
    <View style={styles.logEntryCard}>
      <View style={styles.logEntryMain}>
        <Text style={styles.logEntryName} numberOfLines={2}>
          {entry.foodName}
        </Text>
        <Text style={styles.logEntryGrams}>{entry.grams}g</Text>
        <Text style={styles.logEntryMacros}>
          🥩 {entry.protein}g · 🍚 {entry.carbs}g · 🥑 {entry.fat}g
        </Text>
      </View>
      <View style={styles.logEntryRight}>
        <Text style={styles.logEntryCals}>{entry.calories}</Text>
        <Text style={styles.logEntryCalsUnit}>kcal</Text>
        <Pressable
          onPress={() => onDelete(entry)}
          hitSlop={8}
          style={({ pressed }) => [styles.deleteBtn, pressed && { opacity: 0.5 }]}
        >
          <Text style={styles.deleteBtnText}>🗑️</Text>
        </Pressable>
      </View>
    </View>
  );
}

// ─── Today's log modal ────────────────────────────────────────────────────────

interface TodayLogModalProps {
  visible: boolean;
  onClose: () => void;
  entries: LogEntry[];
  onDelete: (entry: LogEntry) => void;
}

function TodayLogModal({ visible, onClose, entries, onDelete }: TodayLogModalProps) {
  const insets = useSafeAreaInsets();
  const totals = sumMacros(entries);

  return (
    <Modal
      visible={visible}
      transparent
      animationType="slide"
      onRequestClose={onClose}
    >
      <Pressable style={styles.modalBackdrop} onPress={onClose} />
      <View
        style={[
          styles.logModalSheet,
          { paddingBottom: insets.bottom + 24 },
        ]}
      >
        {/* Handle */}
        <View style={styles.modalHandle} />

        {/* Modal header */}
        <View style={styles.logModalHeader}>
          <View>
            <Text style={styles.logModalTitle}>Today's Log 📋</Text>
            <Text style={styles.logModalDate}>{formatTodayDate()}</Text>
          </View>
          <Pressable
            onPress={onClose}
            style={styles.closeBtn}
            hitSlop={8}
          >
            <Text style={styles.closeBtnText}>✕</Text>
          </Pressable>
        </View>

        {/* Summary row */}
        <View style={styles.summaryRow}>
          <SummaryCard emoji="🔥" label="Calories" value={totals.calories} unit="kcal" color={C.primary} />
          <SummaryCard emoji="🥩" label="Protein" value={totals.protein} unit="g" color={C.macroProtein} />
          <SummaryCard emoji="🍚" label="Carbs" value={totals.carbs} unit="g" color="#2196F3" />
          <SummaryCard emoji="🥑" label="Fat" value={totals.fat} unit="g" color={C.macroFat} />
        </View>

        {/* Food list or empty */}
        {entries.length === 0 ? (
          <View style={styles.logEmptyWrap}>
            <Text style={styles.logEmptyEmoji}>🦝</Text>
            <Text style={styles.logEmptyTitle}>Nothing logged yet today!</Text>
            <Text style={styles.logEmptySubtitle}>Tap the search bar to add food 🦝</Text>
          </View>
        ) : (
          <ScrollView
            style={styles.logList}
            contentContainerStyle={styles.logListContent}
            showsVerticalScrollIndicator={false}
          >
            {entries.map((entry) => (
              <LogEntryRow key={entry.id} entry={entry} onDelete={onDelete} />
            ))}
          </ScrollView>
        )}
      </View>
    </Modal>
  );
}

// ─── Food search result card ───────────────────────────────────────────────────

interface FoodCardProps {
  food: FoodSearchResult;
  onPress: () => void;
}
function FoodCard({ food, onPress }: FoodCardProps) {
  return (
    <Pressable
      style={styles.foodCard}
      onPress={() => {
        Haptics.selectionAsync();
        onPress();
      }}
    >
      <Text style={styles.foodName} numberOfLines={2}>
        {food.description}
      </Text>
      <View style={styles.foodMacroRow}>
        <Text style={styles.foodPer}>Per 100g:</Text>
        <MacroTag label="kcal" value={String(food.calories)} color={C.primary} />
        <MacroTag label="prot" value={`${food.protein}g`} color={C.macroProtein} />
        <MacroTag label="carb" value={`${food.carbs}g`} color="#2196F3" />
        <MacroTag label="fat" value={`${food.fat}g`} color={C.macroFat} />
      </View>
    </Pressable>
  );
}

// ─── Portion modal ────────────────────────────────────────────────────────────

interface PortionModalProps {
  food: FoodSearchResult | null;
  visible: boolean;
  onClose: () => void;
  onLog: (grams: number, macros: MacroResult) => void;
}
function PortionModal({ food, visible, onClose, onLog }: PortionModalProps) {
  const [grams, setGrams] = useState("100");
  const [gramsError, setGramsError] = useState("");
  const shakeAnim = useRef(new Animated.Value(0)).current;
  const preview = food ? calculateNutrients(food, Number(grams) || 0) : null;

  useEffect(() => {
    if (visible) { setGrams("100"); setGramsError(""); }
  }, [visible]);

  function shake() {
    shakeAnim.setValue(0);
    Animated.sequence([
      Animated.timing(shakeAnim, { toValue: 8, duration: 50, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: -8, duration: 50, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: 6, duration: 50, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: -6, duration: 50, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: 0, duration: 50, useNativeDriver: true }),
    ]).start();
  }

  function handleLogPress() {
    if (!preview) return;
    const g = Number(grams) || 0;
    if (g <= 0) {
      setGramsError("Please enter a valid amount 🦝");
      shake();
      return;
    }
    if (g > 5000) {
      Alert.alert(
        "That's a lot... 🦝😅",
        "Are you sure you want to log more than 5kg of this food?",
        [
          { text: "Cancel", style: "cancel" },
          {
            text: "Yes, log it",
            onPress: () => {
              Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
              onLog(g, preview);
            },
          },
        ]
      );
      return;
    }
    setGramsError("");
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    onLog(g, preview);
  }

  if (!food) return null;

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <Pressable style={styles.modalBackdrop} onPress={onClose} />
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "position" : "height"}
        style={styles.modalSheet}
      >
        <View style={styles.modalHandle} />
        <View style={styles.modalContent}>
          <Text style={styles.modalFoodName} numberOfLines={2}>
            {food.description}
          </Text>
          <Text style={styles.modalLabel}>Amount in grams</Text>
          <Animated.View style={{ transform: [{ translateX: shakeAnim }] }}>
            <TextInput
              style={[styles.gramsInput, gramsError ? { borderColor: C.destructive } : {}]}
              value={grams}
              onChangeText={(v) => { setGrams(v.replace(/[^0-9.]/g, "")); setGramsError(""); }}
              keyboardType="decimal-pad"
              selectTextOnFocus
              placeholderTextColor={C.textTertiary}
            />
          </Animated.View>
          {gramsError ? <Text style={styles.gramsErrorText}>{gramsError}</Text> : null}
          {preview && (
            <View style={styles.previewCard}>
              <Text style={styles.previewTitle}>For {grams || "0"}g:</Text>
              <View style={styles.previewRows}>
                <Text style={styles.previewRow}>
                  🔥 <Text style={styles.previewVal}>{preview.calories} kcal</Text>
                </Text>
                <Text style={styles.previewRow}>
                  🥩 <Text style={styles.previewVal}>{preview.protein}g</Text> protein
                </Text>
                <Text style={styles.previewRow}>
                  🍚 <Text style={styles.previewVal}>{preview.carbs}g</Text> carbs
                </Text>
                <Text style={styles.previewRow}>
                  🥑 <Text style={styles.previewVal}>{preview.fat}g</Text> fat
                </Text>
              </View>
              <Text style={styles.rockyComment}>Looks delicious! 🦝😋</Text>
            </View>
          )}
          <Pressable
            style={styles.logBtn}
            onPress={handleLogPress}
          >
            <Text style={styles.logBtnText}>Add to Today 🦝</Text>
          </Pressable>
          <Pressable style={styles.cancelBtnRow} onPress={onClose}>
            <Text style={styles.cancelBtnText}>Cancel</Text>
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

// ─── Empty / no-results states ────────────────────────────────────────────────

function EmptyState({ onPillPress }: { onPillPress: (label: string) => void }) {
  return (
    <View style={styles.emptyWrap}>
      <Text style={styles.emptyRocky}>🦝</Text>
      <Text style={styles.emptyTitle}>Search for any food above!</Text>
      <View style={styles.pillsRow}>
        {QUICK_PILLS.map((p) => (
          <Pressable
            key={p.label}
            style={styles.pill}
            onPress={() => {
              Haptics.selectionAsync();
              onPillPress(p.label);
            }}
          >
            <Text style={styles.pillText}>
              {p.emoji} {p.label}
            </Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

function NoResultsState() {
  return (
    <View style={styles.emptyWrap}>
      <Text style={styles.emptyRocky}>🦝</Text>
      <Text style={styles.emptyTitle}>Hmm, couldn't find that one 🦝</Text>
      <Text style={styles.emptySubtitle}>Try different keywords</Text>
    </View>
  );
}

function SuccessOverlay() {
  const scale = useRef(new Animated.Value(0.5)).current;
  const opacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.parallel([
      Animated.spring(scale, { toValue: 1, useNativeDriver: true, damping: 12 }),
      Animated.timing(opacity, { toValue: 1, duration: 200, useNativeDriver: true }),
    ]).start();
  }, [scale, opacity]);

  return (
    <View style={styles.successWrap}>
      <Animated.View style={[styles.successCard, { transform: [{ scale }], opacity }]}>
        <Text style={styles.successEmoji}>🦝✅</Text>
        <Text style={styles.successText}>Logged!</Text>
      </Animated.View>
    </View>
  );
}

// ─── Main screen ──────────────────────────────────────────────────────────────

export default function LogScreen() {
  const insets = useSafeAreaInsets();

  // Search state
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<FoodSearchResult[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [hasSearched, setHasSearched] = useState(false);
  const [searchError, setSearchError] = useState<"NETWORK_ERROR" | "API_ERROR" | null>(null);
  const [selectedFood, setSelectedFood] = useState<FoodSearchResult | null>(null);
  const [showPortionModal, setShowPortionModal] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Log history state
  const [logEntries, setLogEntries] = useState<LogEntry[]>([]);
  const [showLogModal, setShowLogModal] = useState(false);

  // Load today's log on focus (keeps home rings in sync too)
  useFocusEffect(
    useCallback(() => {
      loadTodayLog().then(setLogEntries);
    }, [])
  );

  // Refresh entries whenever the log modal opens
  const handleOpenLogModal = useCallback(async () => {
    const entries = await loadTodayLog();
    setLogEntries(entries);
    setShowLogModal(true);
  }, []);

  const handleDeleteEntry = useCallback((entry: LogEntry) => {
    Alert.alert(
      "Remove food?",
      `Remove "${entry.foodName}" from today's log?`,
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Remove",
          style: "destructive",
          onPress: async () => {
            await removeLogEntry(entry.id);
            const updated = await loadTodayLog();
            setLogEntries(updated);
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
          },
        },
      ]
    );
  }, []);

  // Search
  const runSearch = useCallback(async (q: string) => {
    if (!q.trim()) {
      setResults([]);
      setHasSearched(false);
      setSearchError(null);
      return;
    }
    setIsSearching(true);
    setHasSearched(true);
    setSearchError(null);
    try {
      const data = await searchFoods(q);
      setResults(data);
    } catch (err) {
      setResults([]);
      const msg = err instanceof Error ? err.message : "";
      if (msg === "NETWORK_ERROR") setSearchError("NETWORK_ERROR");
      else setSearchError("API_ERROR");
    } finally {
      setIsSearching(false);
    }
  }, []);

  const handleQueryChange = useCallback(
    (text: string) => {
      setQuery(text);
      if (debounceRef.current) clearTimeout(debounceRef.current);
      debounceRef.current = setTimeout(() => runSearch(text), 500);
    },
    [runSearch]
  );

  const handlePillPress = useCallback(
    (label: string) => {
      setQuery(label);
      runSearch(label);
    },
    [runSearch]
  );

  const handleFoodPress = useCallback((food: FoodSearchResult) => {
    setSelectedFood(food);
    setShowPortionModal(true);
  }, []);

  const handleLog = useCallback(
    async (grams: number, macros: MacroResult) => {
      if (!selectedFood) return;
      const today = new Date().toISOString().slice(0, 10);
      const entry: LogEntry = {
        id: Date.now().toString(),
        foodName: selectedFood.description,
        grams,
        calories: macros.calories,
        protein: macros.protein,
        carbs: macros.carbs,
        fat: macros.fat,
        loggedAt: new Date().toISOString(),
        date: today,
      };
      await appendLogEntry(entry);
      const updated = await loadTodayLog();
      setLogEntries(updated);
      setShowPortionModal(false);
      setShowSuccess(true);
      setTimeout(() => {
        setShowSuccess(false);
        router.back();
      }, 1400);
    },
    [selectedFood]
  );

  const showEmpty = !hasSearched && !isSearching;
  const showNoResults = hasSearched && !isSearching && results.length === 0;

  return (
    <View style={{ flex: 1, backgroundColor: C.background }}>
      <ScrollView
        contentContainerStyle={[
          styles.container,
          { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 40 },
        ]}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <Pressable onPress={() => router.back()} style={styles.backBtn} hitSlop={12}>
            <Text style={styles.backText}>‹</Text>
          </Pressable>
          <Text style={styles.title}>Quick Log 🦝</Text>
          <Pressable
            onPress={handleOpenLogModal}
            style={styles.todayBtn}
            hitSlop={8}
          >
            <Text style={styles.todayBtnText}>📋 Today</Text>
            {logEntries.length > 0 && (
              <View style={styles.todayBadge}>
                <Text style={styles.todayBadgeText}>{logEntries.length}</Text>
              </View>
            )}
          </Pressable>
        </View>

        {/* Search bar */}
        <View style={styles.searchBar}>
          <Text style={styles.searchIcon}>🔍</Text>
          <TextInput
            style={styles.searchInput}
            value={query}
            onChangeText={handleQueryChange}
            placeholder="Search food... (e.g. chicken breast)"
            placeholderTextColor={C.textTertiary}
            returnKeyType="search"
            onSubmitEditing={() => {
              if (debounceRef.current) clearTimeout(debounceRef.current);
              runSearch(query);
            }}
            autoCorrect={false}
          />
          {isSearching && (
            <ActivityIndicator size="small" color={C.primary} style={{ marginRight: 8 }} />
          )}
          {!isSearching && query.length > 0 && (
            <Pressable
              onPress={() => {
                setQuery("");
                setResults([]);
                setHasSearched(false);
              }}
              hitSlop={8}
            >
              <Text style={styles.clearBtn}>✕</Text>
            </Pressable>
          )}
        </View>

        {/* Search errors */}
        {searchError === "NETWORK_ERROR" && (
          <View style={styles.searchErrorCard}>
            <Text style={styles.searchErrorEmoji}>🦝📡</Text>
            <Text style={styles.searchErrorText}>No internet connection. Check your WiFi! 🦝📡</Text>
            <Pressable style={styles.retryBtn} onPress={() => runSearch(query)}>
              <Text style={styles.retryBtnText}>Retry</Text>
            </Pressable>
          </View>
        )}
        {searchError === "API_ERROR" && (
          <View style={styles.searchErrorCard}>
            <Text style={styles.searchErrorEmoji}>🦝</Text>
            <Text style={styles.searchErrorText}>Something went wrong. Try again! 🦝</Text>
            <Pressable style={styles.retryBtn} onPress={() => runSearch(query)}>
              <Text style={styles.retryBtnText}>Retry</Text>
            </Pressable>
          </View>
        )}

        {!searchError && showEmpty && <EmptyState onPillPress={handlePillPress} />}
        {!searchError && showNoResults && <NoResultsState />}

        {results.length > 0 && (
          <View style={styles.resultsList}>
            {results.map((food) => (
              <FoodCard
                key={food.fdcId}
                food={food}
                onPress={() => handleFoodPress(food)}
              />
            ))}
          </View>
        )}
      </ScrollView>

      {/* Portion modal */}
      <PortionModal
        food={selectedFood}
        visible={showPortionModal}
        onClose={() => setShowPortionModal(false)}
        onLog={handleLog}
      />

      {/* Today's log modal */}
      <TodayLogModal
        visible={showLogModal}
        onClose={() => setShowLogModal(false)}
        entries={logEntries}
        onDelete={handleDeleteEntry}
      />

      {showSuccess && <SuccessOverlay />}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 20,
    gap: 16,
  },

  // Header
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
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
  title: {
    fontSize: 20,
    fontWeight: "700" as const,
    color: C.text,
  },
  todayBtn: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: C.secondary,
    borderRadius: 20,
    paddingHorizontal: 12,
    paddingVertical: 6,
    gap: 4,
  },
  todayBtnText: {
    fontSize: 13,
    fontWeight: "600" as const,
    color: C.primary,
  },
  todayBadge: {
    backgroundColor: C.primary,
    borderRadius: 10,
    minWidth: 18,
    height: 18,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 4,
  },
  todayBadgeText: {
    fontSize: 11,
    fontWeight: "700" as const,
    color: C.primaryForeground,
  },

  // Speech bubble
  speechBubble: {
    backgroundColor: C.card,
    borderRadius: 14,
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderWidth: 1,
    borderColor: C.border,
    alignSelf: "flex-start",
    ...CARD_SHADOW,
  },
  speechText: {
    fontSize: 15,
    color: C.text,
    fontWeight: "500" as const,
  },

  // Search bar
  searchBar: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: C.card,
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: C.border,
    gap: 8,
    ...CARD_SHADOW,
  },
  searchIcon: { fontSize: 17 },
  searchInput: {
    flex: 1,
    fontSize: 16,
    color: C.text,
    padding: 0,
  },
  clearBtn: {
    fontSize: 16,
    color: C.textTertiary,
    paddingHorizontal: 4,
  },

  // Food card
  foodCard: {
    backgroundColor: C.card,
    borderRadius: 14,
    padding: 14,
    borderWidth: 1,
    borderColor: C.border,
    gap: 8,
    ...CARD_SHADOW,
  },
  foodName: {
    fontSize: 15,
    fontWeight: "600" as const,
    color: C.text,
    lineHeight: 20,
  },
  foodMacroRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    flexWrap: "wrap",
  },
  foodPer: {
    fontSize: 11,
    color: C.textTertiary,
    marginRight: 2,
  },

  // Macro tag
  macroTag: {
    flexDirection: "row",
    alignItems: "center",
    gap: 3,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 99,
  },
  macroTagText: { fontSize: 12, fontWeight: "700" as const },
  macroTagLabel: { fontSize: 11, color: C.textSecondary },

  // Search error
  searchErrorCard: {
    alignItems: "center",
    paddingVertical: 20,
    paddingHorizontal: 16,
    gap: 8,
    backgroundColor: C.card,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: C.border,
  },
  searchErrorEmoji: { fontSize: 36 },
  searchErrorText: {
    fontSize: 14,
    color: C.text,
    fontWeight: "500" as const,
    textAlign: "center",
  },
  retryBtn: {
    marginTop: 4,
    backgroundColor: C.primary,
    borderRadius: 99,
    paddingHorizontal: 20,
    paddingVertical: 8,
  },
  retryBtnText: {
    color: "#fff",
    fontSize: 14,
    fontWeight: "600" as const,
  },
  gramsErrorText: {
    fontSize: 13,
    color: C.destructive,
    textAlign: "center",
    marginTop: -6,
  },

  // Results list
  resultsList: { gap: 10 },

  // Empty / no results
  emptyWrap: {
    alignItems: "center",
    paddingVertical: 24,
    gap: 12,
  },
  emptyRocky: { fontSize: 56 },
  emptyTitle: {
    fontSize: 16,
    fontWeight: "600" as const,
    color: C.text,
    textAlign: "center",
  },
  emptySubtitle: { fontSize: 14, color: C.textSecondary },
  pillsRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "center",
    gap: 8,
    marginTop: 4,
  },
  pill: {
    backgroundColor: C.card,
    borderRadius: 99,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderWidth: 1,
    borderColor: C.border,
    ...CARD_SHADOW,
  },
  pillText: {
    fontSize: 14,
    color: C.text,
    fontWeight: "500" as const,
  },

  // Shared modal backdrop + handle
  modalBackdrop: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.4)",
  },
  modalHandle: {
    width: 40,
    height: 4,
    backgroundColor: C.border,
    borderRadius: 2,
    alignSelf: "center",
    marginTop: 12,
    marginBottom: 8,
  },

  // Portion modal (bottom sheet)
  modalSheet: {
    backgroundColor: C.card,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    paddingBottom: 40,
    ...CARD_SHADOW,
  },
  modalContent: {
    paddingHorizontal: 24,
    paddingTop: 8,
    gap: 14,
  },
  modalFoodName: {
    fontSize: 18,
    fontWeight: "700" as const,
    color: C.text,
    lineHeight: 24,
  },
  modalLabel: {
    fontSize: 13,
    color: C.textSecondary,
    fontWeight: "500" as const,
    marginBottom: -6,
  },
  gramsInput: {
    backgroundColor: C.input,
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 22,
    fontWeight: "700" as const,
    color: C.text,
    textAlign: "center",
    borderWidth: 1,
    borderColor: C.border,
  },
  previewCard: {
    backgroundColor: "#FFF3EE",
    borderRadius: 14,
    padding: 14,
    gap: 6,
    borderWidth: 1,
    borderColor: C.primary + "33",
  },
  previewTitle: {
    fontSize: 13,
    color: C.textSecondary,
    fontWeight: "600" as const,
    marginBottom: 2,
  },
  previewRows: { gap: 4 },
  previewRow: { fontSize: 15, color: C.text },
  previewVal: { fontWeight: "700" as const, color: C.text },
  rockyComment: {
    fontSize: 13,
    color: C.textSecondary,
    fontStyle: "italic",
    marginTop: 4,
  },
  logBtn: {
    backgroundColor: C.primary,
    borderRadius: 16,
    paddingVertical: 16,
    alignItems: "center",
    shadowColor: C.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 4,
  },
  logBtnText: {
    color: "#FFFFFF",
    fontSize: 17,
    fontWeight: "700" as const,
  },
  cancelBtnRow: {
    alignItems: "center",
    paddingVertical: 8,
  },
  cancelBtnText: {
    fontSize: 15,
    color: C.text,
  },

  // Today's log modal
  logModalSheet: {
    backgroundColor: C.card,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    maxHeight: "85%",
    ...CARD_SHADOW,
  },
  logModalHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    paddingHorizontal: 20,
    paddingBottom: 12,
  },
  logModalTitle: {
    fontSize: 20,
    fontWeight: "700" as const,
    color: C.text,
  },
  logModalDate: {
    fontSize: 13,
    color: C.textSecondary,
    marginTop: 2,
  },
  closeBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: C.muted,
    alignItems: "center",
    justifyContent: "center",
    marginTop: 2,
  },
  closeBtnText: {
    fontSize: 14,
    color: C.textSecondary,
    fontWeight: "600" as const,
  },

  // Summary row
  summaryRow: {
    flexDirection: "row",
    gap: 8,
    paddingHorizontal: 20,
    paddingBottom: 16,
  },
  summaryCard: {
    flex: 1,
    backgroundColor: C.background,
    borderRadius: 12,
    padding: 10,
    alignItems: "center",
    gap: 1,
  },
  summaryEmoji: { fontSize: 18, marginBottom: 2 },
  summaryValue: {
    fontSize: 16,
    fontWeight: "700" as const,
  },
  summaryUnit: {
    fontSize: 10,
    color: C.mutedForeground,
    fontWeight: "500" as const,
  },
  summaryLabel: {
    fontSize: 10,
    color: C.mutedForeground,
    marginTop: 1,
  },

  // Log entry list
  logList: {
    flex: 1,
  },
  logListContent: {
    paddingHorizontal: 20,
    gap: 10,
    paddingBottom: 8,
  },
  logEntryCard: {
    flexDirection: "row",
    backgroundColor: C.background,
    borderRadius: 14,
    padding: 12,
    borderWidth: 1,
    borderColor: C.border,
    gap: 10,
    alignItems: "flex-start",
  },
  logEntryMain: {
    flex: 1,
    gap: 3,
  },
  logEntryName: {
    fontSize: 14,
    fontWeight: "600" as const,
    color: C.text,
    lineHeight: 18,
  },
  logEntryGrams: {
    fontSize: 12,
    color: C.textTertiary,
  },
  logEntryMacros: {
    fontSize: 11,
    color: C.textSecondary,
    marginTop: 2,
  },
  logEntryRight: {
    alignItems: "flex-end",
    gap: 4,
  },
  logEntryCals: {
    fontSize: 16,
    fontWeight: "700" as const,
    color: C.primary,
  },
  logEntryCalsUnit: {
    fontSize: 10,
    color: C.mutedForeground,
    marginTop: -4,
  },
  deleteBtn: {
    marginTop: 4,
  },
  deleteBtnText: {
    fontSize: 16,
  },

  // Log modal empty state
  logEmptyWrap: {
    alignItems: "center",
    paddingVertical: 40,
    gap: 10,
    paddingHorizontal: 20,
  },
  logEmptyEmoji: { fontSize: 52 },
  logEmptyTitle: {
    fontSize: 16,
    fontWeight: "600" as const,
    color: C.text,
    textAlign: "center",
  },
  logEmptySubtitle: {
    fontSize: 13,
    color: C.textSecondary,
    textAlign: "center",
  },

  // Success overlay
  successWrap: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(0,0,0,0.45)",
    alignItems: "center",
    justifyContent: "center",
  },
  successCard: {
    backgroundColor: C.card,
    borderRadius: 24,
    paddingVertical: 36,
    paddingHorizontal: 48,
    alignItems: "center",
    gap: 10,
  },
  successEmoji: { fontSize: 64 },
  successText: {
    fontSize: 24,
    fontWeight: "700" as const,
    color: C.text,
  },
});
