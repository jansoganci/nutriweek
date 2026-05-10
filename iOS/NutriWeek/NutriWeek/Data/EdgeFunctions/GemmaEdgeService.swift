import Foundation

/// Shared inputs for Gemma edge prompts (matches `gemma-generate-week` / `gemma-generate-day` bodies).
struct GemmaPlanTargets: Encodable, Sendable {
    let profile: UserProfile
    let targetCalories: Int
    let macros: MacroGrams
}

struct GemmaEdgeService {
    private let edgeClient: EdgeFunctionClient
    private let weekFunctionName = "gemma-generate-week"

    init(edgeClient: EdgeFunctionClient = EdgeFunctionClient()) {
        self.edgeClient = edgeClient
    }

    func generateWeeklyPlan() async throws -> GemmaWeeklyPlanDTO {
        let payload = GemmaGenerateWeekRequest()
        return try await edgeClient.invoke(weekFunctionName, payload: payload)
    }

    func generateDay(dayName: String, date: String, targets: GemmaPlanTargets) async throws -> GemmaDayDTO {
        let payload = GemmaGenerateDayRequest(
            profile: targets.profile,
            targetCalories: targets.targetCalories,
            macros: targets.macros,
            dayName: dayName,
            date: date
        )
        return try await edgeClient.invoke("gemma-generate-day", payload: payload)
    }
}

struct GemmaGenerateWeekRequest: Encodable {}

private struct GemmaGenerateDayRequest: Encodable {
    let profile: UserProfile
    let targetCalories: Int
    let macros: MacroGrams
    let dayName: String
    let date: String
}

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
