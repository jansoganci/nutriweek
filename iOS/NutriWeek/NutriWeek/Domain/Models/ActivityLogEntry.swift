import Foundation

enum WorkoutType: String, Codable, CaseIterable, Sendable {
    case strength
    case cardio
    case mobility
    case sport
    case other
}

struct ActivityLogEntry: Codable, Equatable, Sendable, Identifiable {
    var id: String
    var userId: String
    var activityName: String
    var activityType: String?
    var durationMinutes: Int
    var caloriesBurned: Double
    var sets: Int?
    var reps: Int?
    var weightKg: Double?
    var notes: String?
    var loggedAt: Date
    var createdAt: Date?

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
        loggedAt: Date,
        createdAt: Date? = nil
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        activityName = try container.decode(String.self, forKey: .activityName)
        activityType = try container.decodeIfPresent(String.self, forKey: .activityType)
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        caloriesBurned = try container.decode(Double.self, forKey: .caloriesBurned)
        sets = try container.decodeIfPresent(Int.self, forKey: .sets)
        reps = try container.decodeIfPresent(Int.self, forKey: .reps)
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        loggedAt = try Self.decodeSupabaseDate(from: container, forKey: .loggedAt)
        createdAt = try container.decodeIfPresent(SupabaseDate.self, forKey: .createdAt)?.value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(activityName, forKey: .activityName)
        try container.encodeIfPresent(activityType, forKey: .activityType)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encode(caloriesBurned, forKey: .caloriesBurned)
        try container.encodeIfPresent(sets, forKey: .sets)
        try container.encodeIfPresent(reps, forKey: .reps)
        try container.encodeIfPresent(weightKg, forKey: .weightKg)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(SupabaseDate(value: loggedAt), forKey: .loggedAt)
        if let createdAt {
            try container.encode(SupabaseDate(value: createdAt), forKey: .createdAt)
        }
    }

    private static func decodeSupabaseDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        let value = try container.decode(SupabaseDate.self, forKey: key)
        return value.value
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
