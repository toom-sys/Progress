//
//  AIBackend.swift
//  Progress
//

import Foundation
import FirebaseCore
import FirebaseAuth

enum AIBackendError: LocalizedError {
    case notConfigured
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "No AI backend configured — Debug builds can set OPENAI_API_KEY in Secrets.xcconfig"
        case .notAuthenticated:
            return "Not signed in to Firebase — AI requests need an auth token"
        }
    }
}

/// How the app reaches OpenAI.
///
/// Release builds always use the production proxy (`AI_PROXY_URL` from
/// `Release.xcconfig`), authenticated with the user's Firebase ID token so
/// the OpenAI key never ships in the app. Debug builds use that same proxy
/// unless `Secrets.xcconfig` points elsewhere or clears it and supplies a
/// local `OPENAI_API_KEY`.
enum AIBackend {
    case proxy(URL)
    case direct(apiKey: String)

    /// Public Cloud Function. The OpenAI key lives in Secret Manager.
    /// Keep this in sync with `Release.xcconfig`.
    static let productionProxyURL = URL(string: "https://europe-west2-progress-d601c.cloudfunctions.net/aiProxy")!

    /// Resolves the backend from build configuration. A real proxy URL wins.
    /// Release builds fall back to `productionProxyURL` when the plist value
    /// is missing, unsubstituted, or still the example placeholder.
    static func resolve() -> AIBackend? {
        if let url = proxyURL(from: Bundle.main.infoDictionary?["AI_PROXY_URL"] as? String) {
            return .proxy(url)
        }

        #if DEBUG
        if let key = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String, !key.isEmpty {
            return .direct(apiKey: key)
        }
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return .direct(apiKey: envKey)
        }
        return nil
        #else
        return .proxy(productionProxyURL)
        #endif
    }

    /// Accepts an https proxy URL. Rejects empty values, unsubstituted
    /// `$(AI_PROXY_URL)` build settings, and the example placeholder host.
    static func proxyURL(from raw: String?) -> URL? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("$(") else { return nil }
        guard let url = URL(string: trimmed), url.scheme == "https", let host = url.host else { return nil }
        guard !host.contains("your-project") else { return nil }
        return url
    }

    /// Endpoint that accepts an OpenAI chat-completions request body.
    var chatCompletionsURL: URL {
        switch self {
        case .proxy(let url):
            return url
        case .direct:
            return URL(string: "https://api.openai.com/v1/chat/completions")!
        }
    }

    var isProxy: Bool {
        if case .proxy = self { return true }
        return false
    }

    /// Value for the `Authorization` header — the OpenAI key in direct mode,
    /// a fresh Firebase ID token in proxy mode.
    @MainActor
    func authorizationValue() async throws -> String {
        switch self {
        case .direct(let apiKey):
            return "Bearer \(apiKey)"
        case .proxy:
            guard FirebaseApp.app() != nil else {
                throw AIBackendError.notAuthenticated
            }
            let user: FirebaseAuth.User
            if let currentUser = Auth.auth().currentUser {
                user = currentUser
            } else {
                // Recover if startup sign-in hasn't completed or failed.
                user = try await Auth.auth().signInAnonymously().user
            }
            let token = try await user.getIDToken()
            return "Bearer \(token)"
        }
    }
}
