//
//  DataExportService.swift
//  Progress
//
//  Builds a JSON copy of the data stored in Progress. Food photos stay on
//  device; the file records that a photo existed without embedding it.
//

import Foundation
import SwiftData
import FirebaseCore
import FirebaseAuth

struct ProgressDataExport: Codable {
    var schemaVersion: Int
    var exportedAt: Date
    var appVersion: String
    /// Anonymous Firebase account that signs AI requests, when one exists.
    var accountId: String?
    var notes: String
    var summary: Summary
    var profile: Profile?
    var workouts: [WorkoutRecord]
    var nutritionEntries: [NutritionRecord]
    var waterEntries: [WaterRecord]
    var weightEntries: [WeightRecord]
    var trainingPlans: [TrainingPlanRecord]
    var customExercises: [CustomExerciseRecord]

    struct Summary: Codable {
        var workouts: Int
        var exercises: Int
        var nutritionEntries: Int
        var waterEntries: Int
        var weightEntries: Int
        var trainingPlans: Int
        var customExercises: Int
    }

    struct Profile: Codable {
        var id: UUID
        var name: String
        var email: String?
        var age: Int
        var biologicalSex: String
        var heightCm: Double
        var weightKg: Double
        var activityLevel: String
        var fitnessGoal: String
        var fitnessLevel: String
        var preferredUnits: String
        var weeklyWorkoutGoal: Int
        var dailyStepGoal: Int
        var dailyWaterGoalMillilitres: Double
        var dailyCalorieGoal: Double
        var dailyProteinGoal: Double
        var dailyCarbGoal: Double
        var dailyFatGoal: Double
        var usesCustomNutritionGoals: Bool
        var hasCompletedOnboarding: Bool
        var createdAt: Date
        var updatedAt: Date
    }

    struct WorkoutRecord: Codable {
        var id: UUID
        var name: String
        var notes: String?
        var status: String
        var isTemplate: Bool
        var templateId: UUID?
        var trainingPlanId: UUID?
        var sourceWorkoutId: UUID?
        var planSessionIndex: Int?
        var planBlockNumber: Int?
        var planPhase: String?
        var createdAt: Date
        var updatedAt: Date
        var startedAt: Date?
        var completedAt: Date?
        var deletedAt: Date?
        var exercises: [ExerciseRecord]
    }

    struct ExerciseRecord: Codable {
        var id: UUID
        var name: String
        var type: String
        var category: String?
        var notes: String?
        var order: Int
        var restTimeSeconds: TimeInterval
        var isHidden: Bool
        var isCustom: Bool
        var predefinedExerciseId: String?
        var primaryMuscleGroup: String?
        var secondaryMuscleGroups: [String: Double]?
        var baselineWeightKg: Double?
        var baselineReps: Int?
        var baselineDurationSeconds: Double?
        var baselineSetCount: Int?
        var createdAt: Date
        var sets: [SetRecord]
        /// Sets captured the last time this exercise was completed. Plan workouts
        /// reset their live sets afterwards, so this is the record of that session.
        var lastCompletionSets: [SetRecord]
    }

    struct SetRecord: Codable {
        var id: UUID
        var order: Int
        var weight: Double
        var reps: Int
        var durationSeconds: TimeInterval
        var distance: Double
        var isCompleted: Bool
        var completedAt: Date?
        var notes: String?
        var targetReps: Int?
        var targetWeight: Double?
        var targetDurationSeconds: TimeInterval?
        var averageHeartRate: Int?
        var caloriesBurned: Double?
        var intensityLevel: Int?
        var createdAt: Date?
    }

    struct NutritionRecord: Codable {
        var id: UUID
        var foodName: String
        var brandName: String?
        var servingSize: String
        var quantity: Double
        var mealType: String
        var logMethod: String
        var caloriesPerServing: Double
        var proteinGramsPerServing: Double
        var carbohydratesGramsPerServing: Double
        var fatGramsPerServing: Double
        var fiberGramsPerServing: Double?
        var sugarGramsPerServing: Double?
        var sodiumMilligramsPerServing: Double?
        var extendedNutrition: [String: Double]?
        var foodDatabaseId: String?
        var barcode: String?
        var aiConfidence: Double?
        var isVerified: Bool
        var isFavorite: Bool
        var isPending: Bool
        var hasPhoto: Bool
        var notes: String?
        var loggedAt: Date
    }

    struct WaterRecord: Codable {
        var id: UUID
        var amountMillilitres: Double
        var loggedAt: Date
    }

    struct WeightRecord: Codable {
        var id: UUID
        var weightKg: Double
        var loggedAt: Date
    }

    struct TrainingPlanRecord: Codable {
        var id: UUID
        var name: String
        var splitType: String
        var isActive: Bool
        var createdAt: Date
        var workoutIds: [UUID]
    }

    struct CustomExerciseRecord: Codable {
        var id: UUID
        var name: String
        var category: String
        var type: String
        var usageCount: Int
        var createdAt: Date
    }
}

