import Foundation

struct FoodSearchResult: Codable, Equatable, Sendable {
    var fdcId: Int
    var description: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var servingSize: Double
}

struct FoodMacroResult: Codable, Equatable, Sendable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
}

struct FoodLogEntry: Codable, Equatable, Sendable {
    var id: String
    var foodName: String
    var grams: Double
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var loggedAt: String
    var date: String
}
