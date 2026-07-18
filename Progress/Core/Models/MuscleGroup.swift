//
//  MuscleGroup.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation

/// Represents the major muscle groups for exercise classification and body map visualization
enum MuscleGroup: String, CaseIterable, Codable, Hashable {
    case chest = "chest"
    case back = "back"
    case shoulders = "shoulders"
    case arms = "arms"
    case core = "core"
    case quads = "quads"
    case posteriorChain = "posteriorChain"
    case cardio = "cardio"
    
    /// Display name for the muscle group
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .core: return "Core"
        case .quads: return "Quads"
        case .posteriorChain: return "Posterior Chain"
        case .cardio: return "Cardio"
        }
    }
    
    /// Description of what muscles are included in this group
    var description: String {
        switch self {
        case .chest:
            return "Pectorals, chest muscles"
        case .back:
            return "Latissimus dorsi, rhomboids, middle traps"
        case .shoulders:
            return "Deltoids, upper traps"
        case .arms:
            return "Biceps, triceps, forearms"
        case .core:
            return "Abdominals, obliques, lower back"
        case .quads:
            return "Quadriceps, hip flexors"
        case .posteriorChain:
            return "Hamstrings, glutes, lower back"
        case .cardio:
            return "Cardiovascular system"
        }
    }
    
    /// Color for body map visualization (hex string)
    var bodyMapColor: String {
        switch self {
        case .chest: return "#FF6B6B"      // Red
        case .back: return "#4ECDC4"       // Teal
        case .shoulders: return "#45B7D1"  // Blue
        case .arms: return "#96CEB4"       // Green
        case .core: return "#FFEAA7"       // Yellow
        case .quads: return "#DDA0DD"      // Plum
        case .posteriorChain: return "#F39C12" // Orange
        case .cardio: return "#E17055"     // Coral (for aura/ring)
        }
    }
    
    /// Icon for UI representation
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.strengthtraining.functional"
        case .shoulders: return "figure.arms.open"
        case .arms: return "figure.flexibility"
        case .core: return "figure.core.training"
        case .quads: return "figure.walk"
        case .posteriorChain: return "figure.run"
        case .cardio: return "heart.fill"
        }
    }
    
    /// Whether this muscle group represents strength training (vs cardio)
    var isStrengthTraining: Bool {
        return self != .cardio
    }
    
    /// Decay rate for progress visualization (how quickly progress fades over time)
    /// Strength training fades slower than cardio
    var decayRate: Double {
        switch self {
        case .cardio:
            return 0.15 // Cardio fades faster (15% per day)
        default:
            return 0.05 // Strength training fades slower (5% per day)
        }
    }
}

/// Represents the intensity percentage for secondary muscle group involvement
typealias MuscleGroupIntensity = [MuscleGroup: Double]

/// Helper extension for working with muscle group intensities
extension MuscleGroupIntensity {
    
    /// Validates that all intensity values are between 0.0 and 1.0
    var isValid: Bool {
        return self.allSatisfy { _, intensity in
            intensity >= 0.0 && intensity <= 1.0
        }
    }
    
    /// Returns the total intensity (should not exceed 1.0 for secondary groups)
    var totalIntensity: Double {
        return self.values.reduce(0.0, +)
    }
    
    /// Creates a normalized version where all intensities sum to the given target
    func normalized(to target: Double = 1.0) -> MuscleGroupIntensity {
        let total = totalIntensity
        guard total > 0 else { return self }
        
        let factor = target / total
        return self.mapValues { $0 * factor }
    }
}
