# Inspiration Inbox — PRD & Roadmap

Oct 30, 2026 · @Stanley

## Vision and principles

Inspiration Inbox turns a spoken thought into a clean, structured note in seconds, with no app to open, folder to pick, or typing. It is a native iPhone app built around the Action Button.

- **Capture first, organize never.** The user never files anything; AI structures the thought after the fact.
- **Never lose a thought.** The raw transcript is saved before any AI step runs.
- **One job per screen.** Capture, Inbox, Thought. No folders, no settings maze.
- **Alive, not busy.** Motion and haptics respond to voice and touch; nothing animates for decoration.
- **AI is an editor, not an author.** It cleans and structures what was said and never adds ideas or facts.

**Non-goals for v1:** collaboration, folders, rich-text editing, iPad, Mac, Android, Apple Watch, web clipper.

## Core user loop

One press, one spoken thought, and a structured note is waiting in the Inbox before the user has put the phone down.

1. Press the Action Button (or the Control Center or Lock Screen control). The app opens straight into recording: no splash, no menu.
2. Speak. A live transcript appears and the orb reacts to the voice.
3. Stop by tapping, releasing a hold, or after 2.5 s of silence (auto-stop, configurable).
4. The raw thought saves instantly with a haptic confirmation.
5. AI structures it in the background: title, cleaned text, type, tags, action items. The card updates in place.
6. Later, the user triages the Inbox: pin, archive, share.

| Metric | Target |
| --- | --- |
| Action Button press to recording | ≤ 1.0 s warm, ≤ 1.5 s cold |
| Live transcript latency | ≤ 500 ms |
| Stop to saved on disk | ≤ 300 ms, works offline |
| Saved to structured (p50 / p95) | ≤ 4 s / ≤ 10 s on a normal connection |
| Captures lost | 0 |

## Tech stack and architecture constraints

Build a native iPhone app in Swift 6 and SwiftUI, targeting iOS 26, for App Store release in English and Chinese. AI runs on the device by default using open-source models; cloud is an opt-in Enhanced mode. The Action Button needs an iPhone 15 Pro or later; other iPhones use the Control Center and Lock Screen controls. All API and model names must be confirmed in the Phase 0 bake-offs.

| Area | Choice | Note |
| --- | --- | --- |
| UI | SwiftUI only | Springs, matchedGeometryEffect, PhaseAnimator; UIKit only if unavoidable |
| Entry points | App Intents + WidgetKit control | Action Button maps to a Capture Thought intent |
| Live speech to text | Apple SpeechAnalyzer | Free, streaming, no model download; English and Mandarin |
| Accuracy pass | WhisperKit (MIT) with Whisper large-v3-turbo | Optional re-transcription of the saved audio; 0.6 to 1.6 GB download depending on variant; SenseVoice Small (about 450 MB) is the Chinese challenger |
| Structuring model | Qwen3.5-2B or Qwen3.5-4B, 4-bit (Apache 2.0) | About 1.3 GB and 2.7 GB; picked by device RAM |
| Model runtime | MLX Swift first, llama.cpp as fallback | Models download after install, never bundled |
| Storage | SwiftData + CloudKit private database | Raw fields first, derived fields second |
| AI abstraction | ThoughtProcessor protocol | On-device (default), Apple Foundation Models (baseline), cloud via proxy (opt-in) |
| Backend | One serverless endpoint, POST /structure | Enhanced mode only; holds the API key; App Attest |
| Tests | Swift Testing + XCUITest | XCUITest covers the capture flow |

**Architecture rules**

- Local Swift packages: DesignSystem, CaptureKit, IntelligenceKit, Persistence, ModelStore. The app target stays thin.
- Capture and saving must work with no network, no AI, and no model downloaded.
- On-device is the default. Cloud runs only after the user opts in on a consent screen that names the provider and the data sent, as App Store guideline 5.1.2(i) requires. Audio never leaves the device.
- Models are never bundled in the app. ModelStore downloads them after install with a checksum, resumes interrupted downloads, and lets the user delete them in Settings. The 4B model likely needs the increased-memory-limit entitlement; confirm in Phase 0.
- AI output is validated against a JSON schema. Invalid output falls back to the raw text and never blocks saving.
- Settings shows license notices for every open-source model and library (Apache 2.0, MIT).
- No third-party dependencies beyond WhisperKit and the model runtime without a written justification in the PR. No analytics SDKs.

