import Foundation
import Supabase

struct SupabaseStreakService: StreakService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientFactory.shared) {
        self.client = client
    }

    func loadStreak() async throws -> Int {
        let userId = try await requireUserId()
        let rows: [LoggingStreakCountRow] = try await client.from("logging_streaks")
            .select("current_count")
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value
        return rows.first?.current_count ?? 0
    }

    func updateStreak() async throws -> Int {
        let userId = try await requireUserId()
        let today = todayISO()

        let existing: [LoggingStreakRow] = try await client.from("logging_streaks")
            .select("current_count, longest_count, last_log_date")
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value

        guard let row = existing.first else {
            try await upsertRow(
                userId: userId,
                currentCount: 1,
                longestCount: 1,
                lastLogDate: today
            )
            return 1
        }

        if let last = row.last_log_date, last == today {
            return row.current_count
        }

        let newCount: Int
        if let last = row.last_log_date,
           let dayDelta = calendarDaysBetween(lastLogDate: last, today: today) {
            if dayDelta == 1 {
                newCount = row.current_count + 1
            } else if dayDelta >= 2 {
                newCount = 1
            } else {
                newCount = row.current_count
            }
        } else {
            newCount = 1
        }

        let newLongest = max(row.longest_count, newCount)
        try await upsertRow(
            userId: userId,
            currentCount: newCount,
            longestCount: newLongest,
            lastLogDate: today
        )

        return newCount
    }

    private func upsertRow(
        userId: String,
        currentCount: Int,
        longestCount: Int,
        lastLogDate: String
    ) async throws {
        let payload = LoggingStreakUpsert(
            user_id: userId,
            current_count: currentCount,
            longest_count: longestCount,
            last_log_date: lastLogDate
        )
        try await client.from("logging_streaks")
            .upsert(payload, onConflict: "user_id")
            .execute()
    }

    private func requireUserId() async throws -> String {
        let session = try await client.auth.session
        return session.user.id.uuidString
    }

    private func todayISO() -> String {
        String(Date().ISO8601Format().prefix(10))
    }

    private func calendarDaysBetween(lastLogDate: String, today: String) -> Int? {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.calendar = cal
        fmt.timeZone = cal.timeZone
        fmt.dateFormat = "yyyy-MM-dd"

        guard let last = fmt.date(from: lastLogDate),
              let todayDate = fmt.date(from: today)
        else { return nil }

        return cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: last),
            to: cal.startOfDay(for: todayDate)
        ).day
    }
}

// MARK: - Rows

private struct LoggingStreakCountRow: Decodable {
    let current_count: Int
}

private struct LoggingStreakRow: Decodable {
    let current_count: Int
    let longest_count: Int
    let last_log_date: String?
}

private struct LoggingStreakUpsert: Encodable {
    let user_id: String
    let current_count: Int
    let longest_count: Int
    let last_log_date: String
}
