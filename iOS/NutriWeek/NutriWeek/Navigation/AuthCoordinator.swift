import Foundation
import Observation

@Observable
@MainActor
final class AuthCoordinator {
    enum Route {
        case login
        case register
    }

    var route: Route = .login
    let authViewModel: AuthViewModel

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    func showLogin() {
        authViewModel.goToLogin()
        route = .login
    }

    func showRegister() {
        route = .register
    }
}
