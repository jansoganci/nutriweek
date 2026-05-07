import Foundation
import Observation

@Observable
@MainActor
final class OnboardingCoordinator {
    var path: [OnboardingDestination] = []
    var onFinish: (() -> Void)?

    func goToStep2() { path.append(.step2) }
    func goToStep3() { path.append(.step3) }
    func goToStep4() { path.append(.step4) }
    func goToResults() { path.append(.results) }

    func finish() {
        onFinish?()
    }

    func reset() {
        path = []
    }
}
