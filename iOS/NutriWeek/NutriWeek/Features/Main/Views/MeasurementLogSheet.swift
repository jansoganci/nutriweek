import SwiftUI
import Supabase

struct MeasurementLogSheet: View {
    enum MeasurementTab: String, CaseIterable {
        case weight = "Kilo"
        case body = "Beden Ölçüsü"
    }

    let client: SupabaseClient = SupabaseClientFactory.shared
    let onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: MeasurementTab = .weight
    @State private var weightKg = ""
    @State private var waistCm = ""
    @State private var hipsCm = ""
    @State private var chestCm = ""
    @State private var armCm = ""
    @State private var legCm = ""
    @State private var measuredDate = Date()
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    private static let measuredAtFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Text(String(localized: "measurement.title"))
                    .font(TypographyToken.inter(size: 20, weight: .bold))
                    .foregroundStyle(ColorToken.textPrimary)
                Spacer(minLength: 0)
                Button("✕") { dismiss() }
                    .font(TypographyToken.inter(size: 14, weight: .semibold))
                    .foregroundStyle(ColorToken.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(ColorToken.muted)
                    .clipShape(Circle())
                    .buttonStyle(.plain)
            }

            Picker("", selection: $selectedTab) {
                ForEach(MeasurementTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    switch selectedTab {
                    case .weight:
                        measurementField(String(localized: "profile.measurements.weight_kg"), text: $weightKg, placeholder: String(localized: "measurement.placeholder.weight"), keyboard: .decimalPad)
                    case .body:
                        measurementField(String(localized: "profile.measurements.waist_cm"), text: $waistCm, placeholder: String(localized: "measurement.placeholder.waist"), keyboard: .decimalPad)
                        measurementField(String(localized: "profile.measurements.hips_cm"), text: $hipsCm, placeholder: String(localized: "measurement.placeholder.hips"), keyboard: .decimalPad)
                        measurementField(String(localized: "profile.measurements.chest_cm"), text: $chestCm, placeholder: String(localized: "measurement.placeholder.chest"), keyboard: .decimalPad)
                        measurementField(String(localized: "profile.measurements.left_arm_cm"), text: $armCm, placeholder: String(localized: "measurement.placeholder.arm"), keyboard: .decimalPad)
                        measurementField(String(localized: "profile.measurements.left_leg_cm"), text: $legCm, placeholder: String(localized: "measurement.placeholder.leg"), keyboard: .decimalPad)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey("common.date"))
                            .font(TypographyToken.inter(size: 12, weight: .semibold))
                            .foregroundStyle(ColorToken.mutedForeground)
                            .tracking(0.5)
                        DatePicker("", selection: $measuredDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(ColorToken.primary)
                    }
                }
                .padding(.bottom, 8)
            }

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
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .background(ColorToken.background)
        .alert(String(localized: "measurement.save_error_title"), isPresented: $showError) {
            Button(String(localized: "measurement.ok"), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func measurementField(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType) -> some View {
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

    private func saveTapped() async {
        let measuredAt = Self.measuredAtFormatter.string(from: measuredDate)

        switch selectedTab {
        case .weight:
            guard let w = Double(weightKg.trimmingCharacters(in: .whitespacesAndNewlines)), !weightKg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = String(localized: "measurement.validation.weight_invalid")
                showError = true
                return
            }
            if w < 20 || w > 500 {
                errorMessage = String(localized: "measurement.validation.weight_range")
                showError = true
                return
            }
            await insert(
                weightKg: w,
                waist: nil,
                hips: nil,
                chest: nil,
                arm: nil,
                leg: nil,
                measuredAt: measuredAt
            )
        case .body:
            let w = optionalDouble(waistCm)
            let h = optionalDouble(hipsCm)
            let c = optionalDouble(chestCm)
            let a = optionalDouble(armCm)
            let l = optionalDouble(legCm)
            let anyFilled = [w, h, c, a, l].contains { $0 != nil }
            guard anyFilled else {
                errorMessage = String(localized: "measurement.validation.any_required")
                showError = true
                return
            }
            if waistCm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false, w == nil {
                errorMessage = String(localized: "measurement.validation.waist_invalid")
                showError = true
                return
            }
            if hipsCm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false, h == nil {
                errorMessage = String(localized: "measurement.validation.hips_invalid")
                showError = true
                return
            }
            if chestCm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false, c == nil {
                errorMessage = String(localized: "measurement.validation.chest_invalid")
                showError = true
                return
            }
            if armCm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false, a == nil {
                errorMessage = String(localized: "measurement.validation.arm_invalid")
                showError = true
                return
            }
            if legCm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false, l == nil {
                errorMessage = String(localized: "measurement.validation.leg_invalid")
                showError = true
                return
            }
            await insert(
                weightKg: nil,
                waist: w,
                hips: h,
                chest: c,
                arm: a,
                leg: l,
                measuredAt: measuredAt
            )
        }
    }

    private func optionalDouble(_ text: String) -> Double? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return nil }
        return Double(t)
    }

    private func insert(
        weightKg: Double?,
        waist: Double?,
        hips: Double?,
        chest: Double?,
        arm: Double?,
        leg: Double?,
        measuredAt: String
    ) async {
        isSaving = true
        defer { isSaving = false }
        do {
            let userId = try await client.auth.session.user.id.uuidString
            struct MeasurementInsert: Encodable {
                let user_id: String
                let weight_kg: Double?
                let waist_cm: Double?
                let hips_cm: Double?
                let chest_cm: Double?
                let left_arm_cm: Double?
                let left_leg_cm: Double?
                let measured_at: String
            }
            try await client.from("body_measurements")
                .insert(
                    MeasurementInsert(
                        user_id: userId,
                        weight_kg: weightKg,
                        waist_cm: waist,
                        hips_cm: hips,
                        chest_cm: chest,
                        left_arm_cm: arm,
                        left_leg_cm: leg,
                        measured_at: measuredAt
                    )
                )
                .execute()
            await onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
