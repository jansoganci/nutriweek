import Foundation
import Supabase

struct TrendPoint: Identifiable, Equatable, Sendable {
    let id: String
    let dateLabel: String
    let value: Double
}

struct RepeatMealSuggestion: Identifiable, Equatable, Sendable {
    let id: String
    let template: FoodLogEntry
    let count: Int

    var title: String { template.foodName }
    var subtitle: String {
        "\(count) \(String(localized: "personal.repeat_meals.times")) · \(Int(template.calories.rounded())) kcal"
    }
}

struct PersonalInsightsSnapshot: Equatable, Sendable {
    var caloriesIn: [TrendPoint]
    var caloriesBurned: [TrendPoint]
    var weightTrend: [TrendPoint]
    var repeatMeals: [RepeatMealSuggestion]
}

struct PersonalInsightsService: Sendable {
    let foodLogRepository: FoodLogRepositoryProtocol
    let activityLogRepository: ActivityLogRepositoryProtocol?
    let client: SupabaseClient

    init(
        foodLogRepository: FoodLogRepositoryProtocol,
        activityLogRepository: ActivityLogRepositoryProtocol? = nil,
        client: SupabaseClient = SupabaseClientFactory.shared
    ) {
        self.foodLogRepository = foodLogRepository
        self.activityLogRepository = activityLogRepository
        self.client = client
    }

    func loadSnapshot(days: Int = 7) async throws -> PersonalInsightsSnapshot {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -(days - 1), to: end) ?? end
        let foodEntries = try await foodLogRepository.loadEntries(from: start, to: end)
        let activityEntries = try await loadActivityEntries(from: start, to: end)
        let weightPoints = try await loadWeightTrend(limit: days)

        return PersonalInsightsSnapshot(
            caloriesIn: Self.buildDailyTrend(
                entries: foodEntries,
                start: start,
                days: days,
                value: { $0.calories }
            ),
            caloriesBurned: Self.buildDailyTrend(
                entries: activityEntries,
                start: start,
                days: days,
                value: { $0.caloriesBurned }
            ),
            weightTrend: weightPoints,
            repeatMeals: Self.buildRepeatMeals(from: foodEntries)
        )
    }

    private func loadActivityEntries(from start: Date, to end: Date) async throws -> [ActivityLogEntry] {
        guard let activityLogRepository else { return [] }
        return try await activityLogRepository.loadEntries(from: start, to: end)
    }

    private func loadWeightTrend(limit: Int) async throws -> [TrendPoint] {
        struct WeightRow: Decodable {
            let weight_kg: Double
            let measured_at: SupabaseDate
        }

        let session = try await client.auth.session
        let userId = session.user.id.uuidString

        let rows: [WeightRow] = try await client.from("body_measurements")
            .select("weight_kg, measured_at")
            .eq("user_id", value: userId)
            .not("weight_kg", operator: .is, value: "null")
            .order("measured_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        let formatter = DateFormatter.personalInsightsShortDay
        return rows.reversed().map {
            TrendPoint(
                id: formatter.string(from: $0.measured_at.value),
                dateLabel: formatter.string(from: $0.measured_at.value),
                value: $0.weight_kg
            )
        }
    }

    private static func buildRepeatMeals(from entries: [FoodLogEntry]) -> [RepeatMealSuggestion] {
        let grouped = Dictionary(grouping: entries, by: { normalizeKey($0.foodName) })
        let suggestions = grouped.compactMap { _, items -> RepeatMealSuggestion? in
            guard let template = items.sorted(by: { $0.loggedAt > $1.loggedAt }).first else { return nil }
            return RepeatMealSuggestion(
                id: template.foodName.lowercased(),
                template: template,
                count: items.count
            )
        }
        return suggestions
            .sorted {
                if $0.count != $1.count { return $0.count > $1.count }
                return $0.template.loggedAt > $1.template.loggedAt
            }
            .prefix(5)
            .map { $0 }
    }

    private static func buildDailyTrend<T>(
        entries: [T],
        start: Date,
        days: Int,
        value: (T) -> Double
    ) -> [TrendPoint] where T: TrendDated {
        let formatter = DateFormatter.personalInsightsShortDay
        var calendar = Calendar.current
        calendar.timeZone = .current

        let dayValues: [String: Double] = Dictionary(grouping: entries, by: { formatter.string(from: $0.trendDate) })
            .mapValues { $0.reduce(0) { $0 + value($1) } }

        return (0..<days).compactMap { index in
            guard let date = calendar.date(byAdding: .day, value: index, to: start) else { return nil }
            let key = formatter.string(from: date)
            return TrendPoint(
                id: key,
                dateLabel: formatter.string(from: date),
                value: dayValues[key] ?? 0
            )
        }
    }

    private static func normalizeKey(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

}

private protocol TrendDated {
    var trendDate: Date { get }
}

extension FoodLogEntry: TrendDated {
    var trendDate: Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date) ?? Date()
    }
}

extension ActivityLogEntry: TrendDated {
    var trendDate: Date { loggedAt }
}

private struct SupabaseDate: Codable, Sendable {
    let value: Date

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        if let date = Self.fractionalFormatter.date(from: rawValue)
            ?? Self.basicFormatter.date(from: rawValue)
            ?? Self.dateOnlyFormatter.date(from: rawValue) {
            value = date
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid Supabase date string: \(rawValue)"
        )
    }

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private static let fractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let basicFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

private extension DateFormatter {
    static let personalInsightsShortDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .current
        formatter.dateFormat = "E"
        return formatter
    }()
}
