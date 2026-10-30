# Progress

Do not start phase N+1 until phase N's exit criteria are checked off here and its gate (docs/gate-tests.md) passed on a physical iPhone.

**Status:** all code for Phases 0–5 is written but has never been compiled or run (no Mac yet). The first job on the Mac is `docs/mac-setup.md`. Checked boxes below mean "written", not "verified". Verification items are the Gate lists.

## Phase 0 · Foundations and bake-offs
- [x] Five local packages, CI workflow, XcodeGen `project.yml` (written)
- [x] DesignSystem tokens: colors, type scale, spacing, spring presets, haptic presets
- [x] Evals folder with 60 synthetic starter cases, scorer (Swift + Python)
- [ ] Generate Xcode project and get everything green (docs/mac-setup.md)
- [ ] Record test set on a real iPhone: 30 EN + 30 ZH incl. mixed, hand-corrected
- [ ] Spike 1: Action Button → recording, cold/warm timing
- [ ] Bake-off 1 (speech) and Bake-off 2 (structuring)
- [ ] Spike 2: MLX Swift on device
- [ ] docs/spike-report.md filled in (template is there)

## Phase 1 · Capture MVP (FR-1…FR-6, FR-13)
- [x] Thought entity + SwiftData store (Persistence)
- [x] Capture screen: orb, live transcript, stop controls, haptics
- [x] Capture App Intent + Control Center/Lock Screen control
- [x] Language handling (device language, mixed speech, Simplified/Traditional)
- [x] Save-first with draft recovery after force-quit
- [x] Inbox list + text-capture fallback
- [x] XCUITest for the capture flow (fake audio/speech)
- [ ] Gate B on device

## Phase 2 · On-device AI (FR-7, FR-8, FR-13, FR-14)
- [x] ThoughtProcessor, schema validation, status states, retry with backoff
- [x] ModelStore: download, resume, checksum, delete, Wi-Fi only
- [x] On-device processor (MLX), Apple Foundation Models fallback, raw-only fallback
- [x] Thought detail with Raw toggle, inline editing, edit-safe re-processing
- [x] Evals runner + scorer
- [ ] Model catalog `files` filled in from bake-off; Gate C on device

## Phase 3 · Interaction polish (FR-9, FR-10)
- [x] Crystallize transition, shimmer, orb tied to audio level
- [x] Swipe, long-press, pull-down-to-capture, undo
- [x] Full-text search incl. Chinese without spaces and cross-script
- [x] Accessibility hooks (Reduce Motion, Dynamic Type, VoiceOver labels, 44 pt targets)
- [ ] Gate D: accessibility pass and 120 fps profiling on device

## Phase 4 · Sync and Enhanced mode (FR-11, FR-12, FR-15)
- [x] CloudKit-ready container (falls back to local without iCloud)
- [x] Markdown / plain-text export
- [x] Consent screen, proxy (`backend/`, 5 tests pass), cloud processor, no-call-before-consent tests
- [x] Settings sheet: auto-stop, private mode, audio retention, model downloads
- [ ] App Attest verification in `backend/src/attest.ts` (refuses all requests until done)
- [ ] Gate E: two-device sync test, proxy log check

## Phase 5 · App Store launch (FR-16)
- [x] Privacy manifest, usage strings, licence screen, review notes, listing EN + 简体, privacy policy draft
- [ ] Final icon, screenshots, full licence texts, native-speaker review of Chinese strings
- [ ] TestFlight beta, App Review (docs/testflight-plan.md)
