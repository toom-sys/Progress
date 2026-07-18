//
//  UnitSystem+Extensions.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

extension UnitSystem {
    
    // MARK: - Weight Conversions
    
    /// Convert weight from kg to the user's preferred unit system
    func convertWeight(from kg: Double) -> Double {
        switch self {
        case .metric:
            return kg
        case .imperial:
            return kg * 2.20462 // kg to lbs
        }
    }
    
    /// Convert weight to kg from the user's preferred unit system
    func convertWeightToKg(from value: Double) -> Double {
        switch self {
        case .metric:
            return value
        case .imperial:
            return value / 2.20462 // lbs to kg
        }
    }
    
    /// Format weight value with appropriate unit
    func formatWeight(_ kg: Double, precision: Int = 1) -> String {
        let convertedWeight = convertWeight(from: kg)
        let format = "%.\(precision)f"
        return String(format: format, convertedWeight)
    }
    
    /// Format weight value with unit label
    func formatWeightWithUnit(_ kg: Double, precision: Int = 1) -> String {
        let convertedWeight = convertWeight(from: kg)
        let format = "%.\(precision)f"
        return String(format: format, convertedWeight) + " " + weightUnit
    }
    

    
    // MARK: - Height Conversions
    
    /// Format a height in centimetres for display in the user's unit system.
    /// Metric returns e.g. "175 cm"; imperial returns e.g. "5'9\"".
    func formatHeight(_ cm: Double) -> String {
        switch self {
        case .metric:
            return "\(Int(cm.rounded())) cm"
        case .imperial:
            let totalInches = cm / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int((totalInches - Double(feet) * 12).rounded())
            // Handle rounding that pushes inches to 12.
            if inches == 12 {
                return "\(feet + 1)'0\""
            }
            return "\(feet)'\(inches)\""
        }
    }
    
    // MARK: - Distance Conversions
    
    /// Convert distance from km to the user's preferred unit system
    func convertDistance(from km: Double) -> Double {
        switch self {
        case .metric:
            return km
        case .imperial:
            return km * 0.621371 // km to miles
        }
    }
    
    /// Convert distance to km from the user's preferred unit system
    func convertDistanceToKm(from value: Double) -> Double {
        switch self {
        case .metric:
            return value
        case .imperial:
            return value / 0.621371 // miles to km
        }
    }
    
    /// Format distance value with appropriate unit
    func formatDistance(_ km: Double, precision: Int = 1) -> String {
        let convertedDistance = convertDistance(from: km)
        let format = "%.\(precision)f"
        return String(format: format, convertedDistance)
    }
    
    /// Format distance value with unit label
    func formatDistanceWithUnit(_ km: Double, precision: Int = 1) -> String {
        let convertedDistance = convertDistance(from: km)
        let format = "%.\(precision)f"
        let unit = self == .metric ? "km" : "mi"
        return String(format: format, convertedDistance) + " " + unit
    }
    
    // MARK: - Unit Labels
    
    var distanceUnit: String {
        switch self {
        case .metric: return "km"
        case .imperial: return "mi"
        }
    }
    
    var distanceUnitLong: String {
        switch self {
        case .metric: return "kilometers"
        case .imperial: return "miles"
        }
    }
    
    var weightUnitLong: String {
        switch self {
        case .metric: return "kilograms"
        case .imperial: return "pounds"
        }
    }
}
