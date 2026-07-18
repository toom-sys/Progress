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
            return "No AI backend configured — set AI_PROXY_URL or OPENAI_API_KEY in Secrets.xcconfig"
        case .notAuthenticated:
            return "Not signed in to Firebase — AI requests need an auth token"
        }
    }
}

/// How the app reaches OpenAI.
///
/// Release builds go through the server-side proxy (`AI_PROXY_URL` in
/// Secrets.xcconfig), authenticated with the user's Firebase ID token so the
/// OpenAI key never ships in the app. When no proxy URL is configured the
/// app falls back to calling OpenAI directly with a local development key.
enum AIBackend {
    case proxy(URL)
    case direct(apiKey: String)

    /// Resolves the backend from build configuration. Proxy wins when both
    /// are configured.
    static func resolve() -> AIBackend? {
        if let urlString = Bundle.main.infoDictionary?["AI_PROXY_URL"] as? String,
           !urlString.isEmpty,
           let url = URL(string: urlString),
           url.scheme == "https" {
            return .proxy(url)
        }

        if let key = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String, !key.isEmpty {
            return .direct(apiKey: key)
        }
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return .direct(apiKey: envKey)
        }

        return nil
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
