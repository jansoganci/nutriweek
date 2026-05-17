import SwiftUI
import Supabase

struct ProfileView: View {
    struct EditablePersonalInfo {
        var age = ""
        var gender = ""
        var height = ""
        var activityLevel = ""
    }

    let client: SupabaseClient = SupabaseClientFactory.shared

    @State var profile: UserProfile?
    @State var results: CalculationResults?
    @State var loadingError: String?
    /// From account email local-part (e.g. `jane.doe@…` → `JD`).
    @State var profileInitials: String = "?"

    @State var editingInfo = false
    @State var infoFields = EditablePersonalInfo()
    @State var infoDraft = EditablePersonalInfo()

    @State var ageError: String?
    @State var heightError: String?

    @State var toastMessage = ""
    @State var showToast = false
    @State var showValidationAlert = false
    @State var validationAlertMessage = ""
    @State var showResetAllConfirm = false
    @State var showDeleteAccountConfirm = false
    @State var isDeleting = false
    @State var showMeasurementLogSheet = false

    var body: some View {
        Group {
            if let profile, let results {
                content(profile: profile, results: results)
            } else {
                loadingView
            }
        }
        .task { await loadProfile() }
        .alert(String(localized: "profile.alert.validation_title"), isPresented: $showValidationAlert) {
            Button(String(localized: "profile.alert.ok"), role: .cancel) {}
        } message: {
            Text(validationAlertMessage)
        }
        .alert(String(localized: "profile.alert.reset_all_title"), isPresented: $showResetAllConfirm) {
            Button(String(localized: "profile.alert.cancel"), role: .cancel) {}
            Button(String(localized: "profile.alert.delete_everything"), role: .destructive) {
                Task { await handleResetAll() }
            }
        } message: {
            Text(LocalizedStringKey("profile.delete_confirm.title"))
        }
        .alert(String(localized: "profile.alert.delete_account_title"), isPresented: $showDeleteAccountConfirm) {
            Button(String(localized: "profile.alert.cancel"), role: .cancel) {}
            Button(String(localized: "profile.alert.delete_my_account"), role: .destructive) {
                Task { await handleDeleteAccount() }
            }
        } message: {
            Text(LocalizedStringKey("profile.delete_confirm.message"))
        }
        .sheet(isPresented: $showMeasurementLogSheet) {
            MeasurementLogSheet(onSaved: { await loadProfile() })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}
