import Foundation
import Supabase
import OSLog

private let repoLog = Logger(subsystem: "com.nutriweek.NutriWeek", category: "ActivityLogRepository")

final class SupabaseActivityLogRepository: ActivityLogRepositoryProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientFactory.shared) {
        self.client = client
    }

    func loadEntries() async throws -> [ActivityLogEntry] {
        let rows: [ActivityLogRow] = try await client.from("activity_log")
            .select("id, user_id, activity_name, activity_type, duration_minutes, calories_burned, sets, reps, weight_kg, notes, logged_at, created_at")
            .order("logged_at", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map(ActivityLogRow.toDomain)
    }

    func loadEntries(for date: Date) async throws -> [ActivityLogEntry] {
        let (start, end) = dayBounds(for: date)
        let rows: [ActivityLogRow] = try await client.from("activity_log")
            .select("id, user_id, activity_name, activity_type, duration_minutes, calories_burned, sets, reps, weight_kg, notes, logged_at, created_at")
            .gte("logged_at", value: start)
            .lte("logged_at", value: end)
            .order("logged_at", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map(ActivityLogRow.toDomain)
    }

    func loadEntries(from startDate: Date, to endDate: Date) async throws -> [ActivityLogEntry] {
        let rows: [ActivityLogRow] = try await client.from("activity_log")
            .select("id, user_id, activity_name, activity_type, duration_minutes, calories_burned, sets, reps, weight_kg, notes, logged_at, created_at")
            .gte("logged_at", value: startDate)
            .lte("logged_at", value: endDate)
            .order("logged_at", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map(ActivityLogRow.toDomain)
    }

    func addEntry(_ entry: ActivityLogEntry) async throws {
        repoLog.log("addEntry: \(entry.activityName, privacy: .public), userId: \(entry.userId, privacy: .public)")
        let payload = ActivityLogRow(from: entry)
        do {
            try await client.from("activity_log")
                .insert(payload)
                .execute()
            repoLog.log("addEntry SUCCESS")
        } catch {
            repoLog.error("addEntry FAILED: \(String(describing: error), privacy: .public)")
            throw error
        }
    }

    func updateEntry(_ entry: ActivityLogEntry) async throws {
        let payload = ActivityLogRow(from: entry)
        try await client.from("activity_log")
            .update(payload)
            .eq("id", value: entry.id)
            .execute()
    }

    func deleteEntry(id: String) async throws {
        try await client.from("activity_log")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func totalCaloriesBurned(for date: Date) async throws -> Double {
        let entries = try await loadEntries(for: date)
        return entries.reduce(0) { $0 + $1.caloriesBurned }
    }

    func totalCaloriesBurned(from startDate: Date, to endDate: Date) async throws -> Double {
        let entries = try await loadEntries(from: startDate, to: endDate)
        return entries.reduce(0) { $0 + $1.caloriesBurned }
    }

    private func dayBounds(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let nextDayStart = calendar.date(byAdding: .day, value: 1, to: start) else {
            return (start, date)
        }
        return (start, nextDayStart.addingTimeInterval(-0.000001))
    }
}

private struct ActivityLogRow: Codable {
    let id: String
    let userId: String
    let activityName: String
    let activityType: String?
    let durationMinutes: Int
    let caloriesBurned: Double
    let sets: Int?
    let reps: Int?
    let weightKg: Double?
    let notes: String?
    let loggedAt: SupabaseDate
    let createdAt: SupabaseDate?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityName = "activity_name"
        case activityType = "activity_type"
        case durationMinutes = "duration_minutes"
        case caloriesBurned = "calories_burned"
        case sets
        case reps
        case weightKg = "weight_kg"
        case notes
        case loggedAt = "logged_at"
        case createdAt = "created_at"
    }

    init(
        id: String,
        userId: String,
        activityName: String,
        activityType: String? = nil,
        durationMinutes: Int,
        caloriesBurned: Double,
        sets: Int? = nil,
        reps: Int? = nil,
        weightKg: Double? = nil,
        notes: String? = nil,
        loggedAt: SupabaseDate,
        createdAt: SupabaseDate? = nil
    ) {
        self.id = id
        self.userId = userId
        self.activityName = activityName
        self.activityType = activityType
        self.durationMinutes = durationMinutes
        self.caloriesBurned = caloriesBurned
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.notes = notes
        self.loggedAt = loggedAt
        self.createdAt = createdAt
    }

    init(from entry: ActivityLogEntry) {
        self.init(
            id: entry.id,
            userId: entry.userId,
            activityName: entry.activityName,
            activityType: entry.activityType,
            durationMinutes: entry.durationMinutes,
            caloriesBurned: entry.caloriesBurned,
            sets: entry.sets,
            reps: entry.reps,
            weightKg: entry.weightKg,
            notes: entry.notes,
            loggedAt: SupabaseDate(value: entry.loggedAt),
            createdAt: entry.createdAt.map { SupabaseDate(value: $0) }
        )
    }

    static func toDomain(_ row: ActivityLogRow) -> ActivityLogEntry {
        ActivityLogEntry(
            id: row.id,
            userId: row.userId,
            activityName: row.activityName,
            activityType: row.activityType,
            durationMinutes: row.durationMinutes,
            caloriesBurned: row.caloriesBurned,
            sets: row.sets,
            reps: row.reps,
            weightKg: row.weightKg,
            notes: row.notes,
            loggedAt: row.loggedAt.value,
            createdAt: row.createdAt?.value
        )
    }
}

private struct SupabaseDate: Codable, Sendable {
    let value: Date

    init(value: Date) {
        self.value = value
    }

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

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Self.dateOnlyFormatter.string(from: value))
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
