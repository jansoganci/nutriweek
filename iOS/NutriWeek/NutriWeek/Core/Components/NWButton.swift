import SwiftUI

/// Full-width or intrinsic-width button. For RN auth primary, set `primaryDisabledUsesReducedOpacity` and `cornerRadius` (e.g. 14).
struct NWButton: View {
    enum Variant {
        case primary
        case secondary
        case destructive
        case disabled
    }

    let title: String
    let variant: Variant
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var isFullWidth: Bool = true
    /// When **true** with `.primary`, disabled state keeps **primary** fill and dims with **opacity 0.55** (RN auth).
    var primaryDisabledUsesReducedOpacity: Bool = false
    var cornerRadius: CGFloat = RadiusToken.field
    let action: () -> Void

    private var isInteractive: Bool {
        isEnabled && !isLoading && variant != .disabled
    }

    private var shouldDimPrimaryOpacity: Bool {
        primaryDisabledUsesReducedOpacity
            && variant == .primary
            && !isEnabled
            && !isLoading
    }

    private var backgroundColor: Color {
        if variant == .primary, primaryDisabledUsesReducedOpacity {
            return ColorToken.primary
        }
        if !isEnabled || variant == .disabled {
            return ColorToken.disabledBackground
        }
        switch variant {
        case .primary:
            return ColorToken.primary
        case .secondary:
            return ColorToken.secondary
        case .destructive:
            return ColorToken.destructive
        case .disabled:
            return ColorToken.disabledBackground
        }
    }

    private var foregroundColor: Color {
        if variant == .primary, primaryDisabledUsesReducedOpacity {
            return ColorToken.onPrimary
        }
        if !isEnabled || variant == .disabled {
            return ColorToken.disabledForeground
        }
        switch variant {
        case .primary:
            return ColorToken.onPrimary
        case .secondary:
            return ColorToken.onSecondary
        case .destructive:
            return ColorToken.onDestructive
        case .disabled:
            return ColorToken.disabledForeground
        }
    }

    private var showsSecondaryBorder: Bool {
        guard isEnabled, variant != .disabled else { return false }
        return variant == .secondary
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: SpacingToken.xs) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                }
                Text(title)
                    .font(TypographyToken.font(.body, weight: .bold))
                    .foregroundStyle(foregroundColor)
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, 13)
            .frame(minHeight: SpacingToken.xxl)
            .padding(.horizontal, SpacingToken.md)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        showsSecondaryBorder ? ColorToken.border : Color.clear,
                        lineWidth: showsSecondaryBorder ? BorderToken.hairline : 0
                    )
            )
            .opacity(shouldDimPrimaryOpacity ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!isInteractive)
    }
}
