//
//  TrainingPlanSettingsView.swift
//  Progress
//

import SwiftUI
import SwiftData

struct TrainingPlanSettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]
    @Query(filter: #Predicate<TrainingPlan> { $0.isActive == true }) private var activePlans: [TrainingPlan]

    @State private var showingSetupFlow = false
    @State private var showingDisableConfirmation = false
    @State private var disableError: String?

    private var currentUser: User? { users.first }

    private var activePlan: TrainingPlan? {
        guard let userId = currentUser?.id else { return nil }
        return activePlans.first { $0.user?.id == userId }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let plan = activePlan {
                    activePlanContent(plan)
                } else {
                    noPlanContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Training Plan")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingSetupFlow) {
            if let user = currentUser {
                TrainingPlanSetupFlowView(user: user, onPlanCreated: handlePlanCreated)
            }
        }
        .alert("Disable training plan?", isPresented: $showingDisableConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Disable plan", role: .destructive) {
                disablePlan()
            }
        } message: {
            Text("Your plan workouts will be hidden from the Workouts tab. Any workouts you created manually will stay.")
        }
        .alert("Couldn't disable plan", isPresented: Binding(
            get: { disableError != nil },
            set: { if !$0 { disableError = nil } }
        )) {
            Button("OK", role: .cancel) { disableError = nil }
        } message: {
            Text(disableError ?? "")
        }
    }

    // MARK: - No Plan

    private var noPlanContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 48))
                    .foregroundColor(Color.brand)

                Text("No active plan")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Build repeating workouts with Session 1 targets for your first block. We'll progress through Sessions 2–4, then deload on Session 5.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            Button {
                HapticFeedback.workoutButtonTap()
                showingSetupFlow = true
            } label: {
                Text("Start a training plan")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Active Plan

    private func activePlanContent(_ plan: TrainingPlan) -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(plan.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(plan.splitType.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(plan.workouts.count) repeating workouts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 12) {
                Text("Workouts")
                    .font(.headline)
                    .fontWeight(.semibold)

                ForEach(sortedWorkouts(in: plan), id: \.id) { workout in
                    ActivePlanWorkoutRow(workout: workout)
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Button(role: .destructive) {
                showingDisableConfirmation = true
            } label: {
                Text("Disable plan")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func handlePlanCreated() {
        NotificationCenter.default.post(name: .navigateToWorkouts, object: nil)
        dismiss()
    }

    private func disablePlan() {
        guard let user = currentUser else { return }
        let service = TrainingPlanService(modelContext: modelContext)
        do {
            try service.disableActivePlan(for: user)
            HapticFeedback.workoutButtonTap()
        } catch {
            disableError = error.localizedDescription
        }
    }

    private func sortedWorkouts(in plan: TrainingPlan) -> [Workout] {
        plan.workouts.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}

// MARK: - Active Plan Workout Row

private struct ActivePlanWorkoutRow: View {
    let workout: Workout

    private var sessionIndex: Int { workout.planSessionIndex ?? 1 }
    private var blockNumber: Int { workout.planBlockNumber ?? 1 }
    private var phaseName: String { workout.planPhase?.displayName ?? "Baseline" }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(workout.name)
                .font(.headline)
                .fontWeight(.semibold)

            Text("Session \(sessionIndex) of 5 · Block \(blockNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(phaseName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color.brand)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.brand.opacity(0.12))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
