//
//  DescribeFoodView.swift
//  Progress
//
//  Forgotten-meal catch-up: describe food → 1–2 clarifying questions → log.
//

import SwiftUI
import SwiftData

struct DescribeFoodView: View {
    let selectedDate: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    @StateObject private var textClient = OpenAIFoodTextClient()

    @State private var step: Step = .describe
    @State private var descriptionText = ""
    @State private var questions: [FoodClarifyingQuestion] = []
    @State private var answers: [String: String] = [:]
    @State private var customAnswers: [String: String] = [:]
    @State private var recognizedFoods: [RecognizedFood] = []
    @State private var estimatedWaterMl: Double?
    @State private var mealType: MealType = .other
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSaving = false

    private enum Step {
        case describe
        case clarify
        case confirm
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    switch step {
                    case .describe:
                        describeStep
                    case .clarify:
                        clarifyStep
                    case .confirm:
                        confirmStep
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background(AdaptiveGradientBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if step != .describe {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Back") { goBack() }
                            .disabled(isLoading || isSaving)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: stepIcon)
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text(stepTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text(stepSubtitle)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var stepIcon: String {
        switch step {
        case .describe: return "text.bubble.fill"
        case .clarify: return "questionmark.bubble.fill"
        case .confirm: return "checkmark.circle.fill"
        }
    }

    private var stepTitle: String {
        switch step {
        case .describe: return "What did you eat?"
        case .clarify: return "Quick check"
        case .confirm: return "Log this meal"
        }
    }

    private var stepSubtitle: String {
        switch step {
        case .describe:
            return "Describe the meal you forgot to log. We’ll ask a couple of clarifying questions if needed."
        case .clarify:
            return "Answer \(questions.count == 1 ? "this question" : "these questions") so we can estimate macros more accurately."
        case .confirm:
            return "Review the estimate, then add it to your log."
        }
    }

    // MARK: - Describe

    private var describeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("e.g. chicken burrito from Chipotle, or leftover pasta with meatballs", text: $descriptionText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundColor(.textPrimary)
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .lineLimit(3...8)

            Text("Tip: include roughly how much if you remember.")
                .font(.caption)
                .foregroundColor(.textSecondary)

            primaryButton(
                title: isLoading ? "Thinking…" : "Continue",
                disabled: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
            ) {
                Task { await submitDescription() }
            }
        }
    }

    // MARK: - Clarify

    private var clarifyStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(questions) { question in
                questionCard(question)
            }

            primaryButton(
                title: isLoading ? "Estimating…" : "Estimate meal",
                disabled: !canSubmitClarifications || isLoading
            ) {
                Task { await submitClarifications() }
            }
        }
    }

    private func questionCard(_ question: FoodClarifyingQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.prompt)
                .font(.headline)
                .foregroundColor(.textPrimary)

            if !question.options.isEmpty {
                FlexibleOptionWrap(options: question.options, selected: answers[question.id]) { option in
                    answers[question.id] = option
                    customAnswers[question.id] = ""
                    HapticFeedback.workoutButtonTap()
                }
            }

