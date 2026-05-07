import Foundation

struct DayPlan: Codable, Equatable, Sendable {
    var date: String
    var meals: [MealEntry]
    var targetMacros: DailyMacros
    var loggedMacros: DailyMacros
}
