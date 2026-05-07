import Foundation
import Supabase

@MainActor
enum OnboardingService {
    private static var client: SupabaseClient { SupabaseClientFactory.shared }

    // MARK: - Fetch

    static func fetchOnboardingProfile() async throws -> OnboardingProfile {
        let session = try await client.auth.session
        let userId = session.user.id

        struct Row: Decodable {
            let gender: String?
            let age: Int?
            let height_cm: Double?
            let weight_kg: Double?
            let activity_level: String?
            let goal: String?
            let dietary_preferences: [String]?
            let onboarding_complete: Bool?

            func toModel() -> OnboardingProfile {
                OnboardingProfile(
                    gender: gender.flatMap { Gender(rawValue: $0) },
                    age: age,
                    heightCm: height_cm,
                    weightKg: weight_kg,
                    activityLevel: activity_level.flatMap { ActivityLevel(rawValue: $0) },
                    goal: goal.flatMap { Goal(rawValue: $0) },
                    dietaryPreferenceKeys: dietary_preferences ?? [],
                    onboardingComplete: onboarding_complete ?? false
                )
            }
        }

        let rows: [Row] = try await client.from("profiles")
            .select("gender, age, height_cm, weight_kg, activity_level, goal, dietary_preferences, onboarding_complete")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        if let row = rows.first {
            return row.toModel()
        }
        return OnboardingProfile(
            gender: nil,
            age: nil,
            heightCm: nil,
            weightKg: nil,
            activityLevel: nil,
            goal: nil,
            dietaryPreferenceKeys: [],
            onboardingComplete: false
        )
    }

    // MARK: - Saves (RN onboarding.ts)

    static func saveStep1(
        gender: Gender,
        age: Int,
        heightCm: Double,
        weightKg: Double,
        activityLevel: ActivityLevel
    ) async throws {
        let userId = try await requireUserId()
        struct Upsert: Encodable {
            let user_id: String
            let gender: String
            let age: Int
            let height_cm: Double
            let weight_kg: Double
            let activity_level: String
            let onboarding_step: Int
        }
        try await client.from("profiles")
            .upsert(
                Upsert(
                    user_id: userId,
                    gender: gender.rawValue,
                    age: age,
                    height_cm: heightCm,
                    weight_kg: weightKg,
                    activity_level: activityLevel.rawValue,
                    onboarding_step: 1
                ),
                onConflict: "user_id"
            )
            .execute()
    }

    static func saveStep2(goal: Goal) async throws {
        let userId = try await requireUserId()
        struct Upsert: Encodable {
            let user_id: String
            let goal: String
            let onboarding_step: Int
        }
        try await client.from("profiles")
            .upsert(
                Upsert(user_id: userId, goal: goal.rawValue, onboarding_step: 2),
                onConflict: "user_id"
            )
            .execute()
    }

    static func saveStep3(
        waistCm: Double?,
        hipsCm: Double?,
        chestCm: Double?,
        leftArmCm: Double?,
        leftLegCm: Double?
    ) async throws {
        let userId = try await requireUserId()
        let hasNumber = [waistCm, hipsCm, chestCm, leftArmCm, leftLegCm].contains { v in
            guard let v else { return false }
            return !v.isNaN
        }

        if hasNumber {
            struct Insert: Encodable {
                let user_id: String
                let waist_cm: Double?
                let hips_cm: Double?
                let chest_cm: Double?
                let left_arm_cm: Double?
                let left_leg_cm: Double?
            }
            try await client.from("body_measurements")
                .insert(
                    Insert(
                        user_id: userId,
                        waist_cm: waistCm,
                        hips_cm: hipsCm,
                        chest_cm: chestCm,
                        left_arm_cm: leftArmCm,
                        left_leg_cm: leftLegCm
                    )
                )
                .execute()
        }

        struct ProfileUpsert: Encodable {
            let user_id: String
            let onboarding_step: Int
        }
        try await client.from("profiles")
            .upsert(ProfileUpsert(user_id: userId, onboarding_step: 3), onConflict: "user_id")
            .execute()
    }

    static func saveStep4(dietaryPreferences: [String]) async throws {
        let userId = try await requireUserId()
        struct Upsert: Encodable {
            let user_id: String
            let dietary_preferences: [String]
            let onboarding_step: Int
        }
        try await client.from("profiles")
            .upsert(
                Upsert(
                    user_id: userId,
                    dietary_preferences: dietaryPreferences,
                    onboarding_step: 4
                ),
                onConflict: "user_id"
            )
            .execute()
    }

    struct NutritionTargetsPayload: Encodable {
        let bmi: Double
        let bmiCategory: String
        let bmr: Int
        let tdee: Int
        let targetCalories: Int
        let proteinG: Int
        let carbsG: Int
        let fatG: Int
        let proteinPct: Double
        let carbsPct: Double
        let fatPct: Double
    }

    static func saveCalculatedResults(_ r: CalculationResults) async throws {
        let payload = NutritionTargetsPayload(
            bmi: r.bmi,
            bmiCategory: r.bmiCategory.label,
            bmr: r.bmr,
            tdee: r.tdee,
            targetCalories: r.targetCalories,
            proteinG: r.macros.protein,
            carbsG: r.macros.carbs,
            fatG: r.macros.fat,
            proteinPct: r.macroPercentages.protein,
            carbsPct: r.macroPercentages.carbs,
            fatPct: r.macroPercentages.fat
        )
        try await saveResults(payload: payload)
    }

    static func saveResults(payload: NutritionTargetsPayload) async throws {
        let userId = try await requireUserId()
        let now = ISO8601DateFormatter().string(from: Date())

        struct TargetsUpsert: Encodable {
            let user_id: String
            let bmi: Double
            let bmi_category: String
            let bmr: Int
            let tdee: Int
            let target_calories: Int
            let protein_g: Int
            let carbs_g: Int
            let fat_g: Int
            let protein_pct: Double
            let carbs_pct: Double
            let fat_pct: Double
            let calculated_at: String
            let updated_at: String
        }

        try await client.from("nutrition_targets")
            .upsert(
                TargetsUpsert(
                    user_id: userId,
                    bmi: payload.bmi,
                    bmi_category: payload.bmiCategory,
                    bmr: payload.bmr,
                    tdee: payload.tdee,
                    target_calories: payload.targetCalories,
                    protein_g: payload.proteinG,
                    carbs_g: payload.carbsG,
                    fat_g: payload.fatG,
                    protein_pct: payload.proteinPct,
                    carbs_pct: payload.carbsPct,
                    fat_pct: payload.fatPct,
                    calculated_at: now,
                    updated_at: now
                ),
                onConflict: "user_id"
            )
            .execute()

        struct ProfileUpsert: Encodable {
            let user_id: String
            let onboarding_complete: Bool
            let onboarding_step: Int
        }
        try await client.from("profiles")
            .upsert(
                ProfileUpsert(user_id: userId, onboarding_complete: true, onboarding_step: 5),
                onConflict: "user_id"
            )
            .execute()
    }

    // MARK: - Auth

    private static func requireUserId() async throws -> String {
        let session = try await client.auth.session
        return session.user.id.uuidString
    }
}
