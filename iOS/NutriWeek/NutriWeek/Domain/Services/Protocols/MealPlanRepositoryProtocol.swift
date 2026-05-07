import Foundation

protocol MealPlanRepositoryProtocol: Sendable {
    func loadWeeklyPlan() async throws -> WeeklyPlan?
    func saveWeeklyPlan(_ plan: WeeklyPlan) async throws
    func generateWeeklyPlan() async throws -> WeeklyPlan
}
