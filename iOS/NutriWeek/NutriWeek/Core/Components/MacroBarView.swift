import SwiftUI

/// RN `results` macro row: label, `pct% · grams`, horizontal bar (track height **10**).
struct MacroBarView: View {
    let label: String
    let grams: Int
    let totalCalories: Int
    let caloriesPerGram: Int
    let color: Color

    private var percentage: Int {
        guard totalCalories > 0 else { return 0 }
        let pct = (Double(grams * caloriesPerGram * 100) / Double(totalCalories))
        return Int((pct).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(TypographyToken.inter(size: 14, weight: .semibold))
                    .foregroundStyle(ColorToken.textPrimary)
                Spacer(minLength: 0)
                Text("\(percentage)% · \(grams)g")
                    .font(TypographyToken.inter(size: 13, weight: .regular))
                    .foregroundStyle(ColorToken.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(ColorToken.muted)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color)
                        .frame(width: max(0, geo.size.width * CGFloat(percentage) / 100), height: 10)
                }
            }
            .frame(height: 10)
        }
    }
}
