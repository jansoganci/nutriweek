import SwiftUI

struct MealPlanHomeView: View {
    let mealPlanRepository: MealPlanRepositoryProtocol
    let foodLogRepository: FoodLogRepositoryProtocol
    let streakService: StreakService?
    var onSwitchToLogTab: () -> Void = {}

    @State private var targets: CalculationResults?
    @State private var consumed = FoodMacroResult(calories: 0, protein: 0, carbs: 0, fat: 0)
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
    @State private var daysReady = 0
    @State private var partialDays: [DayPlan] = []

    private let funFacts = [
        "Raccoons can open locks! 🔓",
        "A raccoon's hands have 5 fingers — just like yours 🖐️",
        "Protein keeps you full for longer than carbs or fat! 💪",
        "Eating slowly helps you eat 10-15% fewer calories! 🍽️",
    ]

    init(
        mealPlanRepository: MealPlanRepositoryProtocol,
        foodLogRepository: FoodLogRepositoryProtocol,
        streakService: StreakService? = nil,
        onSwitchToLogTab: @escaping () -> Void = {}
    ) {
        self.mealPlanRepository = mealPlanRepository
        self.foodLogRepository = foodLogRepository
        self.streakService = streakService
        self.onSwitchToLogTab = onSwitchToLogTab
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    streakRow
                    macroSummary
                    weeklySection
                }
                .padding(.horizontal, SpacingToken.gutter)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(ColorToken.background)

            Button {
                onSwitchToLogTab()
            } label: {
                Text("+")
                    .font(TypographyToken.inter(size: 30, weight: .regular))
                    .foregroundStyle(Color.white)
                    .frame(width: 56, height: 56)
                    .background(ColorToken.primary)
                    .clipShape(Circle())
                    .shadow(color: ColorToken.primary.opacity(0.35), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.trailing, SpacingToken.gutter)
            .padding(.bottom, 148)

            if showInfoToast {
                ToastView(
                    title: "Plan updated",
                    subtitle: "Your new weekly plan is ready.",
                    style: .success
                )
                .padding(.horizontal, SpacingToken.gutter)
                .padding(.bottom, 88)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await initialize() }
        .alert("Rocky says...", isPresented: $showFunFact) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(funFactText)
        }
        .sheet(isPresented: $showGeneratePrompt) {
            generatePromptSheet
                .presentationDetents([.height(330)])
                .presentationDragIndicator(.visible)
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
                Text("Hey there! 👊")
                    .font(TypographyToken.inter(size: 14, weight: .regular))
                    .foregroundStyle(ColorToken.textSecondary)
            }
            Spacer(minLength: 0)
            Button {
                funFactText = funFacts.randomElement() ?? "Rocky says hi!"
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
            Text(streak > 0 ? "🔥 \(streak) day streak" : "🌱 Start your streak today!")
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
            if targetCals == 0 { return "Complete onboarding to see targets" }
            if remaining >= 0 { return "\(remaining) kcal remaining" }
            return "\(abs(remaining)) kcal over target 😅"
        }()

