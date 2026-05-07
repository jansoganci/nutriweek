import SwiftUI
import UIKit

struct MainTabView: View {
    @Bindable var coordinator: MainTabCoordinator

    init(coordinator: MainTabCoordinator) {
        self.coordinator = coordinator
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)

        let active = UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0) // #FF6B35
        let inactive = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1.0) // #9E9E9E

        [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance]
            .forEach { layout in
                layout.normal.iconColor = inactive
                layout.normal.titleTextAttributes = [.foregroundColor: inactive]
                layout.selected.iconColor = active
                layout.selected.titleTextAttributes = [.foregroundColor: active]
            }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = inactive
    }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            MealPlanHomeView(
                mealPlanRepository: coordinator.mealPlanRepository,
                foodLogRepository: coordinator.foodLogRepository,
                streakService: coordinator.streakService
            )
                .tag(MainTabCoordinator.Tab.mealPlan)
                .tabItem {
                    Label("Meal Plan", systemImage: "calendar")
                }

            LogView(repository: coordinator.foodLogRepository)
                .tag(MainTabCoordinator.Tab.quickLog)
                .tabItem {
                    Label("Log", systemImage: "fork.knife")
                }

            ProfileView()
                .tag(MainTabCoordinator.Tab.profile)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .tint(Color(hex: "#FF6B35"))
    }
}

