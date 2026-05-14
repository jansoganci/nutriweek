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

    func generateWeeklyPlan(targets: GemmaPlanTargets, weekStartDate: String) async throws -> GemmaWeeklyPlanDTO {
        let payload = GemmaGenerateWeekRequest(
            profile: targets.profile,
            targetCalories: targets.targetCalories,
            macros: targets.macros,
            weekStartDate: weekStartDate
        )
        return try await edgeClient.invoke(weekFunctionName, payload: payload)
    }

    func generateDay(dayName: String, date: String, targets: GemmaPlanTargets, excludeMealNames: [String]) async throws -> GemmaDayDTO {
        let payload = GemmaGenerateDayRequest(
            profile: targets.profile,
            targetCalories: targets.targetCalories,
            macros: targets.macros,
            dayName: dayName,
            date: date,
            excludeMealNames: excludeMealNames
        )
        let startedAt = Date()
        print("[GemmaEdgeService] day_request_start day=\(dayName) at=\(startedAt.ISO8601Format())")
        do {
            let dto: GemmaDayDTO = try await edgeClient.invoke("gemma-generate-day", payload: payload)
            let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
            print("[GemmaEdgeService] day_request_success day=\(dayName) elapsed_ms=\(elapsedMs)")
            return dto
        } catch {
            let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
            print("[GemmaEdgeService] day_request_failure day=\(dayName) elapsed_ms=\(elapsedMs) message=\(error.localizedDescription)")
            throw error
        }
    }
}

private struct GemmaGenerateWeekRequest: Encodable {
    let profile: UserProfile
    let targetCalories: Int
    let macros: MacroGrams
    let weekStartDate: String
}

private struct GemmaGenerateDayRequest: Encodable {
    let profile: UserProfile
    let targetCalories: Int
    let macros: MacroGrams
    let dayName: String
    let date: String
    let excludeMealNames: [String]
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
    let dietaryTags: [String]?
    let cuisine: String?
    let ingredients: [String]?

    enum CodingKeys: String, CodingKey {
        case type
        case name
        case calories
        case emoji
        case protein
        case carbs
        case fat
        case dietaryTags = "dietary_tags"
        case cuisine
        case ingredients
    }
}
