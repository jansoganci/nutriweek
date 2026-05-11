import SwiftUI

struct ToastView: View {
    enum Style {
        case success
        case error
        case info
    }

    let title: String
    var subtitle: String? = nil
    var style: Style = .info

    var body: some View {
        HStack(spacing: 10) {
            iconLeading
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TypographyToken.inter(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(TypographyToken.inter(size: 12, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.92))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 3)
    }

    @ViewBuilder
    private var iconLeading: some View {
        switch style {
        case .success, .error:
            Text(icon)
                .font(.system(size: 20))
        case .info:
            Image("rocky-celebrate-static")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }

    private var icon: String {
        switch style {
        case .success: return "✅"
        case .error: return "⚠️"
        case .info: return ""
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .success: return ColorToken.success
        case .error: return ColorToken.destructive
        case .info: return ColorToken.primary
        }
    }
}
