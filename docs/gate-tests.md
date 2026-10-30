# Gate tests

You run these yourself on a physical iPhone. A phase is not done until its gate passes. Record results in `docs/progress.md`.

## Gate A: Phase 0
- [ ] Spike report has a pick and go/no-go for speech, structuring and runtime.
- [ ] Press-to-recording measured cold and warm on the oldest target iPhone.
- [ ] 60 recorded, hand-corrected transcripts are in `Evals/`.

## Gate B: Phase 1 capture MVP
- [ ] Action Button, Control Center and Lock Screen control each start recording with no further tap (FR-1). Warm start ≤ 1.0 s.
- [ ] Airplane mode: words appear as you speak (FR-2).
- [ ] Stop by tap, by hold-release, and by 2.5 s of silence (FR-3).
- [ ] Force-quit mid-sentence: relaunch recovers a thought (FR-4). Stop-to-saved ≤ 300 ms.
- [ ] Type a thought; it appears in the Inbox like a voice one (FR-5, FR-6).
- [ ] Speak English, Mandarin, and a mixed sentence; Simplified and Traditional settings both produce the right script (FR-13).
- [ ] Capture works with no network, no model downloaded.

## Gate C: Phase 2 on-device AI
- [ ] `Evals/` passes: ≥ 95% valid and ≥ 90% faithful, English and Chinese scored separately. Hand-check 10 outputs for invented content.
- [ ] Saved-to-structured p50 ≤ 4 s, p95 ≤ 10 s on the oldest target iPhone.
- [ ] Airplane mode: a thought still gets structured with the model downloaded (FR-8).
- [ ] Model download shows progress, survives killing the app, resumes, verifies the checksum, and deletes from Settings (FR-14). Capture works during the download.
- [ ] Raw chip shows original words; inline edits stick; "Structure again" asks before replacing edits (FR-7).
- [ ] Peak memory is safe on the 8 GB and 6 GB tiers.

## Gate D: Phase 3 interaction polish
- [ ] Crystallize transition is smooth at 120 fps on a ProMotion iPhone (Instruments). Reduce Motion gives a cross-fade.
- [ ] Swipe, long-press, pull-down-to-capture all work, each with a haptic and an undo (FR-9).
- [ ] Search finds Chinese written without spaces, and across Simplified/Traditional (FR-10).
- [ ] VoiceOver reads every control; Dynamic Type works through AX5; touch targets ≥ 44 pt.

## Gate E: Phase 4 sync and Enhanced mode
- [ ] A thought appears on a second device within 30 s; last edit wins (FR-11).
- [ ] Markdown and plain-text share sheet works (FR-12).
- [ ] With Enhanced mode off, a proxy log shows zero requests. After consent, one request per thought, text only (FR-15).
- [ ] App Attest verification is implemented in `backend/src/attest.ts` and a tampered request is refused.

## Gate F: Phase 5 App Store
- [ ] Privacy label matches `PrivacyInfo.xcprivacy` and the real behaviour (FR-16).
- [ ] Licence screen lists every notice; full texts are bundled.
- [ ] Seven days of daily use in TestFlight with an empty fix list.
- [ ] App Review approves.
