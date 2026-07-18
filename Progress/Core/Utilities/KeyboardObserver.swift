//
//  KeyboardObserver.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import Combine

// MARK: - Keyboard Observer

@MainActor
class KeyboardObserver: ObservableObject {
    @Published var isKeyboardVisible = false
    @Published var keyboardHeight: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupKeyboardObservers()
    }
    
    private func setupKeyboardObservers() {
        // Keyboard will show
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardWillShow(notification)
            }
            .store(in: &cancellables)
        
        // Keyboard will hide
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardWillHide(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleKeyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.isKeyboardVisible = true
                self.keyboardHeight = keyboardFrame.height
            }
        }
    }
    
    private func handleKeyboardWillHide(_ notification: Notification) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.isKeyboardVisible = false
                self.keyboardHeight = 0
            }
        }
    }
}

// MARK: - View Extension for Keyboard Awareness

extension View {
    func keyboardAware() -> some View {
        self.environmentObject(KeyboardObserver())
    }
}
