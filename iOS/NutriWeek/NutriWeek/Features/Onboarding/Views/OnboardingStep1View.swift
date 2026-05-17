import SwiftUI

struct OnboardingStep1View: View {
    @Bindable var coordinator: OnboardingCoordinator

    @State private var gender: Gender?
    @State private var age = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var goal: Goal?
    @State private var activityLevel: ActivityLevel?
    @State private var saving = false
    @State private var errorMessage: String?

    @State private var shakeGender: CGFloat = 0
    @State private var shakeAge: CGFloat = 0
    @State private var shakeHeight: CGFloat = 0
    @State private var shakeWeight: CGFloat = 0
    @State private var shakeActivity: CGFloat = 0

    private var rockyMessage: String {
        guard let goal else {
            return String(localized: "onboarding.step1.rocky.intro")
        }
        switch goal {
        case .cut: return String(localized: "onboarding.step1.rocky.cut")
        case .bulk: return String(localized: "onboarding.step1.rocky.bulk")
        case .maintain: return String(localized: "onboarding.step1.rocky.maintain")
        }
    }

    private var isComplete: Bool {
        gender != nil
            && !age.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !height.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !weight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && activityLevel != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                StepProgressView(currentStep: 1, totalSteps: 4)

                VStack(spacing: 0) {
                    VStack(spacing: SpacingToken.xs) {
                        RockyVideoView(.wave)
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 64 * 0.12, style: .continuous))

                        Text(rockyMessage)
                            .font(TypographyToken.inter(size: 14, weight: .regular))
                            .foregroundStyle(ColorToken.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(TypographyToken.LineHeight.tight - 14)
                            .padding(.horizontal, SpacingToken.md)
                            .padding(.vertical, 10)
                            .frame(maxWidth: 240)
                            .background(ColorToken.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(ColorToken.border, lineWidth: BorderToken.hairline)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, OnboardingMetrics.mascotTop)
                .padding(.bottom, OnboardingMetrics.mascotBottomStep1_2_4)

                OnboardingSectionLabel(text: String(localized: "profile.field.gender"))
                HStack(spacing: 10) {
                    ForEach(Gender.allCases, id: \.self) { g in
                        let selected = gender == g
                        Button {
                            gender = g
                            Haptics.selection()
                        } label: {
                            Text(genderLabel(g))
                                .font(TypographyToken.inter(size: 14, weight: .semibold))
                                .foregroundStyle(selected ? ColorToken.primary : ColorToken.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selected ? Color(hex: "#FFF3EE") : ColorToken.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(selected ? ColorToken.primary : ColorToken.border, lineWidth: 1.5)
                                )
                                .shadow(color: ColorToken.shadow.opacity(0.06), radius: 4, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .offset(x: shakeGender)

                OnboardingSectionLabel(text: String(localized: "profile.field.age"))
                TextField("", text: $age, prompt: Text("25").foregroundStyle(ColorToken.textTertiary))
                    .keyboardType(.numberPad)
                    .font(TypographyToken.font(.body))
                    .foregroundStyle(ColorToken.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(ColorToken.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(ColorToken.border, lineWidth: 1.5)
                    )
                    .shadow(color: ColorToken.shadow.opacity(0.06), radius: 4, x: 0, y: 1)
                    .offset(x: shakeAge)

                OnboardingSectionLabel(text: String(localized: "profile.field.height_cm"))
                TextField("", text: $height, prompt: Text("175").foregroundStyle(ColorToken.textTertiary))
                    .keyboardType(.decimalPad)
                    .font(TypographyToken.font(.body))
                    .foregroundStyle(ColorToken.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(ColorToken.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(ColorToken.border, lineWidth: 1.5)
                    )
                    .shadow(color: ColorToken.shadow.opacity(0.06), radius: 4, x: 0, y: 1)
                    .offset(x: shakeHeight)

                OnboardingSectionLabel(text: String(localized: "profile.measurements.weight_kg"))
                TextField("", text: $weight, prompt: Text("70").foregroundStyle(ColorToken.textTertiary))
                    .keyboardType(.decimalPad)
                    .font(TypographyToken.font(.body))
                    .foregroundStyle(ColorToken.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(ColorToken.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(ColorToken.border, lineWidth: 1.5)
                    )
                    .shadow(color: ColorToken.shadow.opacity(0.06), radius: 4, x: 0, y: 1)
                    .offset(x: shakeWeight)

                OnboardingSectionLabel(text: String(localized: "profile.field.activity_level"))
                VStack(spacing: 0) {
                    ForEach(activityOptions, id: \.0) { opt in
                        activityRow(value: opt.0, label: opt.1, description: opt.2)
                    }
                }
                .offset(x: shakeActivity)

                OnboardingFooterButton(
                    title: String(localized: "common.continue"),
                    isPrimaryEnabled: isComplete && !saving,
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
        .task {
            await prefill()
        }
    }

    private var activityOptions: [(ActivityLevel, String, String)] {
        [
            (.sedentary, String(localized: "activity.sedentary"), String(localized: "onboarding.step1.activity.sedentary_desc")),
            (.lightlyActive, String(localized: "activity.lightly_active"), String(localized: "onboarding.step1.activity.lightly_active_desc")),
            (.moderatelyActive, String(localized: "activity.moderately_active"), String(localized: "onboarding.step1.activity.moderately_active_desc")),
            (.veryActive, String(localized: "activity.very_active"), String(localized: "onboarding.step1.activity.very_active_desc")),
            (.extraActive, String(localized: "activity.extra_active"), String(localized: "onboarding.step1.activity.extra_active_desc")),
        ]
    }

    private func genderLabel(_ gender: Gender) -> String {
        switch gender {
        case .male: return String(localized: "onboarding.step1.gender.male")
        case .female: return String(localized: "onboarding.step1.gender.female")
        case .other: return String(localized: "onboarding.step1.gender.other")
        }
    }

    @ViewBuilder
    private func activityRow(value: ActivityLevel, label: String, description: String) -> some View {
        let selected = activityLevel == value
        Button {
            activityLevel = value
            Haptics.selection()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(selected ? ColorToken.primary : ColorToken.border, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle()
                            .fill(ColorToken.primary)
                            .frame(width: 10, height: 10)
                    }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(TypographyToken.inter(size: 15, weight: .semibold))
                        .foregroundStyle(selected ? ColorToken.primary : ColorToken.textPrimary)
                    Text(description)
                        .font(TypographyToken.inter(size: 13, weight: .regular))
                        .foregroundStyle(ColorToken.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(selected ? Color(hex: "#FFF3EE") : ColorToken.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? ColorToken.primary : ColorToken.border, lineWidth: 1.5)
            )
            .shadow(color: ColorToken.shadow.opacity(0.06), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 10)
    }

    private func prefill() async {
        guard let p = try? await OnboardingService.fetchOnboardingProfile() else { return }
        gender = p.gender ?? gender
        goal = p.goal ?? goal
        if let a = p.age { age = String(a) }
        if let h = p.heightCm { height = formatNum(h) }
        if let w = p.weightKg { weight = formatNum(w) }
        activityLevel = p.activityLevel ?? activityLevel
    }

    private func formatNum(_ d: Double) -> String {
        d == floor(d) ? String(Int(d)) : String(d)
    }

    private func handleContinue() async {
        guard isComplete, !saving else {
            Haptics.warning()
            if gender == nil { nudge($shakeGender) }
            if age.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { nudge($shakeAge) }
            if height.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { nudge($shakeHeight) }
            if weight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { nudge($shakeWeight) }
            if activityLevel == nil { nudge($shakeActivity) }
            return
        }

        guard let gender, let activityLevel,
              let ageVal = Int(age.trimmingCharacters(in: .whitespacesAndNewlines)),
              let h = Double(height.replacingOccurrences(of: ",", with: ".")),
              let w = Double(weight.replacingOccurrences(of: ",", with: "."))
        else { return }

        Haptics.impactMedium()
        errorMessage = nil
        saving = true
        defer { saving = false }

        do {
            try await OnboardingService.saveStep1(
                gender: gender,
                age: ageVal,
                heightCm: h,
                weightKg: w,
                activityLevel: activityLevel
            )
            coordinator.goToStep2()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func nudge(_ binding: Binding<CGFloat>) {
        withAnimation(.easeInOut(duration: 0.05)) { binding.wrappedValue = 8 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.05)) { binding.wrappedValue = -8 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: 0.04)) { binding.wrappedValue = 0 }
            }
        }
    }
}
