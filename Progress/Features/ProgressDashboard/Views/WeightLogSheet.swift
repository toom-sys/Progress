//
//  WeightLogSheet.swift
//  Progress
//
//  Sheet for logging a body weight measurement at any date,
//  plus reviewing and deleting recent entries.
//

import SwiftUI
import SwiftData

// MARK: - Weight Log Sheet

struct WeightLogSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BodyWeightEntry.loggedAt, order: .reverse) private var allEntries: [BodyWeightEntry]
    @Query private var users: [User]

    @State private var weightText: String = ""
    @State private var selectedDate: Date = Date()
    @FocusState private var isWeightFieldFocused: Bool

    private var currentUser: User? { users.first }
    private var units: UnitSystem { currentUser?.preferredUnits ?? .metric }

    /// Parsed weight in the user's display unit.
    private var enteredWeight: Double? {
        Double(weightText.replacingOccurrences(of: ",", with: "."))
    }

    private var isEntryValid: Bool {
        guard let weight = enteredWeight else { return false }
        let kg = units.convertWeightToKg(from: weight)
        return kg >= 20 && kg <= 400
    }

    private var recentEntries: [BodyWeightEntry] {
        Array(allEntries.prefix(10))
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    weightInputSection
                    dateSection
                    saveButton

                    if !recentEntries.isEmpty {
                        historySection
                    }

                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
            }
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.buttonSecondary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isWeightFieldFocused = false }
                }
            }
            .onAppear(perform: prefillWeight)
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 48))
                .foregroundColor(.purple)

            Text("Log Weight")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text("Track your weight to see your progression over time")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var weightInputSection: some View {
        HStack(spacing: 16) {
            adjustButton(icon: "minus", delta: -0.1)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("0.0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .focused($isWeightFieldFocused)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize()
                    .accessibilityLabel("Weight in \(units.weightUnitLong)")

                Text(units.weightUnit)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)

            adjustButton(icon: "plus", delta: 0.1)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func adjustButton(icon: String, delta: Double) -> some View {
        Button(action: {
            HapticFeedback.workoutButtonTap()
            adjustWeight(by: delta)
        }) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)
                .frame(width: 40, height: 40)
                .background(Color.surfaceWhite)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.border.opacity(0.4), lineWidth: 1))
        }
        .accessibilityLabel(delta > 0 ? "Increase weight" : "Decrease weight")
    }

    private var dateSection: some View {
        DatePicker(
            "Date",
            selection: $selectedDate,
            in: ...Date(),
            displayedComponents: [.date]
        )
        .font(.body)
        .fontWeight(.medium)
        .foregroundColor(.textPrimary)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    private var saveButton: some View {
        Button(action: saveEntry) {
            Label("Add Entry", systemImage: "checkmark")
                .font(.buttonPrimary)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isEntryValid ? Color.brand : Color.gray.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isEntryValid)
        .padding(.horizontal, 20)
        .accessibilityLabel("Add weight entry")
    }

    private var historySection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recent entries")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            VStack(spacing: 1) {
                ForEach(recentEntries) { entry in
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.purple)
                            .font(.subheadline)

                        Text(units.formatWeightWithUnit(entry.weightKg))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)

                        Spacer()

                        Text(dateFormatter.string(from: entry.loggedAt))
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Button(action: { deleteEntry(entry) }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red.opacity(0.8))
                                .font(.title3)
                        }
                        .accessibilityLabel("Remove \(units.formatWeightWithUnit(entry.weightKg)) logged on \(dateFormatter.string(from: entry.loggedAt))")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.backgroundSecondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Actions

    private func prefillWeight() {
        guard weightText.isEmpty else { return }
        let latestKg = allEntries.first?.weightKg ?? currentUser?.weightKg ?? 70
        weightText = String(format: "%.1f", units.convertWeight(from: latestKg))
    }

    private func adjustWeight(by delta: Double) {
        let current = enteredWeight ?? units.convertWeight(from: currentUser?.weightKg ?? 70)
        weightText = String(format: "%.1f", max(0, current + delta))
    }

    private func saveEntry() {
        guard let weight = enteredWeight, isEntryValid else { return }
        isWeightFieldFocused = false

        let weightKg = units.convertWeightToKg(from: weight)
        let entry = BodyWeightEntry(weightKg: weightKg, loggedAt: selectedDate)
        entry.user = currentUser
        modelContext.insert(entry)

        // Keep the profile weight in sync when this is the most recent measurement,
        // so nutrition targets derived from body metrics stay accurate.
        if let user = currentUser,
           allEntries.allSatisfy({ $0.loggedAt <= selectedDate }) {
            user.weightKg = weightKg
            user.recalculateNutritionGoals()
            user.updatedAt = Date()
        }

        do {
            try modelContext.save()
        } catch {}
        HapticFeedback.success()
    }

    private func deleteEntry(_ entry: BodyWeightEntry) {
        withAnimation {
            modelContext.delete(entry)
            try? modelContext.save()
        }
        HapticFeedback.workoutButtonTap()
    }
}

// MARK: - Preview

#Preview {
    WeightLogSheet()
        .modelContainer(for: [User.self, BodyWeightEntry.self], inMemory: true)
}
