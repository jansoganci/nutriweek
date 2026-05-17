import SwiftUI

extension ActivityLogView {
    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let now = Date()
            let calendar = Calendar.current
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)
            let monthInterval = calendar.dateInterval(of: .month, for: now)

            async let fetchedEntries = repository.loadEntries()
            async let todayTotal = repository.totalCaloriesBurned(for: now)
            async let weekTotal: Double = {
                guard let weekInterval else { return 0 }
                return try await repository.totalCaloriesBurned(from: weekInterval.start, to: weekInterval.end)
            }()
            async let monthTotal: Double = {
                guard let monthInterval else { return 0 }
                return try await repository.totalCaloriesBurned(from: monthInterval.start, to: monthInterval.end)
            }()

            entries = sortEntries(try await fetchedEntries)
            todaysCalories = try await todayTotal
            weeklyCalories = try await weekTotal
            monthlyCalories = try await monthTotal
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteEntry(at id: String) async {
        do {
            try await repository.deleteEntry(id: id)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sortEntries(_ entries: [ActivityLogEntry]) -> [ActivityLogEntry] {
        entries.sorted { lhs, rhs in
            if lhs.loggedAt != rhs.loggedAt {
                return lhs.loggedAt > rhs.loggedAt
            }

            switch (lhs.createdAt, rhs.createdAt) {
            case let (left?, right?):
                if left != right { return left > right }
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                break
            }

            return lhs.id > rhs.id
        }
    }
}
