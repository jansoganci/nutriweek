import SwiftUI

// MARK: - RN onboarding spacing (steps 1–4 content, not results)

enum OnboardingMetrics {
    static let horizontalPadding: CGFloat = 20
    static let padTopExtra: CGFloat = 16
    static let padBottomExtra: CGFloat = 24
    static let mascotTop: CGFloat = 20
    static let mascotBottomStep1_2_4: CGFloat = 28
    static let mascotBottomStep3: CGFloat = 24
    static let sectionLabelTop: CGFloat = 20
    static let sectionLabelBottom: CGFloat = 8
    static let continueTop: CGFloat = 28
    static let continueTopStep2: CGFloat = 32
    static let errorTop: CGFloat = 12
}

/// Primary footer CTA: **radius 16**, **padding V 16**; disabled **#CCCCCC** (RN steps 1–2).
struct OnboardingFooterButton: View {
    let title: String
    let isPrimaryEnabled: Bool
    var isLoading: Bool = false
    var marginTop: CGFloat = OnboardingMetrics.continueTop
    let action: () -> Void

    var body: some View {
         Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(Color.white)
                } else {
                    Text(title)
                        .font(TypographyToken.font(.body, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isPrimaryEnabled && !isLoading ? ColorToken.primary : Color(hex: "#CCCCCC"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .padding(.top, marginTop)
    }
}

struct OnboardingSectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(TypographyToken.inter(size: 13, weight: .semibold))
            .foregroundStyle(ColorToken.textSecondary)
            .tracking(0.8)
            .padding(.top, OnboardingMetrics.sectionLabelTop)
            .padding(.bottom, OnboardingMetrics.sectionLabelBottom)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OnboardingHeaderRow: View {
    @Environment(\.dismiss) private var dismiss

    let currentStep: Int
    let totalSteps: Int
    var trailing: Trailing = .spacer

    enum Trailing {
        case spacer
        case skip(action: () -> Void)
    }

    var body: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                Text("‹")
                    .font(TypographyToken.inter(size: 28, weight: .semibold))
                    .foregroundStyle(ColorToken.textPrimary)
                    .frame(width: 40, alignment: .leading)
            }
            .buttonStyle(.plain)

            StepProgressView(currentStep: currentStep, totalSteps: totalSteps)
                .frame(maxWidth: .infinity)

            switch trailing {
            case .spacer:
                Color.clear.frame(width: 60, height: 44)
            case .skip(let action):
                Button(action: action) {
                    Text("Skip")
                        .font(TypographyToken.inter(size: 15, weight: .semibold))
                        .foregroundStyle(ColorToken.primary)
                }
                .buttonStyle(.plain)
                .frame(width: 60, alignment: .trailing)
            }
        }
    }
}
