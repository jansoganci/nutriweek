import Foundation

struct BMICategory: Codable, Equatable, Sendable {
    let label: String
    let colorHex: String
}

struct MacroGrams: Codable, Equatable, Sendable {
    let protein: Int
    let carbs: Int
    let fat: Int
}

struct MacroPercentages: Codable, Equatable, Sendable {
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct CalculationResults: Codable, Equatable, Sendable {
    let bmi: Double
    let bmiCategory: BMICategory
    let bmr: Int
    let tdee: Int
    let targetCalories: Int
    let macros: MacroGrams
    let macroPercentages: MacroPercentages
}

enum NutritionCalculationService {
    static func calculateBMI(weight: Double, height: Double) -> Double {
        let heightM = height / 100.0
        return round((weight / (heightM * heightM)) * 10) / 10
    }

    static func getBMICategory(bmi: Double) -> BMICategory {
        if bmi < 18.5 { return BMICategory(label: "Underweight", colorHex: "#FFB300") }
        if bmi < 25 { return BMICategory(label: "Healthy", colorHex: "#4CAF50") }
        if bmi < 30 { return BMICategory(label: "Overweight", colorHex: "#FFB300") }
        return BMICategory(label: "Obese", colorHex: "#FF4444")
    }

    static func calculateBMR(weight: Double, height: Double, age: Int, gender: Gender) -> Int {
        let base = 10 * weight + 6.25 * height - 5 * Double(age)

        switch gender {
        case .male:
            return Int(round(base + 5))
        case .female:
            return Int(round(base - 161))
        case .other:
            return Int(round((base + 5 + (base - 161)) / 2))
        }
    }

    static func getActivityMultiplier(activityLevel: ActivityLevel) -> Double {
        switch activityLevel {
        case .sedentary:
            return 1.2
        case .lightlyActive:
            return 1.375
        case .moderatelyActive:
            return 1.55
        case .veryActive:
            return 1.725
        case .extraActive:
            return 1.9
        }
    }

    static func calculateTDEE(bmr: Int, activityLevel: ActivityLevel) -> Int {
        Int(round(Double(bmr) * getActivityMultiplier(activityLevel: activityLevel)))
    }

    static func calculateTargetCalories(tdee: Int, goal: Goal) -> Int {
        switch goal {
        case .cut:
            return tdee - 500
        case .bulk:
            return tdee + 300
        case .maintain:
            return tdee
        }
    }

    static func calculateMacros(targetCalories: Int, weight: Double, goal: Goal) -> MacroGrams {
        let proteinMultiplier: Double
        switch goal {
        case .cut:
            proteinMultiplier = 2.2
        case .bulk:
            proteinMultiplier = 2.0
        case .maintain:
            proteinMultiplier = 1.8
        }

        let protein = Int(round(weight * proteinMultiplier))
        let fat = Int(round((Double(targetCalories) * 0.25) / 9.0))

        let proteinCalories = protein * 4
        let fatCalories = fat * 9
        let carbCalories = targetCalories - proteinCalories - fatCalories
        let carbs = max(0, Int(round(Double(carbCalories) / 4.0)))

        return MacroGrams(protein: protein, carbs: carbs, fat: fat)
    }

    static func calculateAll(profile: UserProfile) -> CalculationResults {
        let bmi = calculateBMI(weight: profile.weight, height: profile.height)
        let bmiCategory = getBMICategory(bmi: bmi)
        let bmr = calculateBMR(
            weight: profile.weight,
            height: profile.height,
            age: profile.age,
            gender: profile.gender
        )
        let tdee = calculateTDEE(bmr: bmr, activityLevel: profile.activityLevel)
        let targetCalories = calculateTargetCalories(tdee: tdee, goal: profile.goal)
        let macros = calculateMacros(targetCalories: targetCalories, weight: profile.weight, goal: profile.goal)

        let proteinPercent: Double
        let carbsPercent: Double
        let fatPercent: Double
        if targetCalories > 0 {
            proteinPercent = round(((Double(macros.protein * 4) / Double(targetCalories)) * 1000)) / 10
            carbsPercent = round(((Double(macros.carbs * 4) / Double(targetCalories)) * 1000)) / 10
            fatPercent = round(((Double(macros.fat * 9) / Double(targetCalories)) * 1000)) / 10
        } else {
            proteinPercent = 0
            carbsPercent = 0
            fatPercent = 0
        }

        return CalculationResults(
            bmi: bmi,
            bmiCategory: bmiCategory,
            bmr: bmr,
            tdee: tdee,
            targetCalories: targetCalories,
            macros: macros,
            macroPercentages: MacroPercentages(
                protein: proteinPercent,
                carbs: carbsPercent,
                fat: fatPercent
            )
        )
    }
}
