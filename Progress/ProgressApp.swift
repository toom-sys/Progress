//
//  ProgressApp.swift
//  Progress
//
//  Created by Tom Cameron on 12/07/2025.
//

import SwiftUI

@main
struct ProgressApp: App {
    
    // MARK: - Properties
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate)
                .onAppear {
                    // Additional setup can be done here if needed
                    if appDelegate.isInitialized {
                        print("📱 App UI loaded - SDKs initialized")
                    }
                }
        }
    }
}


