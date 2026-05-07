import SwiftUI

/// SwiftUI port of RN `MacroRing` (circular progress with centered value/unit + label).
struct MacroRingView: View {
    let label: String
    let current: Double
    let target: Double
    var unit: String = "g"
    var color: Color = ColorToken.primary
    var size: CGFloat = 80
    var strokeWidth: CGFloat = 8

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1)
    }

    private var radius: CGFloat {
        (size - strokeWidth) / 2
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(ColorToken.muted, lineWidth: strokeWidth)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text(displayCurrent)
                        .font(TypographyToken.inter(size: 16, weight: .bold))
                        .foregroundStyle(ColorToken.textPrimary)
                    Text(unit)
                        .font(TypographyToken.inter(size: 10, weight: .regular))
                        .foregroundStyle(ColorToken.textSecondary)
                }
            }
            .frame(width: size, height: size)

            Text(label)
                .font(TypographyToken.inter(size: 12, weight: .medium))
                .foregroundStyle(ColorToken.textSecondary)
        }
    }

    private var displayCurrent: String {
        if current == floor(current) {
            return String(Int(current))
        }
        return String(format: "%.1f", current)
    }
}
