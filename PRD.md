# Inspiration Inbox — PRD & Roadmap

Nov 2, 2026 · @Stanley

## Vision and principles

Inspiration Inbox turns scattered spoken thoughts into clear, linked cards. Press the Action Button and speak, and the app splits what you said into one-thought cards for you to review. The recording is raw material; the cards are the product.

- **Capture first, organize later.** Capture takes one press. Organizing comes after, mostly as suggestions from the app.
- **Never lose a thought.** The raw transcript is saved before any AI step runs.
- **One thought per card.** A recording with several ideas becomes several cards, and the user reviews the split before the cards are saved.
- **Structure grows, it is not imposed.** Types and tags start from a small default set and grow with use. The app suggests threads.
- **One job per screen, most important first.** Headline, then detail, then add-ons. Anything that adds no information is cut.
- **AI is an editor, not an author.** It splits, titles and sorts what was said, and never adds ideas or facts.

**Non-goals for v1:** collaboration, folders, cloud AI (Enhanced mode), Cantonese, Traditional Chinese, paid tiers, iPad, Mac, Android, Apple Watch, web clipper.

## Core user loop

One press and one spoken stream of thoughts produce a set of reviewed cards a few seconds after the user stops talking.

1. Press the Action Button (or the Control Center or Lock Screen control). The app opens straight into recording: no splash, no menu.
2. Speak. A live, timestamped transcript scrolls under a live waveform.
3. Stop by tapping, or after 2.5 s of silence (auto-stop, configurable).
4. The recording and raw transcript save instantly, with a haptic confirmation.
5. On-device AI splits the transcript into one-thought cards, each with a title, body, type, tags and a suggested thread.
6. The user reviews the split: edit, merge, split or drop cards, and change type, tags or thread. Save puts the cards in the feed; Later marks the recording Needs review.
7. Typed thoughts use the same pipeline. On Save the app asks whether to split the text into cards or keep it as one card.
8. Later, the user organizes, links, archives and searches cards.

| Metric | Target |
| --- | --- |
| Action Button press to recording | ≤ 1.0 s warm, ≤ 1.5 s cold |
| Live transcript latency | ≤ 500 ms |
| Stop to saved on disk | ≤ 300 ms, works offline |
| Saved to split proposal ready (p50 / p95) | ≤ 4 s / ≤ 10 s, on device |
| Split proposals saved with no merge or split edit | ≥ 70% on the eval set |
| Captures lost | 0 |

## Tech stack and architecture constraints

Build a native iPhone app in Swift 6 and SwiftUI, targeting iOS 26, for the App Store in English and Simplified Chinese, including the mainland China storefront. All AI runs on the device with open-source models; v1 has no cloud AI and no backend. The Action Button needs an iPhone 15 Pro or later; other iPhones use the Control Center and Lock Screen controls. Confirm all API and model names in the Phase 0 bake-offs.

| Area | Choice | Note |
| --- | --- | --- |
| UI | SwiftUI only | Springs, matchedGeometryEffect; UIKit only if unavoidable |
| Entry points | App Intents + WidgetKit control | Action Button maps to a Capture Thought intent |
| Live speech to text | Apple SpeechAnalyzer | Free, streaming, no model download; English and Mandarin; check Mandarin on mainland devices |
| Accuracy pass | WhisperKit (MIT) with Whisper large-v3-turbo | Optional re-transcription of the saved audio; 0.6 to 1.6 GB; SenseVoice Small (about 450 MB) is the Chinese challenger |
| Splitting model | Qwen3.5-2B or Qwen3.5-4B, 4-bit (Apache 2.0) | About 1.3 GB and 2.7 GB; picked by device RAM |
| Model runtime | MLX Swift first, llama.cpp as fallback | Models download after install, never bundled; a mirror reachable from mainland China is required |
| Rich text | SwiftUI TextEditor with AttributedString (iOS 26) | Stored as a Markdown subset; UITextView fallback |
| Storage | SwiftData + CloudKit private database | Recordings, cards, types; raw fields first |
| AI abstraction | CardSplitter protocol | On-device Qwen (default); Apple Foundation Models where available (not in mainland China); raw-only fallback |
| Backend | None in v1 | Only static files: model downloads and remote config |
| Tests | Swift Testing + XCUITest | XCUITest covers capture, review and the card page |

