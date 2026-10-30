# App Store checklist (FR-16)

- [ ] Privacy nutrition label matches `PrivacyInfo.xcprivacy`: Enhanced mode sends "Other User Content" (not linked, not tracking, app functionality); everything else is on-device.
- [ ] Microphone and speech usage strings are final (in `project.yml`).
- [ ] Review notes pasted from `docs/app-review-notes.md`; privacy policy hosted and linked.
- [ ] `LicensesView` lists every model and library; add the full Apache-2.0 and MIT texts under `App/Sources/Resources/Licenses/` and link them. Include the Qwen model's own licence text from its repository.
- [ ] App icon replaced with final art (`AppIcon.appiconset` holds a placeholder orb).
- [ ] Screenshots in English and Chinese (6.9" and 6.3").
- [ ] Listing text reviewed by a native Chinese speaker (`docs/listing/`, `Localizable.xcstrings`; Traditional strings are machine-converted).
- [ ] Mainland China storefront decision made (filing requirements; see PRD open questions).
- [ ] Pricing decided (affects Enhanced mode running cost).
