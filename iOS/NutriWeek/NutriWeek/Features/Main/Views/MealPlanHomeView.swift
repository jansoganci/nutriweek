import SwiftUI
import Supabase

struct MealPlanHomeView: View {
    let mealPlanRepository: MealPlanRepositoryProtocol
    let foodLogRepository: FoodLogRepositoryProtocol
    let activityLogRepository: ActivityLogRepositoryProtocol?
    let streakService: StreakService?
    var onSwitchToActivityTab: () -> Void = {}

    @State private var targets: CalculationResults?
    @State private var consumed = FoodMacroResult(calories: 0, protein: 0, carbs: 0, fat: 0)
    @State private var todaysBurnedCalories: Double = 0
    @State private var weeklyPlan: WeeklyPlan?
    @State private var showGeneratePrompt = false
    /// Set when user confirms in the sheet; cleared when we start `handleGenerate` after dismiss (avoids SwiftUI cancelling the task with the sheet).
    @State private var pendingGenerateAfterSheet = false
    @State private var isGenerating = false
    @State private var refreshError: String?
    @State private var showEmpty = false
    @State private var expandedDayDate: String?
    @State private var loaded = false
    @State private var streak: Int?
    @State private var showFunFact = false
    @State private var funFactText = ""
    @State private var showInfoToast = false
    @State private var showMealLogToast = false
    @State private var daysReady = 0
    @State private var partialDays: [DayPlan] = []
    @State private var currentProfile: UserProfile?
    @State private var currentUserId: String?
    @State private var weeklyActivityCount = 0
    @State private var weeklyBurnedCalories: Double = 0
    @State private var latestWeeklyCheckIn: WeeklyCheckInRecord?
    @State private var latestRecoveryCheckIn: RecoveryCheckInRecord?
    @State private var personalInsightsSnapshot: PersonalInsightsSnapshot?
    @State private var showWeeklyCheckInSheet = false
    @State private var showRecoveryCheckInSheet = false

    private let personalProgressStore = PersonalProgressStore()
    private let personalInsightsService: PersonalInsightsService

    private let funFacts = [
        String(localized: "meal_plan.fun_fact.locks"),
        String(localized: "meal_plan.fun_fact.hands"),
        String(localized: "meal_plan.fun_fact.protein"),
        String(localized: "meal_plan.fun_fact.eating_slowly"),
    ]

