import Testing
import IntelligenceKit
@testable import InspirationInbox

@Test func consentIsOffByDefault() {
    UserDefaults.standard.removeObject(forKey: AppSettings.consentKey)
    UserDefaults.standard.removeObject(forKey: "enhancedEnabled")
    #expect(UserDefaultsConsent().hasConsented == false)
}

@Test func privateModeOverridesConsent() {
    UserDefaults.standard.set(true, forKey: AppSettings.consentKey)
    UserDefaults.standard.set(true, forKey: "enhancedEnabled")
    UserDefaults.standard.set(true, forKey: "privateMode")
    #expect(UserDefaultsConsent().hasConsented == false)
    for k in [AppSettings.consentKey, "enhancedEnabled", "privateMode"] { UserDefaults.standard.removeObject(forKey: k) }
}
