import { Link, router } from "expo-router";
import React, { useMemo, useState } from "react";
import {
  ActivityIndicator,
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
import colors from "@/constants/colors";
import { supabase } from "@/services/supabaseClient";

const C = colors.light;

function isValidEmail(email: string): boolean {
  return /\S+@\S+\.\S+/.test(email);
}

export default function RegisterScreen() {
  const insets = useSafeAreaInsets();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const canSubmit = useMemo(
    () =>
      email.trim().length > 0 &&
      password.length >= 6 &&
      confirmPassword.length >= 6 &&
      !loading,
    [email, password, confirmPassword, loading],
  );

  async function handleRegister() {
    setErrorMessage(null);

    const trimmedEmail = email.trim().toLowerCase();
    if (!isValidEmail(trimmedEmail)) {
      setErrorMessage("Please enter a valid email address.");
      return;
    }
    if (password.length < 6) {
      setErrorMessage("Password must be at least 6 characters.");
      return;
    }
    if (password !== confirmPassword) {
      setErrorMessage("Passwords do not match.");
      return;
    }

    setLoading(true);
    const { error } = await supabase.auth.signUp({
      email: trimmedEmail,
      password,
    });
    setLoading(false);

    if (error) {
      setErrorMessage(error.message);
      return;
    }

    router.replace("/(onboarding)/step1");
  }

  return (
    <KeyboardAvoidingView
      style={styles.screen}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <ScrollView
        contentContainerStyle={[
          styles.container,
          { paddingTop: insets.top + 20, paddingBottom: insets.bottom + 24 },
        ]}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        <RockyMascot mood="encouraging" size={72} message="Let's create your account!" />

        <View style={styles.card}>
          <Text style={styles.title}>Create Account</Text>
          <Text style={styles.subtitle}>Start your NutriWeek journey with Rocky.</Text>

          <Text style={styles.label}>Email</Text>
          <TextInput
            value={email}
            onChangeText={setEmail}
            style={styles.input}
            placeholder="you@example.com"
            autoCapitalize="none"
            autoCorrect={false}
            keyboardType="email-address"
            textContentType="emailAddress"
          />

          <Text style={styles.label}>Password</Text>
          <TextInput
            value={password}
            onChangeText={setPassword}
            style={styles.input}
            placeholder="At least 6 characters"
            secureTextEntry
            textContentType="newPassword"
          />

          <Text style={styles.label}>Confirm Password</Text>
          <TextInput
            value={confirmPassword}
            onChangeText={setConfirmPassword}
            style={styles.input}
            placeholder="Repeat your password"
            secureTextEntry
            textContentType="password"
          />

          {errorMessage ? <Text style={styles.error}>{errorMessage}</Text> : null}

          <Pressable
            onPress={handleRegister}
            disabled={!canSubmit}
            style={[styles.primaryButton, !canSubmit && styles.primaryButtonDisabled]}
          >
            {loading ? (
              <ActivityIndicator color={C.primaryForeground} />
            ) : (
              <Text style={styles.primaryButtonText}>Create Account</Text>
            )}
          </Pressable>

          <View style={styles.linkRow}>
            <Text style={styles.linkHint}>Already have an account? </Text>
            <Link href={"/login" as never} asChild>
              <Pressable>
                <Text style={styles.linkText}>Log in</Text>
              </Pressable>
            </Link>
          </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: C.background,
  },
  container: {
    flexGrow: 1,
    paddingHorizontal: 20,
    justifyContent: "center",
    gap: 18,
  },
  card: {
    backgroundColor: C.card,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: C.border,
    padding: 18,
    gap: 10,
    shadowColor: C.shadowColor,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 2,
  },
  title: {
    fontSize: 24,
    fontWeight: "700",
    color: C.text,
  },
  subtitle: {
    fontSize: 14,
    color: C.textSecondary,
    marginBottom: 8,
  },
  label: {
    fontSize: 13,
    color: C.textSecondary,
    fontWeight: "600",
    marginTop: 4,
  },
  input: {
    backgroundColor: C.input,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: C.border,
    paddingHorizontal: 12,
    paddingVertical: 11,
    color: C.text,
  },
  error: {
    color: C.destructive,
    fontSize: 13,
    marginTop: 2,
  },
  primaryButton: {
    marginTop: 10,
    backgroundColor: C.primary,
    borderRadius: 14,
    paddingVertical: 13,
    alignItems: "center",
    justifyContent: "center",
    minHeight: 48,
  },
  primaryButtonDisabled: {
    opacity: 0.55,
  },
  primaryButtonText: {
    color: C.primaryForeground,
    fontSize: 16,
    fontWeight: "700",
  },
  linkRow: {
    flexDirection: "row",
    justifyContent: "center",
    marginTop: 4,
  },
  linkHint: {
    color: C.textSecondary,
    fontSize: 14,
  },
  linkText: {
    color: C.primary,
    fontSize: 14,
    fontWeight: "700",
  },
});
