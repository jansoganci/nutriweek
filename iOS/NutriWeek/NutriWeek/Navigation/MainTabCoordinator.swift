import Foundation
import Observation

@Observable
@MainActor
final class MainTabCoordinator {
    enum Tab: Hashable {
        case mealPlan
        case quickLog
        case profile
    }

    var selectedTab: Tab = .mealPlan
    let mealPlanRepository: MealPlanRepositoryProtocol
    let foodLogRepository: FoodLogRepositoryProtocol
    let streakService: StreakService?

    init(
        mealPlanRepository: MealPlanRepositoryProtocol,
        foodLogRepository: FoodLogRepositoryProtocol,
        streakService: StreakService? = nil
    ) {
        self.mealPlanRepository = mealPlanRepository
        self.foodLogRepository = foodLogRepository
        self.streakService = streakService
    }
}
