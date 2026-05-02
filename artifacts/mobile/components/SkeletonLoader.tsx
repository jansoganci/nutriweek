import React, { useEffect, useRef } from "react";
import { Animated, StyleSheet, View, ViewStyle } from "react-native";

interface SkeletonBoxProps {
  width: number | `${number}%`;
  height: number;
  borderRadius?: number;
  style?: ViewStyle;
}

function SkeletonBox({ width, height, borderRadius = 8, style }: SkeletonBoxProps) {
  const shimmer = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(shimmer, {
          toValue: 1,
          duration: 850,
          useNativeDriver: true,
        }),
        Animated.timing(shimmer, {
          toValue: 0,
          duration: 850,
          useNativeDriver: true,
        }),
      ])
    ).start();
  }, [shimmer]);

  const opacity = shimmer.interpolate({
    inputRange: [0, 1],
    outputRange: [0.35, 0.85],
  });

  return (
    <View
      style={[
        { width, height, borderRadius, backgroundColor: "#DEDEDE", overflow: "hidden" },
        style,
      ]}
    >
      <Animated.View
        style={[StyleSheet.absoluteFill, { backgroundColor: "#F4F4F4", opacity }]}
      />
    </View>
  );
}

export function SkeletonFoodCard() {
  return (
    <View style={sk.foodCard}>
      <SkeletonBox width="78%" height={16} borderRadius={6} />
      <SkeletonBox width="52%" height={12} borderRadius={6} />
      <View style={sk.macroRow}>
        <SkeletonBox width={54} height={30} borderRadius={8} />
        <SkeletonBox width={54} height={30} borderRadius={8} />
        <SkeletonBox width={54} height={30} borderRadius={8} />
        <SkeletonBox width={54} height={30} borderRadius={8} />
      </View>
    </View>
  );
}

export function SkeletonPlanCard() {
  return (
    <View style={sk.planCard}>
      <View style={sk.planHeader}>
        <View style={{ gap: 7 }}>
          <SkeletonBox width={96} height={16} borderRadius={6} />
          <SkeletonBox width={58} height={12} borderRadius={6} />
        </View>
        <SkeletonBox width={72} height={16} borderRadius={6} />
      </View>
      {[0, 1, 2].map((i) => (
        <View key={i} style={sk.mealRow}>
          <SkeletonBox width={26} height={26} borderRadius={13} />
          <View style={{ flex: 1, gap: 5 }}>
            <SkeletonBox width="38%" height={11} borderRadius={4} />
            <SkeletonBox width="68%" height={14} borderRadius={4} />
          </View>
          <SkeletonBox width={60} height={14} borderRadius={4} />
        </View>
      ))}
    </View>
  );
}

const sk = StyleSheet.create({
  foodCard: {
    backgroundColor: "#F7F7F7",
    borderRadius: 14,
    padding: 14,
    gap: 9,
    borderWidth: 1,
    borderColor: "#EBEBEB",
  },
  macroRow: {
    flexDirection: "row",
    gap: 6,
    marginTop: 2,
  },
  planCard: {
    backgroundColor: "#F7F7F7",
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: "#EBEBEB",
    gap: 14,
  },
  planHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
  },
  mealRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
  },
});
