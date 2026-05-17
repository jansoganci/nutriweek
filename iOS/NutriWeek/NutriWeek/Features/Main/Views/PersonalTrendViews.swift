import SwiftUI

struct PersonalTrendSectionView: View {
    let snapshot: PersonalInsightsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(LocalizedStringKey("personal.trends.title"))
                    .font(TypographyToken.inter(size: 20, weight: .bold))
                    .foregroundStyle(ColorToken.textPrimary)
                Spacer(minLength: 0)
                Text(LocalizedStringKey("personal.trends.subtitle"))
                    .font(TypographyToken.inter(size: 12, weight: .regular))
                    .foregroundStyle(ColorToken.textSecondary)
            }

            VStack(spacing: 10) {
                TrendCard(
                    title: String(localized: "personal.trends.calories_in"),
                    accent: ColorToken.primary,
                    points: snapshot.caloriesIn,
                    valueSuffix: "kcal"
                )
                TrendCard(
                    title: String(localized: "personal.trends.calories_out"),
                    accent: Color(hex: "#4CAF50"),
                    points: snapshot.caloriesBurned,
                    valueSuffix: "kcal"
                )
                TrendCard(
                    title: String(localized: "personal.trends.weight"),
                    accent: Color(hex: "#FFB300"),
                    points: snapshot.weightTrend,
                    valueSuffix: "kg"
                )
            }
        }
        .padding(16)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ColorToken.border, lineWidth: BorderToken.hairline)
        )
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }
}

private struct TrendCard: View {
    let title: String
    let accent: Color
    let points: [TrendPoint]
    let valueSuffix: String

    private var maxValue: Double {
        max(points.map(\.value).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(TypographyToken.inter(size: 13, weight: .semibold))
                    .foregroundStyle(ColorToken.textPrimary)
                Spacer(minLength: 0)
                Text(lastValueText)
                    .font(TypographyToken.inter(size: 12, weight: .medium))
                    .foregroundStyle(ColorToken.textSecondary)
            }

            TrendSparkline(points: points, accent: accent, maxValue: maxValue)
                .frame(height: 56)

            HStack {
                ForEach(points.prefix(4)) { point in
                    VStack(spacing: 2) {
                        Text(point.dateLabel)
                            .font(TypographyToken.inter(size: 10, weight: .regular))
                            .foregroundStyle(ColorToken.textTertiary)
                        Text(valueString(point.value))
                            .font(TypographyToken.inter(size: 11, weight: .semibold))
                            .foregroundStyle(ColorToken.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(12)
        .background(ColorToken.background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        )
    }

    private var lastValueText: String {
        guard let last = points.last else { return "—" }
        return "\(valueString(last.value)) \(valueSuffix)"
    }

    private func valueString(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

private struct TrendSparkline: View {
    let points: [TrendPoint]
    let accent: Color
    let maxValue: Double

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let linePoints = normalizedPoints(in: size)
            ZStack {
                if linePoints.count > 1 {
                    Path { path in
                        path.addLines(linePoints)
                    }
                    .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    Path { path in
                        guard let first = linePoints.first, let last = linePoints.last else { return }
                        path.addLines(linePoints)
                        path.addLine(to: CGPoint(x: last.x, y: size.height))
                        path.addLine(to: CGPoint(x: first.x, y: size.height))
                        path.closeSubpath()
                    }
                    .fill(accent.opacity(0.10))
                } else if let point = linePoints.first {
                    Circle()
                        .fill(accent)
                        .frame(width: 10, height: 10)
                        .position(point)
                }
            }
        }
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        let count = max(points.count - 1, 1)
        return points.enumerated().map { index, point in
            let x = size.width * CGFloat(index) / CGFloat(count)
            let ratio = maxValue > 0 ? min(point.value / maxValue, 1) : 0
            let y = size.height - (size.height * CGFloat(ratio))
            return CGPoint(x: x, y: y)
        }
    }
}
