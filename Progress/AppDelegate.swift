//
//  AppDelegate.swift
//  Progress
//
//  Created by Progress Team
//

import UIKit
import SwiftUI
import UserNotifications

import RevenueCat
import FirebaseCore
import FirebaseCrashlytics
import FirebaseAnalytics
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    
    // MARK: - Properties
    
    @Published var isInitialized = false
    private let userDefaults = UserDefaults.standard
    private let firstLaunchKey = "com.tom.Progress.firstLaunch"
    
    // Orientation lock support - locked to portrait only
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    // MARK: - Application Lifecycle
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        setupLogging()
        initializeSDKs()
        setupNotifications()
        handleFirstLaunch()
        
        // Clear any existing badge count on app launch
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        DispatchQueue.main.async {
            self.isInitialized = true
        }
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Clear badge count when app comes to foreground
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: - Orientation Support
    
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    // MARK: - Private Methods
    
    private func setupLogging() {
        #if DEBUG
        print("🚀 Progress App - Debug mode enabled")
        #endif
    }
    
    private func initializeSDKs() {
        initializeFirebase()
        initializeRevenueCat()
    }
    
    private func setupNotifications() {
        _ = NotificationService.shared
    }
    
    private func initializeFirebase() {
        guard let configPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              FileManager.default.fileExists(atPath: configPath) else {
            #if DEBUG
            print("⚠️ Firebase config not found. Skipping Firebase initialization.")
            #endif
            return
        }
        
        FirebaseApp.configure()
        signInAnonymouslyIfNeeded()
        
        #if DEBUG
        Analytics.setAnalyticsCollectionEnabled(true)
        print("✅ Firebase initialized successfully")
        #endif
    }
    
    /// The AI proxy authenticates requests with Firebase ID tokens, so every
    /// install needs a (anonymous) Firebase user.
    private func signInAnonymouslyIfNeeded() {
        guard Auth.auth().currentUser == nil else { return }
        
        Task {
            do {
                let result = try await Auth.auth().signInAnonymously()
                #if DEBUG
                print("✅ Firebase anonymous sign-in: \(result.user.uid)")
                #endif
            } catch {
                // AIBackend retries sign-in on demand before AI requests.
                print("⚠️ Firebase anonymous sign-in failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func initializeRevenueCat() {
        guard let configPath = Bundle.main.path(forResource: "RevenueCat", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath),
              let apiKey = config["PUBLIC_SDK_KEY_IOS"] as? String,
              !apiKey.isEmpty,
              !apiKey.hasPrefix("${") else {
            #if DEBUG
            print("⚠️ RevenueCat config not found or invalid. Skipping RevenueCat initialization.")
            #endif
            return
        }
        
        #if DEBUG
        Purchases.logLevel = .info
        #else
        Purchases.logLevel = .error
        #endif
        
        Purchases.configure(withAPIKey: apiKey)
        
        if let attributionEnabled = config["ATTRIBUTION_ENABLED"] as? Bool, attributionEnabled {
            Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
        }
        
        #if DEBUG
        print("✅ RevenueCat initialized")
        #endif
    }
    
    private func handleFirstLaunch() {
        let isFirstLaunch = !userDefaults.bool(forKey: firstLaunchKey)
        
        if isFirstLaunch {
            userDefaults.set(true, forKey: firstLaunchKey)
            requestNotificationPermissionsOnFirstLaunch()
            #if DEBUG
            print("🎉 First launch detected")
            #endif
        }
    }
    
    private func requestNotificationPermissionsOnFirstLaunch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            Task {
                let granted = await NotificationService.shared.requestNotificationPermissions()
                #if DEBUG
                print("🔔 Timer notifications \(granted ? "enabled" : "disabled")")
                #endif
            }
        }
    }
    
    // MARK: - Public Methods
    
    func isFirstLaunch() -> Bool {
        return !userDefaults.bool(forKey: firstLaunchKey)
    }
    
    func resetFirstLaunch() {
        userDefaults.removeObject(forKey: firstLaunchKey)
        #if DEBUG
        print("🔄 First launch flag reset")
        #endif
    }
}

// MARK: - Environment Access

extension AppDelegate {
    static var shared: AppDelegate? {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        return delegate
    }
}
