import React, { useCallback, useEffect, useRef, useState } from "react";
import { Animated, StyleSheet, Text } from "react-native";

import colors from "@/constants/colors";

const C = colors.light;

export type ToastType = "success" | "error" | "warning";

const BG: Record<ToastType, string> = {
  success: C.success,
  error: C.destructive,
  warning: C.warning,
};

interface ToastProps {
  message: string;
  type?: ToastType;
  visible: boolean;
  bottomOffset?: number;
}

export function Toast({
  message,
  type = "success",
  visible,
  bottomOffset = 110,
}: ToastProps) {
  const translateY = useRef(new Animated.Value(30)).current;
  const opacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (visible) {
      translateY.setValue(30);
      opacity.setValue(0);
      Animated.parallel([
        Animated.spring(translateY, {
          toValue: 0,
          useNativeDriver: true,
          damping: 18,
          stiffness: 200,
        }),
        Animated.timing(opacity, {
          toValue: 1,
          duration: 180,
          useNativeDriver: true,
        }),
      ]).start();
    } else {
      Animated.parallel([
        Animated.timing(translateY, {
          toValue: 30,
          duration: 220,
          useNativeDriver: true,
        }),
        Animated.timing(opacity, {
          toValue: 0,
          duration: 220,
          useNativeDriver: true,
        }),
      ]).start();
    }
  }, [visible]);

  return (
    <Animated.View
      style={[
        styles.toast,
        {
          bottom: bottomOffset,
          backgroundColor: BG[type],
          transform: [{ translateY }],
          opacity,
        },
      ]}
      pointerEvents="none"
    >
      <Text style={styles.text}>🦝 {message}</Text>
    </Animated.View>
  );
}

interface ToastState {
  message: string;
  type: ToastType;
  visible: boolean;
}

export function useToast() {
  const [state, setState] = useState<ToastState>({
    message: "",
    type: "success",
    visible: false,
  });
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const showToast = useCallback(
    (message: string, type: ToastType = "success") => {
      if (timerRef.current) clearTimeout(timerRef.current);
      setState({ message, type, visible: true });
      timerRef.current = setTimeout(() => {
        setState((s) => ({ ...s, visible: false }));
      }, 3000);
    },
    []
  );

  return { toastState: state, showToast };
}

const styles = StyleSheet.create({
  toast: {
    position: "absolute",
    alignSelf: "center",
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 999,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.18,
    shadowRadius: 8,
    elevation: 6,
    maxWidth: "88%",
  },
  text: {
    color: "#FFFFFF",
    fontSize: 14,
    fontWeight: "600",
    textAlign: "center",
  },
});
