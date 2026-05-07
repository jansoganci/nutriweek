import XCTest
@testable import NutriWeek

final class MealPlanMapperTests: XCTestCase {
    func testMapperConvertsGemmaWeekIntoDomainPlan() {
        let dto = GemmaWeeklyPlanDTO(
            weekOf: "2026-05-04",
            days: [
                GemmaDayDTO(
                    day: "Monday",
                    date: "2026-05-04",
                    totalCalories: 2100,
                    meals: [
                        GemmaMealDTO(
                            type: "Breakfast",
                            name: "Oats",
                            calories: 400,
                            emoji: "🥣",
                            protein: 20,
                            carbs: 50,
                            fat: 12
                        )
                    ]
                )
            ]
        )

        let plan = MealPlanMapper.toDomain(dto: dto, rowId: "week-id", generatedAt: "2026-05-04T12:00:00Z")

        XCTAssertEqual(plan.id, "week-id")
        XCTAssertEqual(plan.weekStartDate, "2026-05-04")
        XCTAssertEqual(plan.days.count, 1)
        XCTAssertEqual(plan.days[0].date, "2026-05-04")
        XCTAssertEqual(plan.days[0].meals.first?.mealType, .breakfast)
    }
}

