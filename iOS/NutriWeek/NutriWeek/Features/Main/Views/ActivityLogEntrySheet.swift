import SwiftUI
import Supabase
import OSLog

private let saveLog = Logger(subsystem: "com.nutriweek.NutriWeek", category: "ActivityLogEntry")

enum ActivityLogError: LocalizedError {
    case notAuthenticated
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return String(localized: "activity.error.not_authenticated")
        case .saveFailed(let detail):
            return String(localized: "activity.error.save_failed \(detail)")
        }
    }
}

struct ActivityLogEntrySheet: View {
    let repository: ActivityLogRepositoryProtocol
    let onSaved: () async -> Void

    let client: SupabaseClient = SupabaseClientFactory.shared

    @Environment(\.dismiss) private var dismiss

    @State private var activityName = ""
    @State private var durationMinutes = ""
    @State private var caloriesBurned = ""
    @State private var loggedAt = Date()
    @State private var selectedWorkoutType: WorkoutType = .cardio
    @State private var sets = ""
    @State private var reps = ""
    @State private var weight = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    labeledTextField(
                        title: String(localized: "activity.form.activity_name"),
                        text: $activityName,
                        placeholder: String(localized: "activity.form.activity_name_placeholder"),
                        keyboardType: .default
                    )

                    labeledTextField(
                        title: String(localized: "activity.form.duration_minutes"),
                        text: $durationMinutes,
                        placeholder: String(localized: "activity.form.duration_placeholder"),
                        keyboardType: .numberPad
                    )
                    .onChange(of: durationMinutes) { _, newValue in
                        durationMinutes = sanitizeDigits(newValue)
                    }

                    labeledTextField(
                        title: String(localized: "activity.form.calories_burned"),
                        text: $caloriesBurned,
                        placeholder: String(localized: "activity.form.calories_placeholder"),
                        keyboardType: .decimalPad
                    )
                    .onChange(of: caloriesBurned) { _, newValue in
                        caloriesBurned = sanitizeDecimal(newValue)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("activity.form.workout_type"))
                            .font(TypographyToken.inter(size: 12, weight: .semibold))
                            .foregroundStyle(ColorToken.mutedForeground)
                            .tracking(0.5)

