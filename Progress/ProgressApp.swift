//
//  ProgressApp.swift
//  Progress
//
//  Created by Tom Cameron on 12/07/2025.
//

import SwiftUI
import SwiftData

@main
struct ProgressApp: App {
    
    // MARK: - Properties
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var subscriptionService = SubscriptionService()
    @State private var showSplash = true
    
    // MARK: - SwiftData Container
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Workout.self,
            Exercise.self,
            ExerciseSet.self,
            NutritionEntry.self,
            CustomExercise.self,
            WaterEntry.self,
            BodyWeightEntry.self,
            TrainingPlan.self
        ])
        
        // v1 keeps the store on this device. CloudKit stays off until the
        // app has an iCloud entitlement and container.
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        
        do {
            print("🔄 Creating local SwiftData container...")
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            print("✅ SwiftData container initialized")
            return container
            
        } catch {
            print("❌ Failed to create SwiftData container: \(error)")
            
            let isMigrationError = Self.isMigrationError(error)
            
            if isMigrationError {
                print("🔄 Attempting database migration recovery...")
                
                let storeURLs = Self.getAllPossibleStoreURLs()
                var deletedAny = false
                
                for storeURL in storeURLs {
                    if FileManager.default.fileExists(atPath: storeURL.path) {
                        do {
                            try FileManager.default.removeItem(at: storeURL)
                            print("🗑️ Removed old database store at: \(storeURL.path)")
                            deletedAny = true
                        } catch {
                            print("⚠️ Failed to remove store at \(storeURL.path): \(error)")
                        }
                    }
                }
                
                if deletedAny {
                    do {
                        let container = try ModelContainer(
                            for: schema,
                            configurations: [modelConfiguration]
                        )
                        print("✅ SwiftData container recovered with fresh database")
                        return container
                    } catch {
                        print("❌ Recovery failed: \(error)")
                    }
                }
            }
            
            print("⚠️ Creating fallback in-memory ModelContainer due to error: \(error)")
            
            let fallbackConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            
            do {
                let fallbackContainer = try ModelContainer(
                    for: schema,
                    configurations: [fallbackConfiguration]
                )
                print("✅ Fallback in-memory SwiftData container created")
                return fallbackContainer
            } catch {
                print("❌ Even fallback container failed: \(error)")
                fatalError("Could not create any ModelContainer: \(error)")
            }
        }
    }()
    
    // MARK: - Helper Methods
    
    private static func isMigrationError(_ error: Error) -> Bool {
        if let nsError = error as? NSError,
           nsError.domain == NSCocoaErrorDomain,
           nsError.code == 134110 {
            return true
        }
        
        let errorString = String(describing: error)
        if errorString.contains("SwiftDataError") && errorString.contains("loadIssueModelContainer") {
            return true
        }
        
        if let nsError = error as? NSError,
           let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError,
           underlyingError.domain == NSCocoaErrorDomain,
           underlyingError.code == 134110 {
            return true
        }
        
        return false
    }
    
    private static func getAllPossibleStoreURLs() -> [URL] {
        var urls: [URL] = []
        
        if let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            urls.append(appSupportDir.appendingPathComponent("default.store"))
            urls.append(appSupportDir.appendingPathComponent("Model.sqlite"))
            urls.append(appSupportDir.appendingPathComponent("DataModel.sqlite"))
            urls.append(appSupportDir.appendingPathComponent("default.store-wal"))
            urls.append(appSupportDir.appendingPathComponent("default.store-shm"))
        }
        
        if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            urls.append(documentsDir.appendingPathComponent("default.store"))
            urls.append(documentsDir.appendingPathComponent("Model.sqlite"))
        }
        
        return urls
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showSplash = false
                        }
                    }
                    .environmentObject(subscriptionService)
                    .transition(.opacity)
                } else {
                    RootContentView(ensureLocalUser: ensureLocalUser)
                    .environmentObject(appDelegate)
                    .environmentObject(subscriptionService)
                    .modelContainer(sharedModelContainer)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showSplash)
        }
    }
    
    // MARK: - Local User Setup
    
    /// Creates a default local user profile on first launch if none exists.
    private func ensureLocalUser() {
        let context = sharedModelContainer.mainContext
        _ = User.current(in: context)
    }
}

// MARK: - Post-Splash Routing

private struct RootContentView: View {
    @Query private var users: [User]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appDelegate: AppDelegate
    @EnvironmentObject private var subscriptionService: SubscriptionService

    let ensureLocalUser: () -> Void

    private var hasCompletedOnboarding: Bool {
        users.first?.hasCompletedOnboarding == true
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(onComplete: {})
                    .environmentObject(subscriptionService)
            }
        }
        .onAppear {
            print("📱 App UI loaded")
            ensureLocalUser()
            DeepLinkService.shared.configure(with: modelContext)
            BodyMapProgressService.configure(with: modelContext)
            Task {
                do {
                    if ExerciseSystemInitializer.needsInitialization {
                        print("🏋️ Exercise system needs initialization...")
                        try await ExerciseSystemInitializer.initializeExerciseSystem(modelContext: modelContext)
                    } else {
                        print("✅ Exercise system already initialized")
                    }
                } catch {
                    print("❌ Failed to initialize exercise system: \(error)")
                }
            }
        }
        .onOpenURL { url in
            DeepLinkService.shared.handleURL(url)
        }
    }
}