**Architecture rules**

- Local Swift packages: DesignSystem, CaptureKit, IntelligenceKit, Persistence, ModelStore. The app target stays thin.
- Capture and saving must work with no network, no AI, and no model downloaded.
- All AI runs on the device. Audio, transcripts and cards never leave it, except through the user's own iCloud sync.
- Models are never bundled. ModelStore downloads them after install with a checksum, resumes interrupted downloads, picks the download source by region, and lets the user delete them in Settings. The 4B model likely needs the increased-memory-limit entitlement; confirm in Phase 0.
- AI output is validated against a JSON schema. Invalid output falls back to one card holding the raw transcript and never blocks saving.
- Settings shows license notices for every open-source model, library and font (Apache 2.0, MIT, SIL OFL).
- No third-party dependencies beyond WhisperKit and the model runtime without a written justification in the PR. No analytics SDKs.

## MVP requirements

Twenty requirements make up v1. Each has an ID the agent cites in commits and PRs, and each is done only when its acceptance criterion passes. IDs were renumbered on Nov 2, 2026 for the card model.

| ID | Requirement | Acceptance criterion | Phase |
| --- | --- | --- | --- |
| FR-1 | One-press capture from Action Button, Control Center and Lock Screen controls | Recording starts within 1.0 s warm with no further tap | 1 |
| FR-2 | Live on-device transcription in English and Mandarin | Words appear as spoken, with timestamps; works in airplane mode | 1 |
| FR-3 | Stop controls | Tap, or silence auto-stop (default 2.5 s, 1 to 6 s in Settings) | 1 |
| FR-4 | Save raw before any AI | Recording, transcript and audio persisted within 300 ms of stop; survives force-quit | 1 |
| FR-5 | Typed capture | Typed text enters the same pipeline; Save asks "split into cards" or "keep as one"; typed cards show no waveform | 1 |
| FR-6 | Cards feed | Newest first, grouped by day; each card shows title, one-line preview, type and tags; thread cards show their card count; recordings needing review are flagged | 1 |
| FR-7 | Card page | Headline, then type and tag pills, then the note filling most of the screen; Thread, Same recording, Links and Recording as separate collapsed sections; archive and delete in a ⋯ menu | 2 |
| FR-8 | On-device splitting | One-thought cards with title, body, type, up to 3 tags, suggested thread and start time; no network needed; retries with backoff | 2 |
| FR-9 | Split review | Edit, merge, split, drop and re-sort proposed cards before saving; Later keeps the recording in Needs review; no cards are saved without a review | 2 |
| FR-10 | Rich-text editing | Formatting bar above the keyboard: bold, italic, underline, strikethrough, heading, bullet and numbered lists, checkbox, quote, link a card; Markdown shortcuts (` -  `, ` 1.  `, ` #  `, ` >  `, ` []  `, `**bold**`) convert as typed | 3 |
| FR-11 | Types, tags and Organize | Default types: thought, idea, epiphany, question, project, thread; users add types and tags; Organize lists both with card counts, hides empty ones, and opens a filtered list | 3 |
| FR-12 | Threads | The app suggests a thread per card; a thread is a card of type thread listing its cards by date; past 12 cards it offers to archive the older ones | 3 |
| FR-13 | Links | Links are bi-directional; a card links to its thread and to cards from the same recording; users add links, and `[[Card title]]` in a note creates one | 3 |
| FR-14 | Search and archive | Instant full-text search over cards and transcripts, including Chinese without spaces; archive and restore with undo; Organize suggests archiving cards untouched for 60+ days with no links | 3 |
| FR-15 | Recordings and calendar | Recordings list with playback and timestamped transcript; calendar heat map of capture days that opens a day's cards | 3 |
| FR-16 | iCloud sync | A card appears on a second device within 30 s; last edit wins | 4 |
| FR-17 | Export | Share a card or a thread as Markdown or plain text | 4 |
| FR-18 | Languages | English and Chinese UI with samples in both; Mandarin output in Simplified; mixed Chinese and English sentences keep both | 1 and 2 |
| FR-19 | Model manager | Download after install with progress, resume, checksum and delete; Wi-Fi only by default; capture works while models download | 2 |
| FR-20 | App Store readiness | Privacy label, privacy manifest, usage strings, review notes, license screen, and the mainland China filing number | 5 |

