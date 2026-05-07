import SwiftUI

/// RN `StepProgress`: label `current/total`, pill dots (active **24×8**, inactive **8×8**).
struct StepProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    var showLabel: Bool = true

    var body: some View {
        VStack(spacing: SpacingToken.xs) {
            if showLabel {
                Text("\(currentStep)/\(totalSteps)")
                    .font(TypographyToken.inter(size: 13, weight: .medium))
                    .foregroundStyle(ColorToken.textSecondary)
            }
            HStack(spacing: 6) {
                ForEach(0 ..< totalSteps, id: \.self) { index in
                    let isCompleted = index < currentStep - 1
                    let isActive = index == currentStep - 1
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(fillColor(isCompleted: isCompleted, isActive: isActive))
                        .frame(width: isActive ? 24 : 8, height: 8)
                        .opacity(isCompleted ? 0.5 : 1)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func fillColor(isCompleted: Bool, isActive: Bool) -> Color {
        if isActive || isCompleted { return ColorToken.primary }
        return ColorToken.muted
    }
}
