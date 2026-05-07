import SwiftUI

struct NWCard<Content: View>: View {
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    /// RN `login` / `register` card: `shadowOffset` y **2**, radius **8**, opacity **0.06**.
    private let rnAuthShadow: Bool
    private let content: Content

    init(
        cornerRadius: CGFloat = RadiusToken.card,
        padding: CGFloat = SpacingToken.md,
        rnAuthShadow: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.rnAuthShadow = rnAuthShadow
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(ColorToken.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(ColorToken.border, lineWidth: BorderToken.hairline)
            )
            .shadow(
                color: ShadowToken.shadowColor(rnAuthShadow ? .medium : .subtle)
                    .opacity(rnAuthShadow ? 0.06 : ShadowToken.opacity(.subtle)),
                radius: rnAuthShadow ? 8 : ShadowToken.radius(.subtle),
                x: (rnAuthShadow ? ShadowToken.offset(.medium) : ShadowToken.offset(.subtle)).width,
                y: (rnAuthShadow ? ShadowToken.offset(.medium) : ShadowToken.offset(.subtle)).height
            )
    }
}
