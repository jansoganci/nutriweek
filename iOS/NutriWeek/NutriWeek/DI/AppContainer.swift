import Foundation

@MainActor
final class AppContainer {
    let repositories: RepositoryFactory
    let streakService: StreakService

    init(
        repositories: RepositoryFactory = .live,
        streakService: StreakService = SupabaseStreakService()
    ) {
        self.repositories = repositories
        self.streakService = streakService
    }

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(repository: repositories.authRepository)
    }

    func makeAppCoordinator() -> AppCoordinator {
        AppCoordinator(
            authViewModel: makeAuthViewModel(),
            onboardingRepository: repositories.onboardingRepository,
            mealPlanRepository: repositories.mealPlanRepository,
            foodLogRepository: repositories.foodLogRepository,
            streakService: streakService
        )
    }
}
