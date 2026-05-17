import SwiftUI

struct WeeklyCheckInSheet: View {
    let userId: String
    let initialRecord: WeeklyCheckInRecord?
    let onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var weightKg = ""
    @State private var workoutCount = ""
    @State private var energyLevel = 3
    @State private var note = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let store = PersonalProgressStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    checkInField(
                        label: String(localized: "personal.weekly_check_in.weight"),
                        text: $weightKg,
                        placeholder: String(localized: "personal.weekly_check_in.weight_placeholder"),
                        keyboard: .decimalPad
                    )
                    checkInField(
                        label: String(localized: "personal.weekly_check_in.workouts"),
                        text: $workoutCount,
                        placeholder: String(localized: "personal.weekly_check_in.workouts_placeholder"),
                        keyboard: .numberPad
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey("personal.weekly_check_in.energy"))
                            .font(TypographyToken.inter(size: 12, weight: .semibold))
                            .foregroundStyle(ColorToken.mutedForeground)
                            .tracking(0.5)
                        Picker("", selection: $energyLevel) {
                            ForEach(1...5, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey("personal.weekly_check_in.note"))
                            .font(TypographyToken.inter(size: 12, weight: .semibold))
                            .foregroundStyle(ColorToken.mutedForeground)
                            .tracking(0.5)
                        TextEditor(text: $note)
                            .frame(minHeight: 96)
                            .padding(10)
                            .background(ColorToken.inputBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(ColorToken.border, lineWidth: 1)
                            )
                    }
                }
                .padding(.bottom, 8)
            }

            saveButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .background(ColorToken.background)
        .onAppear { populateFields() }
        .alert(String(localized: "personal.weekly_check_in.error_title"), isPresented: $showError) {
            Button(String(localized: "measurement.ok"), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "personal.weekly_check_in.title"))
                    .font(TypographyToken.inter(size: 20, weight: .bold))
                    .foregroundStyle(ColorToken.textPrimary)
                Text(String(localized: "personal.weekly_check_in.subtitle"))
                    .font(TypographyToken.inter(size: 14, weight: .regular))
                    .foregroundStyle(ColorToken.textSecondary)
            }

            Spacer(minLength: 0)

            Button("✕") {
                dismiss()
            }
            .font(TypographyToken.inter(size: 14, weight: .semibold))
            .foregroundStyle(ColorToken.textSecondary)
            .frame(width: 32, height: 32)
            .background(ColorToken.muted)
            .clipShape(Circle())
            .buttonStyle(.plain)
        }
    }

    private var saveButton: some View {
        Button {
            Task { await saveTapped() }
        } label: {
            Group {
                if isSaving {
                    ProgressView()
                        .tint(Color.white)
                } else {
                    Text(LocalizedStringKey("common.save"))
                        .font(TypographyToken.inter(size: 17, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSaving ? ColorToken.primary.opacity(0.6) : ColorToken.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }

    private func checkInField(label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(TypographyToken.inter(size: 12, weight: .semibold))
                .foregroundStyle(ColorToken.mutedForeground)
                .tracking(0.5)
            TextField(placeholder, text: text)
                .font(TypographyToken.inter(size: 14, weight: .regular))
                .foregroundStyle(ColorToken.inputForeground)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboard)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(ColorToken.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(ColorToken.border, lineWidth: 1))
        }
    }

    private func populateFields() {
        guard let initialRecord else { return }
        if let weightKg = initialRecord.weightKg {
            self.weightKg = Self.numberFormatter.string(from: NSNumber(value: weightKg)) ?? ""
        }
        workoutCount = String(initialRecord.workoutCount)
        energyLevel = initialRecord.energyLevel
        note = initialRecord.note ?? ""
    }

    private func saveTapped() async {
        let trimmedWorkoutCount = workoutCount.trimmingCharacters(in: .whitespacesAndNewlines)
        let weekStart = Self.currentWeekStartISO()

        let parsedWeight = weightKg.trimmingCharacters(in: .whitespacesAndNewlines)
        let weightValue: Double?
        if parsedWeight.isEmpty {
            weightValue = nil
        } else if let value = Double(parsedWeight), value > 0 {
            weightValue = value
        } else {
            errorMessage = String(localized: "personal.weekly_check_in.validation.weight_invalid")
            showError = true
            return
        }

        guard let workouts = Int(trimmedWorkoutCount), workouts >= 0 else {
            errorMessage = String(localized: "personal.weekly_check_in.validation.workouts_invalid")
            showError = true
            return
        }

        guard (1...5).contains(energyLevel) else {
            errorMessage = String(localized: "personal.weekly_check_in.validation.energy_invalid")
            showError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let record = WeeklyCheckInRecord(
                userId: userId,
                weekStart: weekStart,
                weightKg: weightValue,
                workoutCount: workouts,
                energyLevel: energyLevel,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            try store.saveWeeklyCheckIn(record, userId: userId)
            await onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private static func currentWeekStartISO(reference: Date = Date()) -> String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: reference)) ?? reference
        return formatter.string(from: weekStart)
    }
}

struct RecoveryCheckInSheet: View {
    let userId: String
    let initialRecord: RecoveryCheckInRecord?
    let onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var sleepHours = ""
    @State private var sorenessLevel = 3
    @State private var energyLevel = 3
    @State private var note = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let store = PersonalProgressStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    checkInField(
                        label: String(localized: "personal.recovery_check_in.sleep"),
                        text: $sleepHours,
                        placeholder: String(localized: "personal.recovery_check_in.sleep_placeholder"),
                        keyboard: .decimalPad
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey("personal.recovery_check_in.soreness"))
                            .font(TypographyToken.inter(size: 12, weight: .semibold))
                            .foregroundStyle(ColorToken.mutedForeground)
                            .tracking(0.5)
                        Picker("", selection: $sorenessLevel) {
                            ForEach(1...5, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey("personal.recovery_check_in.energy"))
                            .font(TypographyToken.inter(size: 12, weight: .semibold))
                            .foregroundStyle(ColorToken.mutedForeground)
                            .tracking(0.5)
                        Picker("", selection: $energyLevel) {
                            ForEach(1...5, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey("personal.recovery_check_in.note"))
                            .font(TypographyToken.inter(size: 12, weight: .semibold))
                            .foregroundStyle(ColorToken.mutedForeground)
                            .tracking(0.5)
                        TextEditor(text: $note)
                            .frame(minHeight: 96)
                            .padding(10)
                            .background(ColorToken.inputBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(ColorToken.border, lineWidth: 1)
                            )
                    }
                }
                .padding(.bottom, 8)
            }

            saveButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .background(ColorToken.background)
        .onAppear { populateFields() }
        .alert(String(localized: "personal.recovery_check_in.error_title"), isPresented: $showError) {
            Button(String(localized: "measurement.ok"), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "personal.recovery_check_in.title"))
                    .font(TypographyToken.inter(size: 20, weight: .bold))
                    .foregroundStyle(ColorToken.textPrimary)
                Text(String(localized: "personal.recovery_check_in.subtitle"))
                    .font(TypographyToken.inter(size: 14, weight: .regular))
                    .foregroundStyle(ColorToken.textSecondary)
            }

            Spacer(minLength: 0)

            Button("✕") {
                dismiss()
            }
            .font(TypographyToken.inter(size: 14, weight: .semibold))
            .foregroundStyle(ColorToken.textSecondary)
            .frame(width: 32, height: 32)
            .background(ColorToken.muted)
            .clipShape(Circle())
            .buttonStyle(.plain)
        }
    }

    private var saveButton: some View {
        Button {
            Task { await saveTapped() }
        } label: {
            Group {
                if isSaving {
                    ProgressView()
                        .tint(Color.white)
                } else {
                    Text(LocalizedStringKey("common.save"))
                        .font(TypographyToken.inter(size: 17, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSaving ? ColorToken.primary.opacity(0.6) : ColorToken.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }

    private func checkInField(label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(TypographyToken.inter(size: 12, weight: .semibold))
                .foregroundStyle(ColorToken.mutedForeground)
                .tracking(0.5)
            TextField(placeholder, text: text)
                .font(TypographyToken.inter(size: 14, weight: .regular))
                .foregroundStyle(ColorToken.inputForeground)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboard)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(ColorToken.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(ColorToken.border, lineWidth: 1))
        }
    }

    private func populateFields() {
        guard let initialRecord else { return }
        if let sleepHours = initialRecord.sleepHours {
            self.sleepHours = Self.numberFormatter.string(from: NSNumber(value: sleepHours)) ?? ""
        }
        sorenessLevel = initialRecord.sorenessLevel
        energyLevel = initialRecord.energyLevel
        note = initialRecord.note ?? ""
    }

    private func saveTapped() async {
        let trimmedSleepHours = sleepHours.trimmingCharacters(in: .whitespacesAndNewlines)
        let sleepValue: Double?
        if trimmedSleepHours.isEmpty {
            sleepValue = nil
        } else if let value = Double(trimmedSleepHours), value >= 0, value <= 24 {
            sleepValue = value
        } else {
            errorMessage = String(localized: "personal.recovery_check_in.validation.sleep_invalid")
            showError = true
            return
        }

        guard (1...5).contains(sorenessLevel) else {
            errorMessage = String(localized: "personal.recovery_check_in.validation.soreness_invalid")
            showError = true
            return
        }

        guard (1...5).contains(energyLevel) else {
            errorMessage = String(localized: "personal.recovery_check_in.validation.energy_invalid")
            showError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let record = RecoveryCheckInRecord(
                userId: userId,
                dayKey: Self.dayKey(),
                sleepHours: sleepValue,
                sorenessLevel: sorenessLevel,
                energyLevel: energyLevel,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            try store.saveRecoveryCheckIn(record, userId: userId)
            await onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private static func dayKey(reference: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: reference)
    }
}

struct ProgressChipView: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(TypographyToken.inter(size: 11, weight: .semibold))
                .foregroundStyle(ColorToken.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Text(value)
                .font(TypographyToken.inter(size: 15, weight: .bold))
                .foregroundStyle(ColorToken.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(ColorToken.card)
        .overlay(alignment: .top) {
            Rectangle().fill(accent).frame(height: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        )
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }
}
