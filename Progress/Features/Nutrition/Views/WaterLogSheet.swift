//
//  WaterLogSheet.swift
//  Progress
//

import SwiftUI
import SwiftData

// MARK: - Water Log Sheet

struct WaterLogSheet: View {
    let selectedDate: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WaterEntry.loggedAt, order: .reverse) private var allWaterEntries: [WaterEntry]
    @Query private var users: [User]

    private var currentUser: User? { users.first }

    private var todayEntries: [WaterEntry] {
        allWaterEntries.filter {
            Calendar.current.isDate($0.loggedAt, inSameDayAs: selectedDate)
        }
    }

    /// Pre-set quick-add amounts in mL
    private let presets: [(label: String, amount: Double)] = [
        ("250 mL", 250),
        ("500 mL", 500),
        ("750 mL", 750),
        ("1 L",   1000)
    ]

    @State private var customAmount: Double = 250
    @State private var showingCustomInput = false

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }

    private func formatAmount(_ ml: Double) -> String {
        ml >= 1000 ? String(format: "%.1f L", ml / 1000) : "\(Int(ml)) mL"
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.blue)

                            Text("Log Water")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)

                            Text("How much did you drink?")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 8)

                        // Quick-add grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(presets, id: \.label) { preset in
                                Button(action: {
                                    HapticFeedback.workoutButtonTap()
                                    logWater(amount: preset.amount)
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "drop.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)

                                        Text(preset.label)
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(Color.backgroundSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .accessibilityLabel("Log \(preset.label)")
                            }
                        }
                        .padding(.horizontal, 20)

                        // Custom amount section
                        VStack(spacing: 12) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showingCustomInput.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundColor(.accent)
                                    Text("Custom amount")
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Image(systemName: showingCustomInput ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.textSecondary)
                                        .font(.caption)
                                }
                                .font(.body)
                                .fontWeight(.medium)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color.backgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 20)
                            }
                            .accessibilityLabel("Custom water amount")
                            .accessibilityHint("Expand to enter a custom amount")

                            if showingCustomInput {
                                VStack(spacing: 16) {
                                    Stepper(
                                        value: $customAmount,
                                        in: 50...2000,
                                        step: 50
                                    ) {
                                        Text("\(Int(customAmount)) mL")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.textPrimary)
                                    }
                                    .padding(.horizontal, 20)
                                    .accessibilityLabel("Custom water amount stepper")
                                    .accessibilityValue("\(Int(customAmount)) millilitres")
                                    .accessibilityHint("Adjust in 50 mL increments between 50 and 2,000 mL")

                                    Button(action: {
                                        HapticFeedback.workoutButtonTap()
                                        logWater(amount: customAmount)
                                    }) {
                                        Text("Add \(Int(customAmount)) mL")
                                            .font(.buttonPrimary)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color.blue)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .padding(.horizontal, 20)
                                    .accessibilityLabel("Add \(Int(customAmount)) millilitres")
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .id("customSection")
                            }
                        }

                        // Today's log
                        if !todayEntries.isEmpty {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Today's log")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)

                                VStack(spacing: 1) {
                                    ForEach(todayEntries) { entry in
                                        HStack {
                                            Image(systemName: "drop.fill")
                                                .foregroundColor(.blue)
                                                .font(.subheadline)

                                            Text(formatAmount(entry.amount))
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(.textPrimary)

                                            Spacer()

                                            Text(timeFormatter.string(from: entry.loggedAt))
                                                .font(.caption)
                                                .foregroundColor(.textSecondary)

                                            Button(action: {
                                                deleteEntry(entry)
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(.red.opacity(0.8))
                                                    .font(.title3)
                                            }
                                            .accessibilityLabel("Remove \(formatAmount(entry.amount)) logged at \(timeFormatter.string(from: entry.loggedAt))")
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

                        Spacer(minLength: 24)
                    }
                }
                .onChange(of: showingCustomInput) { _, isOpen in
                    if isOpen {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation { proxy.scrollTo("customSection", anchor: .bottom) }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.buttonSecondary)
                }
            }
        }
    }

    // MARK: - Actions

    private func logWater(amount: Double) {
        let entry = WaterEntry(amount: amount)
        entry.user = currentUser
        modelContext.insert(entry)
        do {
            try modelContext.save()
        } catch {}
        HapticFeedback.success()
    }

    private func deleteEntry(_ entry: WaterEntry) {
        withAnimation {
            modelContext.delete(entry)
            try? modelContext.save()
        }
        HapticFeedback.workoutButtonTap()
    }
}

// MARK: - Preview

#Preview {
    WaterLogSheet(selectedDate: Date())
        .modelContainer(for: [User.self, WaterEntry.self], inMemory: true)
}