        return VStack(alignment: .leading, spacing: 16) {
            Text("Today's Progress")
                .font(TypographyToken.inter(size: 13, weight: .semibold))
                .foregroundStyle(ColorToken.textSecondary)
                .tracking(0.8)
                .textCase(.uppercase)

            HStack(alignment: .top, spacing: 12) {
                MacroRingView(label: "Calories", current: consumed.calories, target: targetCals, unit: "kcal", color: Color(hex: "#FF6B35"), size: 72, strokeWidth: 7)
                MacroRingView(label: "Protein", current: consumed.protein, target: targetProtein, unit: "g", color: Color(hex: "#4CAF50"), size: 72, strokeWidth: 7)
                MacroRingView(label: "Carbs", current: consumed.carbs, target: targetCarbs, unit: "g", color: Color(hex: "#FFB300"), size: 72, strokeWidth: 7)
                MacroRingView(label: "Fat", current: consumed.fat, target: targetFat, unit: "g", color: Color(hex: "#64B5F6"), size: 72, strokeWidth: 7)
            }
            .frame(maxWidth: .infinity)

            Text(remainingText)
                .font(TypographyToken.inter(size: 13, weight: .regular))
                .foregroundStyle(remaining < 0 && targetCals > 0 ? ColorToken.destructive : ColorToken.textSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
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

    private var weeklySection: some View {
        let weekSlots = isoWeekMondayThroughSunday()
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("This Week")
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
                    Text("\(daysReady)/7 days ready")
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
                    title: "Could not load your plan",
                    message: refreshError,
                    retryTitle: "Retry"
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
                        }
                    )
                }
            } else if loaded, showEmpty {
                VStack(spacing: 10) {
                    RockyMascotView(mood: .thinking, size: RockyMascotView.Size.large.rawValue)
                    Text("No plan yet!")
                        .font(TypographyToken.inter(size: 20, weight: .bold))
                        .foregroundStyle(ColorToken.textPrimary)
                    Text("Let Rocky build your personalized 7-day meal plan")
                        .font(TypographyToken.inter(size: 14, weight: .regular))
                        .foregroundStyle(ColorToken.textSecondary)
                        .multilineTextAlignment(.center)
                    Button {
                        showGeneratePrompt = true
                    } label: {
                        Text("Generate My Plan")
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
            Text("Ready to build your first meal plan?")
                .font(TypographyToken.inter(size: 20, weight: .bold))
                .foregroundStyle(ColorToken.textPrimary)
                .multilineTextAlignment(.center)
            Text("I'll create a personalized 7-day plan based on your goals 🎯")
                .font(TypographyToken.inter(size: 14, weight: .regular))
                .foregroundStyle(ColorToken.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                pendingGenerateAfterSheet = true
                showGeneratePrompt = false
            } label: {
                Text("Let's go!")
                    .font(TypographyToken.inter(size: 17, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ColorToken.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Button("Maybe later") {
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
        if h >= 5, h < 11 { return "Good morning!" }
        if h >= 11, h < 17 { return "Good afternoon!" }
        if h >= 17, h < 22 { return "Good evening!" }
        return "Still up?"
    }

    private var todayISO: String {
        let f = ISO8601DateFormatter()
        return String(f.string(from: Date()).prefix(10))
    }

    private func initialize() async {
        await loadTargets()
        await loadWeeklyPlan()
        await loadConsumedAndStreak()
        loaded = true
    }

    private func loadTargets() async {
        do {
            let onboarding = try await OnboardingService.fetchOnboardingProfile()
            if let profile = UserProfile(onboarding: onboarding) {
                targets = NutritionCalculationService.calculateAll(profile: profile)
            }
        } catch {
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

    private func handleGenerate() async {
        guard !isGenerating else { return }
        guard let calorieTarget = targets?.targetCalories, let macros = targets?.macros else {
            refreshError = "Complete onboarding to generate your plan."
            return
        }

        let slots = isoWeekMondayThroughSunday()
        guard slots.count == 7 else {
            refreshError = "Could not load this week's schedule."
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
                refreshError = "Complete onboarding to generate your plan."
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
                            refreshError = "\(slot.weekdayName) günü planı oluşturulamadı, tekrar deneniyor..."
                        } else {
                            refreshError = "\(slot.weekdayName) günü planı oluşturulamadı. Lütfen tekrar deneyin."
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
                refreshError = "Something went wrong while generating your plan."
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
                refreshError = "Something went wrong while generating your plan."
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
        let weekdayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: reference))
        else { return [] }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        return weekdayNames.indices.compactMap { index in
            guard let date = calendar.date(byAdding: .day, value: index, to: weekStart) else { return nil }
            return IsoWeekDaySlot(
                weekdayName: weekdayNames[index],
                dateISO: formatter.string(from: date)
            )
        }
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

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 12) {
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
                            Text("Today")
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

                VStack(spacing: 0) {
                    ForEach(Array(displayMeals.enumerated()), id: \.offset) { idx, meal in
                        if idx > 0 {
                            Rectangle()
                                .fill(ColorToken.border)
                                .frame(height: 1)
                                .padding(.leading, 36)
                        }
                        MealRowView(meal: meal)
                    }
                    if !isExpanded, day.meals.contains(where: { $0.mealType == .snack }) {
                        Text("🍎 Snack  ▾")
                            .font(TypographyToken.inter(size: 12, weight: .medium))
                            .foregroundStyle(ColorToken.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#F1F1F1"))
                            .clipShape(Capsule())
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
        .buttonStyle(.plain)
    }

    private var dayTitle: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        if let d = f.date(from: day.date) {
            let out = DateFormatter()
            out.dateFormat = "EEEE"
            return out.string(from: d)
        }
        return "Day"
    }

    private var totalCalories: Double {
        day.meals.reduce(0) { $0 + $1.calories }
    }

    private var displayMeals: [MealEntry] {
        if isExpanded { return day.meals }
        let main = day.meals.filter { $0.mealType != .snack }
        return Array(main.prefix(3))
    }

    private func formattedDate(_ iso: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: iso) else { return iso }
        let out = DateFormatter()
        out.dateFormat = "MMM d"
        return out.string(from: d)
    }
}

private struct MealRowView: View {
    let meal: MealEntry

    var body: some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(mealTypeLabel)
                    .font(TypographyToken.inter(size: 11, weight: .medium))
                    .foregroundStyle(ColorToken.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(meal.name)
                    .font(TypographyToken.inter(size: 14, weight: .medium))
                    .foregroundStyle(ColorToken.textPrimary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text("\(Int(meal.calories)) kcal")
                .font(TypographyToken.inter(size: 13, weight: .semibold))
                .foregroundStyle(ColorToken.textSecondary)
        }
        .padding(.vertical, 7)
    }

    private var mealTypeLabel: String {
        switch meal.mealType {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
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
