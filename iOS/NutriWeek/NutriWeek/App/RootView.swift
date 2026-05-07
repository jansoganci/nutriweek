import SwiftUI

struct RootView: View {
    private let container: AppContainer
    @State private var coordinator: AppCoordinator

    init() {
        let container = AppContainer()
        self.container = container
        _coordinator = State(initialValue: container.makeAppCoordinator())
    }

    var body: some View {
        Group {
            switch coordinator.route {
            case .bootstrapping:
                ProgressView("Checking your session...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ColorToken.background)
            case .auth:
                switch coordinator.authCoordinator.route {
                case .login:
                    LoginView(
                        viewModel: coordinator.authCoordinator.authViewModel,
                        onShowRegister: coordinator.authCoordinator.showRegister
                    )
                case .register:
                    RegisterView(
                        viewModel: coordinator.authCoordinator.authViewModel,
                        onShowLogin: coordinator.authCoordinator.showLogin
                    )
                }
            case .onboarding:
                OnboardingFlowView(coordinator: coordinator.onboardingCoordinator)
            case .main:
                MainTabView(coordinator: coordinator.mainTabCoordinator)
            }
        }
        .onChange(of: coordinator.authCoordinator.authViewModel.isAuthenticated) { _, _ in
            coordinator.refreshRoute()
        }
        .task {
            coordinator.start()
        }
    }
}
