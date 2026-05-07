import Foundation

struct WeeklyPlanCacheStore: Sendable {
    private let cache: CacheStore

    init(cache: CacheStore = FileCacheStore(namespace: "WeeklyPlanCache")) {
        self.cache = cache
    }

    func load(for userId: String) throws -> WeeklyPlan? {
        try cache.load(WeeklyPlan.self, key: "weekly_plan_\(userId)")
    }

    func save(_ plan: WeeklyPlan, for userId: String) throws {
        try cache.save(plan, key: "weekly_plan_\(userId)")
    }

    func clear(for userId: String) throws {
        try cache.remove(key: "weekly_plan_\(userId)")
    }
}
