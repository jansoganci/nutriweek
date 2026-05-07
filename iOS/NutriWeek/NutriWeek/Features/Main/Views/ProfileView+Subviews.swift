import SwiftUI

extension ProfileView {
    var loadingView: some View {
        VStack {
            if let loadingError, !loadingError.isEmpty {
                ErrorStateView(
                    title: "Profile failed to load",
                    message: loadingError,
                    retryTitle: "Retry"
                ) {
                    Task { await loadProfile() }
                }
            } else {
                VStack(spacing: 10) {
                    LoadingSkeletonView(variant: .card)
                    LoadingSkeletonView(variant: .listRow)
                    LoadingSkeletonView(variant: .listRow)
                }
            }
        }
        .padding(.horizontal, SpacingToken.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorToken.background)
    }

    func content(profile: UserProfile, results: CalculationResults) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    Text("My Profile").font(TypographyToken.inter(size: 20, weight: .bold)).foregroundStyle(ColorToken.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                    rockyHeader(for: profile.goal)
                    statsRow(profile: profile, results: results)
                    dailyTargetsCard(results: results)
                    personalInfoCard(profile: profile)
                    measurementsCard(profile: profile)
                    settingsCard
                }
                .padding(.horizontal, SpacingToken.gutter)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(ColorToken.background)
            .toolbar(.hidden, for: .navigationBar)

