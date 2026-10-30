# AGENTS.md — Inspiration Inbox

Native iPhone app (Swift 6, SwiftUI, iOS 26, English + Chinese): speak a thought via the Action Button, get a structured note in the Inbox. Source of truth: the PRD & Roadmap doc (https://claude.ai/artifact/LeEeKJeLggGHFDgtvZaQkX). Export it as `PRD.md` in the repo root (pending).

## Rules
- Read PRD.md and this file at the start of every session. Update this file when a decision changes.
- One phase at a time; see docs/progress.md. Stop at each gate for the owner's review.
- One task per branch/PR, small diff, tests, note on how verified. Cite requirement IDs (FR-1…FR-16).
- Done = zero warnings, unit tests pass, capture-flow XCUITest passes, and Action Button / microphone / haptics verified on a physical iPhone.
- Ask before adding a dependency, changing the data model after Phase 1, or deviating from the spec.
- Never commit API keys, send audio off device, or add analytics.

## Architecture
- Local packages in `Packages/`: DesignSystem, CaptureKit, IntelligenceKit, Persistence, ModelStore. App target stays thin.
- Capture and saving work with no network, no AI, no model downloaded. Raw transcript saves before any AI step.
- On-device AI by default (Qwen3.5 via MLX Swift; Apple Foundation Models baseline). Cloud is opt-in Enhanced mode behind a consent screen.
- AI output is validated against the JSON schema (`SchemaValidator`); invalid output falls back to raw text.
- Models are never bundled; ModelStore downloads with checksum, resume, delete. Model names come from remote config.
- Only dependencies beyond Apple frameworks: WhisperKit and the model runtime.
