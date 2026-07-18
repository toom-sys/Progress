//
//  Tab.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation

// MARK: - Tab Enum

enum Tab: String, CaseIterable {
    case workouts = "workouts"
    case journey = "journey"
    case nutrition = "nutrition"
    
    var displayName: String {
        switch self {
        case .workouts: return "Workouts"
        case .journey: return "Journey"
        case .nutrition: return "Nutrition"
        }
    }
    
    var icon: String {
        switch self {
        case .workouts: return "dumbbell"
        case .journey: return "figure.walk"
        case .nutrition: return "leaf"
        }
    }
    
    var activeIcon: String {
        switch self {
        case .workouts: return "dumbbell.fill"
        case .journey: return "figure.walk"
        case .nutrition: return "leaf.fill"
        }
    }
}
