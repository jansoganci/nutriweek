import SwiftUI

struct OnboardingStep3View: View {
    @Bindable var coordinator: OnboardingCoordinator

    @State private var waist = ""
    @State private var hips = ""
    @State private var chest = ""
    @State private var arm = ""
    @State private var leg = ""
    @State private var hasTyped = false
    @State private var saving = false
    @State private var errorMessage: String?

    private var rockyMessage: String {
        hasTyped
            ? "Look at you, being all precise! 🦝📏"
            : "Don't worry, these are just for YOU. No judging here! 🦝"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                OnboardingHeaderRow(
                    currentStep: 3,
                    totalSteps: 4,
                    trailing: .skip {
                        Haptics.selection()
                        coordinator.goToStep4()
                    }
                )

                VStack(spacing: 0) {
                    RockyMascotView(mood: .encouraging, size: 64, message: rockyMessage)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, OnboardingMetrics.mascotTop)
                .padding(.bottom, OnboardingMetrics.mascotBottomStep3)

                Text("Body Measurements")
                    .font(TypographyToken.inter(size: 26, weight: .bold))
                    .foregroundStyle(ColorToken.textPrimary)
                    .padding(.bottom, 4)

                Text("All optional — skip if you prefer")
                    .font(TypographyToken.inter(size: 14, weight: .regular))
                    .foregroundStyle(ColorToken.textSecondary)
                    .padding(.bottom, 20)

                VStack(spacing: 12) {
                    measurementRow(label: "Waist", placeholder: "80", text: $waist)
                    measurementRow(label: "Hips", placeholder: "95", text: $hips)
                    measurementRow(label: "Chest", placeholder: "90", text: $chest)
                    measurementRow(label: "Left Arm", placeholder: "35", text: $arm)
                    measurementRow(label: "Left Leg", placeholder: "55", text: $leg)
                }

                OnboardingFooterButton(
                    title: "Continue",
                    isPrimaryEnabled: true,
                    isLoading: saving,
                    action: { Task { await saveAndNavigate() } }
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
        .onChange(of: waist) { _, _ in hasTyped = true }
        .onChange(of: hips) { _, _ in hasTyped = true }
        .onChange(of: chest) { _, _ in hasTyped = true }
        .onChange(of: arm) { _, _ in hasTyped = true }
        .onChange(of: leg) { _, _ in hasTyped = true }
    }

    private func measurementRow(label: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(TypographyToken.inter(size: 15, weight: .semibold))
                .foregroundStyle(ColorToken.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                TextField(
                    "",
                    text: text,
                    prompt: Text(placeholder).foregroundStyle(ColorToken.textTertiary)
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(TypographyToken.inter(size: 16, weight: .semibold))
                .foregroundStyle(ColorToken.textPrimary)
                .frame(minWidth: 60)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(ColorToken.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("cm")
                    .font(TypographyToken.inter(size: 14, weight: .medium))
                    .foregroundStyle(ColorToken.textSecondary)
                    .frame(width: 24, alignment: .leading)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1.5)
        )
        .shadow(color: ColorToken.shadow.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func parseOpt(_ s: String) -> Double? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        return Double(t.replacingOccurrences(of: ",", with: "."))
    }

    private func saveAndNavigate() async {
        guard !saving else { return }
        Haptics.impactMedium()
        errorMessage = nil
        saving = true
        defer { saving = false }
        do {
            try await OnboardingService.saveStep3(
                waistCm: parseOpt(waist),
                hipsCm: parseOpt(hips),
                chestCm: parseOpt(chest),
                leftArmCm: parseOpt(arm),
                leftLegCm: parseOpt(leg)
            )
            coordinator.goToStep4()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
