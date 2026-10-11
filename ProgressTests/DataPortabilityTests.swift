//
//  DataPortabilityTests.swift
//  ProgressTests
//

import Foundation
import Testing
import SwiftData
@testable import Progress

@MainActor
struct DataPortabilityTests {

    @Test func exportIncludesStoredDataAndOmitsPhotos() throws {
        let context = try makeContext()
        let seeded = try seedSampleData(in: context)

        let export = try DataExportService.makeExport(in: context)

        #expect(export.schemaVersion == DataExportService.schemaVersion)
        #expect(export.accountId == nil)
        #expect(export.profile?.name == "Tom")
        #expect(export.profile?.fitnessGoal == FitnessGoal.muscleGain.rawValue)
        #expect(export.summary.workouts == 1)
        #expect(export.summary.exercises == 1)

        let workout = try #require(export.workouts.first)
        #expect(workout.name == "Push Day")
        #expect(workout.deletedAt != nil)
        #expect(workout.exercises.first?.name == "Bench Press")
        #expect(workout.exercises.first?.sets.first?.weight == 80)
        #expect(workout.exercises.first?.sets.first?.reps == 5)
        #expect(workout.exercises.first?.lastCompletionSets.first?.reps == 5)

        let meal = try #require(export.nutritionEntries.first)
        #expect(meal.foodName == "Oats")
        #expect(meal.quantity == 2)
        #expect(meal.hasPhoto)
        #expect(export.waterEntries.first?.amountMillilitres == 350)
        #expect(export.weightEntries.first?.weightKg == 82.5)
        #expect(export.trainingPlans.first?.name == "Full Body")
        #expect(export.trainingPlans.first?.workoutIds == [seeded.workoutId])
        #expect(export.customExercises.first?.name == "My Curl")

        let data = try DataExportService.jsonData(for: export)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(!json.contains("SECRET_PHOTO_BYTES"))

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ProgressDataExport.self, from: data)
        #expect(decoded.profile?.name == "Tom")
        #expect(decoded.workouts.first?.exercises.first?.sets.first?.reps == 5)
    }

    @Test func accountResetRemovesDataAndStartsAFreshProfile() throws {
        let context = try makeContext()
        _ = try seedSampleData(in: context)

        try AccountDeletionService.resetLocalData(in: context)

        let users = try context.fetch(FetchDescriptor<User>())
        #expect(users.count == 1)
        #expect(users.first?.name == "Me")
        #expect(users.first?.hasCompletedOnboarding == false)
        #expect(try context.fetch(FetchDescriptor<Workout>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<NutritionEntry>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<WaterEntry>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<BodyWeightEntry>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<TrainingPlan>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<CustomExercise>()).isEmpty)
        #expect(UserDefaults.standard.string(forKey: OnboardingProgressStore.stepKey) == "welcome")
    }

    // MARK: - Fixtures

    private struct SeededIDs {
        let workoutId: UUID
    }

    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            User.self,
            Workout.self,
            Exercise.self,
            ExerciseSet.self,
            ExerciseSetSnapshot.self,
            NutritionEntry.self,
            CustomExercise.self,
            WaterEntry.self,
            BodyWeightEntry.self,
            TrainingPlan.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return container.mainContext
    }

    private func seedSampleData(in context: ModelContext) throws -> SeededIDs {
        let user = User(
            name: "Tom",
            fitnessGoal: .muscleGain,
            hasCompletedOnboarding: true
        )
        let plan = TrainingPlan(name: "Full Body", splitType: .fullBody)
        let workout = Workout(name: "Push Day", notes: "Heavy")
        let exercise = Exercise(name: "Bench Press", type: .strength, category: "Chest", order: 0)
        let set = ExerciseSet(weight: 80, reps: 5, order: 0)
        let meal = NutritionEntry(
            foodName: "Oats",
            servingSize: "40g",
            quantity: 2,
            calories: 150,
            protein: 5,
            carbohydrates: 27,
            fat: 3,
            mealType: .breakfast,
            logMethod: .manual
        )
        let water = WaterEntry(amount: 350)
        let weight = BodyWeightEntry(weightKg: 82.5)
        let custom = CustomExercise(name: "My Curl", category: "resistance", type: "Arms")

        context.insert(user)
        context.insert(plan)
        context.insert(workout)
        context.insert(exercise)
        context.insert(set)
        context.insert(meal)
        context.insert(water)
        context.insert(weight)
        context.insert(custom)

        plan.user = user
        workout.user = user
        workout.trainingPlanId = plan.id
        plan.workouts.append(workout)
        exercise.workout = workout
        set.isCompleted = true
        set.exercise = exercise

        let snapshot = ExerciseSetSnapshot(from: set)
        context.insert(snapshot)
        snapshot.exercise = exercise

        meal.imageData = Data("SECRET_PHOTO_BYTES".utf8)
        meal.user = user
        water.user = user
        weight.user = user
        workout.softDelete()

        try context.save()
        return SeededIDs(workoutId: workout.id)
    }
}
