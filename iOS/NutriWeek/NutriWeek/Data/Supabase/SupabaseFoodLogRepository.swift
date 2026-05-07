import Foundation
import Supabase

struct SupabaseFoodLogRepository: FoodLogRepositoryProtocol {
    private let client: SupabaseClient
    private let usdaService: USDAEdgeService
    private let cacheStore: DailyLogCacheStore

    init(
        client: SupabaseClient = SupabaseClientFactory.shared,
        usdaService: USDAEdgeService = USDAEdgeService(),
        cacheStore: DailyLogCacheStore = DailyLogCacheStore()
    ) {
        self.client = client
        self.usdaService = usdaService
        self.cacheStore = cacheStore
    }

    func searchFoods(query: String) async throws -> [FoodSearchResult] {
        try await usdaService.searchFoods(query: query)
    }

    func loadTodayLog() async throws -> [FoodLogEntry] {
        let userId = try await requireUserId()
        let today = todayISO()

        do {
            let rows: [FoodLogMapper.FoodLogRow] = try await client.from("food_log_entries")
                .select("id, food_name, grams, calories, protein_g, carbs_g, fat_g, logged_at, log_date")
                .eq("user_id", value: userId)
                .eq("log_date", value: today)
                .order("logged_at", ascending: false)
                .execute()
                .value
            let entries = rows.map(FoodLogMapper.toDomain)
            try? cacheStore.save(entries: entries, date: today, userId: userId)
            return entries
        } catch {
            if let cached = try? cacheStore.load(date: today, userId: userId) {
                return cached ?? []
            }
            throw error
        }
    }

    func addLogEntry(_ entry: FoodLogEntry) async throws {
        let userId = try await requireUserId()
        let payload = FoodLogMapper.toInsert(entry, userId: userId)
        try await client.from("food_log_entries").insert(payload).execute()
        let refreshed = try await loadTodayLog()
        try? cacheStore.save(entries: refreshed, date: entry.date, userId: userId)
    }

    func removeLogEntry(id: String) async throws {
        let userId = try await requireUserId()
        try await client.from("food_log_entries").delete().eq("id", value: id).eq("user_id", value: userId).execute()
        let refreshed = try await loadTodayLog()
        try? cacheStore.save(entries: refreshed, date: todayISO(), userId: userId)
    }

    func sumMacros(entries: [FoodLogEntry]) -> FoodMacroResult {
        entries.reduce(FoodMacroResult(calories: 0, protein: 0, carbs: 0, fat: 0)) { acc, item in
            FoodMacroResult(
                calories: acc.calories + item.calories,
                protein: round((acc.protein + item.protein) * 10) / 10,
                carbs: round((acc.carbs + item.carbs) * 10) / 10,
                fat: round((acc.fat + item.fat) * 10) / 10
            )
        }
    }

    private func requireUserId() async throws -> String {
        let session = try await client.auth.session
        return session.user.id.uuidString
    }

    private func todayISO() -> String {
        String(Date().ISO8601Format().prefix(10))
    }
}
