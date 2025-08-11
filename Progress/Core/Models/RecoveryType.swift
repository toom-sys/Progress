//
//  RecoveryType.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation

enum RecoveryType: String, CaseIterable {
    case active = "active"
    case mental = "mental"
    case mobility = "mobility"
    case passive = "passive"
    case thermal = "thermal"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .mental: return "Mental"
        case .mobility: return "Mobility"
        case .passive: return "Passive"
        case .thermal: return "Thermal"
        }
    }
}