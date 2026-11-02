# AGENTS.md — Inspiration Inbox

Native iPhone app (Swift 6, SwiftUI, iOS 26, English + Chinese): speak via the Action Button, review the one-thought cards the app splits it into. Source of truth: the PRD & Roadmap doc (https://claude.ai/artifact/LeEeKJeLggGHFDgtvZaQkX). Exported to `PRD.md` in the repo root. The prototype in `docs/prototype/index.html` shows every screen; where it and the PRD differ, the PRD wins.

## Rules
- Read PRD.md and this file at the start of every session. Update this file when a decision changes.
- One phase at a time; see docs/progress.md. Stop at each gate for the owner's review.
- One task per branch/PR, small diff, tests, note on how verified. Cite requirement IDs (FR-1…FR-20, renumbered Nov 2 2026).
- Done = zero warnings, unit tests pass, capture-flow XCUITest passes, and Action Button / microphone / haptics verified on a physical iPhone.
- Ask before adding a dependency, changing the data model after Phase 1, or deviating from the spec.
- Never commit API keys, send audio off device, or add analytics.

## Architecture
- Local packages in `Packages/`: DesignSystem, CaptureKit, IntelligenceKit, Persistence, ModelStore. App target stays thin.
- Capture and saving work with no network, no AI, no model downloaded. Raw transcript saves before any AI step.
- All AI on device (Qwen3.5 via MLX Swift; Apple Foundation Models where available, not in mainland China). No cloud AI and no backend in v1.
- AI output is validated against the JSON schema (`SchemaValidator`); invalid output falls back to one card holding the raw transcript.
- Models are never bundled; ModelStore downloads with checksum, resume, delete. Model names and download mirrors (one reachable from mainland China) come from remote config.
- Only dependencies beyond Apple frameworks: WhisperKit and the model runtime.

## Repo map
- `App/Sources` app target (Screens, Components, Services, Resources); `App/Shared` intent shared with `App/ControlsExtension`.
- `Packages/*` logic with tests; MLX and WhisperKit live only in the app target (`#if canImport`) so packages stay light.
- `backend/` Enhanced-mode proxy (Cloudflare Worker, `npm test`), parked: Enhanced mode is after v1. `Evals/` cases + scorers. `docs/` gates, spike report, store material.
- `project.yml` is the source of truth for the Xcode project (XcodeGen); do not commit the generated `.xcodeproj`.

## Decisions (update when they change)
- Written before a Mac was available: nothing has been compiled. Start with docs/mac-setup.md.
- v1 scope: English + Mandarin (Simplified output only), ships in the mainland China storefront, no Enhanced (cloud) mode, free.
- Data model is `Recording` + `Card` + `CardType` (PRD, Nov 2026). The Swift code still uses the older single `Thought` model and the old FR numbers; port it before Phase 1 work.
- Accuracy pass improves the text given to the structuring model; the stored raw transcript is immutable.
- Recordings are raw material, cards are the product: voice recordings are always split and reviewed; typed text asks split-or-keep.
