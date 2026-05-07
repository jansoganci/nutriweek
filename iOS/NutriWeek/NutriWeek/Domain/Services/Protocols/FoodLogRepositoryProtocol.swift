import Foundation

protocol FoodLogRepositoryProtocol: Sendable {
    func searchFoods(query: String) async throws -> [FoodSearchResult]
    func loadTodayLog() async throws -> [FoodLogEntry]
    func addLogEntry(_ entry: FoodLogEntry) async throws
    func removeLogEntry(id: String) async throws
    func sumMacros(entries: [FoodLogEntry]) -> FoodMacroResult
}
