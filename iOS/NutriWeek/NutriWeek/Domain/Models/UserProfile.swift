import Foundation

struct UserProfile: Codable, Equatable, Sendable {
    var gender: Gender
    var age: Int
    var height: Double
    var weight: Double
    var activityLevel: ActivityLevel
    var goal: Goal
    var measurements: BodyMeasurements?
    var dietaryPreferences: [DietaryPreference]
    var onboardingComplete: Bool
    var createdAt: String
    var updatedAt: String
}