## MVP requirements

Sixteen requirements make up v1. Each has an ID the agent cites in commits and PRs, and each is done only when its acceptance criterion passes.

| ID | Requirement | Acceptance criterion | Phase |
| --- | --- | --- | --- |
| FR-1 | One-press capture from Action Button, Control Center and Lock Screen controls | Recording starts within 1.0 s warm with no further tap | 1 |
| FR-2 | Live on-device voice transcription in English and Mandarin | Words appear as spoken; works in airplane mode | 1 |
| FR-3 | Stop controls | Tap, hold-release, or silence auto-stop (default 2.5 s) | 1 |
| FR-4 | Save raw before any AI | Transcript and audio persisted within 300 ms of stop; survives force-quit | 1 |
| FR-5 | Text capture fallback | Typed thought enters the same pipeline as voice | 1 |
| FR-6 | Inbox list | Newest first; card shows title (first line while processing), type, age, and state | 1 |
| FR-7 | Thought detail | Structured view by default; one tap flips to raw; inline editing | 2 |
| FR-8 | On-device AI structuring | Title, cleaned text, summary, type, up to 3 tags, action items; no network needed; retries with backoff | 2 |
| FR-9 | Triage gestures | Swipe to pin or archive; long-press for share, copy, delete; undo on every action | 3 |
| FR-10 | Search | Instant full-text over raw and cleaned text; finds Chinese terms written without spaces | 3 |
| FR-11 | iCloud sync | Thought appears on a second device within 30 s; last edit wins | 4 |
| FR-12 | Export | Share sheet with Markdown and plain text | 4 |
| FR-13 | English and Chinese support | Cleaned text stays in the language spoken; Simplified or Traditional output set in Settings; mixed Chinese and English sentences keep both | 1 and 2 |
| FR-14 | Model manager | First-launch download with progress, resume, checksum, and delete; capture works while models download | 2 |
| FR-15 | Enhanced mode (cloud) | Off by default; consent screen names the provider and the data sent; no network call before consent | 4 |
| FR-16 | App Store readiness | Privacy label, privacy manifest, usage strings, review notes, open-source license screen | 5 |

## UX and interaction spec

The app has three screens: Capture, Inbox, Thought. Everything else sits behind one small settings sheet.

**Visual language**

- Monochrome plus one accent color; SF Pro, large type, generous whitespace; light and dark modes both first-class.
- No tab bar, and no toolbar with more than two buttons.
- Cards instead of separator-lined lists.

**Capture screen**

- Full-screen canvas with a single orb that breathes at rest and swells with voice level.
- The live transcript fades in word by word above the orb; the newest words are brightest.
- Haptics: soft tick on start, light tap on each long pause, success pattern on save.
- On stop the transcript "crystallizes": the orb collapses into a card that animates into its slot in the Inbox (matchedGeometryEffect), then the AI result fills the card in place.

**Inbox**

- Pull down past the top to start a capture; a small orb button is the alternative.
- Swipe right to pin, swipe left to archive, long-press for quick actions. Every gesture has a haptic and an undo.
- Cards still processing show a subtle shimmer, never a spinner.

**Thought**

- Structured view by default; tap the Raw chip to flip to the original words; edit any text inline.
- Action items are tappable checkboxes.

**Quality bar**

- Spring animations everywhere, no linear timing; 120 fps on ProMotion devices.
- Reduce Motion swaps crystallize for a cross-fade; Dynamic Type through AX5; VoiceOver label on every control; 44 pt minimum touch targets.
- The empty state is one sentence and the orb. Microphone and speech permissions are requested in context at the first capture, not up front.

## AI processing pipeline

The AI restructures what the user said and adds nothing. The raw transcript always saves first, so a failed AI step never loses a thought.

1. Transcript finalized, thought saved with status `captured`.
2. `ThoughtProcessor` runs asynchronously, on-device by default, using the Qwen model that fits the device's RAM. If the model is not downloaded yet or fails to load, the thought stays `captured` and is retried later. The cloud processor runs only when the user has opted into Enhanced mode.
3. Output is validated against the schema below. On success the status becomes `ready`; on failure it retries twice with exponential backoff, then becomes `failed` and the card shows the raw text.

Output schema:

```json
{
  "title": "8 words or fewer",
  "cleaned_text": "faithful rewrite: fillers removed, sentences complete",
  "summary": "one line",
  "kind": "idea | task | question | reminder | quote | journal",
  "tags": ["at most 3, lowercase"],
  "action_items": ["verb-first, only if clearly implied"],
  "open_questions": [],
  "uncertain": false
}
```

**System prompt rules**

- Preserve the speaker's meaning and voice. Never add facts, names, or ideas.
- If the transcript is garbled or ambiguous, keep the original wording and set `uncertain` to true.
- Reply in the language the thought was spoken in. For Chinese, use the script chosen in Settings (Simplified or Traditional) and keep English terms, names, and numbers as spoken.
- Turn off thinking mode (Qwen3.5 writes out its reasoning unless the prompt pre-seeds an empty think block), use greedy decoding, and constrain output to the schema where the runtime supports it.
- Return JSON only.

**Evaluation.** Keep an `Evals/` folder of 60 transcripts: 30 English and 30 Chinese, each set covering short, long, rambling, multi-topic, and mixed-language thoughts (Chinese with English terms and names). Rubric: valid JSON, faithful with no invented content, useful title, correct kind. Run it on every prompt, model, or quantization change. The bar is at least 95% valid and 90% faithful, scored separately for English and Chinese.

**Model choice.** On-device by default. The picks below come from published sources, and the Phase 0 bake-off tests them on your own recordings before anything is locked. Model names live in a remote config file, so they can change without an app release.

| Role | Pick | Why | Download | Also test |
| --- | --- | --- | --- | --- |
| Live speech to text | Apple SpeechAnalyzer | Streams, free, nothing to download; in one third-party test its Chinese error rate matched Whisper large-v3-turbo (about 8%), but its English was weaker (8.8% vs 5.5%) | None | SenseVoice Small |
| Accuracy pass after stop | WhisperKit + Whisper large-v3-turbo | Best English score of the options that can run on iPhone | 0.6 to 1.6 GB | SenseVoice Small (Chinese 7.7%, English 8.5%); Qwen3-ASR 1.7B (Chinese 6.5%, English 4.5%) but Mac-only for now |
| Structuring, 8 GB RAM iPhone | Qwen3.5-4B, 4-bit | Apache 2.0; strongest small Qwen3.5 that fits a phone | About 2.7 GB | Gemma 4 E4B (check license and Chinese quality) |
| Structuring, 6 GB RAM iPhone | Qwen3.5-2B, 4-bit | Apache 2.0; runs on iPhone through MLX Swift | About 1.3 GB | Gemma 4 E2B (check license and Chinese quality) |
| Structuring, 4 GB RAM iPhone | Apple Foundation Models if available, else save raw only | No download; availability depends on device and language settings | None | Cloud, if Enhanced mode is on |
| Skipped | Qwen3.5-0.8B and Phi-4-mini | The 0.8B is built for verbatim cleanup, not restructuring; Phi-4-mini's multilingual rival in the same comparison was Qwen3 |  |  |

Caveats: the speech numbers come from one vendor's test on a MacBook Air with clean read speech (character error rate for Chinese, word error rate for English), so expect higher error rates on noisy phone recordings. Sources disagree on whether Whisper large-v3-turbo fits on every recent iPhone, so test on your target devices. RAM tiers are approximate. If the 2B model misses the Gate C bar, the Apache 2.0 license allows a LoRA fine-tune on schema-style English and Chinese examples.

## Data model

One SwiftData entity, `Thought`, holds everything. It must stay CloudKit-compatible: every property optional or defaulted, no unique constraints.

| Field | Type | Note |
| --- | --- | --- |
| id | UUID |  |
| createdAt, updatedAt | Date |  |
| rawTranscript | String | Immutable after save |
| audioFileName | String? | Local only; deleted after 30 days by default |
| status | enum | captured, ready, failed |
| title | String? |  |
| cleanedText | String? | User edits land here |
| summary | String? |  |
| kind | enum? | idea, task, question, reminder, quote, journal |
| tags | \[String\] | Up to 3 |
| actionItems | \[ActionItem\] | Text plus isDone |
| isPinned | Bool |  |
| archivedAt | Date? | Archive, never hard-delete, until the user deletes |
| processorVersion | String? | Prompt and model that produced the result, so results can be re-run |

Re-processing a thought never overwrites the user's edits without confirmation.

## Phased roadmap

The build runs in six phases, about seven to ten weeks in total. The agent stops at every gate and waits for your review before starting the next phase.