    init(
        mealPlanRepository: MealPlanRepositoryProtocol,
        foodLogRepository: FoodLogRepositoryProtocol,
        activityLogRepository: ActivityLogRepositoryProtocol? = nil,
        streakService: StreakService? = nil,
        onSwitchToActivityTab: @escaping () -> Void = {}
    ) {
        self.mealPlanRepository = mealPlanRepository
        self.foodLogRepository = foodLogRepository
        self.activityLogRepository = activityLogRepository
        self.streakService = streakService
        self.onSwitchToActivityTab = onSwitchToActivityTab
        self.personalInsightsService = PersonalInsightsService(
            foodLogRepository: foodLogRepository,
            activityLogRepository: activityLogRepository
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    streakRow
                    macroSummary
                    personalProgressSection
                    if let personalInsightsSnapshot {
                        PersonalTrendSectionView(snapshot: personalInsightsSnapshot)
                        weeklySummarySection(snapshot: personalInsightsSnapshot)
                    }
                    weeklySection
                }
                .padding(.horizontal, SpacingToken.gutter)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(ColorToken.background)

            if showInfoToast {
                ToastView(
                    title: String(localized: "meal_plan.toast.updated_title"),
                    subtitle: String(localized: "meal_plan.toast.updated_subtitle"),
                    style: .success
                )
                .padding(.horizontal, SpacingToken.gutter)
                .padding(.bottom, 88)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if showMealLogToast {
                ToastView(
                    title: String(localized: "log.toast.logged_title"),
                    subtitle: String(localized: "log.toast.logged_subtitle"),
                    style: .success
                )
                .padding(.horizontal, SpacingToken.gutter)
                .padding(.bottom, 88)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await initialize() }
        .alert(LocalizedStringKey("meal_plan.alert.rocky_title"), isPresented: $showFunFact) {
            Button(LocalizedStringKey("common.ok"), role: .cancel) {}
        } message: {
            Text(funFactText)
        }
        .sheet(isPresented: $showGeneratePrompt) {
            generatePromptSheet
                .presentationDetents([.height(330)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showWeeklyCheckInSheet) {
            if let userId = currentUserId {
                WeeklyCheckInSheet(
                    userId: userId,
                    initialRecord: latestWeeklyCheckIn,
                    onSaved: { await loadPersonalProgress() }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showRecoveryCheckInSheet) {
            if let userId = currentUserId {
                RecoveryCheckInSheet(
                    userId: userId,
                    initialRecord: latestRecoveryCheckIn,
                    onSaved: { await loadPersonalProgress() }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: showGeneratePrompt) { _, isPresented in
            guard !isPresented, pendingGenerateAfterSheet else { return }
            pendingGenerateAfterSheet = false
            Task { await handleGenerate() }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(TypographyToken.inter(size: 24, weight: .bold))
                    .foregroundStyle(ColorToken.textPrimary)
                Text(LocalizedStringKey("meal_plan.header.subtitle"))
                    .font(TypographyToken.inter(size: 14, weight: .regular))
                    .foregroundStyle(ColorToken.textSecondary)
            }
            Spacer(minLength: 0)
            Button {
                funFactText = funFacts.randomElement() ?? String(localized: "meal_plan.fun_fact.fallback")
                showFunFact = true
            } label: {
                RockyMascotView(mood: .happy, size: RockyMascotView.Size.small.rawValue)
                    .frame(width: 44, height: 44)
                    .background(ColorToken.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(ColorToken.border, lineWidth: BorderToken.hairline))
                    .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var streakRow: some View {
        if let streak {
            Text(streak > 0 ? String(localized: "meal_plan.streak.days \(streak)") : String(localized: "meal_plan.streak.empty"))
                .font(TypographyToken.inter(size: 14, weight: .semibold))
                .foregroundStyle(ColorToken.textPrimary)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(ColorToken.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(ColorToken.border, lineWidth: BorderToken.hairline)
                )
                .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var macroSummary: some View {
        let targetCals = Double(targets?.targetCalories ?? 0)
        let targetProtein = Double(targets?.macros.protein ?? 0)
        let targetCarbs = Double(targets?.macros.carbs ?? 0)
        let targetFat = Double(targets?.macros.fat ?? 0)
        let remaining = Int(targetCals - consumed.calories)
        let remainingText: String = {
            if targetCals == 0 { return String(localized: "meal_plan.targets.complete_onboarding") }
            if remaining >= 0 { return String(localized: "meal_plan.targets.remaining \(remaining)") }
            return String(localized: "meal_plan.targets.over \(abs(remaining))")
        }()

        return VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey("meal_plan.progress.title"))
                .font(TypographyToken.inter(size: 13, weight: .semibold))
                .foregroundStyle(ColorToken.textSecondary)
                .tracking(0.8)
                .textCase(.uppercase)

            HStack(alignment: .top, spacing: 12) {
                MacroRingView(label: String(localized: "macro.calories"), current: consumed.calories, target: targetCals, unit: "kcal", color: Color(hex: "#FF6B35"), size: 72, strokeWidth: 7)
                MacroRingView(label: String(localized: "macro.protein"), current: consumed.protein, target: targetProtein, unit: "g", color: Color(hex: "#4CAF50"), size: 72, strokeWidth: 7)
                MacroRingView(label: String(localized: "macro.carbs"), current: consumed.carbs, target: targetCarbs, unit: "g", color: Color(hex: "#FFB300"), size: 72, strokeWidth: 7)
                MacroRingView(label: String(localized: "macro.fat"), current: consumed.fat, target: targetFat, unit: "g", color: Color(hex: "#64B5F6"), size: 72, strokeWidth: 7)
            }
            .frame(maxWidth: .infinity)

            Text(remainingText)
                .font(TypographyToken.inter(size: 13, weight: .regular))
                .foregroundStyle(remaining < 0 && targetCals > 0 ? ColorToken.destructive : ColorToken.textSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Button {
                onSwitchToActivityTab()
            } label: {
                Text(String(localized: "meal_plan.activity_summary \(Int(todaysBurnedCalories.rounded()))"))
                    .font(TypographyToken.inter(size: 12, weight: .semibold))
                    .foregroundStyle(ColorToken.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(ColorToken.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
        }
        .padding(18)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ColorToken.border, lineWidth: BorderToken.hairline)
        )
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    private var personalProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(LocalizedStringKey("personal.progress.title"))
                    .font(TypographyToken.inter(size: 20, weight: .bold))
                    .foregroundStyle(ColorToken.textPrimary)
                Spacer(minLength: 0)
                Text(LocalizedStringKey("personal.progress.subtitle"))
                    .font(TypographyToken.inter(size: 12, weight: .regular))
                    .foregroundStyle(ColorToken.textSecondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ProgressChipView(
                    title: String(localized: "personal.goal_chips.goal"),
                    value: goalDisplayText,
                    accent: ColorToken.primary
                )
                ProgressChipView(
                    title: String(localized: "personal.goal_chips.calories"),
                    value: targetCaloriesText,
                    accent: Color(hex: "#FF6B35")
                )
                ProgressChipView(
                    title: String(localized: "personal.goal_chips.protein"),
                    value: proteinTargetText,
                    accent: ColorToken.macroProtein
                )
                ProgressChipView(
                    title: String(localized: "personal.goal_chips.weekly_target"),
                    value: "\(weeklyWorkoutTarget) \(String(localized: "personal.goal_chips.workout_suffix"))",
                    accent: Color(hex: "#64B5F6")
                )
                ProgressChipView(
                    title: String(localized: "personal.goal_chips.weekly_done"),
                    value: "\(weeklyActivityCount) \(String(localized: "personal.goal_chips.workout_suffix"))",
                    accent: Color(hex: "#4CAF50")
                )
                ProgressChipView(
                    title: String(localized: "personal.goal_chips.weekly_burn"),
                    value: "\(Int(weeklyBurnedCalories.rounded())) kcal",
                    accent: Color(hex: "#FFB300")
                )
            }

            weeklyCheckInCard
            recoveryCheckInCard
        }
    }

    private var weeklyCheckInCard: some View {
        Button {
            presentWeeklyCheckInSheet()
        } label: {
            progressActionCard(
                title: String(localized: "personal.weekly_check_in.title"),
                subtitle: String(localized: "personal.weekly_check_in.subtitle"),
                detailText: weeklyCheckInDetailText,
                buttonTitle: String(localized: "personal.weekly_check_in.button"),
                accent: ColorToken.primary,
                iconName: "checkmark.seal.fill"
            )
        }
        .buttonStyle(.plain)
        .disabled(currentUserId == nil)
        .opacity(currentUserId == nil ? 0.65 : 1)
    }

    private var recoveryCheckInCard: some View {
        Button {
            presentRecoveryCheckInSheet()
        } label: {
            progressActionCard(
                title: String(localized: "personal.recovery_check_in.title"),
                subtitle: String(localized: "personal.recovery_check_in.subtitle"),
                detailText: recoveryCheckInDetailText,
                buttonTitle: String(localized: "personal.recovery_check_in.button"),
                accent: Color(hex: "#4CAF50"),
                iconName: "bolt.heart.fill"
            )
        }
        .buttonStyle(.plain)
        .disabled(currentUserId == nil)
        .opacity(currentUserId == nil ? 0.65 : 1)
    }

    private func weeklySummarySection(snapshot: PersonalInsightsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(LocalizedStringKey("personal.weekly_summary.title"))
                    .font(TypographyToken.inter(size: 20, weight: .bold))
                    .foregroundStyle(ColorToken.textPrimary)
                Spacer(minLength: 0)
                Text(LocalizedStringKey("personal.weekly_summary.subtitle"))
                    .font(TypographyToken.inter(size: 12, weight: .regular))
                    .foregroundStyle(ColorToken.textSecondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(summaryCopy(snapshot: snapshot))
                    .font(TypographyToken.inter(size: 14, weight: .medium))
                    .foregroundStyle(ColorToken.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                    ProgressChipView(
                        title: String(localized: "personal.weekly_summary.workouts"),
                        value: "\(weeklyActivityCount)",
                        accent: Color(hex: "#4CAF50")
                    )
                    ProgressChipView(
                        title: String(localized: "personal.weekly_summary.avg_intake"),
                        value: averageTrendValue(snapshot.caloriesIn),
                        accent: ColorToken.primary
                    )
                    ProgressChipView(
                        title: String(localized: "personal.weekly_summary.avg_burn"),
                        value: averageTrendValue(snapshot.caloriesBurned),
                        accent: Color(hex: "#FFB300")
                    )
                    ProgressChipView(
                        title: String(localized: "personal.weekly_summary.weight_change"),
                        value: weightDeltaText(snapshot.weightTrend),
                        accent: Color(hex: "#64B5F6")
                    )
                }
            }
            .padding(14)
            .background(ColorToken.background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ColorToken.border, lineWidth: 1)
            )
        }
        .padding(16)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ColorToken.border, lineWidth: BorderToken.hairline)
        )
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    private func summaryCopy(snapshot: PersonalInsightsSnapshot) -> String {
        let progressLine: String
        if weeklyActivityCount >= weeklyWorkoutTarget {
            progressLine = String(localized: "personal.weekly_summary.on_track")
        } else {
            progressLine = String(localized: "personal.weekly_summary.behind")
        }

        let intake = averageTrendValue(snapshot.caloriesIn)
        let burn = averageTrendValue(snapshot.caloriesBurned)
        let delta = weightDeltaText(snapshot.weightTrend)
        let focus = goalSpecificSummary()
        let detail = "\(weeklyActivityCount)/\(weeklyWorkoutTarget) \(String(localized: "personal.goal_chips.workout_suffix")) · \(String(localized: "personal.weekly_summary.avg_intake")) \(intake) · \(String(localized: "personal.weekly_summary.avg_burn")) \(burn) · \(String(localized: "personal.weekly_summary.weight_change")) \(delta)"

        return "\(progressLine) \(detail) \(focus)"
    }

    private func goalSpecificSummary() -> String {
        guard let currentProfile else {
            return String(localized: "personal.weekly_summary.goal_generic")
        }

        switch currentProfile.goal {
        case .cut:
            return String(localized: "personal.weekly_summary.goal_cut")
        case .bulk:
            return String(localized: "personal.weekly_summary.goal_bulk")
        case .maintain:
            return String(localized: "personal.weekly_summary.goal_maintain")
        }
    }

    private func progressActionCard(title: String, subtitle: String, detailText: String, buttonTitle: String, accent: Color, iconName: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 34, height: 34)
                    .background(accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(TypographyToken.inter(size: 16, weight: .bold))
                        .foregroundStyle(ColorToken.textPrimary)
                    Text(subtitle)
                        .font(TypographyToken.inter(size: 13, weight: .regular))
                        .foregroundStyle(ColorToken.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            Text(detailText)
                .font(TypographyToken.inter(size: 13, weight: .medium))
                .foregroundStyle(ColorToken.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(buttonTitle)
                .font(TypographyToken.inter(size: 13, weight: .semibold))
                .foregroundStyle(accent)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ColorToken.border, lineWidth: BorderToken.hairline)
        )
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    private var weeklySection: some View {
        let weekSlots = isoWeekMondayThroughSunday()
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStringKey("meal_plan.week.title"))
                    .font(TypographyToken.inter(size: 20, weight: .bold))
                    .foregroundStyle(ColorToken.textPrimary)
                Spacer(minLength: 0)
                if weeklyPlan != nil, !isGenerating {
                    Button("↻") {
                        Task { await handleGenerate() }
                    }
                    .buttonStyle(.plain)
                    .font(TypographyToken.inter(size: 22, weight: .semibold))
                    .foregroundStyle(ColorToken.primary)
                }
            }

            if isGenerating {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "meal_plan.week.progress \(daysReady)"))
                        .font(TypographyToken.inter(size: 13, weight: .semibold))
                        .foregroundStyle(ColorToken.textSecondary)
                    ForEach(weekSlots) { slot in
                        if let day = partialDays.first(where: { $0.date == slot.dateISO }) {
                            DayPlanCardView(
                                day: day,
                                isToday: day.date == todayISO,
                                isExpanded: expandedDayDate == day.date,
                                onToggle: {
                                    expandedDayDate = (expandedDayDate == day.date) ? nil : day.date
                                },
                                onLogMeal: { meal in
                                    Task { await logMealFromPlan(meal) }
                                }
                            )
                        } else {
                            LoadingSkeletonView(variant: .card)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
            } else if let refreshError {
                ErrorStateView(
                    title: String(localized: "meal_plan.error.load_title"),
                    message: refreshError,
                    retryTitle: String(localized: "common.retry")
                ) {
                    Task { await handleGenerate() }
                }
            }

            if let weeklyPlan, !isGenerating {
                ForEach(weeklyPlan.days, id: \.date) { day in
                    DayPlanCardView(
                        day: day,
                        isToday: day.date == todayISO,
                        isExpanded: expandedDayDate == day.date,
                        onToggle: {
                            expandedDayDate = (expandedDayDate == day.date) ? nil : day.date
                        },
                        onLogMeal: { meal in
                            Task { await logMealFromPlan(meal) }
                        }
                    )
                }
            } else if loaded, showEmpty {
                VStack(spacing: 10) {
                    RockyMascotView(mood: .thinking, size: RockyMascotView.Size.large.rawValue)
                    Text(LocalizedStringKey("meal_plan.empty.title"))
                        .font(TypographyToken.inter(size: 20, weight: .bold))
                        .foregroundStyle(ColorToken.textPrimary)
                    Text(LocalizedStringKey("meal_plan.empty.subtitle"))
                        .font(TypographyToken.inter(size: 14, weight: .regular))
                        .foregroundStyle(ColorToken.textSecondary)
                        .multilineTextAlignment(.center)
                    Button {
                        showGeneratePrompt = true
                    } label: {
                        Text(LocalizedStringKey("meal_plan.empty.generate_button"))
                            .font(TypographyToken.inter(size: 16, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 28)
                            .background(ColorToken.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(ColorToken.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(ColorToken.border, lineWidth: BorderToken.hairline)
                )
                .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
            } else if !loaded {
                VStack(spacing: 10) {
                    LoadingSkeletonView(variant: .card)
                    LoadingSkeletonView(variant: .ring)
                    LoadingSkeletonView(variant: .card)
                }
            }
        }
    }

    private var generatePromptSheet: some View {
        VStack(spacing: 12) {
            RockyMascotView(mood: .happy, size: RockyMascotView.Size.large.rawValue)
                .padding(.bottom, 4)
            Text(LocalizedStringKey("meal_plan.sheet.title"))
                .font(TypographyToken.inter(size: 20, weight: .bold))
                .foregroundStyle(ColorToken.textPrimary)
                .multilineTextAlignment(.center)
            Text(LocalizedStringKey("meal_plan.sheet.subtitle"))
                .font(TypographyToken.inter(size: 14, weight: .regular))
                .foregroundStyle(ColorToken.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                pendingGenerateAfterSheet = true
                showGeneratePrompt = false
            } label: {
                Text(LocalizedStringKey("meal_plan.sheet.confirm"))
                    .font(TypographyToken.inter(size: 17, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ColorToken.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Button(LocalizedStringKey("meal_plan.sheet.cancel")) {
                pendingGenerateAfterSheet = false
                showGeneratePrompt = false
                showEmpty = true
            }
            .buttonStyle(.plain)
            .foregroundStyle(ColorToken.textPrimary)
            .font(TypographyToken.inter(size: 15, weight: .regular))
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorToken.card)
    }

    private var greetingText: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h >= 5, h < 11 { return String(localized: "meal_plan.greeting.morning") }
        if h >= 11, h < 17 { return String(localized: "meal_plan.greeting.afternoon") }
        if h >= 17, h < 22 { return String(localized: "meal_plan.greeting.evening") }
        return String(localized: "meal_plan.greeting.night")
    }

    private var todayISO: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func initialize() async {
        await loadTargets()
        await loadWeeklyPlan()
        await loadConsumedAndStreak()
        await loadTodaysBurnedCalories()
        await loadPersonalProgress()
        loaded = true
    }

    private func loadTargets() async {
        do {
            let onboarding = try await OnboardingService.fetchOnboardingProfile()
            if let profile = UserProfile(onboarding: onboarding) {
                currentProfile = profile
                targets = NutritionCalculationService.calculateAll(profile: profile)
            }
        } catch {
            currentProfile = nil
            targets = nil
        }
    }

    private func loadWeeklyPlan() async {
        weeklyPlan = try? await mealPlanRepository.loadWeeklyPlan()
        if weeklyPlan == nil {
            showEmpty = true
            showGeneratePrompt = true
        } else {
            showEmpty = false
            showGeneratePrompt = false
        }
    }

    private func loadConsumedAndStreak() async {
        let entries = (try? await foodLogRepository.loadTodayLog()) ?? []
        consumed = foodLogRepository.sumMacros(entries: entries)
        if let streakService {
            streak = (try? await streakService.loadStreak()) ?? 0
        } else {
            streak = 0
        }
    }

    private func logMealFromPlan(_ meal: MealEntry) async {
        let entry = FoodLogEntry(
            id: String(Int(Date().timeIntervalSince1970 * 1000)),
            foodName: meal.name,
            grams: 1,
            calories: meal.calories.rounded(),
            protein: round(meal.protein * 10) / 10,
            carbs: round(meal.carbs * 10) / 10,
            fat: round(meal.fat * 10) / 10,
            loggedAt: Date().ISO8601Format(),
            date: todayISO
        )
        do {
            try await foodLogRepository.addLogEntry(entry)
            await loadConsumedAndStreak()
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                    showMealLogToast = true
                }
            }
            Haptics.success()
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    showMealLogToast = false
                }
            }
        } catch {
            // silent fail
        }
    }

    private func loadTodaysBurnedCalories() async {
        guard let activityLogRepository else {
            todaysBurnedCalories = 0
            return
        }

        todaysBurnedCalories = (try? await activityLogRepository.totalCaloriesBurned(for: Date())) ?? 0
    }

    private func loadPersonalProgress() async {
        do {
            let session = try await SupabaseClientFactory.shared.auth.session
            let userId = session.user.id.uuidString
            currentUserId = userId

            latestWeeklyCheckIn = try? personalProgressStore.latestWeeklyCheckIn(userId: userId)
            latestRecoveryCheckIn = try? personalProgressStore.latestRecoveryCheckIn(userId: userId)
            personalInsightsSnapshot = try? await personalInsightsService.loadSnapshot(days: 7)

            if let activityLogRepository {
                let end = Date()
                let start = Calendar.current.date(byAdding: .day, value: -6, to: end) ?? end
                let entries = (try? await activityLogRepository.loadEntries(from: start, to: end)) ?? []
                weeklyActivityCount = entries.count
                weeklyBurnedCalories = entries.reduce(0) { $0 + $1.caloriesBurned }
            } else {
                weeklyActivityCount = 0
                weeklyBurnedCalories = 0
            }
        } catch {
            currentUserId = nil
            latestWeeklyCheckIn = nil
            latestRecoveryCheckIn = nil
            personalInsightsSnapshot = nil
            weeklyActivityCount = 0
            weeklyBurnedCalories = 0
        }
    }

    private func presentWeeklyCheckInSheet() {
        guard currentUserId != nil else { return }
        showWeeklyCheckInSheet = true
    }

    private func presentRecoveryCheckInSheet() {
        guard currentUserId != nil else { return }
        showRecoveryCheckInSheet = true
    }

    private func handleGenerate() async {
        guard !isGenerating else { return }
        guard let calorieTarget = targets?.targetCalories, let macros = targets?.macros else {
            refreshError = String(localized: "meal_plan.error.complete_onboarding_generate")
            return
        }

        let slots = isoWeekMondayThroughSunday()
        guard slots.count == 7 else {
            refreshError = String(localized: "meal_plan.error.schedule_load")
            return
        }

        refreshError = nil
        partialDays = []
        daysReady = 0
        isGenerating = true
        defer { isGenerating = false }

        let repo = mealPlanRepository

        func mergePartial(_ day: DayPlan) {
            var merged = partialDays.filter { $0.date != day.date }
            merged.append(day)
            merged.sort { $0.date < $1.date }
            partialDays = merged
            daysReady = merged.count
        }

        do {
            let onboardingProfile = try await OnboardingService.fetchOnboardingProfile()
            guard let profile = UserProfile(onboarding: onboardingProfile) else {
                refreshError = String(localized: "meal_plan.error.complete_onboarding_generate")
                return
            }
            print("[MealPlanHomeView] weekly_generation_profile_loaded once=true")
            // Build once and reuse for all 7 days to avoid per-day profile fetch drift.
            let planTargets = GemmaPlanTargets(
                profile: profile,
                targetCalories: calorieTarget,
                macros: macros
            )
            var usedMealNames = Set<String>()

            // One Gemini request at a time: parallel calls often return empty / truncated JSON (422 AI_SCHEMA_INVALID).
            for slot in slots {
                var generatedDay: DayPlan?
                var attempt = 0
                while generatedDay == nil, attempt < 2 {
                    attempt += 1
                    do {
                        generatedDay = try await repo.generateDay(
                            dayName: slot.weekdayName,
                            date: slot.dateISO,
                            targets: planTargets,
                            excludeMealNames: Array(usedMealNames)
                        )
                    } catch {
                        let detail = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                        print("[MealPlanHomeView] day_generation_failed day=\(slot.weekdayName) attempt=\(attempt) message=\(detail)")
                        if attempt < 2 {
                            refreshError = String(localized: "meal_plan.error.day_retry \(slot.weekdayName)")
                        } else {
                            refreshError = String(localized: "meal_plan.error.day_failed \(slot.weekdayName)")
                            throw error
                        }
                    }
                }
                if let generatedDay {
                    refreshError = nil
                    mergePartial(generatedDay)
                    generatedDay.meals.forEach { usedMealNames.insert($0.name) }
                }
            }

            let ordered = slots.compactMap { slot in partialDays.first(where: { $0.date == slot.dateISO }) }
            guard ordered.count == 7 else {
                refreshError = String(localized: "meal_plan.error.generate_generic")
                partialDays = []
                daysReady = 0
                if weeklyPlan == nil { showEmpty = true }
                return
            }

            let weekStart = slots[0].dateISO
            let plan = WeeklyPlan(
                id: UUID().uuidString,
                weekStartDate: weekStart,
                days: ordered,
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                notes: nil
            )
            weeklyPlan = plan
            try? await mealPlanRepository.saveWeeklyPlan(plan)

            partialDays = []
            daysReady = 0
            showEmpty = false

            withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                showInfoToast = true
            }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeOut(duration: 0.2)) {
                showInfoToast = false
            }
        } catch {
            if refreshError == nil {
                refreshError = String(localized: "meal_plan.error.generate_generic")
            }
            partialDays = []
            daysReady = 0
            if weeklyPlan == nil {
                showEmpty = true
            }
        }
    }

    private func isoWeekMondayThroughSunday(reference: Date = Date()) -> [IsoWeekDaySlot] {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.calendar = calendar
        weekdayFormatter.locale = .autoupdatingCurrent
        weekdayFormatter.dateFormat = "EEEE"
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: reference))
        else { return [] }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        return (0..<7).compactMap { index in
            guard let date = calendar.date(byAdding: .day, value: index, to: weekStart) else { return nil }
            return IsoWeekDaySlot(
                weekdayName: weekdayFormatter.string(from: date),
                dateISO: formatter.string(from: date)
            )
        }
    }

    private var goalDisplayText: String {
        guard let currentProfile else {
            return String(localized: "personal.goal_chips.goal_unknown")
        }
        switch currentProfile.goal {
        case .cut:
            return String(localized: "goal.cut.short")
        case .bulk:
            return String(localized: "goal.bulk.short")
        case .maintain:
            return String(localized: "goal.maintain.short")
        }
    }

    private var targetCaloriesText: String {
        guard let targets else { return String(localized: "personal.goal_chips.target_unknown") }
        return "\(targets.targetCalories) kcal"
    }

    private var proteinTargetText: String {
        guard let targets else { return String(localized: "personal.goal_chips.target_unknown") }
        return "\(targets.macros.protein) g"
    }

    private var weeklyWorkoutTarget: Int {
        guard let currentProfile else { return 3 }
        switch currentProfile.activityLevel {
        case .sedentary:
            return 2
        case .lightlyActive:
            return 3
        case .moderatelyActive:
            return 4
        case .veryActive, .extraActive:
            return 5
        }
    }

    private var weeklyCheckInDetailText: String {
        guard let latestWeeklyCheckIn else {
            return String(localized: "personal.weekly_check_in.empty")
        }

        let weightText = latestWeeklyCheckIn.weightKg.map { "\(oneDecimal($0)) kg" } ?? "—"
        return "⚖️ \(weightText) · 🏋️ \(latestWeeklyCheckIn.workoutCount) · 🔋 \(latestWeeklyCheckIn.energyLevel)/5"
    }

    private var recoveryCheckInDetailText: String {
        guard let latestRecoveryCheckIn else {
            return String(localized: "personal.recovery_check_in.empty")
        }

        let sleepText = latestRecoveryCheckIn.sleepHours.map { "\(oneDecimal($0))h" } ?? "—"
        return "😴 \(sleepText) · 💥 \(latestRecoveryCheckIn.sorenessLevel)/5 · 🔋 \(latestRecoveryCheckIn.energyLevel)/5"
    }

    private func oneDecimal(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func averageTrendValue(_ points: [TrendPoint]) -> String {
        guard !points.isEmpty else { return "—" }
        let average = points.reduce(0) { $0 + $1.value } / Double(points.count)
        return "\(oneDecimal(average)) kcal"
    }

    private func weightDeltaText(_ points: [TrendPoint]) -> String {
        guard let first = points.first?.value, let last = points.last?.value else {
            return "—"
        }
        let delta = last - first
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(oneDecimal(delta)) kg"
    }

    private func averageNumericValue(_ points: [TrendPoint]) -> String {
        guard !points.isEmpty else { return "0" }
        let average = points.reduce(0) { $0 + $1.value } / Double(points.count)
        return String(Int(average.rounded()))
    }

}

private struct IsoWeekDaySlot: Identifiable {
    let weekdayName: String
    let dateISO: String

    var id: String { dateISO }
}


private struct DayPlanCardView: View {
    let day: DayPlan
    let isToday: Bool
    let isExpanded: Bool
    let onToggle: () -> Void
    var onLogMeal: ((MealEntry) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggle) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayTitle)
                            .font(TypographyToken.inter(size: 16, weight: .bold))
                            .foregroundStyle(isToday ? ColorToken.primary : ColorToken.textPrimary)
                        Text(formattedDate(day.date))
                            .font(TypographyToken.inter(size: 12, weight: .regular))
                            .foregroundStyle(ColorToken.textSecondary)
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 4) {
                        if isToday {
                            Text(LocalizedStringKey("common.today"))
                                .font(TypographyToken.inter(size: 11, weight: .bold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(ColorToken.primary)
                                .clipShape(Capsule())
                        }
                        Text("\(Int(totalCalories)) kcal")
                            .font(TypographyToken.inter(size: 13, weight: .semibold))
                            .foregroundStyle(ColorToken.textSecondary)
                        Text(isExpanded ? "▲" : "▼")
                            .font(TypographyToken.inter(size: 10, weight: .regular))
                            .foregroundStyle(ColorToken.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 0) {
                ForEach(Array(displayMeals.enumerated()), id: \.offset) { idx, meal in
                    if idx > 0 {
                        Rectangle()
                            .fill(ColorToken.border)
                            .frame(height: 1)
                            .padding(.leading, 36)
                    }
                    MealRowView(
                        meal: meal,
                        showLogButton: onLogMeal != nil,
                        onLogMeal: { onLogMeal?(meal) }
                    )
                }
                if showsSnackCollapsedHint {
                    Button(action: onToggle) {
                        Text(LocalizedStringKey("meal_plan.card.snack_collapsed"))
                            .font(TypographyToken.inter(size: 12, weight: .medium))
                            .foregroundStyle(ColorToken.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#F1F1F1"))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                    .padding(.leading, 36)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .background(isToday ? Color(hex: "#FFF3EE") : ColorToken.card)
        .overlay(alignment: .leading) {
            if isToday {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(ColorToken.primary)
                    .frame(width: 4)
                    .padding(.vertical, 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isToday ? ColorToken.primary : ColorToken.border, lineWidth: BorderToken.hairline)
        )
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    private var dayTitle: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        if let d = f.date(from: day.date) {
            let out = DateFormatter()
            out.dateFormat = "EEEE"
            return out.string(from: d)
        }
        return String(localized: "common.day")
    }

    private var totalCalories: Double {
        day.meals.reduce(0) { $0 + $1.calories }
    }

    private var displayMeals: [MealEntry] {
        if isExpanded { return day.meals }
        let main = day.meals.filter { $0.mealType != .snack }
        return Array(main.prefix(3))
    }

    private var showsSnackCollapsedHint: Bool {
        !isExpanded && day.meals.contains(where: { $0.mealType == .snack })
    }

    private func formattedDate(_ iso: String) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = .autoupdatingCurrent
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: iso) else { return iso }
        let out = DateFormatter()
        out.calendar = f.calendar
        out.locale = .autoupdatingCurrent
        out.dateStyle = .medium
        out.timeStyle = .none
        return out.string(from: d)
    }
}

private struct MealRowView: View {
    let meal: MealEntry
    var showLogButton: Bool = false
    var onLogMeal: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(mealTypeLabel)
                    .font(TypographyToken.inter(size: 11, weight: .medium))
                    .foregroundStyle(ColorToken.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(meal.name)
                    .font(TypographyToken.inter(size: 14, weight: .medium))
                    .foregroundStyle(ColorToken.textPrimary)
                    .lineLimit(1)
                Text("P: \(Int(meal.protein))g · C: \(Int(meal.carbs))g · F: \(Int(meal.fat))g")
                    .font(TypographyToken.inter(size: 11, weight: .regular))
                    .foregroundStyle(ColorToken.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("\(Int(meal.calories)) kcal")
                    .font(TypographyToken.inter(size: 13, weight: .semibold))
                    .foregroundStyle(ColorToken.textSecondary)

                if showLogButton, let onLogMeal {
                    Button(action: onLogMeal) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(ColorToken.primary)
                            .frame(width: 28, height: 28)
                            .background(ColorToken.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 7)
    }

    private var mealTypeLabel: String {
        switch meal.mealType {
        case .breakfast: return String(localized: "meal_type.breakfast")
        case .lunch: return String(localized: "meal_type.lunch")
        case .dinner: return String(localized: "meal_type.dinner")
        case .snack: return String(localized: "meal_type.snack")
        }
    }

    private var emoji: String {
        switch meal.mealType {
        case .breakfast: return "🥣"
        case .lunch: return "🥗"
        case .dinner: return "🍽️"
        case .snack: return "🍎"
        }
    }
}
