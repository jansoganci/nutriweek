import Foundation

protocol StreakService: Sendable {
    func loadStreak() async throws -> Int
    func updateStreak() async throws -> Int
}