@MainActor
enum DataExportService {
    static let schemaVersion = 1

    static let exportNotes = """
    Exercise weights and distances use the unit system that was active when they were logged. \
    Body weight is always kilograms. Water is always millilitres. Nutrition values are per serving, \
    before quantity is applied. Food photos are not included.
    """

    static func makeExport(in context: ModelContext) throws -> ProgressDataExport {
        let users = try context.fetch(FetchDescriptor<User>())
        let workouts = try context.fetch(FetchDescriptor<Workout>())
            .sorted { $0.createdAt < $1.createdAt }
        let nutrition = try context.fetch(FetchDescriptor<NutritionEntry>())
            .sorted { $0.loggedAt < $1.loggedAt }
        let water = try context.fetch(FetchDescriptor<WaterEntry>())
            .sorted { $0.loggedAt < $1.loggedAt }
        let weights = try context.fetch(FetchDescriptor<BodyWeightEntry>())
            .sorted { $0.loggedAt < $1.loggedAt }
        let plans = try context.fetch(FetchDescriptor<TrainingPlan>())
            .sorted { $0.createdAt < $1.createdAt }
        let customExercises = try context.fetch(FetchDescriptor<CustomExercise>())
            .sorted { $0.createdAt < $1.createdAt }

        let workoutRecords = workouts.map(workoutRecord)
        let exerciseCount = workoutRecords.reduce(0) { $0 + $1.exercises.count }

        return ProgressDataExport(
            schemaVersion: schemaVersion,
            exportedAt: Date(),
            appVersion: appVersion,
            accountId: currentAccountId(),
            notes: exportNotes,
            summary: ProgressDataExport.Summary(
                workouts: workoutRecords.count,
                exercises: exerciseCount,
                nutritionEntries: nutrition.count,
                waterEntries: water.count,
                weightEntries: weights.count,
                trainingPlans: plans.count,
                customExercises: customExercises.count
            ),
            profile: users.first.map(profileRecord),
            workouts: workoutRecords,
            nutritionEntries: nutrition.map(nutritionRecord),
            waterEntries: water.map { entry in
                ProgressDataExport.WaterRecord(
                    id: entry.id,
                    amountMillilitres: entry.amount,
                    loggedAt: entry.loggedAt
                )
            },
            weightEntries: weights.map { entry in
                ProgressDataExport.WeightRecord(
                    id: entry.id,
                    weightKg: entry.weightKg,
                    loggedAt: entry.loggedAt
                )
            },
            trainingPlans: plans.map { plan in
                ProgressDataExport.TrainingPlanRecord(
                    id: plan.id,
                    name: plan.name,
                    splitType: plan.splitType.rawValue,
                    isActive: plan.isActive,
                    createdAt: plan.createdAt,
                    workoutIds: plan.workouts.map(\.id).sorted { $0.uuidString < $1.uuidString }
                )
            },
            customExercises: customExercises.map { exercise in
                ProgressDataExport.CustomExerciseRecord(
                    id: exercise.id,
                    name: exercise.name,
                    category: exercise.category,
                    type: exercise.type,
                    usageCount: exercise.usageCount,
                    createdAt: exercise.createdAt
                )
            }
        )
    }

