//
//  DataExportView.swift
//  Progress
//

import SwiftUI
import SwiftData
import UIKit

struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [Workout]
    @Query private var exercises: [Exercise]
    @Query private var nutritionEntries: [NutritionEntry]
    @Query private var waterEntries: [WaterEntry]
    @Query private var weightEntries: [BodyWeightEntry]
    @Query private var trainingPlans: [TrainingPlan]
    @Query private var customExercises: [CustomExercise]

    @State private var isExporting = false
    @State private var exportFile: ExportFile?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                contentsCard
                exportButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $exportFile) { file in
            ShareSheetView(items: [file.url])
                .presentationDetents([.medium, .large])
        }
        .alert("Couldn't Export Data", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 72, height: 72)
                .background(Color.primary.opacity(0.12))
                .clipShape(Circle())

            Text("Take a copy of your data")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text(
                "Exports a JSON file of your profile, workouts, nutrition, water, and weight history. "
                + "Save it to Files, or send it with AirDrop or Mail."
            )
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var contentsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Included")
                .font(.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            countRow("Workouts", count: workouts.count)
            countRow("Exercises", count: exercises.count)
            countRow("Nutrition logs", count: nutritionEntries.count)
            countRow("Water logs", count: waterEntries.count)
            countRow("Weight logs", count: weightEntries.count)
            countRow("Training plans", count: trainingPlans.count)
            countRow("Custom exercises", count: customExercises.count)

            Text("Recently deleted workouts are included. Food photos stay on this device and are left out of the file.")
                .font(.caption)
                .foregroundColor(.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .whiteCardStyle()
    }

    private var exportButton: some View {
        Button {
            export()
        } label: {
            HStack(spacing: 8) {
                if isExporting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Preparing export…")
                } else {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export JSON File")
                }
            }
            .font(.buttonPrimary)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(.white)
            .background(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(isExporting)
        .accessibilityHint("Creates a JSON file and opens the share sheet")
    }

    private func countRow(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.textPrimary)
            Spacer()
            Text("\(count)")
                .font(.body)
                .foregroundColor(.textSecondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(count)")
    }

    private func export() {
        isExporting = true
        HapticFeedback.light()
        do {
            let url = try DataExportService.writeExportFile(in: modelContext)
            exportFile = ExportFile(url: url)
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
        isExporting = false
    }
}

private struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = controller.view
            popover.permittedArrowDirections = []
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        DataExportView()
    }
    .modelContainer(
        for: [
            User.self,
            Workout.self,
            Exercise.self,
            ExerciseSet.self,
            ExerciseSetSnapshot.self,
            NutritionEntry.self,
            WaterEntry.self,
            BodyWeightEntry.self,
            TrainingPlan.self,
            CustomExercise.self
        ],
        inMemory: true
    )
}
