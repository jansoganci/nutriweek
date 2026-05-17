import SwiftUI

extension LogView {
    var header: some View {
        HStack {
            Color.clear.frame(width: 32, height: 32)
            Spacer(minLength: 0)
            Text(LocalizedStringKey("log.title"))
                .font(TypographyToken.inter(size: 20, weight: .bold))
                .foregroundStyle(ColorToken.textPrimary)
            Spacer(minLength: 0)
            Button {
                Task { await refreshTodayLog(); showTodayLogSheet = true }
            } label: {
                HStack(spacing: 4) {
                    Text(LocalizedStringKey("log.today_button"))
                        .font(TypographyToken.inter(size: 13, weight: .semibold))
                        .foregroundStyle(ColorToken.primary)
                    if !logEntries.isEmpty {
                        Text("\(logEntries.count)")
                            .font(TypographyToken.inter(size: 11, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(ColorToken.primary).clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(ColorToken.secondary).clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    var searchBar: some View {
        HStack(spacing: 8) {
            Text("🔍").font(.system(size: 16))
            TextField(String(localized: "log.search.placeholder"), text: $query)
                .font(TypographyToken.inter(size: 16, weight: .regular))
                .foregroundStyle(ColorToken.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: query) { _, newValue in scheduleSearch(for: newValue) }
                .submitLabel(.search)
                .onSubmit { debounceTask?.cancel(); Task { await runSearch(query) } }

            if isSearching {
                ProgressView().controlSize(.small).tint(ColorToken.primary)
            } else if !query.isEmpty {
                Button {
                    query = ""; results = []; hasSearched = false; searchError = nil
                } label: {
                    Text("✕")
                        .font(TypographyToken.inter(size: 16, weight: .regular))
                        .foregroundStyle(ColorToken.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(ColorToken.border, lineWidth: 1))
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    var repeatMealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey("personal.repeat_meals.title"))
                        .font(TypographyToken.inter(size: 18, weight: .bold))
                        .foregroundStyle(ColorToken.textPrimary)
                    Text(LocalizedStringKey("personal.repeat_meals.subtitle"))
                        .font(TypographyToken.inter(size: 12, weight: .regular))
                        .foregroundStyle(ColorToken.textSecondary)
                }
                Spacer(minLength: 0)
            }

            if repeatMeals.isEmpty {
                Text(LocalizedStringKey("personal.repeat_meals.empty"))
                    .font(TypographyToken.inter(size: 13, weight: .regular))
                    .foregroundStyle(ColorToken.textSecondary)
                    .padding(.vertical, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(repeatMeals) { item in
                            repeatMealCard(item)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    var contentSection: some View {
        if let searchError {
            ErrorStateView(
                title: searchError == .network ? String(localized: "log.error.network_title") : String(localized: "common.error.generic_title"),
                message: searchError == .network ? String(localized: "log.error.network_message") : String(localized: "log.error.search_message"),
                retryTitle: String(localized: "common.retry")
            ) {
                Task { await runSearch(query) }
            }
        } else if isSearching {
            skeletonSection
        } else if !hasSearched {
            emptyState
        } else if results.isEmpty {
            noResultState
        } else {
            VStack(spacing: 10) {
                ForEach(results, id: \.fdcId) { food in
                    foodCard(food)
                }
            }
        }
    }

    func foodCard(_ food: FoodSearchResult) -> some View {
        Button {
            Haptics.selection()
            selectedFood = food
            gramsText = "100"
            gramsError = ""
            showPortionSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(food.description)
                    .font(TypographyToken.inter(size: 15, weight: .semibold))
                    .foregroundStyle(ColorToken.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(LocalizedStringKey("log.food.per_100g"))
                        .font(TypographyToken.inter(size: 11, weight: .regular))
                        .foregroundStyle(ColorToken.textTertiary)
                    macroTag(label: "kcal", value: "\(Int(food.calories))", color: ColorToken.primary)
                    macroTag(label: "prot", value: "\(oneDecimal(food.protein))g", color: ColorToken.macroProtein)
                    macroTag(label: "carb", value: "\(oneDecimal(food.carbs))g", color: Color(hex: "#2196F3"))
                    macroTag(label: "fat", value: "\(oneDecimal(food.fat))g", color: ColorToken.macroFat)
                }
            }
            .padding(14)
            .background(ColorToken.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(ColorToken.border, lineWidth: 1))
            .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    func macroTag(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value).font(TypographyToken.inter(size: 11, weight: .bold)).foregroundStyle(color)
            Text(label).font(TypographyToken.inter(size: 11, weight: .regular)).foregroundStyle(ColorToken.textSecondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(color.opacity(0.09)).clipShape(Capsule())
    }

    func repeatMealCard(_ item: RepeatMealSuggestion) -> some View {
        Button {
            Task { await repeatMeal(item) }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(TypographyToken.inter(size: 14, weight: .semibold))
                    .foregroundStyle(ColorToken.textPrimary)
                    .lineLimit(2)
                Text(item.subtitle)
                    .font(TypographyToken.inter(size: 11, weight: .regular))
                    .foregroundStyle(ColorToken.textSecondary)
                Text(String(localized: "personal.repeat_meals.action"))
                    .font(TypographyToken.inter(size: 12, weight: .semibold))
                    .foregroundStyle(ColorToken.primary)
            }
            .frame(width: 180, alignment: .leading)
            .padding(12)
            .background(ColorToken.background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ColorToken.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            RockyMascotView(mood: .happy, size: RockyMascotView.Size.large.rawValue)
            Text(LocalizedStringKey("log.empty.title"))
                .font(TypographyToken.inter(size: 16, weight: .semibold))
                .foregroundStyle(ColorToken.textPrimary)
            FlowWrapLayout(spacing: 8) {
                ForEach(quickPills, id: \.self) { pill in
                    Button {
                        Haptics.selection()
                        query = pill
                        Task { await runSearch(pill) }
                    } label: {
                        Text(pill)
                            .font(TypographyToken.inter(size: 14, weight: .medium))
                            .foregroundStyle(ColorToken.textPrimary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(ColorToken.card)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(ColorToken.border, lineWidth: 1))
                            .shadow(color: ColorToken.shadow.opacity(0.07), radius: 6, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: CGFloat.infinity)
        }
        .padding(.top, 16)
    }

    var noResultState: some View {
        VStack(spacing: 8) {
            RockyMascotView(mood: .thinking, size: RockyMascotView.Size.large.rawValue)
            Text(LocalizedStringKey("log.no_results.title"))
                .font(TypographyToken.inter(size: 16, weight: .semibold))
                .foregroundStyle(ColorToken.textPrimary)
                .multilineTextAlignment(.center)
            Text(LocalizedStringKey("log.no_results.subtitle"))
                .font(TypographyToken.inter(size: 14, weight: .regular))
                .foregroundStyle(ColorToken.textSecondary)
        }
        .padding(.top, 16)
    }

    var skeletonSection: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                LoadingSkeletonView(variant: .listRow)
            }
        }
    }
}