    static func jsonData(for export: ProgressDataExport) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }

    static func writeExportFile(in context: ModelContext) throws -> URL {
        let export = try makeExport(in: context)
        let data = try jsonData(for: export)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName(for: export.exportedAt))
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Mapping

    private static func profileRecord(for user: User) -> ProgressDataExport.Profile {
        ProgressDataExport.Profile(
            id: user.id,
            name: user.name,
            email: user.email.isEmpty ? nil : user.email,
            age: user.age,
            biologicalSex: user.biologicalSex.rawValue,
            heightCm: user.heightCm,
            weightKg: user.weightKg,
            activityLevel: user.activityLevel.rawValue,
            fitnessGoal: user.fitnessGoal.rawValue,
            fitnessLevel: user.fitnessLevel.rawValue,
            preferredUnits: user.preferredUnits.rawValue,
            weeklyWorkoutGoal: user.weeklyWorkoutGoal,
            dailyStepGoal: user.dailyStepGoal,
            dailyWaterGoalMillilitres: user.dailyWaterGoal,
            dailyCalorieGoal: user.dailyCalorieGoal,
            dailyProteinGoal: user.dailyProteinGoal,
            dailyCarbGoal: user.dailyCarbGoal,
            dailyFatGoal: user.dailyFatGoal,
            usesCustomNutritionGoals: user.usesCustomNutritionGoals,
            hasCompletedOnboarding: user.hasCompletedOnboarding,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt
        )
    }

    private static func workoutRecord(for workout: Workout) -> ProgressDataExport.WorkoutRecord {
        ProgressDataExport.WorkoutRecord(
            id: workout.id,
            name: workout.name,
            notes: workout.notes,
            status: workout.status.rawValue,
            isTemplate: workout.isTemplate,
            templateId: workout.templateId,
            trainingPlanId: workout.trainingPlanId,
            sourceWorkoutId: workout.sourceWorkoutId,
            planSessionIndex: workout.planSessionIndex,
            planBlockNumber: workout.planBlockNumber,
            planPhase: workout.planPhase?.rawValue,
            createdAt: workout.createdAt,
            updatedAt: workout.updatedAt,
            startedAt: workout.startedAt,
            completedAt: workout.completedAt,
            deletedAt: workout.deletedAt,
            exercises: workout.exercises
                .sorted { $0.order < $1.order }
                .map(exerciseRecord)
        )
    }

    private static func exerciseRecord(for exercise: Exercise) -> ProgressDataExport.ExerciseRecord {
        let secondary = exercise.secondaryMuscleGroupsDecoded
        let secondaryRecord: [String: Double]? = secondary.isEmpty
            ? nil
            : Dictionary(uniqueKeysWithValues: secondary.map { ($0.key.rawValue, $0.value) })

        return ProgressDataExport.ExerciseRecord(
            id: exercise.id,
            name: exercise.name,
            type: exercise.type.rawValue,
            category: exercise.category,
            notes: exercise.notes,
            order: exercise.order,
            restTimeSeconds: exercise.restTime,
            isHidden: exercise.isHidden,
            isCustom: exercise.isCustom,
            predefinedExerciseId: exercise.predefinedExerciseId,
            primaryMuscleGroup: exercise.primaryMuscleGroup?.rawValue,
            secondaryMuscleGroups: secondaryRecord,
            baselineWeightKg: exercise.baselineWeightKg,
            baselineReps: exercise.baselineReps,
            baselineDurationSeconds: exercise.baselineDurationSec,
            baselineSetCount: exercise.baselineSetCount,
            createdAt: exercise.createdAt,
            sets: exercise.sets.sorted { $0.order < $1.order }.map(setRecord),
            lastCompletionSets: exercise.setsSnapshot
                .sorted { $0.order < $1.order }
                .map(snapshotRecord)
        )
    }

    private static func setRecord(for set: ExerciseSet) -> ProgressDataExport.SetRecord {
        ProgressDataExport.SetRecord(
            id: set.id,
            order: set.order,
            weight: set.weight,
            reps: set.reps,
            durationSeconds: set.duration,
            distance: set.distance,
            isCompleted: set.isCompleted,
            completedAt: set.completedAt,
            notes: set.notes,
            targetReps: set.targetReps,
            targetWeight: set.targetWeight,
            targetDurationSeconds: set.targetDuration,
            averageHeartRate: set.averageHeartRate,
            caloriesBurned: set.caloriesBurned,
            intensityLevel: set.intensityLevel,
            createdAt: set.createdAt
        )
    }

    private static func snapshotRecord(for snapshot: ExerciseSetSnapshot) -> ProgressDataExport.SetRecord {
        ProgressDataExport.SetRecord(
            id: snapshot.id,
            order: snapshot.order,
            weight: snapshot.weight,
            reps: snapshot.reps,
            durationSeconds: snapshot.duration,
            distance: snapshot.distance,
            isCompleted: snapshot.isCompleted,
            completedAt: snapshot.completedAt,
            notes: snapshot.notes,
            targetReps: nil,
            targetWeight: nil,
            targetDurationSeconds: nil,
            averageHeartRate: nil,
            caloriesBurned: nil,
            intensityLevel: nil,
            createdAt: nil
        )
    }

    private static func nutritionRecord(for entry: NutritionEntry) -> ProgressDataExport.NutritionRecord {
        ProgressDataExport.NutritionRecord(
            id: entry.id,
            foodName: entry.foodName,
            brandName: entry.brandName,
            servingSize: entry.servingSize,
            quantity: entry.quantity,
            mealType: entry.mealType.rawValue,
            logMethod: entry.logMethod.rawValue,
            caloriesPerServing: entry.calories,
            proteinGramsPerServing: entry.protein,
            carbohydratesGramsPerServing: entry.carbohydrates,
            fatGramsPerServing: entry.fat,
            fiberGramsPerServing: entry.fiber,
            sugarGramsPerServing: entry.sugar,
            sodiumMilligramsPerServing: entry.sodium,
            extendedNutrition: entry.extendedNutrition,
            foodDatabaseId: entry.foodDatabaseId,
            barcode: entry.barcode,
            aiConfidence: entry.aiConfidence,
            isVerified: entry.isVerified,
            isFavorite: entry.isFavorite,
            isPending: entry.isPending,
            hasPhoto: entry.imageData != nil,
            notes: entry.notes,
            loggedAt: entry.loggedAt
        )
    }

    private static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }

    private static func currentAccountId() -> String? {
        guard FirebaseApp.app() != nil else { return nil }
        return Auth.auth().currentUser?.uid
    }

    private static func fileName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HHmmss'Z'"
        return "Progress-Export-\(formatter.string(from: date)).json"
    }
}
