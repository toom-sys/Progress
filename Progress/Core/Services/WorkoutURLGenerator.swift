//
//  WorkoutURLGenerator.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation

/// Service for generating and parsing shareable workout URLs
/// Handles encoding workout data into URL-safe parameters and validation
class WorkoutURLGenerator {
    
    // MARK: - Constants
    
    /// Custom URL scheme for the Progress app
    private static let urlScheme = "progress"
    
    /// Host for workout sharing URLs
    private static let workoutHost = "workout"
    
    /// Maximum URL length to ensure compatibility across platforms
    private static let maxURLLength = 2000
    
    /// Version of the URL format for future compatibility
    private static let urlVersion = "1"
    
    // MARK: - Error Types
    
    enum WorkoutSharingError: LocalizedError {
        case workoutContainsCustomExercises
        case workoutHasNoExercises
        case workoutNameTooLong
        case encodingFailed
        case urlTooLong
        case invalidWorkoutData
        case unsupportedExerciseType
        
        var errorDescription: String? {
            switch self {
            case .workoutContainsCustomExercises:
                return "This workout contains custom exercises that cannot be shared. Only workouts with default exercises can be shared for compatibility."
            case .workoutHasNoExercises:
                return "Cannot share an empty workout. Add some exercises first."
            case .workoutNameTooLong:
                return "Workout name is too long for sharing. Please use a shorter name."
            case .encodingFailed:
                return "Failed to encode workout data for sharing."
            case .urlTooLong:
                return "Workout data is too large to share. Try reducing the number of exercises or sets."
            case .invalidWorkoutData:
                return "Invalid workout data provided."
            case .unsupportedExerciseType:
                return "This workout contains unsupported exercise types that cannot be shared."
            }
        }
    }
    
    // MARK: - Data Models
    
    /// Compact representation of workout data for URL encoding
    struct ShareableWorkout: Codable {
        let name: String
        let exercises: [ShareableExercise]
        let version: String
        
        init(name: String, exercises: [ShareableExercise]) {
            self.name = name
            self.exercises = exercises
            self.version = WorkoutURLGenerator.urlVersion
        }
    }
    
    /// Compact representation of exercise data for URL encoding
    struct ShareableExercise: Codable {
        let name: String
        let type: String // ExerciseType raw value
        let category: String?
        let order: Int
        let restTime: Int // TimeInterval as seconds
        let sets: [ShareableSet]
    }
    
    /// Compact representation of set data for URL encoding
    struct ShareableSet: Codable {
        let order: Int
        let weight: Double?
        let reps: Int?
        let duration: Int? // TimeInterval as seconds
        let distance: Double?
        let notes: String?
        
        init(from exerciseSet: ExerciseSet) {
            self.order = exerciseSet.order
            
            // Only include non-zero values to keep URLs shorter
            self.weight = exerciseSet.weight > 0 ? exerciseSet.weight : nil
            self.reps = exerciseSet.reps > 0 ? exerciseSet.reps : nil
            self.duration = exerciseSet.duration > 0 ? Int(exerciseSet.duration) : nil
            self.distance = exerciseSet.distance > 0 ? exerciseSet.distance : nil
            self.notes = exerciseSet.notes?.isEmpty == false ? exerciseSet.notes : nil
        }
    }
    
    // MARK: - Public Methods
    
    /// Generates a shareable URL for the given workout
    /// - Parameter workout: The workout to share
    /// - Returns: A shareable URL string
    /// - Throws: WorkoutSharingError if the workout cannot be shared
    static func generateShareableURL(for workout: Workout) throws -> String {
        // Validate workout can be shared
        try validateWorkoutForSharing(workout)
        
        // Convert workout to shareable format
        let shareableWorkout = try createShareableWorkout(from: workout)
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys // For consistent URLs
        
        guard let jsonData = try? encoder.encode(shareableWorkout) else {
            throw WorkoutSharingError.encodingFailed
        }
        
        // Compress and encode to base64
        let compressedData = try compressData(jsonData)
        let base64String = compressedData.base64EncodedString()
        
        // Create URL
        let urlString = "\(urlScheme)://\(workoutHost)?v=\(urlVersion)&data=\(base64String)"
        
        // Validate URL length
        if urlString.count > maxURLLength {
            throw WorkoutSharingError.urlTooLong
        }
        
        return urlString
    }
    
    /// Validates if a workout can be shared
    /// - Parameter workout: The workout to validate
    /// - Throws: WorkoutSharingError if the workout cannot be shared
    static func validateWorkoutForSharing(_ workout: Workout) throws {
        // Check if workout has exercises
        guard !workout.exercises.isEmpty else {
            throw WorkoutSharingError.workoutHasNoExercises
        }
        
        // Check workout name length (keep reasonable for URLs)
        guard workout.name.count <= 100 else {
            throw WorkoutSharingError.workoutNameTooLong
        }
        
        // Check if all exercises are predefined (not custom)
        for exercise in workout.exercises {
            if exercise.isCustom {
                throw WorkoutSharingError.workoutContainsCustomExercises
            }
            
            // Validate exercise has a predefined ID
            guard exercise.predefinedExerciseId != nil else {
                throw WorkoutSharingError.workoutContainsCustomExercises
            }
            
            // Validate exercise type is supported
            guard isExerciseTypeSupported(exercise.type) else {
                throw WorkoutSharingError.unsupportedExerciseType
            }
        }
    }
    
