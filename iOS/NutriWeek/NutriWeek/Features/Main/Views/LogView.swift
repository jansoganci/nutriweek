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

    let quickPills = ["Chicken Breast", "Eggs", "Banana", "Milk", "Rice", "Avocado"]

    init(repository: FoodLogRepositoryProtocol) {
        self.repository = repository
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    searchBar
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
                    title: "Logged!",
                    subtitle: "Food added to today's log.",
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
        .alert("That's a lot... 😅", isPresented: $showLargeAmountConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Yes, log it") { performAddFromPendingLargeAmount() }
        } message: {
            Text("Are you sure you want to log more than 5kg of this food?")
        }
        .alert("Remove food?", isPresented: $showDeleteConfirm, presenting: entryToDelete) { entry in
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                Task { await remove(entry: entry) }
            }
        } message: { entry in
            Text("Remove \"\(entry.foodName)\" from today's log?")
        }
    }
}
