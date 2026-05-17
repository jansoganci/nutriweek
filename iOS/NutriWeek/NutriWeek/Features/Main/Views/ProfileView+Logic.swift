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
            struct LatestWeightRow: Decodable {
                let weight_kg: Double
            }

            let profileRows: [ProfileRow] = try await client.from("profiles")
                .select("gender, age, height_cm, weight_kg, activity_level, goal, dietary_preferences, onboarding_complete")
                .eq("user_id", value: userId)
                .execute()
                .value

            guard let row = profileRows.first else {
                throw NSError(domain: "ProfileView", code: 1, userInfo: [NSLocalizedDescriptionKey: String(localized: "profile.error.not_found")])
            }

            let latestWeightRows: [LatestWeightRow] = (try? await client.from("body_measurements")
                .select("weight_kg")
                .eq("user_id", value: userId)
                .not("weight_kg", operator: .is, value: "null")
                .order("measured_at", ascending: false)
                .limit(1)
                .execute()
                .value) ?? []

            let weightForDisplay = latestWeightRows.first?.weight_kg ?? row.weight_kg ?? 0

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
                weight: weightForDisplay,
                activityLevel: ActivityLevel(rawValue: row.activity_level ?? "sedentary") ?? .sedentary,
                goal: Goal(rawValue: row.goal ?? "maintain") ?? .maintain,
                measurements: measurements,
                dietaryPreferences: (row.dietary_preferences ?? []).compactMap(DietaryPreference.init(rawValue:)),
                onboardingComplete: row.onboarding_complete ?? false,
                createdAt: Date().ISO8601Format(),
                updatedAt: Date().ISO8601Format()
            )

            profileInitials = Self.displayInitials(fromEmail: session.user.email)
            profile = p
            results = NutritionCalculationService.calculateAll(profile: p)
            hydrateEditableFields(p)
        } catch {
            loadingError = error.localizedDescription
        }
    }

    func hydrateEditableFields(_ p: UserProfile) {
        let info = EditablePersonalInfo(age: "\(p.age)", gender: p.gender.rawValue, height: oneDecimal(p.height), activityLevel: p.activityLevel.rawValue)
        infoFields = info
        infoDraft = info
    }

    func handleSaveInfo() async {
        guard var profile else { return }
        let ageNum = Int(infoDraft.age) ?? -1
        let heightNum = Double(infoDraft.height) ?? -1
        var valid = true
        if ageNum < 10 || ageNum > 120 { ageError = String(localized: "profile.validation.age_range"); valid = false } else { ageError = nil }
        if heightNum < 50 || heightNum > 300 { heightError = String(localized: "profile.validation.height_range"); valid = false } else { heightError = nil }
        guard valid else { return }
        guard let gender = Gender(rawValue: infoDraft.gender.lowercased()), let activity = ActivityLevel(rawValue: infoDraft.activityLevel.lowercased()) else {
            validationAlertMessage = String(localized: "profile.validation.gender_activity_required")
            showValidationAlert = true
            return
        }

        profile.age = ageNum
        profile.gender = gender
        profile.height = heightNum
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
            showToastMessage(String(localized: "profile.toast.updated"))
        } catch {
            validationAlertMessage = String(localized: "profile.error.save_failed \(error.localizedDescription)")
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
            showToastMessage(String(localized: "profile.toast.reset_all_done"))
        } catch {
            validationAlertMessage = String(localized: "profile.error.reset_failed \(error.localizedDescription)")
            showValidationAlert = true
        }
    }

    func handleDeleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            struct DeleteAccountResponse: Decodable { let success: Bool }
            let response: DeleteAccountResponse = try await EdgeFunctionClient(client: client).invoke("delete-account")
            guard response.success else {
                validationAlertMessage = String(localized: "profile.error.delete_failed_generic")
                showValidationAlert = true
                return
            }
            try await client.auth.signOut()
        } catch {
            validationAlertMessage = String(localized: "profile.error.delete_failed \(error.localizedDescription)")
            showValidationAlert = true
        }
    }

    func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation(.easeInOut(duration: 0.2)) { showToast = true }
        Task { try? await Task.sleep(nanoseconds: 2_000_000_000); withAnimation(.easeInOut(duration: 0.3)) { showToast = false } }
    }

    func clearFieldErrors() { ageError = nil; heightError = nil }

    func goalLabel(_ goal: Goal) -> String {
        switch goal { case .cut: return String(localized: "goal.cut"); case .bulk: return String(localized: "goal.bulk"); case .maintain: return String(localized: "goal.maintain") }
    }
    func activityLabel(_ level: ActivityLevel) -> String {
        switch level {
        case .sedentary: return String(localized: "activity.sedentary")
        case .lightlyActive: return String(localized: "activity.lightly_active")
        case .moderatelyActive: return String(localized: "activity.moderately_active")
        case .veryActive: return String(localized: "activity.very_active")
        case .extraActive: return String(localized: "activity.extra_active")
        }
    }
    func rockyMessage(for goal: Goal) -> String {
        switch goal { case .cut: return String(localized: "profile.rocky.cut"); case .bulk: return String(localized: "profile.rocky.bulk"); case .maintain: return String(localized: "profile.rocky.maintain") }
    }
    func dietaryLabel(_ pref: DietaryPreference) -> String {
        switch pref {
        case .vegetarian: return String(localized: "diet.vegetarian")
        case .vegan: return String(localized: "diet.vegan")
        case .glutenFree: return String(localized: "diet.gluten_free")
        case .dairyFree: return String(localized: "diet.dairy_free")
        case .keto: return String(localized: "diet.keto")
        case .paleo: return String(localized: "diet.paleo")
        case .halal: return String(localized: "diet.halal")
        case .kosher: return String(localized: "diet.kosher")
        case .nutFree: return String(localized: "diet.nut_free")
        case .lowSodium: return String(localized: "diet.low_sodium")
        }
    }
    func oneDecimal(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }

    /// Up to two letters from the account email local-part (e.g. `jane.doe@…` → `JD`).
    static func displayInitials(fromEmail email: String?) -> String {
        guard let email = email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            return "?"
        }
        let local = email.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? email
        let segments = local.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init).filter { !$0.isEmpty }
        if segments.count >= 2, let f = segments.first?.first, let l = segments.last?.first {
            return String([f, l]).uppercased()
        }
        let alphanumeric = local.filter { $0.isLetter || $0.isNumber }
        if alphanumeric.count >= 2 {
            return String(alphanumeric.prefix(2)).uppercased()
        }
        if let c = alphanumeric.first {
            return String(c).uppercased()
        }
        return "?"
    }
}
