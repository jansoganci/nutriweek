import Foundation

protocol MealPlanRepositoryProtocol: Sendable {
    func loadWeeklyPlan() async throws -> WeeklyPlan?
    func saveWeeklyPlan(_ plan: WeeklyPlan) async throws
    func generateWeeklyPlan() async throws -> WeeklyPlan
    func generateDay(dayName: String, date: String, targets: GemmaPlanTargets, excludeMealNames: [String]) async throws -> DayPlan
}

enum MealPlanGenerationError: Error {
    case profileIncomplete
}
