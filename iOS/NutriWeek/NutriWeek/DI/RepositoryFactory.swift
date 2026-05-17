import Foundation

struct RepositoryFactory {
    let authRepository: AuthRepositoryProtocol
    let onboardingRepository: OnboardingRepositoryProtocol
    let foodLogRepository: FoodLogRepositoryProtocol
    let mealPlanRepository: MealPlanRepositoryProtocol
    let activityLogRepository: ActivityLogRepositoryProtocol

    static let live = RepositoryFactory(
        authRepository: SupabaseAuthRepository(),
        onboardingRepository: SupabaseOnboardingRepository(),
        foodLogRepository: SupabaseFoodLogRepository(),
        mealPlanRepository: SupabaseMealPlanRepository(),
        activityLogRepository: SupabaseActivityLogRepository()
    )
}
