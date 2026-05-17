import Foundation
import Observation

@Observable
@MainActor
final class MainTabCoordinator {
    enum Tab: Hashable {
        case mealPlan
        case quickLog
        case activity
        case profile
    }

    var selectedTab: Tab = .mealPlan
    let mealPlanRepository: MealPlanRepositoryProtocol
    let foodLogRepository: FoodLogRepositoryProtocol
    let activityLogRepository: ActivityLogRepositoryProtocol
    let streakService: StreakService?

    init(
        mealPlanRepository: MealPlanRepositoryProtocol,
        foodLogRepository: FoodLogRepositoryProtocol,
        activityLogRepository: ActivityLogRepositoryProtocol,
        streakService: StreakService? = nil
    ) {
        self.mealPlanRepository = mealPlanRepository
        self.foodLogRepository = foodLogRepository
        self.activityLogRepository = activityLogRepository
        self.streakService = streakService
    }
}
