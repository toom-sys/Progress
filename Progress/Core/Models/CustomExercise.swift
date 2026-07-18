//
//  CustomExercise.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

@Model
class CustomExercise {
    var id: UUID
    var name: String
    var category: String
    var type: String
    var createdAt: Date
    var usageCount: Int
    
    init(name: String, category: String, type: String) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.type = type
        self.createdAt = Date()
        self.usageCount = 0
    }
    
    // MARK: - Computed Properties
    
    var exerciseType: ExerciseType {
        switch category.lowercased() {
        case "resistance":
            return .resistance
        case "cardio":
            return .cardio
        case "recovery":
            return .recovery
        default:
            return .resistance
        }
    }
    
    // MARK: - Methods
    
    func incrementUsage() {
        usageCount += 1
    }
    
    func toPredefinedExercise() -> ExerciseDatabase.PredefinedExercise {
        return ExerciseDatabase.PredefinedExercise(
            name: name,
            category: category,
            type: type,
            imageName: nil
        )
    }
}
