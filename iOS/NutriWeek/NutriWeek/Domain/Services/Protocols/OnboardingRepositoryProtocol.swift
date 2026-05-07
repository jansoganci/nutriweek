import Foundation

protocol OnboardingRepositoryProtocol: Sendable {
    func fetchOnboardingProfile() async throws -> OnboardingProfile
    func saveStep1(
        gender: Gender,
        age: Int,
        heightCm: Double,
        weightKg: Double,
        activityLevel: ActivityLevel
    ) async throws
    func saveStep2(goal: Goal) async throws
    func saveStep3(
        waistCm: Double?,
        hipsCm: Double?,
        chestCm: Double?,
        leftArmCm: Double?,
        leftLegCm: Double?
    ) async throws
    func saveStep4(dietaryPreferences: [String]) async throws
    func saveResults(_ results: CalculationResults) async throws
}
