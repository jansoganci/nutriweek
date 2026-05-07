import Foundation

/// Subset of `profiles` + measurements used during onboarding (matches RN `fetchOnboardingProfile`).
struct OnboardingProfile: Equatable, Sendable {
    var gender: Gender?
    var age: Int?
    var heightCm: Double?
    var weightKg: Double?
    var activityLevel: ActivityLevel?
    var goal: Goal?
    var dietaryPreferenceKeys: [String]
    var onboardingComplete: Bool
}
