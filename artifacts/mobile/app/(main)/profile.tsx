import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import RockyMascot from "@/components/RockyMascot";
import { useColors } from "@/hooks/useColors";
import type { UserProfile } from "@/constants/types";

export default function ProfileScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();

  return (
    <ScrollView
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={[
        styles.container,
        { paddingTop: insets.top + 16 },
      ]}
    >
      <Text style={[styles.title, { color: colors.text }]}>Profile</Text>
      <RockyMascot mood="happy" size={56} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 24,
    gap: 16,
    alignItems: "center",
  },
  title: {
    fontSize: 28,
    fontWeight: "700" as const,
    alignSelf: "flex-start",
  },
});
