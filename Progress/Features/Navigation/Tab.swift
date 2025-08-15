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
    case progress = "progress"
    case nutrition = "nutrition"
    
    var displayName: String {
        switch self {
        case .workouts: return "Workouts"
        case .progress: return "Progress"
        case .nutrition: return "Nutrition"
        }
    }
    
    var icon: String {
        switch self {
        case .workouts: return "dumbbell"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .nutrition: return "leaf"
        }
    }
    
    var activeIcon: String {
        switch self {
        case .workouts: return "dumbbell.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .nutrition: return "leaf.fill"
        }
    }
}
