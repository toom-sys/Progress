//
//  AccountDeletionService.swift
//  Progress
//
//  Progress creates an anonymous Firebase user on launch so AI requests can
//  be authenticated. Deleting an account removes that user, then clears the
//  data stored with it and starts a fresh local profile.
//

import Foundation
import SwiftData
import FirebaseCore
import FirebaseAuth

enum AccountDeletionError: LocalizedError {
    case firebase(String)
    case localData(String)

    var errorDescription: String? {
        switch self {
        case .firebase(let message):
            return message
        case .localData(let message):
            return "Your account was removed, but data on this device could not be cleared. \(message)"
        }
    }
}

@MainActor
enum AccountDeletionService {
    static let confirmationTitle = "Delete Account?"
    static let confirmationMessage = """
    This permanently deletes your Progress account and the profile, workouts, \
    nutrition, water, and weight history saved in the app, including the copy \
    synced through iCloud. This cannot be undone.

    An App Store subscription is not cancelled. Manage that in the App Store.
    """

    /// Deletes the Firebase user first. Local data is cleared only after that succeeds.
    static func deleteAccount(in context: ModelContext) async throws {
        try await deleteFirebaseUser()
        do {
            try resetLocalData(in: context)
        } catch {
            await signInAnonymouslyIfNeeded()
            throw AccountDeletionError.localData(error.localizedDescription)
        }
        await signInAnonymouslyIfNeeded()
    }

    /// Removes stored records and inserts a new profile that has not finished onboarding.
    static func resetLocalData(in context: ModelContext) throws {
        try deleteAll(TrainingPlan.self, in: context)
        try deleteAll(Workout.self, in: context)
        try deleteAll(NutritionEntry.self, in: context)
        try deleteAll(WaterEntry.self, in: context)
        try deleteAll(BodyWeightEntry.self, in: context)
        try deleteAll(CustomExercise.self, in: context)
        try deleteAll(User.self, in: context)

        context.insert(User())
        try context.save()
        OnboardingProgressStore.resetSavedProgress()
    }

    // MARK: - Firebase

    private static func deleteFirebaseUser() async throws {
        guard FirebaseApp.app() != nil else { return }
        guard let user = Auth.auth().currentUser else { return }

        do {
            try await user.delete()
        } catch {
            guard isRecentLoginRequired(error) else {
                throw AccountDeletionError.firebase(
                    "Couldn't delete the account. \(error.localizedDescription)"
                )
            }
            do {
                _ = try await user.getIDToken(forcingRefresh: true)
                try await user.delete()
            } catch {
                throw AccountDeletionError.firebase(
                    "This session is too old to delete the account. Force-quit Progress, open it again, and try once more."
                )
            }
        }
    }

    /// A new anonymous user keeps AI requests working after the old account is gone.
    private static func signInAnonymouslyIfNeeded() async {
        guard FirebaseApp.app() != nil else { return }
        guard Auth.auth().currentUser == nil else { return }
        do {
            _ = try await Auth.auth().signInAnonymously()
        } catch {
            print("⚠️ Replacement Firebase sign-in failed: \(error.localizedDescription)")
        }
    }

    private static func isRecentLoginRequired(_ error: Error) -> Bool {
        (error as NSError).code == AuthErrorCode.requiresRecentLogin.rawValue
    }

    private static func deleteAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws {
        let items = try context.fetch(FetchDescriptor<T>())
        for item in items {
            context.delete(item)
        }
    }
}