    /// Checks if a workout can be shared (non-throwing version)
    /// - Parameter workout: The workout to check
    /// - Returns: True if the workout can be shared, false otherwise
    static func canShareWorkout(_ workout: Workout) -> Bool {
        do {
            try validateWorkoutForSharing(workout)
            return true
        } catch {
            return false
        }
    }
    
    /// Gets the reason why a workout cannot be shared
    /// - Parameter workout: The workout to check
    /// - Returns: Error description if workout cannot be shared, nil if it can be shared
    static func getSharingError(for workout: Workout) -> String? {
        do {
            try validateWorkoutForSharing(workout)
            return nil
        } catch let error as WorkoutSharingError {
            return error.errorDescription
        } catch {
            return "Unknown error occurred while validating workout for sharing."
        }
    }
    
    // MARK: - Private Methods
    
    /// Creates a shareable workout from the full workout model
    private static func createShareableWorkout(from workout: Workout) throws -> ShareableWorkout {
        let shareableExercises = workout.exercises
            .sorted { $0.order < $1.order }
            .map { exercise in
                let shareableSets = exercise.sets
                    .sorted { $0.order < $1.order }
                    .map { ShareableSet(from: $0) }
                
                return ShareableExercise(
                    name: exercise.name,
                    type: exercise.type.rawValue,
                    category: exercise.category,
                    order: exercise.order,
                    restTime: Int(exercise.restTime),
                    sets: shareableSets
                )
            }
        
        return ShareableWorkout(
            name: workout.name,
            exercises: shareableExercises
        )
    }
    
    /// Compresses data using gzip compression
    private static func compressData(_ data: Data) throws -> Data {
        // For now, return data as-is. In the future, we could add compression
        // if URLs become too long. Foundation doesn't have built-in gzip,
        // but we could use a third-party library if needed.
        return data
    }
    
    /// Checks if an exercise type is supported for sharing
    private static func isExerciseTypeSupported(_ type: ExerciseType) -> Bool {
        // Support all modern exercise types
        switch type {
        case .strength, .cardio, .flexibility:
            return true
        case .resistance, .recovery:
            // Legacy types - still supported for backward compatibility
            return true
        }
    }
    
    // MARK: - URL Parsing (for future use in Step 7C)
    
    /// Parses a workout URL and extracts the encoded data
    /// - Parameter urlString: The workout URL to parse
    /// - Returns: The decoded workout data
    /// - Throws: WorkoutSharingError if the URL is invalid
    static func parseWorkoutURL(_ urlString: String) throws -> ShareableWorkout {
        guard let url = URL(string: urlString) else {
            throw WorkoutSharingError.invalidWorkoutData
        }
        
        // Validate scheme and host
        guard url.scheme == urlScheme, url.host == workoutHost else {
            throw WorkoutSharingError.invalidWorkoutData
        }
        
        // Extract query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            throw WorkoutSharingError.invalidWorkoutData
        }
        
        // Find data parameter
        guard let dataItem = queryItems.first(where: { $0.name == "data" }),
              let base64String = dataItem.value else {
            throw WorkoutSharingError.invalidWorkoutData
        }
        
        // Decode base64
        guard let compressedData = Data(base64Encoded: base64String) else {
            throw WorkoutSharingError.invalidWorkoutData
        }
        
        // Decompress data (for now, no compression is applied)
        let jsonData = compressedData
        
        // Decode JSON
        let decoder = JSONDecoder()
        do {
            let shareableWorkout = try decoder.decode(ShareableWorkout.self, from: jsonData)
            return shareableWorkout
        } catch {
            throw WorkoutSharingError.invalidWorkoutData
        }
    }
    
    /// Validates a workout URL format without fully parsing it
    /// - Parameter urlString: The URL to validate
    /// - Returns: True if the URL format is valid, false otherwise
    static func isValidWorkoutURL(_ urlString: String) -> Bool {
        do {
            _ = try parseWorkoutURL(urlString)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - URL Security Extensions

extension WorkoutURLGenerator {
    
    /// Sanitizes workout data to prevent potential security issues
    private static func sanitizeString(_ string: String) -> String {
        // Remove any potentially harmful characters
        let allowedCharacters = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(.punctuationCharacters)
            .subtracting(CharacterSet(charactersIn: "<>\"'&"))
        
        return string.components(separatedBy: allowedCharacters.inverted).joined()
    }
    
    /// Validates that numeric values are within reasonable ranges
    private static func validateNumericValue(_ value: Double, min: Double = 0, max: Double = 10000) -> Bool {
        return value >= min && value <= max && value.isFinite
    }
}