            if showToast {
                ToastView(title: toastMessage, style: .info)
                    .padding(.horizontal, SpacingToken.gutter)
                    .padding(.bottom, 110)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    func rockyHeader(for goal: Goal) -> some View {
        VStack(spacing: 8) {
            RockyMascotView(
                mood: mascotMood(for: goal),
                size: RockyMascotView.Size.large.rawValue
            )
            Text(rockyMessage(for: goal)).font(TypographyToken.inter(size: 14, weight: .medium)).foregroundStyle(ColorToken.onSecondary).multilineTextAlignment(.center).lineSpacing(2).padding(.horizontal, 16).padding(.vertical, 10).background(ColorToken.secondary).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func mascotMood(for goal: Goal) -> RockyMascotView.Mood {
        switch goal {
        case .cut:
            return .encouraging
        case .bulk:
            return .celebrating
        case .maintain:
            return .happy
        }
    }

    func statsRow(profile: UserProfile, results: CalculationResults) -> some View {
        HStack(spacing: 10) {
            statCard(label: "BMI", value: oneDecimal(results.bmi), sub: results.bmiCategory.label, subColor: Color(hex: results.bmiCategory.colorHex))
            statCard(label: "Daily Calories", value: "\(results.targetCalories)", sub: "kcal", subColor: nil)
            statCard(label: "Goal", value: goalLabel(profile.goal), sub: nil, subColor: nil)
        }
    }

    func statCard(label: String, value: String, sub: String?, subColor: Color?) -> some View {
        VStack(spacing: 2) {
            Text(value).font(TypographyToken.inter(size: 13, weight: .bold)).foregroundStyle(ColorToken.textPrimary).multilineTextAlignment(.center)
            if let sub { Text(sub).font(TypographyToken.inter(size: 11, weight: .semibold)).foregroundStyle(subColor ?? ColorToken.textSecondary).multilineTextAlignment(.center) }
            Text(label).font(TypographyToken.inter(size: 10, weight: .regular)).foregroundStyle(ColorToken.mutedForeground).multilineTextAlignment(.center).padding(.top, 2)
        }
        .frame(maxWidth: .infinity).padding(12).background(ColorToken.card).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).shadow(color: ColorToken.shadow.opacity(0.06), radius: 4, x: 0, y: 1)
    }

    func dailyTargetsCard(results: CalculationResults) -> some View {
        card {
            Text("Daily Targets").font(TypographyToken.inter(size: 16, weight: .bold)).foregroundStyle(ColorToken.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
            macroRow("🔥", "Calories", "\(results.targetCalories)", "kcal")
            divider
            macroRow("🥩", "Protein", "\(results.macros.protein)", "g")
            divider
            macroRow("🍚", "Carbs", "\(results.macros.carbs)", "g")
            divider
            macroRow("🥑", "Fat", "\(results.macros.fat)", "g")
        }
    }

    func macroRow(_ emoji: String, _ label: String, _ value: String, _ unit: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji).font(.system(size: 18)).frame(width: 28)
            Text(label).font(TypographyToken.inter(size: 14, weight: .regular)).foregroundStyle(ColorToken.textSecondary)
            Spacer(minLength: 0)
            Text("\(value) ").font(TypographyToken.inter(size: 15, weight: .bold)).foregroundStyle(ColorToken.textPrimary) + Text(unit).font(TypographyToken.inter(size: 12, weight: .regular)).foregroundStyle(ColorToken.mutedForeground)
        }
    }

    func personalInfoCard(profile: UserProfile) -> some View {
        card {
            HStack {
                Text("Personal Info").font(TypographyToken.inter(size: 16, weight: .bold)).foregroundStyle(ColorToken.textPrimary)
                Spacer(minLength: 0)
                if editingInfo {
                    HStack(spacing: 8) {
                        Button("Cancel") { infoDraft = infoFields; editingInfo = false; clearFieldErrors() }
                            .font(TypographyToken.inter(size: 13, weight: .semibold)).foregroundStyle(ColorToken.textSecondary).padding(.horizontal, 12).padding(.vertical, 5).background(ColorToken.muted).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
                        Button("Save") { Task { await handleSaveInfo() } }
                            .font(TypographyToken.inter(size: 13, weight: .semibold)).foregroundStyle(ColorToken.onPrimary).padding(.horizontal, 14).padding(.vertical, 5).background(ColorToken.primary).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
                    }
                } else {
                    Button("Edit") { infoDraft = infoFields; editingInfo = true }
                        .font(TypographyToken.inter(size: 13, weight: .semibold)).foregroundStyle(ColorToken.primary).padding(.horizontal, 14).padding(.vertical, 5).background(ColorToken.secondary).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
                }
            }
            if editingInfo {
                infoInput("Age", text: $infoDraft.age, placeholder: "e.g. 28", keyboard: .numberPad, error: ageError)
                infoInput("Gender", text: $infoDraft.gender, placeholder: "male / female / other", keyboard: .default, error: nil)
                infoInput("Height (cm)", text: $infoDraft.height, placeholder: "e.g. 175", keyboard: .decimalPad, error: heightError)
                infoInput("Weight (kg)", text: $infoDraft.weight, placeholder: "e.g. 70", keyboard: .decimalPad, error: weightError)
                infoInput("Activity Level", text: $infoDraft.activityLevel, placeholder: "sedentary / lightly_active / moderately_active / very_active / extra_active", keyboard: .default, error: nil)
            } else {
                infoRow("Age", "\(Int(profile.age)) yrs")
                infoRow("Gender", profile.gender.rawValue.capitalized)
                infoRow("Height", "\(Int(profile.height)) cm")
                infoRow("Weight", "\(oneDecimal(profile.weight)) kg")
                infoRow("Activity Level", activityLabel(profile.activityLevel))
                HStack(alignment: .top, spacing: 8) {
                    Text("Dietary Prefs").font(TypographyToken.inter(size: 13, weight: .regular)).foregroundStyle(ColorToken.mutedForeground).frame(width: 110, alignment: .leading)
                    if profile.dietaryPreferences.isEmpty {
                        Text("None").font(TypographyToken.inter(size: 13, weight: .regular)).foregroundStyle(ColorToken.textTertiary).italic()
                    } else { dietaryPills(profile.dietaryPreferences) }
                }
            }
        }
    }

    func measurementsCard(profile: UserProfile) -> some View {
        let hasMeasurements = profile.measurements.map { m in [m.waist, m.hips, m.chest, m.arms, m.thighs].contains { $0 != nil } } ?? false
        return card {
            HStack {
                Text("Body Measurements").font(TypographyToken.inter(size: 16, weight: .bold)).foregroundStyle(ColorToken.textPrimary)
                Spacer(minLength: 0)
                if editingMeasurements {
                    HStack(spacing: 8) {
                        Button("Cancel") { measurementDraft = measurementFields; editingMeasurements = false }
                            .font(TypographyToken.inter(size: 13, weight: .semibold)).foregroundStyle(ColorToken.textSecondary).padding(.horizontal, 12).padding(.vertical, 5).background(ColorToken.muted).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
                        Button("Save") { Task { await handleSaveMeasurements() } }
                            .font(TypographyToken.inter(size: 13, weight: .semibold)).foregroundStyle(ColorToken.onPrimary).padding(.horizontal, 14).padding(.vertical, 5).background(ColorToken.primary).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
                    }
                } else {
                    Button("Edit") { measurementDraft = measurementFields; editingMeasurements = true }
                        .font(TypographyToken.inter(size: 13, weight: .semibold)).foregroundStyle(ColorToken.primary).padding(.horizontal, 14).padding(.vertical, 5).background(ColorToken.secondary).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
                }
            }
            if editingMeasurements {
                infoInput("Waist (cm)", text: $measurementDraft.waist, placeholder: "e.g. 82", keyboard: .decimalPad, error: nil)
                infoInput("Hips (cm)", text: $measurementDraft.hips, placeholder: "e.g. 96", keyboard: .decimalPad, error: nil)
                infoInput("Chest (cm)", text: $measurementDraft.chest, placeholder: "e.g. 100", keyboard: .decimalPad, error: nil)
                infoInput("Left Arm (cm)", text: $measurementDraft.arms, placeholder: "e.g. 33", keyboard: .decimalPad, error: nil)
                infoInput("Left Leg (cm)", text: $measurementDraft.thighs, placeholder: "e.g. 55", keyboard: .decimalPad, error: nil)
            } else if hasMeasurements {
                if let v = profile.measurements?.waist { infoRow("Waist", "\(oneDecimal(v)) cm") }
                if let v = profile.measurements?.hips { infoRow("Hips", "\(oneDecimal(v)) cm") }
                if let v = profile.measurements?.chest { infoRow("Chest", "\(oneDecimal(v)) cm") }
                if let v = profile.measurements?.arms { infoRow("Left Arm", "\(oneDecimal(v)) cm") }
                if let v = profile.measurements?.thighs { infoRow("Left Leg", "\(oneDecimal(v)) cm") }
            } else {
                Text("Add measurements to track your progress over time").font(TypographyToken.inter(size: 13, weight: .regular)).foregroundStyle(ColorToken.textTertiary).italic().frame(maxWidth: .infinity).padding(.vertical, 8)
            }
        }
    }

    var settingsCard: some View {
        card {
            Text("Settings").font(TypographyToken.inter(size: 16, weight: .bold)).foregroundStyle(ColorToken.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
            Button("Reset Weekly Plan 🔄") { UserDefaults.standard.removeObject(forKey: "weeklyPlan"); showToastMessage("Weekly plan reset! 🦝✅") }
                .font(TypographyToken.inter(size: 14, weight: .semibold)).foregroundStyle(ColorToken.textPrimary).frame(maxWidth: .infinity).padding(.vertical, 12).background(ColorToken.muted).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
            divider
            Button("Reset All Data 🗑️") { showResetAllConfirm = true }
                .font(TypographyToken.inter(size: 14, weight: .semibold)).foregroundStyle(ColorToken.destructive).frame(maxWidth: .infinity).padding(.vertical, 12).background(ColorToken.destructiveSurface).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
        }
    }

    func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) { content() }.padding(16).background(ColorToken.card).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).shadow(color: ColorToken.shadow.opacity(0.07), radius: 6, x: 0, y: 2)
    }

    var divider: some View { Rectangle().fill(ColorToken.border).frame(height: 1) }

    func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label).font(TypographyToken.inter(size: 13, weight: .regular)).foregroundStyle(ColorToken.mutedForeground).frame(width: 110, alignment: .leading)
            Text(value).font(TypographyToken.inter(size: 13, weight: .semibold)).foregroundStyle(ColorToken.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func dietaryPills(_ prefs: [DietaryPreference]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(prefs, id: \.rawValue) { pref in
                Text(dietaryLabel(pref)).font(TypographyToken.inter(size: 11, weight: .semibold)).foregroundStyle(ColorToken.primary).padding(.horizontal, 10).padding(.vertical, 3).background(ColorToken.secondary).clipShape(Capsule())
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    func infoInput(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType, error: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased()).font(TypographyToken.inter(size: 12, weight: .semibold)).foregroundStyle(ColorToken.mutedForeground).tracking(0.5)
            TextField(placeholder, text: text)
                .font(TypographyToken.inter(size: 14, weight: .regular)).foregroundStyle(ColorToken.inputForeground).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(keyboard)
                .padding(.horizontal, 12).padding(.vertical, 10).background(ColorToken.inputBackground).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(error == nil ? ColorToken.border : ColorToken.destructive, lineWidth: error == nil ? 1 : 1.5))
            if let error { Text(error).font(TypographyToken.inter(size: 12, weight: .regular)).foregroundStyle(ColorToken.destructive) }
        }
    }
}
