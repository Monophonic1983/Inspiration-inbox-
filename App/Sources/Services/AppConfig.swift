import Foundation

enum AppConfig {
    /// Named on the Enhanced mode consent screen (App Store guideline 5.1.2(i)). Must match what the backend calls.
    static let cloudProviderName = "Anthropic"
    /// Base URL of the serverless proxy (backend/). Replace after deploying.
    static let cloudEndpoint = URL(string: "https://inspiration-inbox-proxy.example.workers.dev")!
    /// iCloud container for CloudKit sync (FR-11). Replace with your container id.
    static let cloudKitContainer = "iCloud.com.example.inspirationinbox"
    /// Remote model catalog (nil until hosted; the bundled catalog is used meanwhile).
    static let catalogURL: URL? = nil

    static var isUITest: Bool { ProcessInfo.processInfo.arguments.contains("-uitest") }
}