            TextField(
                question.options.isEmpty ? "Your answer" : "Or type your own",
                text: Binding(
                    get: { customAnswers[question.id] ?? "" },
                    set: { value in
                        customAnswers[question.id] = value
                        if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            answers[question.id] = value
                        }
                    }
                ),
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .font(.body)
            .padding(12)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
            )
            .lineLimit(1...3)
        }
        .whiteCardStyle(cornerRadius: 16, padding: 16)
    }

    private var canSubmitClarifications: Bool {
        questions.allSatisfy { question in
            let answer = resolvedAnswer(for: question)
            return !answer.isEmpty
        }
    }

    private func resolvedAnswer(for question: FoodClarifyingQuestion) -> String {
        let custom = customAnswers[question.id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !custom.isEmpty { return custom }
        return answers[question.id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    // MARK: - Confirm

    private var confirmStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Meal")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                Spacer()
                Picker("Meal", selection: $mealType) {
                    ForEach(MealType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal, 4)

            ForEach(Array(recognizedFoods.enumerated()), id: \.offset) { _, food in
                foodSummaryCard(food)
            }

            if let water = estimatedWaterMl, water > 0 {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                    Text("Also logs \(Int(water)) mL water")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 4)
            }

            primaryButton(
                title: isSaving ? "Logging…" : "Log meal",
                disabled: isSaving || (recognizedFoods.isEmpty && (estimatedWaterMl ?? 0) <= 0)
            ) {
                saveMeal()
            }
        }
    }

    private func foodSummaryCard(_ food: RecognizedFood) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(food.name)
                .font(.headline)
                .foregroundColor(.textPrimary)

            Text(food.quantity)
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            HStack(spacing: 12) {
                macroChip("Cal", value: food.calories)
                macroChip("P", value: food.protein, suffix: "g")
                macroChip("C", value: food.carbs, suffix: "g")
                macroChip("F", value: food.fat, suffix: "g")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .whiteCardStyle(cornerRadius: 16, padding: 16)
    }

    private func macroChip(_ label: String, value: Double?, suffix: String = "") -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.textTertiary)
            Text(formattedMacro(value) + suffix)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func formattedMacro(_ value: Double?) -> String {
        guard let value else { return "—" }
        return value < 10 ? String(format: "%.1f", value) : String(format: "%.0f", value)
    }

    // MARK: - Shared UI

    private func primaryButton(title: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if isLoading || isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                }
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(disabled ? Color.gray : Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(disabled)
    }

    // MARK: - Actions

    private func goBack() {
        errorMessage = nil
        switch step {
        case .describe:
            break
        case .clarify:
            step = .describe
        case .confirm:
            step = questions.isEmpty ? .describe : .clarify
        }
    }

    @MainActor
    private func submitDescription() async {
        let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let analysis = try await textClient.analyzeDescription(trimmed)
            switch analysis {
            case .needsClarification(let asked):
                questions = asked
                answers = [:]
                customAnswers = [:]
                step = .clarify
            case .ready(let result):
                applyReadyResult(result)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func submitClarifications() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let pairs: [(question: String, answer: String)] = questions.compactMap { question in
            let answer = resolvedAnswer(for: question)
            guard !answer.isEmpty else { return nil }
            return (question.prompt, answer)
        }

        do {
            let result = try await textClient.finalizeDescription(
                descriptionText,
                clarifications: pairs
            )
            applyReadyResult(result)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyReadyResult(_ result: FoodRecognitionResult) {
        recognizedFoods = result.foods
        estimatedWaterMl = result.estimatedWaterMl
        mealType = inferredMealType(for: selectedDate)
        step = .confirm
    }

    private func inferredMealType(for date: Date) -> MealType {
        let hour = Calendar.current.component(.hour, from: Calendar.current.isDateInToday(date) ? Date() : date)
        switch hour {
        case 5..<11: return .breakfast
        case 11..<15: return .lunch
        case 17..<22: return .dinner
        default: return .snack
        }
    }

    private func saveMeal() {
        isSaving = true
        errorMessage = nil

        let stamp = logTimestamp(for: selectedDate)
        let currentUser = users.first

        for food in recognizedFoods {
            let entry = NutritionEntry(
                foodName: food.name,
                servingSize: food.quantity,
                quantity: 1.0,
                calories: food.calories ?? 0,
                protein: food.protein ?? 0,
                carbohydrates: food.carbs ?? 0,
                fat: food.fat ?? 0,
                mealType: mealType,
                logMethod: .aiPrompt
            )
            entry.loggedAt = stamp
            entry.aiConfidence = food.confidence
            entry.user = currentUser
            if let extended = food.extendedNutrition {
                entry.extendedNutrition = extended
            }
            if let notes = notesSummary {
                entry.notes = notes
            }
            modelContext.insert(entry)
        }

        if let water = estimatedWaterMl, water > 0 {
            let waterEntry = WaterEntry(amount: water.rounded())
            waterEntry.user = currentUser
            waterEntry.loggedAt = stamp
            modelContext.insert(waterEntry)
        }

        do {
            try modelContext.save()
            HapticFeedback.success()
            dismiss()
        } catch {
            isSaving = false
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    private var notesSummary: String? {
        let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if questions.isEmpty {
            return "Described: \(trimmed)"
        }
        let clarificationNotes = questions.compactMap { question -> String? in
            let answer = resolvedAnswer(for: question)
            guard !answer.isEmpty else { return nil }
            return "\(question.prompt) → \(answer)"
        }.joined(separator: "; ")
        return "Described: \(trimmed). \(clarificationNotes)"
    }

    private func logTimestamp(for date: Date) -> Date {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return Date()
        }
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        let now = Date()
        components.hour = calendar.component(.hour, from: now)
        components.minute = calendar.component(.minute, from: now)
        return calendar.date(from: components) ?? date
    }
}

// MARK: - Option chips

private struct FlexibleOptionWrap: View {
    let options: [String]
    let selected: String?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
                    Text(option)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selected == option ? .white : .textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(selected == option ? Color.accentColor : Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    DescribeFoodView(selectedDate: Date())
        .modelContainer(for: [NutritionEntry.self, WaterEntry.self, User.self], inMemory: true)
}
