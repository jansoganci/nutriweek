import SwiftUI

/// RN onboarding stack: step1 (root) → step2 → step3 → step4 → results.
struct OnboardingFlowView: View {
    @Bindable var coordinator: OnboardingCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            OnboardingStep1View(coordinator: coordinator)
                .navigationDestination(for: OnboardingDestination.self) { destination in
                    switch destination {
                    case .step2:
                        OnboardingStep2View(coordinator: coordinator)
                    case .step3:
                        OnboardingStep3View(coordinator: coordinator)
                    case .step4:
                        OnboardingStep4View(coordinator: coordinator)
                    case .results:
                        OnboardingResultsView(coordinator: coordinator)
                    }
                }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
