import Foundation

enum DietaryPreference: String, Codable, CaseIterable, Sendable {
    case vegetarian
    case vegan
    case glutenFree = "gluten_free"
    case dairyFree = "dairy_free"
    case keto
    case paleo
    case halal
    case kosher
    case nutFree = "nut_free"
    case lowSodium = "low_sodium"
}
