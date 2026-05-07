import Foundation

enum FoodLogMapper {
    struct FoodLogRow: Decodable {
        let id: String
        let food_name: String
        let grams: Double
        let calories: Double
        let protein_g: Double
        let carbs_g: Double
        let fat_g: Double
        let logged_at: String
        let log_date: String
    }

    struct FoodLogInsert: Encodable {
        let user_id: String
        let log_date: String
        let food_name: String
        let grams: Double
        let calories: Double
        let protein_g: Double
        let carbs_g: Double
        let fat_g: Double
        let fdc_id: Int?
        let logged_at: String
    }

    static func toDomain(_ row: FoodLogRow) -> FoodLogEntry {
        FoodLogEntry(
            id: row.id,
            foodName: row.food_name,
            grams: row.grams,
            calories: row.calories,
            protein: row.protein_g,
            carbs: row.carbs_g,
            fat: row.fat_g,
            loggedAt: row.logged_at,
            date: row.log_date
        )
    }

    static func toInsert(_ entry: FoodLogEntry, userId: String) -> FoodLogInsert {
        FoodLogInsert(
            user_id: userId,
            log_date: entry.date,
            food_name: entry.foodName,
            grams: entry.grams,
            calories: entry.calories,
            protein_g: entry.protein,
            carbs_g: entry.carbs,
            fat_g: entry.fat,
            fdc_id: nil,
            logged_at: entry.loggedAt
        )
    }
}
