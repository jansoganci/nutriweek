import SwiftUI

struct ErrorStateView: View {
    let title: String
    let message: String
    var retryTitle: String = "Try again"
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            RockyMascotView(mood: .thinking, size: 40)
            Text(title)
                .font(TypographyToken.inter(size: 16, weight: .bold))
                .foregroundStyle(ColorToken.textPrimary)
            Text(message)
                .font(TypographyToken.inter(size: 13, weight: .regular))
                .foregroundStyle(ColorToken.textSecondary)
                .multilineTextAlignment(.center)

            if let onRetry {
                Button(retryTitle, action: onRetry)
                    .font(TypographyToken.inter(size: 14, weight: .semibold))
                    .foregroundStyle(ColorToken.primary)
                    .buttonStyle(.plain)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ColorToken.border, lineWidth: BorderToken.hairline)
        )
    }
}
