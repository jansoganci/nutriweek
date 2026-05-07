import Foundation

struct RepositoryFactory {
    let authRepository: AuthRepositoryProtocol
    let onboardingRepository: OnboardingRepositoryProtocol
    let foodLogRepository: FoodLogRepositoryProtocol
    let mealPlanRepository: MealPlanRepositoryProtocol

    static let live = RepositoryFactory(
        authRepository: SupabaseAuthRepository(),
        onboardingRepository: SupabaseOnboardingRepository(),
        foodLogRepository: SupabaseFoodLogRepository(),
        mealPlanRepository: SupabaseMealPlanRepository()
    )
}
