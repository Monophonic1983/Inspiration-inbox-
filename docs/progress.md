# Progress

Do not start phase N+1 until phase N's exit criteria are checked off here and its gate passed on a physical iPhone.

## Phase 0 · Foundations and bake-offs
- [x] Five local packages scaffolded (DesignSystem, CaptureKit, IntelligenceKit, Persistence, ModelStore) — not yet compiled
- [x] DesignSystem tokens: colors, type scale, spacing, spring presets, haptic presets
- [x] Evals/ folder and rubric README
- [x] CI workflow (macOS, `swift test` per package)
- [ ] Xcode project (needs Xcode on a Mac: app target, Action Button App Intent, WidgetKit control extension)
- [ ] Record test set on a real iPhone: 30 EN + 30 ZH, incl. mixed, hand-corrected transcripts
- [ ] Spike 1: Action Button intent opens into recording; measure press-to-recording cold and warm
- [ ] Bake-off 1 (speech): SpeechAnalyzer vs WhisperKit large-v3-turbo vs SenseVoice Small
- [ ] Bake-off 2 (structuring): Qwen3.5-2B, Qwen3.5-4B, Apple Foundation Models
- [ ] Spike 2: winning model via MLX Swift on device (load time, tok/s, peak memory, memory entitlement)
- [ ] docs/spike-report.md with pick and go/no-go for each
