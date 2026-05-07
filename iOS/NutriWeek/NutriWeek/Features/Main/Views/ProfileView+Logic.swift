import SwiftUI
import Supabase

extension ProfileView {
    func loadProfile() async {
        do {
            loadingError = nil
            let session = try await client.auth.session
            let userId = session.user.id.uuidString

            struct ProfileRow: Decodable {
                let gender: String?
                let age: Int?
                let height_cm: Double?
                let weight_kg: Double?
                let activity_level: String?
                let goal: String?
                let dietary_preferences: [String]?
                let onboarding_complete: Bool?
            }
            struct MeasurementRow: Decodable {
                let waist_cm: Double?
                let hips_cm: Double?
                let chest_cm: Double?
                let left_arm_cm: Double?
                let left_leg_cm: Double?
            }

            let profileRows: [ProfileRow] = try await client.from("profiles")
                .select("gender, age, height_cm, weight_kg, activity_level, goal, dietary_preferences, onboarding_complete")
                .eq("user_id", value: userId)
                .execute()
                .value

            guard let row = profileRows.first else {
                throw NSError(domain: "ProfileView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Profile not found. Please complete onboarding again."])
            }

            let measurementRows: [MeasurementRow] = (try? await client.from("body_measurements")
                .select("waist_cm, hips_cm, chest_cm, left_arm_cm, left_leg_cm")
                .eq("user_id", value: userId)
                .order("measured_at", ascending: false)
                .limit(1)
                .execute()
                .value) ?? []

            let measurements: BodyMeasurements? = measurementRows.first.map {
                BodyMeasurements(chest: $0.chest_cm, waist: $0.waist_cm, hips: $0.hips_cm, thighs: $0.left_leg_cm, arms: $0.left_arm_cm)
            }

            let p = UserProfile(
                gender: Gender(rawValue: row.gender ?? "other") ?? .other,
                age: row.age ?? 0,
                height: row.height_cm ?? 0,
                weight: row.weight_kg ?? 0,
                activityLevel: ActivityLevel(rawValue: row.activity_level ?? "sedentary") ?? .sedentary,
                goal: Goal(rawValue: row.goal ?? "maintain") ?? .maintain,
                measurements: measurements,
                dietaryPreferences: (row.dietary_preferences ?? []).compactMap(DietaryPreference.init(rawValue:)),
                onboardingComplete: row.onboarding_complete ?? false,
                createdAt: Date().ISO8601Format(),
                updatedAt: Date().ISO8601Format()
            )

            profile = p
            results = NutritionCalculationService.calculateAll(profile: p)
            hydrateEditableFields(p)
        } catch {
            loadingError = error.localizedDescription
        }
    }

    func hydrateEditableFields(_ p: UserProfile) {
        let info = EditablePersonalInfo(age: "\(p.age)", gender: p.gender.rawValue, height: oneDecimal(p.height), weight: oneDecimal(p.weight), activityLevel: p.activityLevel.rawValue)
        infoFields = info
        infoDraft = info
        let m = p.measurements
        let measurement = EditableMeasurements(
            waist: m?.waist.map(oneDecimal) ?? "",
            hips: m?.hips.map(oneDecimal) ?? "",
            chest: m?.chest.map(oneDecimal) ?? "",
            arms: m?.arms.map(oneDecimal) ?? "",
            thighs: m?.thighs.map(oneDecimal) ?? ""
        )
        measurementFields = measurement
        measurementDraft = measurement
    }

    func handleSaveInfo() async {
        guard var profile else { return }
        let ageNum = Int(infoDraft.age) ?? -1
        let heightNum = Double(infoDraft.height) ?? -1
        let weightNum = Double(infoDraft.weight) ?? -1
        var valid = true
        if ageNum < 10 || ageNum > 120 { ageError = "Age must be between 10 and 120"; valid = false } else { ageError = nil }
        if heightNum < 50 || heightNum > 300 { heightError = "Height must be between 50 and 300 cm"; valid = false } else { heightError = nil }
        if weightNum < 20 || weightNum > 500 { weightError = "Weight must be between 20 and 500 kg"; valid = false } else { weightError = nil }
        guard valid else { return }
        guard let gender = Gender(rawValue: infoDraft.gender.lowercased()), let activity = ActivityLevel(rawValue: infoDraft.activityLevel.lowercased()) else {
            validationAlertMessage = "Gender and activity level are required."
            showValidationAlert = true
            return
        }

        profile.age = ageNum
        profile.gender = gender
        profile.height = heightNum
        profile.weight = weightNum
        profile.activityLevel = activity
        profile.updatedAt = Date().ISO8601Format()

        do {
            let userId = try await client.auth.session.user.id.uuidString
            struct ProfileUpsert: Encodable {
                let user_id: String
                let gender: String
                let age: Int
                let height_cm: Double
                let weight_kg: Double
                let activity_level: String
            }
            try await client.from("profiles")
                .upsert(ProfileUpsert(user_id: userId, gender: profile.gender.rawValue, age: profile.age, height_cm: profile.height, weight_kg: profile.weight, activity_level: profile.activityLevel.rawValue), onConflict: "user_id")
                .execute()

            let calc = NutritionCalculationService.calculateAll(profile: profile)
            try await OnboardingService.saveCalculatedResults(calc)
            self.profile = profile
            results = calc
            infoFields = infoDraft
            editingInfo = false
            showToastMessage("Profile updated! 🦝✅")
        } catch {
            validationAlertMessage = "Save failed: \(error.localizedDescription)"
            showValidationAlert = true
        }
    }

    func handleSaveMeasurements() async {
        guard var profile else { return }
        let measurements = BodyMeasurements(
            chest: measurementDraft.chest.isEmpty ? nil : Double(measurementDraft.chest),
            waist: measurementDraft.waist.isEmpty ? nil : Double(measurementDraft.waist),
            hips: measurementDraft.hips.isEmpty ? nil : Double(measurementDraft.hips),
            thighs: measurementDraft.thighs.isEmpty ? nil : Double(measurementDraft.thighs),
            arms: measurementDraft.arms.isEmpty ? nil : Double(measurementDraft.arms)
        )
        do {
            let userId = try await client.auth.session.user.id.uuidString
            struct MeasurementInsert: Encodable {
                let user_id: String
                let waist_cm: Double?
                let hips_cm: Double?
                let chest_cm: Double?
                let left_arm_cm: Double?
                let left_leg_cm: Double?
            }
            try await client.from("body_measurements")
                .insert(MeasurementInsert(user_id: userId, waist_cm: measurements.waist, hips_cm: measurements.hips, chest_cm: measurements.chest, left_arm_cm: measurements.arms, left_leg_cm: measurements.thighs))
                .execute()
            profile.measurements = measurements
            profile.updatedAt = Date().ISO8601Format()
            self.profile = profile
            measurementFields = measurementDraft
            editingMeasurements = false
            showToastMessage("Measurements saved! 🦝✅")
        } catch {
            validationAlertMessage = "Save failed: \(error.localizedDescription)"
            showValidationAlert = true
        }
    }

    func handleResetAll() async {
        do {
            let userId = try await client.auth.session.user.id.uuidString
            struct ResetProfile: Encodable { let user_id: String; let onboarding_complete: Bool; let onboarding_step: Int }
            try await client.from("profiles")
                .upsert(ResetProfile(user_id: userId, onboarding_complete: false, onboarding_step: 0), onConflict: "user_id")
                .execute()
            if let bundleId = Bundle.main.bundleIdentifier { UserDefaults.standard.removePersistentDomain(forName: bundleId) }
            showToastMessage("All local data reset. Please reopen app.")
        } catch {
            validationAlertMessage = "Reset failed: \(error.localizedDescription)"
            showValidationAlert = true
        }
    }

    func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation(.easeInOut(duration: 0.2)) { showToast = true }
        Task { try? await Task.sleep(nanoseconds: 2_000_000_000); withAnimation(.easeInOut(duration: 0.3)) { showToast = false } }
    }

    func clearFieldErrors() { ageError = nil; heightError = nil; weightError = nil }

    func goalLabel(_ goal: Goal) -> String {
        switch goal { case .cut: return "Lose Fat 🔥"; case .bulk: return "Build Muscle 💪"; case .maintain: return "Stay Balanced ⚖️" }
    }
    func activityLabel(_ level: ActivityLevel) -> String {
        switch level {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive: return "Very Active"
        case .extraActive: return "Extra Active"
        }
    }
    func rockyMessage(for goal: Goal) -> String {
        switch goal { case .cut: return "Stay in that deficit! You've got this 🦝🔥"; case .bulk: return "Eat big, lift big! Let's grow 🦝💪"; case .maintain: return "Balance is the key 🦝⚖️" }
    }
    func dietaryLabel(_ pref: DietaryPreference) -> String {
        switch pref {
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .glutenFree: return "Gluten Free"
        case .dairyFree: return "Dairy Free"
        case .keto: return "Keto"
        case .paleo: return "Paleo"
        case .halal: return "Halal"
        case .kosher: return "Kosher"
        case .nutFree: return "Nut Free"
        case .lowSodium: return "Low Sodium"
        }
    }
    func oneDecimal(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