_Roadmap: 6 phases, 6 gates (diagram in the original doc)._

Each gate is a test you run yourself on a physical iPhone; a phase is not done until its gate passes.

**Phase 0 · Foundations and bake-offs**

- [ ] Create the Xcode project, five local packages (DesignSystem, CaptureKit, IntelligenceKit, Persistence, ModelStore), and CI that builds and runs tests
- [ ] DesignSystem tokens: colors, type scale, spacing, spring presets, haptic presets
- [ ] Record the test set on a real iPhone: 30 English and 30 Chinese spoken thoughts, including mixed-language ones, with hand-corrected transcripts
- [ ] Spike 1: an App Intent bound to the Action Button that opens straight into recording; measure press-to-recording cold and warm
- [ ] Bake-off 1 (speech): Apple SpeechAnalyzer, WhisperKit with large-v3-turbo, and SenseVoice Small on the test set; report error rate, latency, and memory per language, on the oldest target iPhone
- [ ] Bake-off 2 (structuring): Qwen3.5-2B, Qwen3.5-4B, and Apple Foundation Models scored with the Evals rubric in English and Chinese; test Gemma 4 E2B and E4B only if their license allows commercial use
- [ ] Spike 2: run the winning model through MLX Swift on device; record load time, tokens per second, peak memory, and whether the increased-memory-limit entitlement is needed
- [ ] Write `docs/spike-report.md` with a pick and a go/no-go for each

**Phase 1 · Capture MVP (FR-1 to FR-6, FR-13)**

- [ ] `Thought` entity and SwiftData store, raw fields only
- [ ] Capture screen: orb, live transcript, stop controls, haptics
- [ ] Capture App Intent and Control Center control
- [ ] Language handling: follow the device language, handle mixed English and Chinese speech, Simplified or Traditional setting
- [ ] Save before anything else, with a force-quit test
- [ ] Inbox list and text-capture fallback
- [ ] XCUITest for the capture flow

**Phase 2 · On-device AI structuring (FR-7, FR-8, FR-13, FR-14)**

- [ ] `ThoughtProcessor` protocol, schema validation, status states
- [ ] ModelStore: download after install, resume, checksum, delete, Wi-Fi-only by default
- [ ] On-device processor using the Qwen model for the device's RAM tier, thinking mode off, greedy decoding
- [ ] Fallbacks: Apple Foundation Models on low-RAM devices, raw-only when no model is available
- [ ] Retry with backoff and the failed state
- [ ] Thought detail with Raw toggle and inline editing
- [ ] `Evals/` folder and runner (60 transcripts); pass Gate C, and fine-tune with LoRA only if the bar is missed

**Phase 3 · Interaction polish (FR-9, FR-10)**

- [ ] Crystallize transition from Capture to an Inbox card
- [ ] Orb motion tied to audio level; shimmer on processing cards
- [ ] Swipe, long-press, pull-down-to-capture, and undo
- [ ] Full-text search, including Chinese text written without spaces
- [ ] Accessibility pass: Reduce Motion, Dynamic Type, VoiceOver
- [ ] Frame-rate profiling on device

**Phase 4 · Sync and Enhanced mode (FR-11, FR-12, FR-15)**

- [ ] CloudKit sync, tested across two devices
- [ ] Share-sheet export as Markdown and plain text
- [ ] Enhanced mode: consent screen naming the provider and the data sent, serverless proxy with App Attest, cloud processor
- [ ] A test that proves no network call fires before consent
- [ ] Lock Screen control and the settings sheet (auto-stop, private mode, audio retention, model downloads)

**Phase 5 · App Store launch (FR-16)**

- [ ] Privacy nutrition label and privacy manifest that match what the app actually does
- [ ] Microphone and speech usage strings; App Store Connect review notes that explain the Action Button flow and the on-device AI
- [ ] Open-source license screen with the Apache 2.0 and MIT notices
- [ ] App icon, screenshots, and listing text in English and Chinese
- [ ] TestFlight external beta with a seven-day daily-use fix list
- [ ] Submit for App Review; fix and resubmit until approved

**After v1:** daily resurfacing of old thoughts, related-thought linking, a weekly review, export to Notion, a Share extension, and Apple Watch.

## Agent execution rules

The coding agent works in small, reviewable steps, and every phase ends with a build you can run on your phone. Export this doc as Markdown and save it in the repo root as `PRD.md`.

