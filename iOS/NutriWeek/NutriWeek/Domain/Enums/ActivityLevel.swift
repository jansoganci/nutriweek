import Foundation

enum ActivityLevel: String, Codable, CaseIterable, Sendable {
    case sedentary
    case lightlyActive = "lightly_active"
    case moderatelyActive = "moderately_active"
    case veryActive = "very_active"
    case extraActive = "extra_active"
}
