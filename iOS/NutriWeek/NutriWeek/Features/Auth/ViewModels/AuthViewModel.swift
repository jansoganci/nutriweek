import Foundation
import Observation

@Observable
@MainActor
final class AuthViewModel {
    private let repository: AuthRepositoryProtocol
    private var authListenerTask: Task<Void, Never>?

    var email = ""
    var password = ""
    var confirmPassword = ""

    var isLoading = false
    var errorMessage: String?
    var isAuthenticated = false

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
        authListenerTask = Task { [weak self] in
            guard let self else { return }
            do {
                isAuthenticated = try await repository.currentSession()
            } catch {
                isAuthenticated = false
            }

            for await sessionState in repository.authStateStream() {
                isAuthenticated = sessionState
            }
        }
    }

    func signIn() async {
        errorMessage = nil

        guard isValidEmail(email) else {
            errorMessage = String(localized: "auth.validation.email_invalid")
            return
        }

        guard password.count >= 6 else {
            errorMessage = String(localized: "auth.validation.password_short")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            isAuthenticated = true
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func signUp() async {
        errorMessage = nil

        guard isValidEmail(email) else {
            errorMessage = String(localized: "auth.validation.email_invalid")
            return
        }

        guard password.count >= 6 else {
            errorMessage = String(localized: "auth.validation.password_short")
            return
        }

        guard password == confirmPassword else {
            errorMessage = String(localized: "auth.validation.passwords_mismatch")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.signUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            isAuthenticated = true
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func goToLogin() {
        errorMessage = nil
        confirmPassword = ""
    }

    func signOut() async {
        do {
            try await repository.signOut()
        } catch {
            // Keep UX simple for Phase 2; session is still considered logged out locally.
        }

        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
        isAuthenticated = false
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    private func friendlyMessage(for error: Error) -> String {
        let text = error.localizedDescription
        if text.isEmpty {
            return String(localized: "auth.error.generic_retry")
        }
        return text
    }
}
