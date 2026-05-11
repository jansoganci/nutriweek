import SwiftUI

struct OnboardingResultsView: View {
    @Bindable var coordinator: OnboardingCoordinator

    @State private var loaded = false
    @State private var results: CalculationResults = .fallback
    @State private var goal: Goal = .maintain
    @State private var saving = false
    @State private var errorMessage: String?

    private var rockyMessage: String {
        switch results.bmiCategory.label {
        case "Healthy": return "Looking good! Now let's eat right ✨"
        case "Underweight": return "We'll get you fueled up properly! 💪"
        case "Overweight": return "No worries, Rocky's got your back! ❤️"
        default: return "Every journey starts with one step. Let's go! 🌟"
        }
    }

    private var bmiIndicatorPercent: CGFloat {
        let bmiMin = 15.0
        let bmiMax = 40.0
        let raw = ((results.bmi - bmiMin) / (bmiMax - bmiMin)) * 100
        return CGFloat(min(max(raw, 2), 98))
    }

    var body: some View {
        Group {
            if !loaded {
                VStack(spacing: 12) {
                    RockyMascotView(mood: .thinking, size: RockyMascotView.Size.medium.rawValue)
                    Text("Crunching your numbers…")
                        .font(TypographyToken.inter(size: 15, weight: .regular))
                        .foregroundStyle(ColorToken.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ColorToken.background)
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        VStack(spacing: SpacingToken.xs) {
                            RockyVideoView(.celebrate, loop: false)
                                .frame(width: 88, height: 88)
                                .clipShape(RoundedRectangle(cornerRadius: 88 * 0.12, style: .continuous))

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
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 4)

                        Text("Your plan is ready!")
                            .font(TypographyToken.inter(size: 28, weight: .bold))
                            .foregroundStyle(ColorToken.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Text("Here's what we calculated for you")
                            .font(TypographyToken.inter(size: 15, weight: .regular))
                            .foregroundStyle(ColorToken.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 4)

                        bmiCard
                        dailyTargetsCard
                        macroSplitCard
                        goalCard

                        Button {
                            Task { await handleStart() }
                        } label: {
                            Group {
                                if saving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Let's Start!")
                                        .font(TypographyToken.inter(size: 18, weight: .bold))
                                        .foregroundStyle(Color.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(ColorToken.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: ColorToken.primary.opacity(0.3), radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(saving)
                        .padding(.top, 6)

                        if let errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(TypographyToken.inter(size: 13, weight: .regular))
                                .foregroundStyle(ColorToken.destructive)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(ColorToken.background)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await load() }
        .onChange(of: loaded) { _, isLoaded in
            if isLoaded && results.bmi == 0 {
                coordinator.reset()
            }
        }
    }

    private var bmiCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your BMI")
                .font(TypographyToken.inter(size: 13, weight: .semibold))
                .foregroundStyle(ColorToken.textSecondary)
                .tracking(0.8)
                .textCase(.uppercase)
                .padding(.bottom, 14)

            VStack(spacing: 8) {
                Text(String(format: "%.1f", results.bmi))
                    .font(TypographyToken.inter(size: 52, weight: .bold))
                    .foregroundStyle(ColorToken.textPrimary)

                Text(results.bmiCategory.label)
                    .font(TypographyToken.inter(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: results.bmiCategory.colorHex))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(Color(hex: results.bmiCategory.colorHex).opacity(0.13))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)

            bmiScale
        }
        .padding(20)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        )
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    private var bmiScale: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                let flex: [CGFloat] = [1, 2, 1.5, 2]
                let sum = flex.reduce(0, +)
                ZStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(hex: "#FFB300"))
                            .frame(width: w * flex[0] / sum)
                        Rectangle()
                            .fill(ColorToken.success)
                            .frame(width: w * flex[1] / sum)
                        Rectangle()
                            .fill(Color(hex: "#FFB300"))
                            .frame(width: w * flex[2] / sum)
                        Rectangle()
                            .fill(Color(hex: "#FF4444"))
                            .frame(width: w * flex[3] / sum)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    Circle()
                        .fill(ColorToken.textPrimary)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(ColorToken.card, lineWidth: 3))
                        .shadow(color: ColorToken.shadow.opacity(0.2), radius: 3, x: 0, y: 1)
                        .offset(x: w * bmiIndicatorPercent / 100 - 9, y: -4)
                }
            }
            .frame(height: 18)

            HStack {
                Text("15")
                Spacer()
                Text("18.5")
                Spacer()
                Text("25")
                Spacer()
                Text("30")
                Spacer()
                Text("40")
            }
            .font(TypographyToken.inter(size: 10, weight: .regular))
            .foregroundStyle(ColorToken.textTertiary)
        }
    }

    private var dailyTargetsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your Daily Targets")
                .font(TypographyToken.inter(size: 13, weight: .semibold))
                .foregroundStyle(ColorToken.textSecondary)
                .tracking(0.8)
                .textCase(.uppercase)
                .padding(.bottom, 14)

            VStack(spacing: 0) {
                statRow(emoji: "🔥", label: "Calories", value: "\(results.targetCalories) kcal")
                Divider().background(ColorToken.border)
                statRow(emoji: "🥩", label: "Protein", value: "\(results.macros.protein) g")
                Divider().background(ColorToken.border)
                statRow(emoji: "🍚", label: "Carbs", value: "\(results.macros.carbs) g")
                Divider().background(ColorToken.border)
                statRow(emoji: "🥑", label: "Fat", value: "\(results.macros.fat) g")
            }
        }
        .padding(20)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        )
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    private func statRow(emoji: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji).font(.system(size: 20)).frame(width: 28, alignment: .center)
            Text(label)
                .font(TypographyToken.inter(size: 15, weight: .medium))
                .foregroundStyle(ColorToken.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(TypographyToken.inter(size: 16, weight: .bold))
                .foregroundStyle(ColorToken.textPrimary)
        }
        .padding(.vertical, 10)
    }

    private var macroSplitCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Macro Split")
                .font(TypographyToken.inter(size: 13, weight: .semibold))
                .foregroundStyle(ColorToken.textSecondary)
                .tracking(0.8)
                .textCase(.uppercase)
                .padding(.bottom, 14)

            VStack(spacing: 14) {
                MacroBarView(
                    label: "Protein",
                    grams: results.macros.protein,
                    totalCalories: results.targetCalories,
                    caloriesPerGram: 4,
                    color: ColorToken.primary
                )
                MacroBarView(
                    label: "Carbs",
                    grams: results.macros.carbs,
                    totalCalories: results.targetCalories,
                    caloriesPerGram: 4,
                    color: ColorToken.success
                )
                MacroBarView(
                    label: "Fat",
                    grams: results.macros.fat,
                    totalCalories: results.targetCalories,
                    caloriesPerGram: 9,
                    color: ColorToken.warning
                )
            }
        }
        .padding(20)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        )
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    private var goalCard: some View {
        let meta = goalMeta(goal)
        return VStack(alignment: .leading, spacing: 0) {
            Text("Your Goal")
                .font(TypographyToken.inter(size: 13, weight: .semibold))
                .foregroundStyle(ColorToken.textSecondary)
                .tracking(0.8)
                .textCase(.uppercase)
                .padding(.bottom, 14)

            HStack(alignment: .center, spacing: 14) {
                Text(meta.emoji).font(.system(size: 36))
                VStack(alignment: .leading, spacing: 2) {
                    Text(meta.title)
                        .font(TypographyToken.inter(size: 17, weight: .bold))
                        .foregroundStyle(ColorToken.textPrimary)
                    Text(meta.desc)
                        .font(TypographyToken.inter(size: 13, weight: .regular))
                        .foregroundStyle(ColorToken.textSecondary)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(20)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        )
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    private func goalMeta(_ g: Goal) -> (emoji: String, title: String, desc: String) {
        switch g {
        case .cut: return ("🔥", "Lose Fat", "500 kcal daily deficit")
        case .bulk: return ("💪", "Build Muscle", "300 kcal daily surplus")
        case .maintain: return ("⚖️", "Stay Balanced", "Eating at maintenance")
        }
    }

    private func load() async {
        do {
            let profile = try await OnboardingService.fetchOnboardingProfile()
            guard let user = UserProfile(onboarding: profile) else {
                results = .fallback
                goal = .maintain
                loaded = true
                return
            }
            let calc = NutritionCalculationService.calculateAll(profile: user)
            results = calc
            goal = user.goal
        } catch {
            errorMessage = error.localizedDescription
            results = .fallback
        }
        loaded = true
    }

    private func handleStart() async {
        guard !saving else { return }
        Haptics.success()
        saving = true
        defer { saving = false }
        errorMessage = nil
        do {
            try await OnboardingService.saveCalculatedResults(results)
            coordinator.finish()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension CalculationResults {
    static var fallback: CalculationResults {
        CalculationResults(
            bmi: 0,
            bmiCategory: BMICategory(label: "Healthy", colorHex: "#4CAF50"),
            bmr: 0,
            tdee: 0,
            targetCalories: 0,
            macros: MacroGrams(protein: 0, carbs: 0, fat: 0),
            macroPercentages: MacroPercentages(protein: 30, carbs: 45, fat: 25)
        )
    }
}
