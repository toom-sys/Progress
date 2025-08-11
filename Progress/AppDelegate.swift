//
//  AppDelegate.swift
//  Progress
//
//  Created by Progress Team
//

import UIKit
import SwiftUI

// TODO: Uncomment when frameworks are added to project
import RevenueCat
import FirebaseCore
import FirebaseCrashlytics
import FirebaseAnalytics

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    
    // MARK: - Properties
    
    @Published var isInitialized = false
    private let userDefaults = UserDefaults.standard
    private let firstLaunchKey = "com.tom.Progress.firstLaunch"
    
    // Orientation lock support
    static var orientationLock = UIInterfaceOrientationMask.all
    
    // MARK: - Application Lifecycle
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        setupLogging()
        initializeSDKs()
        handleFirstLaunch()
        
        DispatchQueue.main.async {
            self.isInitialized = true
        }
        
        return true
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
    
    private func initializeFirebase() {
        guard let configPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              FileManager.default.fileExists(atPath: configPath) else {
            print("⚠️ Firebase config not found. Skipping Firebase initialization.")
            return
        }
        
        // TODO: Uncomment when Firebase is added
        FirebaseApp.configure()
        
        // Enable debug logging in debug builds
        #if DEBUG
        Analytics.setAnalyticsCollectionEnabled(true)
        #endif
        
        print("✅ Firebase initialized successfully")
        
        print("📝 Firebase configuration found - ready for initialization")
    }
    
    private func initializeRevenueCat() {
        guard let configPath = Bundle.main.path(forResource: "RevenueCat", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath),
              let apiKey = config["PUBLIC_SDK_KEY_IOS"] as? String,
              !apiKey.isEmpty,
              !apiKey.hasPrefix("${") else {
            print("⚠️ RevenueCat config not found or invalid. Skipping RevenueCat initialization.")
            return
        }
        
        // Configure RevenueCat for sandbox testing
        #if DEBUG
        Purchases.logLevel = .info  // Reduced from .debug
        #else
        Purchases.logLevel = .error
        #endif
        
        // Configure with the new API
        Purchases.configure(withAPIKey: apiKey)
        
        // Enable StoreKit 2 if specified
        if let storeKit2Enabled = config["STORE_KIT_2_ENABLED"] as? Bool, storeKit2Enabled {
            // StoreKit 2 is enabled by default in RevenueCat 4.0+
        }
        
        // Set attribution if enabled
        if let attributionEnabled = config["ATTRIBUTION_ENABLED"] as? Bool, attributionEnabled {
            Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
        }
        
        print("✅ RevenueCat initialized with API key: \(String(apiKey.prefix(8)))...")
        
        #if DEBUG
        print("🧪 RevenueCat configured for sandbox testing")
        #endif
        
        print("💰 RevenueCat configuration found - ready for initialization")
    }
    
    private func handleFirstLaunch() {
        let isFirstLaunch = !userDefaults.bool(forKey: firstLaunchKey)
        
        if isFirstLaunch {
            userDefaults.set(true, forKey: firstLaunchKey)
            logFirstLaunchEvent()
            print("🎉 First launch detected - welcome to Progress!")
        }
    }
    
    private func logFirstLaunchEvent() {
        let deviceInfo = [
            "device_model": UIDevice.current.model,
            "ios_version": UIDevice.current.systemVersion,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            "launch_timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Log to console for now
        print("📊 First Launch Event:")
        deviceInfo.forEach { key, value in
            print("   \(key): \(value)")
        }
        
        // TODO: Uncomment when Firebase Analytics is added
        Analytics.logEvent("first_launch", parameters: deviceInfo)
        
        // TODO: Uncomment when RevenueCat is added
        /*
        Purchases.shared.attribution.setAttributes(deviceInfo)
        */
    }
    
    // MARK: - Public Methods
    
    func isFirstLaunch() -> Bool {
        return !userDefaults.bool(forKey: firstLaunchKey)
    }
    
    func resetFirstLaunch() {
        userDefaults.removeObject(forKey: firstLaunchKey)
        print("🔄 First launch flag reset")
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