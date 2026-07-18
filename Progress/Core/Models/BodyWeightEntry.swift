//
//  BodyWeightEntry.swift
//  Progress
//

import Foundation
import SwiftData

@Model
final class BodyWeightEntry {

    // MARK: - Properties

    var id: UUID = UUID()
    /// Body weight in kilograms (canonical storage unit)
    var weightKg: Double = 0
    var loggedAt: Date = Date()

    // MARK: - Relationships

    var user: User?

    // MARK: - Initialization

    init(weightKg: Double, loggedAt: Date = Date()) {
        self.id = UUID()
        self.weightKg = weightKg
        self.loggedAt = loggedAt
    }
}
