import Foundation
import Supabase

struct SupabaseMealPlanRepository: MealPlanRepositoryProtocol {
    private let client: SupabaseClient
    private let gemmaService: GemmaEdgeService
    private let cacheStore: WeeklyPlanCacheStore

    init(
        client: SupabaseClient = SupabaseClientFactory.shared,
        gemmaService: GemmaEdgeService = GemmaEdgeService(),
        cacheStore: WeeklyPlanCacheStore = WeeklyPlanCacheStore()
    ) {
        self.client = client
        self.gemmaService = gemmaService
        self.cacheStore = cacheStore
    }

    func loadWeeklyPlan() async throws -> WeeklyPlan? {
        let userId = try await requireUserId()

        do {
            let rows: [MealPlanMapper.WeeklyPlanRow] = try await client.from("weekly_meal_plans")
                .select("id, week_start_date, plan_json, generated_at")
                .eq("user_id", value: userId)
                .order("week_start_date", ascending: false)
                .limit(1)
                .execute()
                .value
            let plan = rows.first.map(MealPlanMapper.toDomain)
            if let plan {
                try? cacheStore.save(plan, for: userId)
            }
            return plan
        } catch {
            return try cacheStore.load(for: userId)
        }
    }

    func saveWeeklyPlan(_ plan: WeeklyPlan) async throws {
        let userId = try await requireUserId()
        let payload = MealPlanMapper.toUpsert(plan, userId: userId)
        try await client.from("weekly_meal_plans")
            .upsert(payload, onConflict: "user_id,week_start_date")
            .execute()
        try? cacheStore.save(plan, for: userId)
    }

    func generateWeeklyPlan() async throws -> WeeklyPlan {
        let onboardingProfile = try await OnboardingService.fetchOnboardingProfile()
        guard let profile = UserProfile(onboarding: onboardingProfile) else {
            throw MealPlanGenerationError.profileIncomplete
        }
        let calculations = NutritionCalculationService.calculateAll(profile: profile)
        let targets = GemmaPlanTargets(
            profile: profile,
            targetCalories: calculations.targetCalories,
            macros: calculations.macros
        )
        let weekStart = Self.isoWeekStartMondayISO()
        let generated = try await gemmaService.generateWeeklyPlan(targets: targets, weekStartDate: weekStart)
        let weeklyPlan = MealPlanMapper.toDomain(dto: generated)
        try await saveWeeklyPlan(weeklyPlan)
        return weeklyPlan
    }

    /// ISO-8601 Monday date for the current week (matches meal plan home week slots).
    private static func isoWeekStartMondayISO(reference: Date = Date()) -> String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: reference))
        else {
            return String(ISO8601DateFormatter().string(from: reference).prefix(10))
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: weekStart)
    }

    func generateDay(dayName: String, date: String, targets: GemmaPlanTargets, excludeMealNames: [String]) async throws -> DayPlan {
        let dto = try await gemmaService.generateDay(
            dayName: dayName,
            date: date,
            targets: targets,
            excludeMealNames: excludeMealNames
        )
        return MealPlanMapper.dayPlan(from: dto)
    }

    private func requireUserId() async throws -> String {
        let session = try await client.auth.session
        return session.user.id.uuidString
    }
}
