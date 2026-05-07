import SwiftUI

extension LogView {
    var portionSheet: some View {
        let preview = selectedFood.flatMap { calculateNutrients(for: $0, grams: Double(gramsText) ?? 0) }
        return VStack(alignment: .leading, spacing: 14) {
            if let selectedFood {
                Text(selectedFood.description).font(TypographyToken.inter(size: 18, weight: .bold)).foregroundStyle(ColorToken.textPrimary).lineLimit(1)
            }
            Text("Amount in grams").font(TypographyToken.inter(size: 13, weight: .medium)).foregroundStyle(ColorToken.textSecondary)
            TextField("100", text: $gramsText)
                .font(TypographyToken.inter(size: 22, weight: .bold))
                .foregroundStyle(ColorToken.textPrimary)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 16).frame(height: 56)
                .background(ColorToken.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(gramsError.isEmpty ? ColorToken.border : ColorToken.destructive, lineWidth: gramsError.isEmpty ? 1 : 1.5))
                .onChange(of: gramsText) { _, newValue in gramsText = sanitizeDecimal(newValue); gramsError = "" }

            if !gramsError.isEmpty {
                Text(gramsError).font(TypographyToken.inter(size: 13, weight: .regular)).foregroundStyle(ColorToken.destructive).frame(maxWidth: .infinity)
            }
            if let preview {
                VStack(alignment: .leading, spacing: 6) {
                    Text("For \(gramsText.isEmpty ? "0" : gramsText)g:")
                        .font(TypographyToken.inter(size: 13, weight: .semibold)).foregroundStyle(ColorToken.textSecondary)
                    Text("🔥 \(Int(preview.calories)) kcal")
                    Text("🥩 \(oneDecimal(preview.protein))g protein")
                    Text("🍚 \(oneDecimal(preview.carbs))g carbs")
                    Text("🥑 \(oneDecimal(preview.fat))g fat")
                    Text("Looks delicious! 🦝😋").font(TypographyToken.inter(size: 13, weight: .regular)).foregroundStyle(ColorToken.textSecondary).italic().padding(.top, 2)
                }
                .font(TypographyToken.inter(size: 15, weight: .regular))
                .foregroundStyle(ColorToken.textPrimary)
                .padding(14)
                .background(Color(hex: "#FFF3EE"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(ColorToken.primary.opacity(0.2), lineWidth: 1))
            }
            Button("Add to Today 🦝") { handleAddTapped(preview: preview) }
                .font(TypographyToken.inter(size: 17, weight: .bold)).foregroundStyle(Color.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(ColorToken.primary).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).buttonStyle(.plain)
            Button("Cancel") { showPortionSheet = false }.font(TypographyToken.inter(size: 15, weight: .regular)).foregroundStyle(ColorToken.textPrimary).frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24).padding(.top, 6)
    }

