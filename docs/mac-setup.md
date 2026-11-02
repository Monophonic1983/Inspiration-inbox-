# When the Mac arrives

Everything in this repo was written without a compiler. Expect a first pass of compile errors, mostly in the iOS 26 / MLX Swift / WhisperKit API calls flagged in comments. Fix them in this order.

## 1. Generate the project and get green
1. Install Xcode 26 and `brew install xcodegen`.
2. In `project.yml` set `DEVELOPMENT_TEAM` and change `com.example` to your bundle id prefix. Update the same id in `App/Sources/Resources/InspirationInbox.entitlements`, `App/Sources/Services/AppConfig.swift` and `App/ControlsExtension/CaptureControl.swift`.
3. `xcodegen generate && open InspirationInbox.xcodeproj`.
4. Test each package first (`cd Packages/Persistence && xcodebuild test -scheme Persistence -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`), in this order: DesignSystem, Persistence, ModelStore, IntelligenceKit, CaptureKit. Then the app target and the capture-flow UI test.
5. Known API risks to check against the SDK docs: `SpeechAnalyzer` / `SpeechTranscriber` / `AssetInventory` (AppleSpeechTranscriber.swift), `MLXLMCommon.generate` and `UserInput` (MLXRunner.swift), `WhisperKitConfig` (WhisperAccuracyPass.swift), `FoundationModels` session API (Processors.swift), `onScrollGeometryChange` (InboxView.swift). The MLX product names (`MLXLLM`, `MLXLMCommon`) and versions in `project.yml` need confirming; pin exact versions.
6. Zero warnings is part of "done": CI builds with warnings as errors.

## 2. Phase 0 on a physical iPhone (see docs/gate-tests.md, Gate A)
- Record the 60 test thoughts and hand-correct the transcripts; add them to `Evals/`.
- Spike 1: map the Action Button to **Capture Thought**, measure press-to-recording cold and warm. If cold is over 1.5 s, try an audio-recording intent with a Live Activity, or keep the app warm.
- Bake-off 1 and 2, Spike 2: fill in `docs/spike-report.md`.
- Pick the winning models, then fill `files` (url, sha256, sizeBytes) for them in `Packages/ModelStore/Sources/ModelStore/catalog.json`. Get hashes with `shasum -a 256`. The model prompt card and Settings rows stay hidden until `files` is non-empty.
- If the 4B model needs it, keep the increased-memory-limit entitlement; otherwise remove it.

## 3. Decisions the PRD left open (defaults chosen; change if wrong)
- Cloud provider named on the consent screen: **Anthropic** (`AppConfig.cloudProviderName`), via the proxy in `backend/`.
- Chinese defaults to Simplified unless the device language is Traditional; output script is a Settings toggle.
- "Private mode" = never keep audio and never use Enhanced mode.
- Whisper accuracy pass feeds the structuring model a better transcript; the stored raw transcript is never changed.
- `Thought` gained `userEditedAt` and `failureCount` (so re-processing can protect edits). Done before Phase 1 ships, so no migration.
