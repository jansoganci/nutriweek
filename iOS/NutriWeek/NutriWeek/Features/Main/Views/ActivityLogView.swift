import SwiftUI

struct ActivityLogView: View {
    let repository: ActivityLogRepositoryProtocol

    @State var entries: [ActivityLogEntry] = []
    @State var todaysCalories: Double = 0
    @State var weeklyCalories: Double = 0
    @State var monthlyCalories: Double = 0
    @State var isLoading = true
    @State var errorMessage: String?
    @State private var showAddSheet = false

    init(repository: ActivityLogRepositoryProtocol) {
        self.repository = repository
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    summarySection
                    contentSection
                }
                .padding(.horizontal, SpacingToken.gutter)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            .background(ColorToken.background)
            .refreshable { await loadData() }
            .task { await loadData() }

            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 56, height: 56)
                    .background(ColorToken.primary)
                    .clipShape(Circle())
                    .shadow(color: ColorToken.primary.opacity(0.35), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.trailing, SpacingToken.gutter)
            .padding(.bottom, 20)
        }
        .navigationTitle(LocalizedStringKey("activity.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSheet) {
            ActivityLogEntrySheet(repository: repository) {
                await loadData()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var summarySection: some View {
        VStack(spacing: 12) {
            todaySummaryCard

            HStack(spacing: 12) {
                statCard(
                    text: String(localized: "activity.week_total \(Int(weeklyCalories.rounded()))"),
                    accent: ColorToken.macroProtein
                )
                statCard(
                    text: String(localized: "activity.month_total \(Int(monthlyCalories.rounded()))"),
                    accent: ColorToken.primary
                )
            }
        }
    }

    private var todaySummaryCard: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "activity.today_burned \(Int(todaysCalories.rounded()))"))
                    .font(TypographyToken.inter(size: 22, weight: .bold))
                    .foregroundStyle(ColorToken.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

            Text(LocalizedStringKey("common.today"))
                .font(TypographyToken.inter(size: 13, weight: .regular))
                .foregroundStyle(ColorToken.textSecondary)
        }
        .padding(16)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        )
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    private func statCard(text: String, accent: Color) -> some View {
        Text(text)
            .font(TypographyToken.inter(size: 15, weight: .semibold))
            .foregroundStyle(ColorToken.textPrimary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.horizontal, 12)
            .background(ColorToken.card)
            .overlay(alignment: .top) {
                Rectangle().fill(accent).frame(height: 3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ColorToken.border, lineWidth: 1)
            )
            .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var contentSection: some View {
        if let errorMessage {
            ErrorStateView(
                title: String(localized: "common.error.generic_title"),
                message: errorMessage,
                retryTitle: String(localized: "common.retry")
            ) {
                Task { await loadData() }
            }
        } else if isLoading && entries.isEmpty {
            ProgressView()
                .tint(ColorToken.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else if entries.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 10) {
                ForEach(entries) { entry in
                    activityRow(entry)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await deleteEntry(at: entry.id) }
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(ColorToken.primary)
                .padding(.bottom, 2)

            Text(LocalizedStringKey("activity.empty.title"))
                .font(TypographyToken.inter(size: 16, weight: .semibold))
                .foregroundStyle(ColorToken.textPrimary)

            Text(LocalizedStringKey("activity.empty.subtitle"))
                .font(TypographyToken.inter(size: 13, weight: .regular))
                .foregroundStyle(ColorToken.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        )
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    private func activityRow(_ entry: ActivityLogEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.activityName)
                    .font(TypographyToken.inter(size: 15, weight: .semibold))
                    .foregroundStyle(ColorToken.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text("\(entry.durationMinutes) min")
                    Text(entry.loggedAt.formatted(date: .abbreviated, time: .omitted))
                }
                .font(TypographyToken.inter(size: 12, weight: .regular))
                .foregroundStyle(ColorToken.textSecondary)

                if let detail = activityDetailText(entry) {
                    Text(detail)
                        .font(TypographyToken.inter(size: 11, weight: .regular))
                        .foregroundStyle(ColorToken.textTertiary)
                }
            }

            Spacer(minLength: 0)

            Text("\(Int(entry.caloriesBurned.rounded())) kcal")
                .font(TypographyToken.inter(size: 16, weight: .bold))
                .foregroundStyle(ColorToken.primary)
                .lineLimit(1)
        }
        .padding(14)
        .background(ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        )
        .shadow(color: ColorToken.shadow.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    private func activityDetailText(_ entry: ActivityLogEntry) -> String? {
        var parts: [String] = []

        if let type = entry.activityType {
            parts.append(activityTypeLabel(type))
        }

        if let sets = entry.sets, let reps = entry.reps {
            parts.append("\(sets) x \(reps)")
        }

        if let weight = entry.weightKg {
            parts.append("\(oneDecimal(weight)) kg")
        }

        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ")
    }

    private func activityTypeLabel(_ rawValue: String) -> String {
        switch WorkoutType(rawValue: rawValue) ?? .other {
        case .strength: return String(localized: "activity.workout_type.strength")
        case .cardio: return String(localized: "activity.workout_type.cardio")
        case .mobility: return String(localized: "activity.workout_type.mobility")
        case .sport: return String(localized: "activity.workout_type.sport")
        case .other: return String(localized: "activity.workout_type.other")
        }
    }

    private func oneDecimal(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }

}
