import Foundation

protocol AuthRepositoryProtocol: Sendable {
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String) async throws
    func signOut() async throws
    func currentSession() async throws -> Bool
    func authStateStream() -> AsyncStream<Bool>
}
