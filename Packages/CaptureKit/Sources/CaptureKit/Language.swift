import Foundation

public enum SpeechLanguage: String, CaseIterable, Codable, Sendable { case auto, english, chinese }

/// FR-13: follows the device language by default. A Chinese recogniser also handles English terms inside Chinese sentences,
/// so mixed speech is captured with the Chinese locale when the user speaks mostly Chinese.
public enum LocaleResolver {
    public static func resolve(setting: SpeechLanguage, preferredLanguages: [String] = Locale.preferredLanguages) -> Locale {
        switch setting {
        case .english: return Locale(identifier: "en-US")
        case .chinese: return Locale(identifier: "zh-CN")
        case .auto:
            let first = preferredLanguages.first?.lowercased() ?? "en"
            if first.hasPrefix("zh") { return Locale(identifier: first.contains("tw") || first.contains("hant") || first.contains("hk") ? "zh-TW" : "zh-CN") }
            return Locale(identifier: "en-US")
        }
    }
}
