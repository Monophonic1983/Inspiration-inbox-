import Foundation

public enum ChineseScript: String, Codable, CaseIterable, Sendable {
    case simplified, traditional
}

public enum ScriptConverter {
    /// Converts Han characters to the requested script; Latin text, digits and punctuation pass through.
    public static func convert(_ text: String, to script: ChineseScript) -> String {
        let id = script == .simplified ? "Hant-Hans" : "Hans-Hant"
        return text.applyingTransform(StringTransform(rawValue: id), reverse: false) ?? text
    }

    public static func containsHan(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) || (0x3400...0x4DBF).contains($0.value) }
    }
}