                        Picker("", selection: $selectedWorkoutType) {
                            ForEach(WorkoutType.allCases, id: \.self) { type in
                                Text(workoutTypeLabel(type)).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if selectedWorkoutType == .strength {
                        labeledTextField(
                            title: String(localized: "activity.form.sets"),
                            text: $sets,
                            placeholder: String(localized: "activity.form.sets_placeholder"),
                            keyboardType: .numberPad
                        )
                        .onChange(of: sets) { _, newValue in
                            sets = sanitizeDigits(newValue)
                        }

                        labeledTextField(
                            title: String(localized: "activity.form.reps"),
                            text: $reps,
                            placeholder: String(localized: "activity.form.reps_placeholder"),
                            keyboardType: .numberPad
                        )
                        .onChange(of: reps) { _, newValue in
                            reps = sanitizeDigits(newValue)
                        }

                        labeledTextField(
                            title: String(localized: "activity.form.weight"),
                            text: $weight,
                            placeholder: String(localized: "activity.form.weight_placeholder"),
                            keyboardType: .decimalPad
                        )
                        .onChange(of: weight) { _, newValue in
                            weight = sanitizeDecimal(newValue)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("activity.form.date"))
                            .font(TypographyToken.inter(size: 12, weight: .semibold))
                            .foregroundStyle(ColorToken.mutedForeground)
                            .tracking(0.5)

                        DatePicker("", selection: $loggedAt, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(ColorToken.primary)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("activity.form.notes"))
                            .font(TypographyToken.inter(size: 12, weight: .semibold))
                            .foregroundStyle(ColorToken.mutedForeground)
                            .tracking(0.5)

                        ZStack(alignment: .topLeading) {
                            if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(LocalizedStringKey("activity.form.notes_placeholder"))
                                    .font(TypographyToken.inter(size: 14, weight: .regular))
                                    .foregroundStyle(ColorToken.textTertiary)
                                    .padding(.horizontal, 4)
                                    .padding(.top, 8)
                            }

                            TextEditor(text: $notes)
                                .font(TypographyToken.inter(size: 14, weight: .regular))
                                .foregroundStyle(ColorToken.textPrimary)
                                .frame(minHeight: 110)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, 2)
                                .padding(.vertical, 4)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ColorToken.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(ColorToken.border, lineWidth: 1)
                        )
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(LocalizedStringKey("activity.sheet.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveTapped() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(LocalizedStringKey("common.save"))
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .tint(ColorToken.primary)
        .alert(String(localized: "common.error.generic_title"), isPresented: $showError) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func labeledTextField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(TypographyToken.inter(size: 12, weight: .semibold))
                .foregroundStyle(ColorToken.mutedForeground)
                .tracking(0.5)

            TextField(placeholder, text: text)
                .font(TypographyToken.inter(size: 14, weight: .regular))
                .foregroundStyle(ColorToken.inputForeground)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(ColorToken.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(ColorToken.border, lineWidth: 1)
                )
        }
    }

    private func saveTapped() async {
        let trimmedName = activityName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            presentValidationError("activity.validation.name_required")
            return
        }

        let trimmedDuration = durationMinutes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let duration = Int(trimmedDuration) else {
            presentValidationError("activity.validation.duration_invalid")
            return
        }
        guard duration > 0 else {
            presentValidationError("activity.validation.duration_positive")
            return
        }

        let trimmedCalories = caloriesBurned.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let calories = Double(trimmedCalories) else {
            presentValidationError("activity.validation.calories_invalid")
            return
        }
        guard calories > 0 else {
            presentValidationError("activity.validation.calories_positive")
            return
        }

        if selectedWorkoutType == .strength {
            guard let setsValue = Int(sets.trimmingCharacters(in: .whitespacesAndNewlines)), setsValue > 0 else {
                presentValidationError("activity.validation.sets_invalid")
                return
            }
            guard let repsValue = Int(reps.trimmingCharacters(in: .whitespacesAndNewlines)), repsValue > 0 else {
                presentValidationError("activity.validation.reps_invalid")
                return
            }
        }

        isSaving = true
        defer { isSaving = false }

        do {
            saveLog.log("Attempting to get user ID from auth session")
            let userId: String
            do {
                userId = try await client.auth.session.user.id.uuidString
            } catch {
                saveLog.error("Auth session error: \(String(describing: error), privacy: .public)")
                throw ActivityLogError.notAuthenticated
            }
            saveLog.log("Got userId: \(userId, privacy: .public)")

            let entry = ActivityLogEntry(
                id: UUID().uuidString,
                userId: userId,
                activityName: trimmedName,
                activityType: selectedWorkoutType.rawValue,
                durationMinutes: duration,
                caloriesBurned: calories,
                sets: strengthSets(),
                reps: strengthReps(),
                weightKg: strengthWeight(),
                notes: normalizedNotes(),
                loggedAt: Calendar.current.startOfDay(for: loggedAt),
                createdAt: Date()
            )
            saveLog.log("Saving activity: \(trimmedName, privacy: .public), \(duration) min, \(calories, privacy: .public) kcal")

            try await repository.addEntry(entry)
            saveLog.log("Activity saved successfully")
            await onSaved()
            dismiss()
        } catch {
            saveLog.error("Failed to save activity: \(error.localizedDescription, privacy: .public)")
            saveLog.error("Full error: \(String(describing: error), privacy: .public)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func presentValidationError(_ key: String.LocalizationValue) {
        errorMessage = String(localized: key)
        showError = true
    }

    private func normalizedNotes() -> String? {
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func sanitizeDigits(_ text: String) -> String {
        text.filter { $0.isNumber }
    }

    private func sanitizeDecimal(_ text: String) -> String {
        let allowed = text.filter { "0123456789.".contains($0) }
        var output = ""
        var hasDot = false

        for character in allowed {
            if character == "." {
                if hasDot { continue }
                hasDot = true
            }
            output.append(character)
        }

        return output
    }

    private func workoutTypeLabel(_ type: WorkoutType) -> String {
        switch type {
        case .strength: return String(localized: "activity.workout_type.strength")
        case .cardio: return String(localized: "activity.workout_type.cardio")
        case .mobility: return String(localized: "activity.workout_type.mobility")
        case .sport: return String(localized: "activity.workout_type.sport")
        case .other: return String(localized: "activity.workout_type.other")
        }
    }

    private func strengthSets() -> Int? {
        selectedWorkoutType == .strength ? Int(sets.trimmingCharacters(in: .whitespacesAndNewlines)) : nil
    }

    private func strengthReps() -> Int? {
        selectedWorkoutType == .strength ? Int(reps.trimmingCharacters(in: .whitespacesAndNewlines)) : nil
    }

    private func strengthWeight() -> Double? {
        guard selectedWorkoutType == .strength else { return nil }
        let trimmed = weight.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : Double(trimmed)
    }
}