    var todayLogSheet: some View {
        let totals = sumEntries(logEntries)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Log 📋").font(TypographyToken.inter(size: 20, weight: .bold)).foregroundStyle(ColorToken.textPrimary)
                    Text(formatTodayDate()).font(TypographyToken.inter(size: 13, weight: .regular)).foregroundStyle(ColorToken.textSecondary)
                }
                Spacer(minLength: 0)
                Button("✕") { showTodayLogSheet = false }
                    .font(TypographyToken.inter(size: 14, weight: .semibold)).foregroundStyle(ColorToken.textSecondary)
                    .frame(width: 32, height: 32).background(ColorToken.muted).clipShape(Circle()).buttonStyle(.plain)
            }
            HStack(spacing: 8) {
                summaryCard("🔥", "Calories", Int(totals.calories), "kcal", ColorToken.primary)
                summaryCard("🥩", "Protein", oneDecimal(totals.protein), "g", ColorToken.macroProtein)
                summaryCard("🍚", "Carbs", oneDecimal(totals.carbs), "g", Color(hex: "#2196F3"))
                summaryCard("🥑", "Fat", oneDecimal(totals.fat), "g", ColorToken.macroFat)
            }
            if logEntries.isEmpty {
                VStack(spacing: 10) {
                    RockyMascotView(mood: .thinking, size: RockyMascotView.Size.large.rawValue)
                    Text("Nothing logged yet today!").font(TypographyToken.inter(size: 16, weight: .semibold)).foregroundStyle(ColorToken.textPrimary)
                    Text("Tap the search bar to add food 🦝").font(TypographyToken.inter(size: 13, weight: .regular)).foregroundStyle(ColorToken.textSecondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 40)
            } else {
                ScrollView { VStack(spacing: 10) { ForEach(logEntries, id: \.id) { logEntryCard($0) } }.padding(.bottom, 8) }
            }
        }
        .padding(.horizontal, 20).padding(.top, 6)
    }

    func summaryCard(_ emoji: String, _ label: String, _ value: CustomStringConvertible, _ unit: String, _ color: Color) -> some View {
        VStack(spacing: 1) {
            Text(emoji).font(.system(size: 18))
            Text("\(value)").font(TypographyToken.inter(size: 16, weight: .bold)).foregroundStyle(color)
            Text(unit).font(TypographyToken.inter(size: 10, weight: .medium)).foregroundStyle(ColorToken.mutedForeground)
            Text(label).font(TypographyToken.inter(size: 10, weight: .regular)).foregroundStyle(ColorToken.mutedForeground)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10).background(ColorToken.background)
        .overlay(alignment: .top) { Rectangle().fill(color).frame(height: 3) }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func logEntryCard(_ entry: FoodLogEntry) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.foodName).font(TypographyToken.inter(size: 14, weight: .semibold)).foregroundStyle(ColorToken.textPrimary).lineLimit(2)
                Text("\(oneDecimal(entry.grams))g").font(TypographyToken.inter(size: 12, weight: .regular)).foregroundStyle(ColorToken.textTertiary)
                Text("🥩 \(oneDecimal(entry.protein))g · 🍚 \(oneDecimal(entry.carbs))g · 🥑 \(oneDecimal(entry.fat))g")
                    .font(TypographyToken.inter(size: 11, weight: .regular)).foregroundStyle(ColorToken.textSecondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(entry.calories))").font(TypographyToken.inter(size: 16, weight: .bold)).foregroundStyle(ColorToken.primary)
                Text("kcal").font(TypographyToken.inter(size: 10, weight: .regular)).foregroundStyle(ColorToken.mutedForeground)
                Button("🗑️") { entryToDelete = entry; showDeleteConfirm = true }.buttonStyle(.plain).padding(.top, 4)
            }
        }
        .padding(12).background(ColorToken.background).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(ColorToken.border, lineWidth: 1))
    }

    func scheduleSearch(for text: String) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if Task.isCancelled { return }
            await runSearch(text)
        }
    }

    func runSearch(_ q: String) async {
        let trimmed = q.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            await MainActor.run { results = []; hasSearched = false; searchError = nil }
            return
        }
        await MainActor.run { isSearching = true; hasSearched = true; searchError = nil }
        do {
            let data = try await repository.searchFoods(query: trimmed)
            await MainActor.run { results = data }
        } catch {
            await MainActor.run { results = []; searchError = String(describing: error).contains("NETWORK") ? .network : .api }
        }
        await MainActor.run { isSearching = false }
    }

    func calculateNutrients(for food: FoodSearchResult, grams: Double) -> FoodMacroResult {
        let factor = grams / 100
        return FoodMacroResult(calories: (food.calories * factor).rounded(), protein: round(food.protein * factor * 10) / 10, carbs: round(food.carbs * factor * 10) / 10, fat: round(food.fat * factor * 10) / 10)
    }

    func handleAddTapped(preview: FoodMacroResult?) {
        guard let preview, let selectedFood else { return }
        let grams = Double(gramsText) ?? 0
        guard grams > 0 else { gramsError = "Please enter a valid amount 🦝"; Haptics.warning(); return }
        if grams > 5000 { pendingMacros = preview; showLargeAmountConfirm = true; return }
        Task { await addLog(food: selectedFood, grams: grams, macros: preview) }
    }

    func performAddFromPendingLargeAmount() {
        guard let selectedFood, let pendingMacros else { return }
        let grams = Double(gramsText) ?? 0
        Task { await addLog(food: selectedFood, grams: grams, macros: pendingMacros) }
    }

    func addLog(food: FoodSearchResult, grams: Double, macros: FoodMacroResult) async {
        let entry = FoodLogEntry(id: String(Int(Date().timeIntervalSince1970 * 1000)), foodName: food.description, grams: grams, calories: macros.calories, protein: macros.protein, carbs: macros.carbs, fat: macros.fat, loggedAt: Date().ISO8601Format(), date: todayISO)
        do {
            try await repository.addLogEntry(entry)
            await refreshTodayLog()
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                    showPortionSheet = false
                    showSuccessOverlay = true
                }
            }
            Haptics.success()
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    showSuccessOverlay = false
                }
            }
        } catch {
            await MainActor.run { gramsError = "Something went wrong. Try again 🦝" }
        }
    }

    func remove(entry: FoodLogEntry) async {
        try? await repository.removeLogEntry(id: entry.id)
        await refreshTodayLog()
        Haptics.impactMedium()
    }

    func refreshTodayLog() async {
        let entries = (try? await repository.loadTodayLog()) ?? []
        await MainActor.run { logEntries = entries }
    }

    func sumEntries(_ entries: [FoodLogEntry]) -> FoodMacroResult {
        repository.sumMacros(entries: entries)
    }

    func clearPortionState() { selectedFood = nil; gramsText = "100"; gramsError = ""; pendingMacros = nil }

    var todayISO: String { String(Date().ISO8601Format().prefix(10)) }

    func formatTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    func sanitizeDecimal(_ text: String) -> String {
        let allowed = text.filter { "0123456789.".contains($0) }
        var output = ""
        var hasDot = false
        for ch in allowed {
            if ch == "." { if hasDot { continue }; hasDot = true }
            output.append(ch)
        }
        return output
    }

    func oneDecimal(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }

}

struct FlowWrapLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    var body: some View {
        content().frame(maxWidth: .infinity, alignment: .center)
    }
}
