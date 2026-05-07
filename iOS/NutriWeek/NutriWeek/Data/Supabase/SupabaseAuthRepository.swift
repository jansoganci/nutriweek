import Foundation
import Supabase

struct SupabaseAuthRepository: AuthRepositoryProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientFactory.shared) {
        self.client = client
    }

    func signIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        _ = try await client.auth.signUp(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func currentSession() async throws -> Bool {
        _ = try await client.auth.session
        return true
    }

    func authStateStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let task = Task {
                for await (_, session) in client.auth.authStateChanges {
                    continuation.yield(session != nil)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
