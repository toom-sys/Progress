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
    
    // MARK: - SwiftData Container
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Workout.self,
            Exercise.self,
            ExerciseSet.self,
            NutritionEntry.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic // Enable CloudKit sync
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            print("✅ SwiftData container initialized with CloudKit sync")
            return container
            
        } catch {
            print("❌ Failed to create SwiftData container: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appDelegate)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    // Additional setup can be done here if needed
                    if appDelegate.isInitialized {
                        print("📱 App UI loaded - SDKs initialized")
                    }
                }
        }
    }
}


