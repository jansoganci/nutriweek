import Foundation

protocol ProfileRepositoryProtocol: Sendable {
    func loadProfile() async throws -> UserProfile
    func saveProfile(_ profile: UserProfile) async throws
    func saveMeasurements(_ measurements: BodyMeasurements) async throws
    func resetData() async throws
}
