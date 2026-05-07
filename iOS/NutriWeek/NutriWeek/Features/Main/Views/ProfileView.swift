import SwiftUI
import Supabase

struct ProfileView: View {
    struct EditablePersonalInfo {
        var age = ""
        var gender = ""
        var height = ""
        var weight = ""
        var activityLevel = ""
    }

    struct EditableMeasurements {
        var waist = ""
        var hips = ""
        var chest = ""
        var arms = ""
        var thighs = ""
    }

    let client: SupabaseClient = SupabaseClientFactory.shared

    @State var profile: UserProfile?
    @State var results: CalculationResults?
    @State var loadingError: String?

    @State var editingInfo = false
    @State var infoFields = EditablePersonalInfo()
    @State var infoDraft = EditablePersonalInfo()

    @State var editingMeasurements = false
    @State var measurementFields = EditableMeasurements()
    @State var measurementDraft = EditableMeasurements()

    @State var ageError: String?
    @State var heightError: String?
    @State var weightError: String?

    @State var toastMessage = ""
    @State var showToast = false
    @State var showValidationAlert = false
    @State var validationAlertMessage = ""
    @State var showResetAllConfirm = false

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
    }
}
