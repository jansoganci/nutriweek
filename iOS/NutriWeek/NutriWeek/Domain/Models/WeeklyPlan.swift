import Foundation

struct WeeklyPlan: Codable, Equatable, Sendable {
    var id: String
    var weekStartDate: String
    var days: [DayPlan]
    var generatedAt: String
    var notes: String?
}
