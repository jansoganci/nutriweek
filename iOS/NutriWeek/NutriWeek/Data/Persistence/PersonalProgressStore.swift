import Foundation

struct WeeklyCheckInRecord: Codable, Equatable, Sendable, Identifiable {
    var id: String
    var userId: String
    var weekStart: String
    var recordedAt: Date
    var weightKg: Double?
    var workoutCount: Int
    var energyLevel: Int
    var note: String?

    init(
        userId: String,
        weekStart: String,
        recordedAt: Date = Date(),
        weightKg: Double? = nil,
        workoutCount: Int,
        energyLevel: Int,
        note: String? = nil
    ) {
        self.id = weekStart
        self.userId = userId
        self.weekStart = weekStart
        self.recordedAt = recordedAt
        self.weightKg = weightKg
        self.workoutCount = workoutCount
        self.energyLevel = energyLevel
        self.note = note
    }
}

struct RecoveryCheckInRecord: Codable, Equatable, Sendable, Identifiable {
    var id: String
    var userId: String
    var dayKey: String
    var recordedAt: Date
    var sleepHours: Double?
    var sorenessLevel: Int
    var energyLevel: Int
    var note: String?

    init(
        userId: String,
        dayKey: String,
        recordedAt: Date = Date(),
        sleepHours: Double? = nil,
        sorenessLevel: Int,
        energyLevel: Int,
        note: String? = nil
    ) {
        self.id = dayKey
        self.userId = userId
        self.dayKey = dayKey
        self.recordedAt = recordedAt
        self.sleepHours = sleepHours
        self.sorenessLevel = sorenessLevel
        self.energyLevel = energyLevel
        self.note = note
    }
}

struct PersonalProgressStore: Sendable {
    private let cache: CacheStore

    init(cache: CacheStore = FileCacheStore(namespace: "PersonalProgressCache")) {
        self.cache = cache
    }

    func loadWeeklyCheckIns(userId: String) throws -> [WeeklyCheckInRecord] {
        try cache.load([WeeklyCheckInRecord].self, key: weeklyKey(userId: userId)) ?? []
    }

    func saveWeeklyCheckIn(_ record: WeeklyCheckInRecord, userId: String) throws {
        var records = try loadWeeklyCheckIns(userId: userId)
        records.removeAll { $0.weekStart == record.weekStart }
        records.append(record)
        records.sort { $0.recordedAt > $1.recordedAt }
        try cache.save(records, key: weeklyKey(userId: userId))
    }

    func latestWeeklyCheckIn(userId: String) throws -> WeeklyCheckInRecord? {
        try loadWeeklyCheckIns(userId: userId).sorted { $0.recordedAt > $1.recordedAt }.first
    }

    func loadRecoveryCheckIns(userId: String) throws -> [RecoveryCheckInRecord] {
        try cache.load([RecoveryCheckInRecord].self, key: recoveryKey(userId: userId)) ?? []
    }

    func saveRecoveryCheckIn(_ record: RecoveryCheckInRecord, userId: String) throws {
        var records = try loadRecoveryCheckIns(userId: userId)
        records.removeAll { $0.dayKey == record.dayKey }
        records.append(record)
        records.sort { $0.recordedAt > $1.recordedAt }
        try cache.save(records, key: recoveryKey(userId: userId))
    }

    func latestRecoveryCheckIn(userId: String) throws -> RecoveryCheckInRecord? {
        try loadRecoveryCheckIns(userId: userId).sorted { $0.recordedAt > $1.recordedAt }.first
    }

    private func weeklyKey(userId: String) -> String {
        "weekly_check_ins_\(userId)"
    }

    private func recoveryKey(userId: String) -> String {
        "recovery_check_ins_\(userId)"
    }
}
