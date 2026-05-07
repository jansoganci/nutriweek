import Foundation

struct DailyLogCacheStore: Sendable {
    private let cache: CacheStore

    init(cache: CacheStore = FileCacheStore(namespace: "DailyLogCache")) {
        self.cache = cache
    }

    func load(date: String, userId: String) throws -> [FoodLogEntry]? {
        try cache.load([FoodLogEntry].self, key: "daily_log_\(userId)_\(date)")
    }

    func save(entries: [FoodLogEntry], date: String, userId: String) throws {
        try cache.save(entries, key: "daily_log_\(userId)_\(date)")
    }

    func clear(date: String, userId: String) throws {
        try cache.remove(key: "daily_log_\(userId)_\(date)")
    }
}
