import SwiftUI

/// v1 design colors (parity with RN `constants/colors.ts`, plus tokens for former hardcoded values).
enum ColorToken {
    // MARK: - Base

    static let background = Color(hex: "#FAFAFA")
    static let foreground = Color(hex: "#2D2D2D")
    static let card = Color(hex: "#FFFFFF")
    static let cardForeground = Color(hex: "#2D2D2D")

    static let muted = Color(hex: "#F0F0F0")
    static let mutedForeground = Color(hex: "#9E9E9E")

    // MARK: - Brand

    static let primary = Color(hex: "#FF6B35")
    static let onPrimary = Color(hex: "#FFFFFF")
    static let secondary = Color(hex: "#FFF3EE")
    static let onSecondary = Color(hex: "#FF6B35")
    static let accent = Color(hex: "#FF6B35")
    static let onAccent = Color(hex: "#FFFFFF")
    static let tint = Color(hex: "#FF6B35")

    // MARK: - Text

    static let textPrimary = Color(hex: "#2D2D2D")
    static let textSecondary = Color(hex: "#757575")
    static let textTertiary = Color(hex: "#BDBDBD")

    // MARK: - Semantic

    static let success = Color(hex: "#4CAF50")
    static let onSuccess = Color(hex: "#FFFFFF")
    static let successSurface = Color(hex: "#E8F5E9")

    static let warning = Color(hex: "#FFB300")
    static let onWarning = Color(hex: "#FFFFFF")
    static let warningSurface = Color(hex: "#FFF8E1")

    static let destructive = Color(hex: "#EF5350")
    static let onDestructive = Color(hex: "#FFFFFF")
    static let destructiveSurface = Color(hex: "#FFEBEE")

    /// High-emphasis destructive (e.g. BMI “obese” band — was `#FF4444`).
    static let destructiveDark = Color(hex: "#D32F2F")

    // MARK: - Inputs / chrome

    static let border = Color(hex: "#EFEFEF")
    static let inputBackground = Color(hex: "#F5F5F5")
    static let inputForeground = Color(hex: "#2D2D2D")

    // MARK: - Macros

    static let macroCarb = Color(hex: "#FF6B35")
    static let macroProtein = Color(hex: "#4CAF50")
    static let macroFat = Color(hex: "#FFB300")

    // MARK: - Shadow baseline

    static let shadow = Color.black

    // MARK: - Disabled (was `#CCCCCC` fill)

    static let disabledBackground = Color(hex: "#CCCCCC")
    static let disabledForeground = Color(hex: "#FFFFFF")

    // MARK: - Skeleton

    static let skeletonBase = Color(hex: "#DEDEDE")
    static let skeletonHighlight = Color(hex: "#F4F4F4")
    static let skeletonCard = Color(hex: "#F7F7F7")
    static let skeletonBorder = Color(hex: "#EBEBEB")

    // MARK: - Overlay

    static let overlayScrim = Color.black.opacity(0.5)
}
