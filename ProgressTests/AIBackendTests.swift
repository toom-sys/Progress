//
//  AIBackendTests.swift
//  ProgressTests
//

import Testing
@testable import Progress

struct AIBackendTests {

    @Test func acceptsProductionProxyURL() {
        let url = AIBackend.proxyURL(from: AIBackend.productionProxyURL.absoluteString)
        #expect(url == AIBackend.productionProxyURL)
    }

    @Test func rejectsMissingAndPlaceholderProxyURLs() {
        #expect(AIBackend.proxyURL(from: nil) == nil)
        #expect(AIBackend.proxyURL(from: "") == nil)
        #expect(AIBackend.proxyURL(from: "   ") == nil)
        #expect(AIBackend.proxyURL(from: "$(AI_PROXY_URL)") == nil)
        #expect(AIBackend.proxyURL(from: "https://europe-west2-your-project.cloudfunctions.net/aiProxy") == nil)
        #expect(AIBackend.proxyURL(from: "http://europe-west2-progress-d601c.cloudfunctions.net/aiProxy") == nil)
    }
}
