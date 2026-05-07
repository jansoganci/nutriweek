import Foundation

struct MealEntry: Codable, Equatable, Sendable {
    var id: String
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double?
    var servingSize: String?
    var mealType: MealType
    var loggedAt: String
}
