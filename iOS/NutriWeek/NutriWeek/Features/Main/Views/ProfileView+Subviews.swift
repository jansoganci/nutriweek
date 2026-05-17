import SwiftUI

extension ProfileView {
    var loadingView: some View {
        VStack {
            if let loadingError, !loadingError.isEmpty {
                ErrorStateView(
                    title: String(localized: "profile.error.load_title"),
                    message: loadingError,
                    retryTitle: String(localized: "common.retry")
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
                    Text(LocalizedStringKey("profile.title")).font(TypographyToken.inter(size: 20, weight: .bold)).foregroundStyle(ColorToken.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                    profileAvatarHeader(for: profile.goal, initials: profileInitials)
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

    func profileAvatarHeader(for goal: Goal, initials: String) -> some View {
        VStack(spacing: 8) {
            Text(initials)
                .font(TypographyToken.inter(size: 32, weight: .bold))
                .foregroundStyle(ColorToken.onPrimary)
                .frame(width: RockyMascotView.Size.large.rawValue, height: RockyMascotView.Size.large.rawValue)
                .background(ColorToken.primary)
                .clipShape(Circle())
                .overlay(Circle().stroke(ColorToken.border, lineWidth: 1))
                .shadow(color: ColorToken.shadow.opacity(0.08), radius: 6, x: 0, y: 2)
            Text(rockyMessage(for: goal)).font(TypographyToken.inter(size: 14, weight: .medium)).foregroundStyle(ColorToken.onSecondary).multilineTextAlignment(.center).lineSpacing(2).padding(.horizontal, 16).padding(.vertical, 10).background(ColorToken.secondary).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    func statsRow(profile: UserProfile, results: CalculationResults) -> some View {
        HStack(spacing: 10) {
            statCard(label: String(localized: "profile.stats.bmi"), value: oneDecimal(results.bmi), sub: results.bmiCategory.label, subColor: Color(hex: results.bmiCategory.colorHex))
            statCard(label: String(localized: "profile.stats.daily_calories"), value: "\(results.targetCalories)", sub: "kcal", subColor: nil)
            statCard(label: String(localized: "profile.stats.goal"), value: goalLabel(profile.goal), sub: nil, subColor: nil)
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
            Text(LocalizedStringKey("profile.targets.title")).font(TypographyToken.inter(size: 16, weight: .bold)).foregroundStyle(ColorToken.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
            macroRow("🔥", String(localized: "macro.calories"), "\(results.targetCalories)", "kcal")
            divider
            macroRow("🥩", String(localized: "macro.protein"), "\(results.macros.protein)", "g")
            divider
            macroRow("🍚", String(localized: "macro.carbs"), "\(results.macros.carbs)", "g")
            divider
            macroRow("🥑", String(localized: "macro.fat"), "\(results.macros.fat)", "g")
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
                Text(LocalizedStringKey("profile.personal_info.title")).font(TypographyToken.inter(size: 16, weight: .bold)).foregroundStyle(ColorToken.textPrimary)
                Spacer(minLength: 0)
                if editingInfo {
                    HStack(spacing: 8) {
                        Button(LocalizedStringKey("common.cancel")) { infoDraft = infoFields; editingInfo = false; clearFieldErrors() }
                            .font(TypographyToken.inter(size: 13, weight: .semibold)).foregroundStyle(ColorToken.textSecondary).padding(.horizontal, 12).padding(.vertical, 5).background(ColorToken.muted).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
                        Button(LocalizedStringKey("common.save")) { Task { await handleSaveInfo() } }
                            .font(TypographyToken.inter(size: 13, weight: .semibold)).foregroundStyle(ColorToken.onPrimary).padding(.horizontal, 14).padding(.vertical, 5).background(ColorToken.primary).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
                    }
                } else {
                    Button(LocalizedStringKey("common.edit")) { infoDraft = infoFields; editingInfo = true }
                        .font(TypographyToken.inter(size: 13, weight: .semibold)).foregroundStyle(ColorToken.primary).padding(.horizontal, 14).padding(.vertical, 5).background(ColorToken.secondary).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
                }
            }
            if editingInfo {
                infoInput(String(localized: "profile.field.age"), text: $infoDraft.age, placeholder: String(localized: "profile.placeholder.age"), keyboard: .numberPad, error: ageError)
                infoInput(String(localized: "profile.field.gender"), text: $infoDraft.gender, placeholder: String(localized: "profile.placeholder.gender"), keyboard: .default, error: nil)
                infoInput(String(localized: "profile.field.height_cm"), text: $infoDraft.height, placeholder: String(localized: "profile.placeholder.height_cm"), keyboard: .decimalPad, error: heightError)
                infoInput(String(localized: "profile.field.activity_level"), text: $infoDraft.activityLevel, placeholder: String(localized: "profile.placeholder.activity_level"), keyboard: .default, error: nil)
            } else {
                infoRow(String(localized: "profile.field.age"), "\(Int(profile.age)) \(String(localized: "common.years"))")
                infoRow(String(localized: "profile.field.gender"), profile.gender.rawValue.capitalized)
                infoRow(String(localized: "profile.field.height_cm"), "\(Int(profile.height)) cm")
                infoRow(String(localized: "profile.field.activity_level"), activityLabel(profile.activityLevel))
                HStack(alignment: .top, spacing: 8) {
                    Text(LocalizedStringKey("profile.field.dietary_preferences")).font(TypographyToken.inter(size: 13, weight: .regular)).foregroundStyle(ColorToken.mutedForeground).frame(width: 110, alignment: .leading)
                    if profile.dietaryPreferences.isEmpty {
                        Text(LocalizedStringKey("common.none")).font(TypographyToken.inter(size: 13, weight: .regular)).foregroundStyle(ColorToken.textTertiary).italic()
                    } else { dietaryPills(profile.dietaryPreferences) }
                }
            }
        }
    }

    func measurementsCard(profile: UserProfile) -> some View {
        let hasMeasurements = profile.measurements.map { m in [m.waist, m.hips, m.chest, m.arms, m.thighs].contains { $0 != nil } } ?? false
        return card {
            HStack {
                Text(LocalizedStringKey("profile.measurements.title")).font(TypographyToken.inter(size: 16, weight: .bold)).foregroundStyle(ColorToken.textPrimary)
                Spacer(minLength: 0)
                Button(LocalizedStringKey("profile.measurements.log_new")) { showMeasurementLogSheet = true }
                    .font(TypographyToken.inter(size: 13, weight: .semibold)).foregroundStyle(ColorToken.primary).padding(.horizontal, 14).padding(.vertical, 5).background(ColorToken.secondary).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
            }
            infoRow(String(localized: "profile.measurements.weight"), "\(oneDecimal(profile.weight)) kg")
            if hasMeasurements {
                if let v = profile.measurements?.waist { infoRow(String(localized: "profile.measurements.waist"), "\(oneDecimal(v)) cm") }
                if let v = profile.measurements?.hips { infoRow(String(localized: "profile.measurements.hips"), "\(oneDecimal(v)) cm") }
                if let v = profile.measurements?.chest { infoRow(String(localized: "profile.measurements.chest"), "\(oneDecimal(v)) cm") }
                if let v = profile.measurements?.arms { infoRow(String(localized: "profile.measurements.left_arm"), "\(oneDecimal(v)) cm") }
                if let v = profile.measurements?.thighs { infoRow(String(localized: "profile.measurements.left_leg"), "\(oneDecimal(v)) cm") }
            } else {
                Text(LocalizedStringKey("profile.measurements.empty")).font(TypographyToken.inter(size: 13, weight: .regular)).foregroundStyle(ColorToken.textTertiary).italic().frame(maxWidth: .infinity).padding(.vertical, 8)
            }
        }
    }

    var settingsCard: some View {
        card {
            Text(LocalizedStringKey("profile.settings.title")).font(TypographyToken.inter(size: 16, weight: .bold)).foregroundStyle(ColorToken.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
            Button(LocalizedStringKey("profile.settings.reset_weekly_plan")) { UserDefaults.standard.removeObject(forKey: "weeklyPlan"); showToastMessage(String(localized: "profile.toast.weekly_plan_reset")) }
                .font(TypographyToken.inter(size: 14, weight: .semibold)).foregroundStyle(ColorToken.textPrimary).frame(maxWidth: .infinity).padding(.vertical, 12).background(ColorToken.muted).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
                .disabled(isDeleting)
            divider
            Button(LocalizedStringKey("profile.settings.reset_all_data")) { showResetAllConfirm = true }
                .font(TypographyToken.inter(size: 14, weight: .semibold)).foregroundStyle(ColorToken.destructive).frame(maxWidth: .infinity).padding(.vertical, 12).background(ColorToken.destructiveSurface).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
                .disabled(isDeleting)
            divider
            Button(LocalizedStringKey("profile.settings.delete_account")) { showDeleteAccountConfirm = true }
                .font(TypographyToken.inter(size: 14, weight: .semibold)).foregroundStyle(ColorToken.destructive).frame(maxWidth: .infinity).padding(.vertical, 12).background(ColorToken.destructiveSurface).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)).buttonStyle(.plain)
                .disabled(isDeleting)
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
