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
        .alert("Validation", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationAlertMessage)
        }
        .alert("Reset All Data", isPresented: $showResetAllConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Everything", role: .destructive) {
                Task { await handleResetAll() }
            }
        } message: {
            Text("Are you sure? This will delete everything.")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete My Account", role: .destructive) {
                Task { await handleDeleteAccount() }
            }
        } message: {
            Text("This will permanently delete all your data including meal plans, food logs, measurements, and streaks. This action cannot be undone.")
        }
        .sheet(isPresented: $showMeasurementLogSheet) {
            MeasurementLogSheet(onSaved: { await loadProfile() })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}
