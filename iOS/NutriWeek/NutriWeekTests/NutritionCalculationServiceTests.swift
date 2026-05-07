import XCTest
@testable import NutriWeek

final class NutritionCalculationServiceTests: XCTestCase {
    func testCalculateBMIRoundsToSingleDecimal() {
        let bmi = NutritionCalculationService.calculateBMI(weight: 70, height: 175)
        XCTAssertEqual(bmi, 22.9)
    }

    func testCalculateTargetCaloriesForEachGoal() {
        XCTAssertEqual(NutritionCalculationService.calculateTargetCalories(tdee: 2200, goal: .cut), 1700)
        XCTAssertEqual(NutritionCalculationService.calculateTargetCalories(tdee: 2200, goal: .bulk), 2500)
        XCTAssertEqual(NutritionCalculationService.calculateTargetCalories(tdee: 2200, goal: .maintain), 2200)
    }

    func testCalculateAllProducesStableMacroPercentages() {
        let profile = UserProfile(
            gender: .male,
            age: 29,
            height: 178,
            weight: 80,
            activityLevel: .moderatelyActive,
            goal: .maintain,
            measurements: nil,
            dietaryPreferences: [],
            onboardingComplete: true,
            createdAt: "",
            updatedAt: ""
        )

        let result = NutritionCalculationService.calculateAll(profile: profile)

        XCTAssertGreaterThan(result.targetCalories, 0)
        XCTAssertGreaterThan(result.macros.protein, 0)
        XCTAssertGreaterThan(result.macros.carbs, 0)
        XCTAssertGreaterThan(result.macros.fat, 0)
        XCTAssertEqual(
            result.macroPercentages.protein + result.macroPercentages.carbs + result.macroPercentages.fat,
            100,
            accuracy: 1.0
        )
    }
}

