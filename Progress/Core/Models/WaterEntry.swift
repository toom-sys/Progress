//
//  WaterEntry.swift
//  Progress
//

import Foundation
import SwiftData

@Model
final class WaterEntry {

    // MARK: - Properties

    var id: UUID
    /// Amount of water logged, in millilitres
    var amount: Double
    var loggedAt: Date

    // MARK: - Relationships

    var user: User?

    // MARK: - Initialization

    init(amount: Double, loggedAt: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.loggedAt = loggedAt
    }
}
