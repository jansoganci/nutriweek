import * as Haptics from "expo-haptics";
import { router } from "expo-router";
import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  ActivityIndicator,
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
  searchFoods,
  type FoodSearchResult,
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

function MacroTag({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <View style={[styles.macroTag, { backgroundColor: color + "18" }]}>
      <Text style={[styles.macroTagText, { color }]}>{value}</Text>
      <Text style={styles.macroTagLabel}>{label}</Text>
    </View>
  );
}

interface FoodCardProps {
  food: FoodSearchResult;
  onPress: () => void;
}
function FoodCard({ food, onPress }: FoodCardProps) {
  return (
    <Pressable style={styles.foodCard} onPress={() => { Haptics.selectionAsync(); onPress(); }}>
      <Text style={styles.foodName} numberOfLines={2}>{food.description}</Text>
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

interface PortionModalProps {
  food: FoodSearchResult | null;
  visible: boolean;
  onClose: () => void;
  onLog: (grams: number, macros: MacroResult) => void;
}
function PortionModal({ food, visible, onClose, onLog }: PortionModalProps) {
  const [grams, setGrams] = useState("100");
  const preview = food ? calculateNutrients(food, Number(grams) || 0) : null;

  useEffect(() => {
    if (visible) setGrams("100");
  }, [visible]);

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
          <Text style={styles.modalFoodName} numberOfLines={2}>{food.description}</Text>

          <Text style={styles.modalLabel}>Amount in grams</Text>
          <TextInput
            style={styles.gramsInput}
            value={grams}
            onChangeText={(v) => setGrams(v.replace(/[^0-9.]/g, ""))}
            keyboardType="decimal-pad"
            selectTextOnFocus
            placeholderTextColor={C.textTertiary}
          />

          {preview && (
            <View style={styles.previewCard}>
              <Text style={styles.previewTitle}>For {grams || "0"}g:</Text>
              <View style={styles.previewRows}>
                <Text style={styles.previewRow}>🔥 <Text style={styles.previewVal}>{preview.calories} kcal</Text></Text>
                <Text style={styles.previewRow}>🥩 <Text style={styles.previewVal}>{preview.protein}g</Text> protein</Text>
                <Text style={styles.previewRow}>🍚 <Text style={styles.previewVal}>{preview.carbs}g</Text> carbs</Text>
                <Text style={styles.previewRow}>🥑 <Text style={styles.previewVal}>{preview.fat}g</Text> fat</Text>
              </View>
              <Text style={styles.rockyComment}>Looks delicious! 🦝😋</Text>
            </View>
          )}

          <Pressable
            style={styles.logBtn}
            onPress={() => {
              if (!preview) return;
              Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
              onLog(Number(grams) || 0, preview);
            }}
          >
            <Text style={styles.logBtnText}>Add to Today 🦝</Text>
          </Pressable>
          <Pressable style={styles.cancelBtn} onPress={onClose}>
            <Text style={styles.cancelBtnText}>Cancel</Text>
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

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
            onPress={() => { Haptics.selectionAsync(); onPillPress(p.label); }}
          >
            <Text style={styles.pillText}>{p.emoji} {p.label}</Text>
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

export default function LogScreen() {
  const insets = useSafeAreaInsets();
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<FoodSearchResult[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [hasSearched, setHasSearched] = useState(false);
  const [selectedFood, setSelectedFood] = useState<FoodSearchResult | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const runSearch = useCallback(async (q: string) => {
    if (!q.trim()) {
      setResults([]);
      setHasSearched(false);
      return;
    }
    setIsSearching(true);
    setHasSearched(true);
    try {
      const data = await searchFoods(q);
      setResults(data);
    } catch {
      setResults([]);
    } finally {
      setIsSearching(false);
    }
  }, []);

  const handleQueryChange = useCallback((text: string) => {
    setQuery(text);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => runSearch(text), 500);
  }, [runSearch]);

  const handlePillPress = useCallback((label: string) => {
    setQuery(label);
    runSearch(label);
  }, [runSearch]);

  const handleFoodPress = useCallback((food: FoodSearchResult) => {
    setSelectedFood(food);
    setShowModal(true);
  }, []);

  const handleLog = useCallback(async (grams: number, macros: MacroResult) => {
    if (!selectedFood) return;
    const today = new Date().toISOString().slice(0, 10);
    const entry = {
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
    setShowModal(false);
    setShowSuccess(true);
    setTimeout(() => {
      setShowSuccess(false);
      router.back();
    }, 1400);
  }, [selectedFood]);

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
          <View style={{ width: 40 }} />
        </View>

        <View style={styles.speechBubble}>
          <Text style={styles.speechText}>What did you eat? 🦝🍽️</Text>
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
            onSubmitEditing={() => { if (debounceRef.current) clearTimeout(debounceRef.current); runSearch(query); }}
            autoCorrect={false}
          />
          {isSearching && <ActivityIndicator size="small" color={C.primary} style={{ marginRight: 8 }} />}
          {!isSearching && query.length > 0 && (
            <Pressable onPress={() => { setQuery(""); setResults([]); setHasSearched(false); }} hitSlop={8}>
              <Text style={styles.clearBtn}>✕</Text>
            </Pressable>
          )}
        </View>

        {/* States */}
        {showEmpty && <EmptyState onPillPress={handlePillPress} />}
        {showNoResults && <NoResultsState />}

        {/* Results */}
        {results.length > 0 && (
          <View style={styles.resultsList}>
            {results.map((food) => (
              <FoodCard key={food.fdcId} food={food} onPress={() => handleFoodPress(food)} />
            ))}
          </View>
        )}
      </ScrollView>

      {/* Portion modal */}
      <PortionModal
        food={selectedFood}
        visible={showModal}
        onClose={() => setShowModal(false)}
        onLog={handleLog}
      />

      {/* Success overlay */}
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
  searchIcon: {
    fontSize: 17,
  },
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
  macroTagText: {
    fontSize: 12,
    fontWeight: "700" as const,
  },
  macroTagLabel: {
    fontSize: 11,
    color: C.textSecondary,
  },

  // Results list
  resultsList: {
    gap: 10,
  },

  // Empty / no results
  emptyWrap: {
    alignItems: "center",
    paddingVertical: 24,
    gap: 12,
  },
  emptyRocky: {
    fontSize: 56,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: "600" as const,
    color: C.text,
    textAlign: "center",
  },
  emptySubtitle: {
    fontSize: 14,
    color: C.textSecondary,
  },
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

  // Portion modal
  modalBackdrop: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.4)",
  },
  modalSheet: {
    backgroundColor: C.card,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    paddingBottom: 40,
    ...CARD_SHADOW,
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
  previewRows: {
    gap: 4,
  },
  previewRow: {
    fontSize: 15,
    color: C.text,
  },
  previewVal: {
    fontWeight: "700" as const,
    color: C.text,
  },
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
  cancelBtn: {
    alignItems: "center",
    paddingVertical: 8,
  },
  cancelBtnText: {
    fontSize: 15,
    color: C.text,
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
  successEmoji: {
    fontSize: 64,
  },
  successText: {
    fontSize: 24,
    fontWeight: "700" as const,
    color: C.text,
  },
});