## UX and interaction spec

Each screen does one job, with the most important thing first. A side drawer (swipe right or tap the menu) holds Cards, Organize, Calendar, Recordings and Settings. Record and Type sit in a bar docked at the bottom. The interactive prototype shows every screen: [prototype](https://claude.ai/artifact/52R4Bx5y2KFcNeujLyoPqc), also in the repo at `docs/prototype/index.html`.

**Visual language**

- Spotify-inspired: black (dark) or white (light) background, grey card surfaces, one purple accent. Light, dark and system themes.
- Small 8 pt corner radius on cards and sheets; buttons, tag pills and the bottom bar are fully rounded.
- One sans-serif for content, set heavy and large for headlines; monospace only for timestamps and durations.
- No tab bar, no floating buttons. Empty tags and types are hidden; empty states are one sentence.

**Capture**

- Full screen: a live striped waveform (dense thin bars that fade at the edges), the last three transcript lines with timestamps (newest brightest), and Stop and save at the bottom.
- A thin bar counts down the silence auto-stop. Haptics: soft tick on start, success pattern on save.

**Split review**

- Headline "N cards". Each proposed card shows an editable title and body, a type-and-tags chip and a thread chip.
- Per card: Merge with next, Split, Drop. Bottom: Save all, or Later.
- Voice recordings go straight here. Typed text comes here only if the user picks Split, and shows no waveform.

**Cards (home)**

- Cards grouped by day, newest first: title, one-line preview, then type and tags in small text. Thread cards show their card count.
- Swipe a card to archive it, with undo. Search sits in the top bar.

**Card page**

- Hierarchy: editable headline, then type and tag pills (tap to change, + to add), then the note, which takes most of the screen.
- Tap the note to edit in place; the formatting bar docks above the keyboard.
- Below the note, separate collapsed rows, each with a one-line summary: Thread (its name), Same recording (card count), Links (count, + Link another card), Recording (length and date, small player inside).
- Thread cards list their cards by date under the note. Typed cards show "Typed" and a date instead of a recording.
- The ⋯ menu holds Type and tags, Archive or Restore, and Delete.

**Organize**

- Large "Types" and "Tags" headings with smaller rows and card counts; tap a row for a filtered list.
- An archive suggestion sits at the top when stale cards exist; Archive is the last row.

**Calendar, Recordings, Settings**

- Calendar: a month heat map of capture days; tap a day for its cards.
- Recordings: list with duration and review state; a recording page with a scrubbable waveform, the timestamped transcript, and the cards made from it.
- Settings: language (中文 / English), appearance, auto-stop seconds, keep audio (off, 7, 30 or 90 days), on-device model, licenses.

**Quality bar**

- Spring animations, no linear timing; 120 fps on ProMotion devices.
- Reduce Motion respected; Dynamic Type through AX5; a VoiceOver label on every control; 44 pt minimum touch targets.
- Microphone and speech permissions are requested in context at the first capture, not up front.

## AI processing pipeline

The AI splits what the user said into cards and adds nothing. The raw transcript always saves first, so a failed AI step never loses a thought.

1. Transcript finalized; the recording is saved with status `captured`.
2. `CardSplitter` runs on the device with the Qwen model that fits the device's RAM. Its input is the timestamped transcript plus the user's existing types, tags and thread titles. With no model downloaded yet, the recording stays `captured` and is retried later; its transcript is readable on the Recordings page meanwhile.
3. Output is validated against the schema below, and every card's text is checked against the transcript. On success the status becomes `needsReview`. On failure it retries twice with exponential backoff, then becomes `failed` and proposes one card holding the raw text.
4. The user reviews the proposal (FR-9). Save creates the cards, links them to each other and to their thread, and sets the status to `done`.

Output schema:

```json
{
  "cards": [
    {
      "title": "8 words or fewer",
      "body": "faithful rewrite of this part: fillers removed, sentences complete",
      "type": "one of the given types",
      "tags": ["at most 3, existing tags preferred"],
      "thread": "an existing thread title, a new thread title, or null",
      "start_s": 0,
      "end_s": 12.4
    }
  ],
  "uncertain": false
}
```

**System prompt rules**

- One thought per card. Split only where the topic changes; never split one argument across cards.
- Preserve the speaker's meaning and voice. Never add facts, names or ideas.
- Prefer the user's existing types, tags and threads; propose a new one only when nothing fits.
- If the transcript is garbled or ambiguous, keep the original wording and set `uncertain` to true.
- Reply in the language spoken. Chinese output is Simplified; keep English terms, names and numbers as spoken.
- Turn off thinking mode (Qwen3.5 writes out its reasoning unless the prompt pre-seeds an empty think block), use greedy decoding, constrain output to the schema where the runtime supports it, and return JSON only.

**Evaluation.** Keep an `Evals/` folder of 60 transcripts: 30 English and 30 Chinese, covering short, long, rambling, multi-topic and mixed-language thoughts. Each has a hand-made reference split. Rubric: valid JSON, faithful with no invented content, card count within one of the reference, useful titles, sensible type. Run it on every prompt, model or quantization change. The bar is at least 95% valid, 90% faithful and 80% within one card of the reference, scored separately for English and Chinese.

**Model choice.** On-device by default. The picks below come from published sources, and the Phase 0 bake-off tests them on your own recordings before anything is locked. Model names live in a remote config file, so they can change without an app release.

| Role | Pick | Why | Download | Also test |
| --- | --- | --- | --- | --- |
| Live speech to text | Apple SpeechAnalyzer | Streams, free, nothing to download; in one third-party test its Chinese error rate matched Whisper large-v3-turbo (about 8%), but its English was weaker (8.8% vs 5.5%) | None | SenseVoice Small |
| Accuracy pass after stop | WhisperKit + Whisper large-v3-turbo | Best English score of the options that can run on iPhone | 0.6 to 1.6 GB | SenseVoice Small (Chinese 7.7%, English 8.5%); Qwen3-ASR 1.7B (Chinese 6.5%, English 4.5%) but Mac-only for now |
| Splitting, 8 GB RAM iPhone | Qwen3.5-4B, 4-bit | Apache 2.0; strongest small Qwen3.5 that fits a phone | About 2.7 GB | Gemma 4 E4B (check license and Chinese quality) |
| Splitting, 6 GB RAM iPhone | Qwen3.5-2B, 4-bit | Apache 2.0; runs on iPhone through MLX Swift | About 1.3 GB | Gemma 4 E2B (check license and Chinese quality) |
| Splitting, 4 GB RAM iPhone | Apple Foundation Models if available (not in mainland China), else save raw only | No download; availability depends on device and language settings | None | None (no cloud in v1) |
| Skipped | Qwen3.5-0.8B and Phi-4-mini | The 0.8B is built for verbatim cleanup, not restructuring; Phi-4-mini's multilingual rival in the same comparison was Qwen3 |  |  |

Caveats: the speech numbers come from one vendor's test on a MacBook Air with clean read speech (character error rate for Chinese, word error rate for English), so expect higher error rates on noisy phone recordings. Sources disagree on whether Whisper large-v3-turbo fits on every recent iPhone, so test on your target devices. RAM tiers are approximate. If the 2B model misses the Gate C bar, the Apache 2.0 license allows a LoRA fine-tune on schema-style English and Chinese examples.

## Data model

Three SwiftData entities: `Recording` (raw material), `Card` (the product) and `CardType`. They must stay CloudKit-compatible: every property optional or defaulted, relationships optional, no unique constraints.

**Recording**

| Field | Type | Note |
| --- | --- | --- |
| id | UUID |  |
| createdAt | Date |  |
| source | enum | voice, text |
| rawTranscript | String | Immutable after save |
| segments | \[Segment\] | Text plus start time, for timestamps |
| audioFileName | String? | Local only; deleted after the Keep audio period (default 30 days) |
| duration | Double | Seconds; 0 for text |
| levels | \[Float\] | Waveform samples for display |
| status | enum | captured, splitting, needsReview, done, failed |
| failureCount | Int | For retry with backoff |
| processorVersion | String? | Prompt and model that made the split, so it can be re-run |

**Card**

| Field | Type | Note |
| --- | --- | --- |
| id | UUID |  |
| createdAt, updatedAt | Date |  |
| recording | Recording? | Nil for a typed card kept as one |
| startOffset | Double? | Seconds into the recording |
| title | String |  |
| body | String | Markdown subset (FR-10); `[[Card title]]` references resolve to card IDs |
| type | String | Key of a `CardType` |
| tags | \[String\] | Up to 3 suggested; users may add more |
| thread | Card? | A card whose type is thread |
| linkedCardIDs | \[UUID\] | Links the user added, outgoing only |
| archivedAt | Date? | Archive, never hard-delete, until the user deletes |
| userEditedAt | Date? | Set on any user edit |

**CardType**: key, name, isDefault, sortOrder. Defaults: thought, idea, epiphany, question, project, thread.

Backlinks are computed, not stored: a card's links are its added links, cards that link to it, cards its body names with `[[ ]]`, its thread, and the other cards from the same recording. Re-splitting a recording never overwrites a card with `userEditedAt` set without confirmation.

## Phased roadmap

The build runs in six phases, about eight to eleven weeks in total. The agent stops at every gate and waits for your review before starting the next phase.

_Roadmap: 6 phases, 6 gates (diagram in the original doc)._

Each gate is a test you run yourself on a physical iPhone; a phase is not done until its gate passes.

**Phase 0 · Foundations and bake-offs**

- [ ] Create the Xcode project, five local packages (DesignSystem, CaptureKit, IntelligenceKit, Persistence, ModelStore), and CI that builds and runs tests
- [ ] DesignSystem tokens from the prototype: colors, type scale, spacing, radii, spring presets, haptic presets
- [ ] Record the test set on a real iPhone: 30 English and 30 Mandarin spoken streams, including multi-topic and mixed-language ones, with hand-corrected transcripts and hand-made reference splits
- [ ] Spike 1: an App Intent bound to the Action Button that opens straight into recording; measure press-to-recording cold and warm
- [ ] Bake-off 1 (speech): Apple SpeechAnalyzer, WhisperKit with large-v3-turbo, and SenseVoice Small on the test set; report error rate, latency and memory per language on the oldest target iPhone, and check Mandarin on a mainland China device
- [ ] Bake-off 2 (splitting): Qwen3.5-2B, Qwen3.5-4B and Apple Foundation Models scored with the Evals rubric in English and Chinese; test Gemma 4 E2B and E4B only if their license allows commercial use
- [ ] Spike 2: run the winning model through MLX Swift on device; record load time, tokens per second, peak memory, and whether the increased-memory-limit entitlement is needed; test the model download from mainland China
- [ ] Write `docs/spike-report.md` with a pick and a go/no-go for each

**Phase 1 · Capture MVP (FR-1 to FR-6, FR-18)**

- [ ] `Recording`, `Card` and `CardType` entities and the SwiftData store, raw fields first
- [ ] Capture screen: live waveform, timestamped transcript, stop controls, haptics
- [ ] Capture App Intent and Control Center control
- [ ] Languages: English and Chinese UI, Mandarin output in Simplified, mixed sentences
- [ ] Save before anything else, with a force-quit test
- [ ] Cards feed, side drawer, docked Record and Type bar, typed capture with the split-or-keep prompt
- [ ] XCUITest for the capture flow

**Phase 2 · On-device splitting and review (FR-7, FR-8, FR-9, FR-18, FR-19)**

- [ ] `CardSplitter` protocol, schema validation, transcript check, status states
- [ ] ModelStore: download after install, resume, checksum, delete, Wi-Fi only by default, download source by region
- [ ] On-device splitter using the Qwen model for the device's RAM tier, thinking mode off, greedy decoding
- [ ] Fallbacks: Apple Foundation Models where available, raw-only when no model is available
- [ ] Retry with backoff and the failed state
- [ ] Split review screen: edit, merge, split, drop, re-sort, Later
- [ ] Card page: headline, type and tag pills, note, separate collapsed sections, ⋯ menu
- [ ] `Evals/` runner with reference splits; pass Gate C, and fine-tune with LoRA only if the bar is missed

**Phase 3 · Organize, links and editing (FR-10 to FR-15)**

- [ ] Rich-text editor: formatting bar above the keyboard, Markdown shortcuts, Markdown round-trip tests
- [ ] Types and tags: defaults, user-created, Organize with counts, filtered lists
- [ ] Threads: suggestions, thread cards, long-thread archive hint
- [ ] Links: bi-directional, same-recording siblings, `[[ ]]` references, link picker
- [ ] Full-text search including Chinese without spaces; archive, restore and the stale-card suggestion
- [ ] Recordings list, recording page and calendar heat map
- [ ] Motion, haptics, accessibility pass (Reduce Motion, Dynamic Type, VoiceOver) and frame-rate profiling

**Phase 4 · Sync and export (FR-16, FR-17)**

- [ ] CloudKit sync, tested across two devices, including links and custom types
- [ ] Share a card or thread as Markdown and plain text
- [ ] Lock Screen control and Settings (language, appearance, auto-stop, keep audio, model, licenses)

**Phase 5 · App Store launch (FR-20)**

- [ ] Privacy nutrition label and privacy manifest that match what the app actually does
- [ ] Microphone and speech usage strings; App Store Connect review notes that explain the Action Button flow and the on-device AI
- [ ] Open-source license screen with the Apache 2.0, MIT and SIL OFL notices
- [ ] Mainland China: app filing number from MIIT in App Store Connect, model mirror live, and a lawyer's check of the rules for on-device generative AI
- [ ] App icon, screenshots, and listing text in English and Chinese
- [ ] TestFlight external beta with a seven-day daily-use fix list
- [ ] Submit for App Review; fix and resubmit until approved

**After v1:** daily resurfacing of old cards, a weekly review, Enhanced (cloud) mode, export to Notion, a Share extension, Apple Watch, Cantonese and Traditional Chinese.

## Agent execution rules

The coding agent works in small, reviewable steps, and every phase ends with a build you can run on your phone. Export this doc as Markdown and save it in the repo root as `PRD.md`.

The interactive prototype in `docs/prototype/index.html` shows every screen. Build to match its layout and behavior; where it and this doc disagree, this doc wins.

- At the start of every session, read `PRD.md` and `AGENTS.md` (or `CLAUDE.md`). Update `AGENTS.md` whenever a decision changes.
- One phase at a time. Do not start phase N+1 until phase N's exit criteria are checked off in `docs/progress.md`.
- One task per branch or PR: small diff, tests, and a short note on what changed and how it was verified. Cite requirement IDs (FR-1 to FR-20).
- Definition of done: builds with zero warnings, unit tests pass, the capture-flow XCUITest passes, and anything involving the Action Button, microphone or haptics is verified on a physical iPhone (the simulator cannot).
- Ask before adding a dependency, changing the data model after Phase 1, or deviating from this spec.
- Never commit API keys, send audio off the device, or add analytics.

**Kickoff prompt** for Codex or Claude Code:

```text
You are building "Inspiration Inbox", a minimalist iOS app for the App Store (Swift 6, SwiftUI, iOS 26, iPhone only, English and Mandarin Chinese, Simplified).
Read PRD.md fully and open docs/prototype/index.html, then create AGENTS.md summarizing the "Tech stack and architecture constraints" and "Agent execution rules" sections.
Start Phase 0 only: scaffold the Xcode project with local Swift packages (DesignSystem, CaptureKit, IntelligenceKit, Persistence, ModelStore), set up CI, and run the Action Button spike plus the speech and splitting bake-offs on my recorded English and Chinese test set.
Write findings to docs/spike-report.md with a pick and a go/no-go for each, then stop and wait for my review before Phase 1.
```

## Risks and open questions

The two biggest risks are getting from an Action Button press into live recording fast enough, and splitting a rambling recording into the right cards on a phone. Phase 0 tests both first.

**Decided for v1** (Nov 2026): Chinese means Mandarin only, with Simplified output. The app ships in the mainland China storefront. No Enhanced (cloud) mode. Free.

**Risks and fallbacks**

- **Slow launch** (over 1.5 s cold): switch to an audio-recording intent with a Live Activity, or keep the app warm.
- **Bad splits:** nothing is saved as cards without a review; merge and split are one tap; the eval set has reference splits; fine-tune with LoRA if the 2B model misses the bar.
- **Weak transcription** on accents, mixed Chinese and English, or noise: keep the audio so the accuracy pass can re-transcribe it, and keep the transcript readable on the Recordings page.
- **Script mix-ups in Chinese:** some Whisper variants return Traditional characters. Convert to Simplified and test it.
- **Mainland China:** Hugging Face is not reliably reachable there, so models need a mirror reachable from China, with the same checksums. Apple Foundation Models is not available there, so Qwen is the only splitter. An app filing number from MIIT is needed before release, and the rules for generative AI may apply even on device; check both with a lawyer.
- **Memory limits:** a 4B model plus the app may hit iOS memory limits on some devices. Test on the oldest 8 GB iPhone, request the increased-memory-limit entitlement, and fall back to the 2B model.
- **Large downloads:** models run from about 1.3 to 2.7 GB for splitting, plus 0.6 to 1.6 GB if the accuracy pass ships. Capture must work before they finish, and downloads default to Wi-Fi only.
- **AI over-editing** (invented or dropped content): the faithfulness rule, the transcript check, the raw transcript on the Recordings page, and the eval set.
- **Rich-text editor scope:** editors are a known time sink. Limit it to the formatting bar's set and a Markdown subset, and fall back to UITextView if the SwiftUI editor falls short.
- **Feature creep:** a new feature must remove a step for the user, or it is cut.

**Open questions**

- Store notes as a Markdown subset (recommended: simple export, sync and search) or as an archived AttributedString?
- Keep audio for 30 days by default, or default to Off?
- Bundle Figtree (SIL OFL) to match the prototype, or use SF Pro to match the platform?
- Where is the remote config file (model names, mirror URLs) hosted so it is reachable inside and outside mainland China?

## Sources

Checked October 31, 2026. The first two pages were opened and read; the rest were read as search results only, so check them before relying on them.

- [Whisper Notes: speech models compared by language](https://whispernotes.app/whisper-models): error rates and download sizes; one vendor's test on a MacBook Air with clean read speech
- [Quobi/Quill model card on Hugging Face](https://huggingface.co/quobi/quill): Qwen3.5 Apache 2.0 license, 4-bit file sizes, thinking-mode setting
- [Qwen3.5 small models on iPhone](https://letsdatascience.com/blog/a-9b-model-on-your-phone-just-beat-a-120b-cloud-model): release date, sizes, MLX Swift on iPhone
- [iOS speech SDKs compared](https://www.forasoft.com/blog/article/speech-recognition-with-neural-networks-on-ios-1621): WhisperKit and SpeechAnalyzer
- [Running LLMs on iPhone by RAM tier](https://dev.to/alichherawalla/how-to-run-llms-locally-on-your-iphone-in-2026-completely-offline-no-subscription-4b3a): approximate RAM tiers
- [TechCrunch on App Review guideline 5.1.2(i)](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai): third-party AI consent rule
