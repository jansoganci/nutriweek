import Foundation
import Observation

@Observable
@MainActor
final class AppCoordinator {
    enum Route {
        case bootstrapping
        case auth
        case onboarding
        case main
    }

    var route: Route = .bootstrapping
    let authCoordinator: AuthCoordinator
    let onboardingCoordinator: OnboardingCoordinator
    let mainTabCoordinator: MainTabCoordinator
    private let onboardingRepository: OnboardingRepositoryProtocol
    private var refreshTask: Task<Void, Never>?

    init(
        authViewModel: AuthViewModel,
        onboardingRepository: OnboardingRepositoryProtocol,
        mealPlanRepository: MealPlanRepositoryProtocol,
        foodLogRepository: FoodLogRepositoryProtocol
    ) {
        self.authCoordinator = AuthCoordinator(authViewModel: authViewModel)
        self.onboardingCoordinator = OnboardingCoordinator()
        self.mainTabCoordinator = MainTabCoordinator(
            mealPlanRepository: mealPlanRepository,
            foodLogRepository: foodLogRepository
        )
        self.onboardingRepository = onboardingRepository
        self.onboardingCoordinator.onFinish = { [weak self] in
            self?.finishOnboarding()
        }
    }

    func start() {
        refreshRoute()
    }

    func finishOnboarding() {
        route = .main
        onboardingCoordinator.reset()
    }

    func refreshRoute() {
        refreshTask?.cancel()
        refreshTask = Task { await refreshRouteAsync() }
    }

    private func refreshRouteAsync() async {
        route = .bootstrapping

        guard authCoordinator.authViewModel.isAuthenticated else {
            authCoordinator.showLogin()
            route = .auth
            onboardingCoordinator.reset()
            return
        }

        do {
            let profile = try await onboardingRepository.fetchOnboardingProfile()
            if profile.onboardingComplete {
                route = .main
                onboardingCoordinator.reset()
            } else {
                route = .onboarding
                onboardingCoordinator.reset()
            }
        } catch {
            // Keep RN parity: on profile check failure, continue with onboarding.
            route = .onboarding
            onboardingCoordinator.reset()
        }
    }
}
