import SwiftUI

struct LogView: View {
    enum SearchErrorType {
        case network
        case api
    }

    let repository: FoodLogRepositoryProtocol

    @State var query = ""
    @State var results: [FoodSearchResult] = []
    @State var isSearching = false
    @State var hasSearched = false
    @State var searchError: SearchErrorType?
    @State var selectedFood: FoodSearchResult?
    @State var showPortionSheet = false
    @State var gramsText = "100"
    @State var gramsError = ""
    @State var showLargeAmountConfirm = false
    @State var pendingMacros: FoodMacroResult?
    @State var showSuccessOverlay = false
    @State var logEntries: [FoodLogEntry] = []
    @State var showTodayLogSheet = false
    @State var debounceTask: Task<Void, Never>?
    @State var showDeleteConfirm = false
    @State var entryToDelete: FoodLogEntry?
    @State var repeatMeals: [RepeatMealSuggestion] = []

    let quickPills = [
        String(localized: "log.quick_pill.chicken_breast"),
        String(localized: "log.quick_pill.eggs"),
        String(localized: "log.quick_pill.banana"),
        String(localized: "log.quick_pill.milk"),
        String(localized: "log.quick_pill.rice"),
        String(localized: "log.quick_pill.avocado"),
    ]

    init(repository: FoodLogRepositoryProtocol) {
        self.repository = repository
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    searchBar
                    repeatMealsSection
                    contentSection
                }
                .padding(.horizontal, SpacingToken.gutter)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            .background(ColorToken.background)
            .toolbar(.hidden, for: .navigationBar)
            .task { await refreshTodayLog() }

            if showSuccessOverlay {
                ToastView(
                    title: String(localized: "log.toast.logged_title"),
                    subtitle: String(localized: "log.toast.logged_subtitle"),
                    style: .success
                )
                .padding(.horizontal, SpacingToken.gutter)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showPortionSheet, onDismiss: clearPortionState) {
            portionSheet
                .presentationDetents([.height(470)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTodayLogSheet) {
            todayLogSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert(String(localized: "log.alert.large_amount_title"), isPresented: $showLargeAmountConfirm) {
            Button(String(localized: "log.alert.cancel"), role: .cancel) {}
            Button(String(localized: "log.alert.large_amount_confirm")) { performAddFromPendingLargeAmount() }
        } message: {
            Text(LocalizedStringKey("log.confirm.over_5kg"))
        }
        .alert(String(localized: "log.alert.remove_title"), isPresented: $showDeleteConfirm, presenting: entryToDelete) { entry in
            Button(String(localized: "log.alert.cancel"), role: .cancel) {}
            Button(String(localized: "log.alert.remove_confirm"), role: .destructive) {
                Task { await remove(entry: entry) }
            }
        } message: { entry in
            Text(String(localized: "log.confirm.remove_food \(entry.foodName)"))
        }
    }
}
