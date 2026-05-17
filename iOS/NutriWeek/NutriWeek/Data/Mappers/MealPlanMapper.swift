import Foundation
import os

enum MealPlanMapper {
    struct WeeklyPlanRow: Decodable {
        let id: String
        let week_start_date: String
        let plan_json: GemmaWeeklyPlanDTO
        let generated_at: String
    }

    struct WeeklyPlanUpsert: Encodable {
        let user_id: String
        let week_start_date: String
        let plan_json: GemmaWeeklyPlanDTO
        let generated_at: String
    }

    static func toDomain(dto: GemmaWeeklyPlanDTO, rowId: String = UUID().uuidString, generatedAt: String = Date().ISO8601Format()) -> WeeklyPlan {
        WeeklyPlan(
            id: rowId,
            weekStartDate: dto.weekOf,
            days: dto.days.map(dayPlan(from:)),
            generatedAt: generatedAt
        )
    }

    static func dayPlan(from day: GemmaDayDTO) -> DayPlan {
        let meals = day.meals.enumerated().map { idx, meal in
            MealEntry(
                id: "\(day.date)-\(idx)",
                name: meal.name,
                calories: meal.calories,
                protein: meal.protein,
                carbs: meal.carbs,
                fat: meal.fat,
                fiber: nil,
                servingSize: nil,
                mealType: mealType(from: meal.type),
                loggedAt: day.date
            )
        }
        return DayPlan(
            date: day.date,
            meals: meals,
            targetMacros: DailyMacros(calories: day.totalCalories, protein: 0, carbs: 0, fat: 0),
            loggedMacros: DailyMacros(calories: 0, protein: 0, carbs: 0, fat: 0)
        )
    }

    static func toDomain(_ row: WeeklyPlanRow) -> WeeklyPlan {
        toDomain(dto: row.plan_json, rowId: row.id, generatedAt: row.generated_at)
    }

    static func toUpsert(_ plan: WeeklyPlan, userId: String) -> WeeklyPlanUpsert {
        WeeklyPlanUpsert(
            user_id: userId,
            week_start_date: plan.weekStartDate,
            plan_json: toGemmaDTO(plan),
            generated_at: plan.generatedAt
        )
    }

    private static func toGemmaDTO(_ plan: WeeklyPlan) -> GemmaWeeklyPlanDTO {
        GemmaWeeklyPlanDTO(
            weekOf: plan.weekStartDate,
            days: plan.days.map { day in
                GemmaDayDTO(
                    day: weekdayName(for: day.date),
                    date: day.date,
                    totalCalories: day.meals.reduce(0) { $0 + $1.calories },
                    meals: day.meals.map { meal in
                        GemmaMealDTO(
                            type: mealTypeLabel(meal.mealType),
                            name: meal.name,
                            calories: meal.calories,
                            emoji: "🍽️",
                            protein: meal.protein,
                            carbs: meal.carbs,
                            fat: meal.fat,
                            dietaryTags: nil,
                            cuisine: nil,
                            ingredients: nil
                        )
                    }
                )
            }
        )
    }

    private static func mealType(from text: String) -> MealType {
        switch text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines) {
        case "breakfast", "kahvalti":
            return .breakfast
        case "lunch", "ogle yemegi":
            return .lunch
        case "dinner", "aksam yemegi":
            return .dinner
        case "snack", "atistirmalik", "ara ogun":
            return .snack
        default:
            os_log("Warning: unexpected meal type received: %{public}@", log: .default, type: .default, text)
            return .snack
        }
    }

    private static func mealTypeLabel(_ type: MealType) -> String {
        switch type {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }

    private static func weekdayName(for isoDate: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: isoDate) else { return "Unknown" }
        let output = DateFormatter()
        output.dateFormat = "EEEE"
        return output.string(from: date)
    }
}
