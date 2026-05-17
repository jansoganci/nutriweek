import SwiftUI

struct OnboardingStep2View: View {
    @Bindable var coordinator: OnboardingCoordinator

    @State private var goal: Goal?
    @State private var saving = false
    @State private var errorMessage: String?

    private let cards: [(Goal, String, LocalizedStringKey, LocalizedStringKey)] = [
        (.cut, "🔥", LocalizedStringKey("goal.cut.short"), LocalizedStringKey("goal.cut.subtitle")),
        (.bulk, "💪", LocalizedStringKey("goal.bulk.short"), LocalizedStringKey("goal.bulk.subtitle")),
        (.maintain, "⚖️", LocalizedStringKey("goal.maintain.short"), LocalizedStringKey("goal.maintain.subtitle")),
    ]

    private var rockyMessage: String {
        guard let goal else {
            return String(localized: "onboarding.goal.prompt")
        }
        switch goal {
        case .cut: return String(localized: "onboarding.goal.rocky.cut")
        case .bulk: return String(localized: "onboarding.goal.rocky.bulk")
        case .maintain: return String(localized: "onboarding.goal.rocky.maintain")
        }
    }

    private var isComplete: Bool { goal != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                OnboardingHeaderRow(currentStep: 2, totalSteps: 4, trailing: .spacer)

                VStack(spacing: 0) {
                    RockyMascotView(mood: .happy, size: 64, message: rockyMessage)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, OnboardingMetrics.mascotTop)
                .padding(.bottom, OnboardingMetrics.mascotBottomStep1_2_4)

                Text(LocalizedStringKey("onboarding.goal.title"))
                    .font(TypographyToken.inter(size: 26, weight: .bold))
                    .foregroundStyle(ColorToken.textPrimary)
                    .padding(.bottom, 20)

                VStack(spacing: 14) {
                    ForEach(cards, id: \.0) { item in
                        goalCard(goal: item.0, emoji: item.1, title: item.2, subtitle: item.3)
                    }
                }

                OnboardingFooterButton(
                    title: String(localized: "common.continue"),
                    isPrimaryEnabled: isComplete && !saving,
                    isLoading: saving,
                    marginTop: OnboardingMetrics.continueTopStep2,
                    action: { Task { await handleContinue() } }
                )

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(TypographyToken.inter(size: 13, weight: .regular))
                        .foregroundStyle(ColorToken.destructive)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, OnboardingMetrics.errorTop)
                }
            }
            .padding(.horizontal, OnboardingMetrics.horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(ColorToken.background)
        .toolbar(.hidden, for: .navigationBar)
        .task { await prefill() }
    }

    @ViewBuilder
    private func goalCard(goal g: Goal, emoji: String, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        let selected = goal == g
        Button {
            goal = g
            Haptics.selection()
        } label: {
            ZStack(alignment: .topTrailing) {
                if selected {
                    ZStack {
                        Circle()
                            .fill(ColorToken.primary)
                            .frame(width: 24, height: 24)
                        Text("✓")
                            .font(TypographyToken.inter(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                    .padding(.top, 14)
                    .padding(.trailing, 14)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(emoji)
                        .font(.system(size: 36))
                        .padding(.bottom, 10)
                    Text(title)
                        .font(TypographyToken.inter(size: 20, weight: .bold))
                        .foregroundStyle(selected ? ColorToken.primary : ColorToken.textPrimary)
                    Text(subtitle)
                        .font(TypographyToken.inter(size: 14, weight: .regular))
                        .foregroundStyle(ColorToken.textSecondary)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
            }
            .background(selected ? Color(hex: "#FFF3EE") : ColorToken.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? ColorToken.primary : Color(hex: "#E0E0E0"), lineWidth: 2)
            )
            .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func prefill() async {
        guard let p = try? await OnboardingService.fetchOnboardingProfile() else { return }
        goal = p.goal ?? goal
    }

    private func handleContinue() async {
        guard isComplete, let goal, !saving else { return }
        Haptics.impactMedium()
        errorMessage = nil
        saving = true
        defer { saving = false }
        do {
            try await OnboardingService.saveStep2(goal: goal)
            coordinator.goToStep3()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
