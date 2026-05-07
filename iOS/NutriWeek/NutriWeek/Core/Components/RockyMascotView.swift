import SwiftUI

/// Matches RN `RockyMascot`: raccoon emoji + optional speech bubble (no extra animation — RN uses `idle` float by default; omitted for parity with “no improvements”).
struct RockyMascotView: View {
    enum Mood: String {
        case happy
        case thinking
        case celebrating
        case encouraging
    }

    var mood: Mood = .happy
    var size: CGFloat = Size.medium.rawValue
    var message: String?

    enum Size: CGFloat {
        case small = 36
        case medium = 64
        case large = 88
    }

    var body: some View {
        VStack(spacing: SpacingToken.xs) {
            Text(primaryEmoji)
                .font(.system(size: size))
                .overlay(alignment: .bottomTrailing) {
                    if let accentEmoji {
                        Text(accentEmoji)
                            .font(.system(size: max(14, size * 0.26)))
                            .offset(x: size * 0.08, y: size * 0.08)
                    }
                }

            if let message, !message.isEmpty {
                Text(message)
                    .font(TypographyToken.inter(size: 14, weight: .regular))
                    .foregroundStyle(ColorToken.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(TypographyToken.LineHeight.tight - 14)
                    .padding(.horizontal, SpacingToken.md)
                    .padding(.vertical, 10)
                    .frame(maxWidth: 240)
                    .background(ColorToken.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(ColorToken.border, lineWidth: BorderToken.hairline)
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var primaryEmoji: String {
        "🦝"
    }

    private var accentEmoji: String? {
        switch mood {
        case .happy:
            return nil
        case .thinking:
            return "💭"
        case .celebrating:
            return "✨"
        case .encouraging:
            return "💪"
        }
    }
}
