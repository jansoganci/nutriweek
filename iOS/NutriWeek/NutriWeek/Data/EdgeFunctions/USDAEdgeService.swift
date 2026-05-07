import Foundation

struct USDAEdgeService {
    private let edgeClient: EdgeFunctionClient
    private let functionName = "usda-search"

    init(edgeClient: EdgeFunctionClient = EdgeFunctionClient()) {
        self.edgeClient = edgeClient
    }

    func searchFoods(query: String, pageSize: Int = 20) async throws -> [FoodSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let payload = USDARequest(query: trimmed, pageSize: pageSize)
        let response: USDAResponse = try await edgeClient.invoke(functionName, payload: payload)
        return response.foods.map { $0.toDomain() }
    }
}

private struct USDARequest: Encodable {
    let query: String
    let pageSize: Int
}

private struct USDAResponse: Decodable {
    let foods: [USDAFood]
}

private struct USDAFood: Decodable {
    let fdcId: Int
    let description: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: Double

    func toDomain() -> FoodSearchResult {
        FoodSearchResult(
            fdcId: fdcId,
            description: description,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            servingSize: servingSize
        )
    }
}
