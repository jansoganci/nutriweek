import Foundation

struct SupabaseOnboardingRepository: OnboardingRepositoryProtocol {
    func fetchOnboardingProfile() async throws -> OnboardingProfile {
        try await OnboardingService.fetchOnboardingProfile()
    }

    func saveStep1(
        gender: Gender,
        age: Int,
        heightCm: Double,
        weightKg: Double,
        activityLevel: ActivityLevel
    ) async throws {
        try await OnboardingService.saveStep1(
            gender: gender,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            activityLevel: activityLevel
        )
    }

    func saveStep2(goal: Goal) async throws {
        try await OnboardingService.saveStep2(goal: goal)
    }

    func saveStep3(
        waistCm: Double?,
        hipsCm: Double?,
        chestCm: Double?,
        leftArmCm: Double?,
        leftLegCm: Double?
    ) async throws {
        try await OnboardingService.saveStep3(
            waistCm: waistCm,
            hipsCm: hipsCm,
            chestCm: chestCm,
            leftArmCm: leftArmCm,
            leftLegCm: leftLegCm
        )
    }

    func saveStep4(dietaryPreferences: [String]) async throws {
        try await OnboardingService.saveStep4(dietaryPreferences: dietaryPreferences)
    }

    func saveResults(_ results: CalculationResults) async throws {
        try await OnboardingService.saveCalculatedResults(results)
    }
}
