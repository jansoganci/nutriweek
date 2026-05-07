import Foundation

struct GemmaEdgeService {
    private let edgeClient: EdgeFunctionClient
    private let functionName = "gemma-generate-week"

    init(edgeClient: EdgeFunctionClient = EdgeFunctionClient()) {
        self.edgeClient = edgeClient
    }

    func generateWeeklyPlan() async throws -> GemmaWeeklyPlanDTO {
        let payload = GemmaGenerateWeekRequest()
        return try await edgeClient.invoke(functionName, payload: payload)
    }
}

struct GemmaGenerateWeekRequest: Encodable {}

struct GemmaWeeklyPlanDTO: Codable, Sendable {
    let weekOf: String
    let days: [GemmaDayDTO]
}

struct GemmaDayDTO: Codable, Sendable {
    let day: String
    let date: String
    let totalCalories: Double
    let meals: [GemmaMealDTO]
}

struct GemmaMealDTO: Codable, Sendable {
    let type: String
    let name: String
    let calories: Double
    let emoji: String
    let protein: Double
    let carbs: Double
    let fat: Double
}
