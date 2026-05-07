import Foundation

@MainActor
final class AppContainer {
    let repositories: RepositoryFactory

    init(repositories: RepositoryFactory = .live) {
        self.repositories = repositories
    }

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(repository: repositories.authRepository)
    }

    func makeAppCoordinator() -> AppCoordinator {
        AppCoordinator(
            authViewModel: makeAuthViewModel(),
            onboardingRepository: repositories.onboardingRepository,
            mealPlanRepository: repositories.mealPlanRepository,
            foodLogRepository: repositories.foodLogRepository
        )
    }
}