- At the start of every session, read `PRD.md` and `AGENTS.md` (or `CLAUDE.md`). Update `AGENTS.md` whenever a decision changes.
- One phase at a time. Do not start phase N+1 until phase N's exit criteria are checked off in `docs/progress.md`.
- One task per branch or PR: small diff, tests, and a short note on what changed and how it was verified. Cite requirement IDs (FR-1, FR-2…).
- Definition of done: builds with zero warnings, unit tests pass, the capture-flow XCUITest passes, and anything involving the Action Button, microphone or haptics is verified on a physical iPhone (the simulator cannot).
- Ask before adding a dependency, changing the data model after Phase 1, or deviating from this spec.
- Never commit API keys, send audio off the device, or add analytics.

**Kickoff prompt** for Codex or Claude Code:

```text
You are building "Inspiration Inbox", a minimalist iOS app for the App Store (Swift 6, SwiftUI, iOS 26, iPhone only, English and Chinese).
Read PRD.md fully, then create AGENTS.md summarizing the "Tech stack and architecture constraints" and "Agent execution rules" sections.
Start Phase 0 only: scaffold the Xcode project with local Swift packages (DesignSystem, CaptureKit, IntelligenceKit, Persistence, ModelStore), set up CI, and run the Action Button spike plus the speech and structuring bake-offs on my recorded English and Chinese test set.
Write findings to docs/spike-report.md with a pick and a go/no-go for each, then stop and wait for my review before Phase 1.
```

## Risks and open questions

The biggest risk is getting from an Action Button press into live recording fast enough, because iOS restricts background audio capture. Phase 0 tests this first.

**Risks and fallbacks**

- **Slow launch** (over 1.5 s cold): switch to an audio-recording intent with a Live Activity, or keep the app warm.
- **Weak transcription** on accents, mixed Chinese and English, or noise: keep the audio so the accuracy pass can re-transcribe it, and keep the transcript editable.
- **Script mix-ups in Chinese:** some Whisper variants return Traditional characters. Convert to the script chosen in Settings and test both.
- **Memory limits:** a 4B model plus the app may hit iOS memory limits on some devices. Test on the oldest 8 GB iPhone, request the increased-memory-limit entitlement, and fall back to the 2B model.
- **Large downloads:** models run from about 1.3 to 2.7 GB for structuring, plus 0.6 to 1.6 GB if the accuracy pass ships. Capture must work before they finish, and downloads default to Wi-Fi only.
- **AI over-editing** (invented or dropped content): faithfulness rule, Raw toggle, and the eval set.
- **App Review rejection:** guideline 5.1.2(i) requires disclosure and explicit permission before personal data goes to third-party AI. Cloud mode stays off by default and shows a consent screen before any call.
- **Feature creep:** a new feature must remove a step for the user, or it is cut.

**Open questions**

- Is your Chinese Mandarin, Cantonese, or both, and should output be Simplified, Traditional, or both?
- Will you release in the mainland China storefront? That adds local filing requirements worth checking with a lawyer before choosing storefronts.
- Keep the opt-in cloud Enhanced mode in v1, or ship on-device only? Dropping it removes FR-15 and the backend.
- Free, paid up front, or subscription? Cloud mode adds a running cost per user; on-device does not.

## Sources

Checked October 31, 2026. The first two pages were opened and read; the rest were read as search results only, so check them before relying on them.

- [Whisper Notes: speech models compared by language](https://whispernotes.app/whisper-models): error rates and download sizes; one vendor's test on a MacBook Air with clean read speech
- [Quobi/Quill model card on Hugging Face](https://huggingface.co/quobi/quill): Qwen3.5 Apache 2.0 license, 4-bit file sizes, thinking-mode setting
- [Qwen3.5 small models on iPhone](https://letsdatascience.com/blog/a-9b-model-on-your-phone-just-beat-a-120b-cloud-model): release date, sizes, MLX Swift on iPhone
- [iOS speech SDKs compared](https://www.forasoft.com/blog/article/speech-recognition-with-neural-networks-on-ios-1621): WhisperKit and SpeechAnalyzer
- [Running LLMs on iPhone by RAM tier](https://dev.to/alichherawalla/how-to-run-llms-locally-on-your-iphone-in-2026-completely-offline-no-subscription-4b3a): approximate RAM tiers
- [TechCrunch on App Review guideline 5.1.2(i)](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai): third-party AI consent rule
