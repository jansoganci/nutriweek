import SwiftUI

/// Three consolidated elevation levels. Use `ctaGlow` only for primary CTA glow (tinted shadow).
enum ShadowToken {
    enum Level {
        /// Elevation ~1–2 — soft controls, skeleton, light cards.
        case subtle
        /// Elevation ~3–4 — standard cards, auth surfaces.
        case medium
        /// Elevation ~5–6 — toast, prominent floating elements.
        case prominent
    }

    static func shadowColor(_ level: Level) -> Color {
        ColorToken.shadow
    }

    static func radius(_ level: Level) -> CGFloat {
        switch level {
        case .subtle: return 4
        case .medium: return 8
        case .prominent: return 8
        }
    }

    static func offset(_ level: Level) -> CGSize {
        switch level {
        case .subtle: return CGSize(width: 0, height: 1)
        case .medium: return CGSize(width: 0, height: 2)
        case .prominent: return CGSize(width: 0, height: 4)
        }
    }

    static func opacity(_ level: Level) -> Double {
        switch level {
        case .subtle: return 0.06
        case .medium: return 0.10
        case .prominent: return 0.18
        }
    }

    /// Primary CTA tinted shadow (from RN results CTA). Apply `shadowColor: ColorToken.primary` at call site if needed.
    static let ctaGlowRadius: CGFloat = 10
    static let ctaGlowYOffset: CGFloat = 4
    static let ctaGlowOpacity: Double = 0.30
}
