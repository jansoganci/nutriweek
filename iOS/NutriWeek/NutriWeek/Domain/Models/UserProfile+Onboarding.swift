import Foundation

extension UserProfile {
    /// Builds a profile for `NutritionCalculationService.calculateAll` from fetched onboarding row.
    init?(onboarding profile: OnboardingProfile) {
        guard let gender = profile.gender,
              let age = profile.age,
              let height = profile.heightCm,
              let weight = profile.weightKg,
              let activityLevel = profile.activityLevel,
              let goal = profile.goal
        else { return nil }

        self.init(
            gender: gender,
            age: age,
            height: height,
            weight: weight,
            activityLevel: activityLevel,
            goal: goal,
            measurements: nil,
            dietaryPreferences: profile.dietaryPreferenceKeys.compactMap(DietaryPreference.init(rawValue:)),
            onboardingComplete: profile.onboardingComplete,
            createdAt: "",
            updatedAt: ""
        )
    }
}
