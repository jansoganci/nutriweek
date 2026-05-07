import { Link, router } from "expo-router";
import React, { useMemo, useState } from "react";
import {
  ActivityIndicator,
  Alert,
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

export default function LoginScreen() {
  const insets = useSafeAreaInsets();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const canSubmit = useMemo(
    () => email.trim().length > 0 && password.length > 0 && !loading,
    [email, password, loading],
  );

  async function handleLogin() {
    setErrorMessage(null);
    setLoading(true);

    const { data, error } = await supabase.auth.signInWithPassword({
      email: email.trim().toLowerCase(),
      password,
    });

    if (error || !data.session) {
      setLoading(false);
      setErrorMessage(error?.message ?? "Unable to sign in.");
      return;
    }

    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("onboarding_complete")
      .eq("user_id", data.session.user.id)
      .maybeSingle();

    setLoading(false);

    if (profileError) {
      setErrorMessage(profileError.message);
      return;
    }

    const onboardingComplete = Boolean(profile?.onboarding_complete);
    router.replace(onboardingComplete ? "/(main)" : "/(onboarding)/step1");
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
        <RockyMascot mood="happy" size={72} message="Welcome back!" />

        <View style={styles.card}>
          <Text style={styles.title}>Log In</Text>
          <Text style={styles.subtitle}>Continue where you left off.</Text>

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
            placeholder="Your password"
            secureTextEntry
            textContentType="password"
          />

          <Pressable
            onPress={() => Alert.alert("Forgot Password", "Password reset flow will be added soon.")}
            style={styles.forgotWrap}
          >
            <Text style={styles.forgotText}>Forgot Password?</Text>
          </Pressable>

          {errorMessage ? <Text style={styles.error}>{errorMessage}</Text> : null}

          <Pressable
            onPress={handleLogin}
            disabled={!canSubmit}
            style={[styles.primaryButton, !canSubmit && styles.primaryButtonDisabled]}
          >
            {loading ? (
              <ActivityIndicator color={C.primaryForeground} />
            ) : (
              <Text style={styles.primaryButtonText}>Login</Text>
            )}
          </Pressable>

          <View style={styles.linkRow}>
            <Text style={styles.linkHint}>New here? </Text>
            <Link href={"/register" as never} asChild>
              <Pressable>
                <Text style={styles.linkText}>Create account</Text>
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
  forgotWrap: {
    alignSelf: "flex-end",
    marginTop: 2,
  },
  forgotText: {
    color: C.primary,
    fontSize: 13,
    fontWeight: "600",
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
