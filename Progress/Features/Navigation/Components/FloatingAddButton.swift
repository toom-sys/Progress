//
//  FloatingAddButton.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Floating Add Button Component

/// A circular glass "+" button that floats above the tab bar and presents
/// a menu of add actions. Hides itself while the keyboard is visible.
struct FloatingAddButton<MenuContent: View>: View {
    @EnvironmentObject private var keyboardObserver: KeyboardObserver
    @ViewBuilder let menuContent: () -> MenuContent

    var body: some View {
        if !keyboardObserver.isKeyboardVisible {
            Menu {
                menuContent()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(Color.border.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                    .shadow(color: .cardShadow, radius: 8, x: 0, y: 2)
            }
            .accessibilityLabel("Add")
        }
    }
}
