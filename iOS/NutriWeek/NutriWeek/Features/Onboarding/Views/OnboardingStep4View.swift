import SwiftUI

struct OnboardingStep4View: View {
    @Bindable var coordinator: OnboardingCoordinator

    @State private var selected: Set<String> = []
    @State private var saving = false
    @State private var errorMessage: String?

    private let options: [(String, String, String)] = [
        ("everything", "🥩", "Everything"),
        ("vegetarian", "🥬", "Vegetarian"),
        ("vegan", "🌱", "Vegan"),
        ("gluten_free", "🌾", "Gluten Free"),
        ("lactose_free", "🥛", "Lactose Free"),
        ("halal", "✅", "Halal"),
        ("no_pork", "🐷", "No Pork"),
        ("no_seafood", "🐟", "No Seafood"),
    ]

    private var rockyMessage: String {
        let keys = Array(selected)
        if keys.isEmpty { return "Any food rules I should know about? 🦝🍽️" }
        if keys.contains("everything") { return "My kind of human! 🦝🍕🍗🥗" }
        if keys.contains("vegan") { return "A fellow plant lover! 🦝🌱" }
        if keys.contains("gluten_free") { return "Got it, no bread crimes! 🦝🌾" }
        if keys.contains("halal") { return "Noted! Clean eating all the way 🦝✅" }
        if keys.count > 1 { return "Complex taste! I respect it 🦝" }
        return "Any food rules I should know about? 🦝🍽️"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                OnboardingHeaderRow(currentStep: 4, totalSteps: 4, trailing: .spacer)

                VStack(spacing: 0) {
                    RockyMascotView(mood: .happy, size: 64, message: rockyMessage)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, OnboardingMetrics.mascotTop)
                .padding(.bottom, 24)

                Text("Dietary Preferences")
                    .font(TypographyToken.inter(size: 26, weight: .bold))
                    .foregroundStyle(ColorToken.textPrimary)
                    .padding(.bottom, 4)

                Text("Select all that apply")
                    .font(TypographyToken.inter(size: 14, weight: .regular))
                    .foregroundStyle(ColorToken.textSecondary)
                    .padding(.bottom, 20)

                VStack(spacing: 12) {
                    ForEach(0 ..< (options.count + 1) / 2, id: \.self) { rowIndex in
                        HStack(spacing: 12) {
                            let i = rowIndex * 2
                            pill(key: options[i].0, emoji: options[i].1, label: options[i].2)
                            if i + 1 < options.count {
                                pill(key: options[i + 1].0, emoji: options[i + 1].1, label: options[i + 1].2)
                            } else {
                                Spacer(minLength: 0)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }

                OnboardingFooterButton(
                    title: "See My Results",
                    isPrimaryEnabled: true,
                    isLoading: saving,
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
    }

    @ViewBuilder
    private func pill(key: String, emoji: String, label: String) -> some View {
        let isOn = selected.contains(key)
        Button {
            applyDietToggle(key)
        } label: {
            HStack(spacing: 8) {
                Text(emoji).font(.system(size: 18))
                Text(label)
                    .font(TypographyToken.inter(size: 14, weight: .semibold))
                    .foregroundStyle(isOn ? Color.white : ColorToken.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isOn ? ColorToken.primary : ColorToken.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isOn ? ColorToken.primary : Color(hex: "#E0E0E0"), lineWidth: 1.5)
            )
            .shadow(color: ColorToken.shadow.opacity(0.06), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func applyDietToggle(_ key: String) {
        Haptics.selection()
        if key == "everything" {
            if selected.contains("everything") {
                selected.removeAll()
            } else {
                selected = ["everything"]
            }
            return
        }
        var items: [String] = selected.filter { $0 != "everything" }
        if let i = items.firstIndex(of: key) {
            items.remove(at: i)
        } else {
            items.append(key)
        }
        selected = Set(items)
    }

    private func handleContinue() async {
        guard !saving else { return }
        Haptics.impactMedium()
        errorMessage = nil
        saving = true
        defer { saving = false }
        do {
            try await OnboardingService.saveStep4(dietaryPreferences: Array(selected))
            coordinator.goToResults()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
