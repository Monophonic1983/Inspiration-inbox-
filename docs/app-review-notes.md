# App Store Connect review notes (draft)

Inspiration Inbox turns a spoken thought into a structured note. It needs a physical iPhone to test the headline flow.

**How to test**
1. Open the app. Tap the orb button (top right) to start recording. Allow microphone and speech access when asked.
2. Speak a sentence, then tap Stop (or stay silent for 2.5 seconds). A card appears in the Inbox immediately; it fills in with a title and structure a moment later.
3. Action Button (iPhone 15 Pro or later): Settings → Action Button → Controls → "Capture Thought". Other iPhones: add the "Capture Thought" control to Control Center or the Lock Screen. Pressing it opens the app directly into recording.

**On-device AI.** Structuring runs on the device using an open-source model that the app downloads after install (Settings shows size, licence and a Delete button). Until the model finishes downloading, thoughts are saved and structured later; capture never waits.

**Cloud (Enhanced mode).** Off by default. Turning it on shows a consent screen naming the provider (Anthropic) and the data sent (the text of each thought, never audio). Reviewers do not need it. No network request is made before consent. This follows guideline 5.1.2(i).

**Permissions.** Microphone and speech recognition, requested at the first capture with an in-context explanation. A typed-thought fallback works if they are declined.

**No account, no login, no in-app purchase in v1** _(update if pricing changes)_.
