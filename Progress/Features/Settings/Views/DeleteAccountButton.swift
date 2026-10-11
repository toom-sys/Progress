//
//  DeleteAccountButton.swift
//  Progress
//

import SwiftUI
import SwiftData

struct DeleteAccountButton<Label: View>: View {
    var usesPlainStyle: Bool = false
    @ViewBuilder var label: () -> Label

    @Environment(\.modelContext) private var modelContext
    @State private var showingConfirmation = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if usesPlainStyle {
                accountButton.buttonStyle(.plain)
            } else {
                accountButton
            }
        }
    }

    private var accountButton: some View {
        Button(role: .destructive) {
            showingConfirmation = true
        } label: {
            label()
                .overlay {
                    if isDeleting {
                        ProgressView()
                    }
                }
        }
        .disabled(isDeleting)
        .accessibilityLabel(isDeleting ? "Deleting account" : "Delete Account")
        .accessibilityHint("Permanently deletes your account and the data saved in Progress")
        .alert(AccountDeletionService.confirmationTitle, isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Account", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text(AccountDeletionService.confirmationMessage)
        }
        .alert("Couldn't Delete Account", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await AccountDeletionService.deleteAccount(in: modelContext)
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
    }
}
