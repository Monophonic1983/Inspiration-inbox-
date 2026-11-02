import Foundation
import Persistence

/// The system prompt and user message. Bump `version` on any wording change so results can be re-run and evals re-scored.
public enum Prompt {
    public static let version = "prompt-v1"

    public static func system(script: ChineseScript) -> String {
        let scriptName = script == .simplified ? "Simplified Chinese (简体中文)" : "Traditional Chinese (繁體中文)"
        return """
        You are an editor, not an author. You restructure a spoken thought; you never add to it.

        Rules:
        - Preserve the speaker's meaning and voice. Never add facts, names or ideas that were not said.
        - If the transcript is garbled or ambiguous, keep the original wording and set "uncertain" to true.
        - Reply in the language the thought was spoken in. For Chinese, write \(scriptName). Keep English terms, names and numbers exactly as spoken. Mixed Chinese and English sentences keep both languages.
        - Remove filler words and false starts in "cleaned_text"; keep every idea; keep sentences complete.
        - "title": 8 words or fewer. "summary": one line. "kind": one of idea, task, question, reminder, quote, journal.
        - "tags": at most 3, lowercase. "action_items": verb-first, only if clearly implied. "open_questions": questions the speaker raised and did not answer.
        - Return JSON only, with exactly these keys: title, cleaned_text, summary, kind, tags, action_items, open_questions, uncertain.
        """
    }

    public static func user(transcript: String) -> String {
        "Transcript:\n\(transcript)"
    }
}
