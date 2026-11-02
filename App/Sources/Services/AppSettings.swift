import Foundation
import Observation
import CaptureKit
import IntelligenceKit
import Persistence

@MainActor @Observable
final class AppSettings {
    static let consentKey = "enhancedConsent"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        autoStopSeconds = defaults.object(forKey: "autoStopSeconds") as? Double ?? 2.5
        speechLanguage = SpeechLanguage(rawValue: defaults.string(forKey: "speechLanguage") ?? "") ?? .auto
        chineseScript = ChineseScript(rawValue: defaults.string(forKey: "chineseScript") ?? "") ?? Self.defaultScript
        audioRetentionDays = defaults.object(forKey: "audioRetentionDays") as? Int ?? 30
        privateMode = defaults.bool(forKey: "privateMode")
        enhancedEnabled = defaults.bool(forKey: "enhancedEnabled") && defaults.bool(forKey: Self.consentKey)
        wifiOnly = defaults.object(forKey: "wifiOnly") as? Bool ?? true
        accuracyPass = defaults.bool(forKey: "accuracyPass")
    }

    private static var defaultScript: ChineseScript {
        let first = Locale.preferredLanguages.first?.lowercased() ?? ""
        return first.contains("hant") || first.contains("tw") || first.contains("hk") ? .traditional : .simplified
    }

    var autoStopSeconds: Double { didSet { defaults.set(autoStopSeconds, forKey: "autoStopSeconds") } }
    var speechLanguage: SpeechLanguage { didSet { defaults.set(speechLanguage.rawValue, forKey: "speechLanguage") } }
    var chineseScript: ChineseScript { didSet { defaults.set(chineseScript.rawValue, forKey: "chineseScript") } }
    /// 0 = do not keep audio. 30 days by default.
    var audioRetentionDays: Int { didSet { defaults.set(audioRetentionDays, forKey: "audioRetentionDays") } }
    /// Private mode: never keep audio and never use Enhanced mode, even if it is switched on.
    var privateMode: Bool { didSet { defaults.set(privateMode, forKey: "privateMode") } }
    var enhancedEnabled: Bool { didSet { defaults.set(enhancedEnabled, forKey: "enhancedEnabled") } }
    var wifiOnly: Bool { didSet { defaults.set(wifiOnly, forKey: "wifiOnly") } }
    var accuracyPass: Bool { didSet { defaults.set(accuracyPass, forKey: "accuracyPass") } }

    var keepAudio: Bool { !privateMode && audioRetentionDays > 0 }

    /// Consent is recorded separately from the toggle, and only by the consent screen.
    func recordConsent(_ granted: Bool) {
        defaults.set(granted, forKey: Self.consentKey)
        enhancedEnabled = granted
    }
}

/// Reads consent straight from UserDefaults so the cloud processor can check it from any context.
/// Both the consent record and the Enhanced toggle must be on, and private mode must be off.
struct UserDefaultsConsent: ConsentStore {
    var hasConsented: Bool {
        let d = UserDefaults.standard
        return d.bool(forKey: AppSettings.consentKey) && d.bool(forKey: "enhancedEnabled") && !d.bool(forKey: "privateMode")
    }
}
