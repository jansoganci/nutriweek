import Foundation

protocol ActivityLogRepositoryProtocol: Sendable {
    func loadEntries() async throws -> [ActivityLogEntry]
    func loadEntries(for date: Date) async throws -> [ActivityLogEntry]
    func loadEntries(from startDate: Date, to endDate: Date) async throws -> [ActivityLogEntry]
    func addEntry(_ entry: ActivityLogEntry) async throws
    func updateEntry(_ entry: ActivityLogEntry) async throws
    func deleteEntry(id: String) async throws
    func totalCaloriesBurned(for date: Date) async throws -> Double
    func totalCaloriesBurned(from startDate: Date, to endDate: Date) async throws -> Double
}
