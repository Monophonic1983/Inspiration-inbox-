# Interactive prototype (v10)

`index.html` is a single-file HTML prototype of the current design. Open it in Safari on an iPhone (or any browser at phone width). It needs no build and no network access, except Google Fonts.

Live version: https://claude.ai/artifact/52R4Bx5y2KFcNeujLyoPqc

## How it differs from PRD.md

The prototype went through 10 rounds of owner feedback. Where it differs from `PRD.md`, the prototype reflects the newer decisions. These have not yet been written into the PRD or the Swift code:

- **Cards, not notes.** A recording is raw material. The system splits it into one-thought cards and the user reviews the split. Typed text asks before splitting. Typed cards show no waveform.
- **Types and tags grow naturally.** Default types are thought, idea, epiphany, question, project and thread. Users add their own. Empty tags are hidden.
- **Threads are cards of type "thread".** The system suggests threads. Once a thread has more than 12 cards, it suggests archiving the older ones.
- **Links are bi-directional.** A card links to the other cards from the same recording and to its thread. Users add explicit links, and `[[Card title]]` in the body also creates one.
- **Rich-text editing.** There is a formatting bar (bold, italic, underline, strikethrough, heading, bullet and numbered lists, checkbox, quote, card link) plus markdown shortcuts. This reverses the PRD's "no rich-text editing" non-goal.
- **Navigation.** A side drawer holds Cards, Organize (types and tags with counts), Calendar, Recordings and Settings. Archive and search are included. Record and Type sit in a bar docked at the bottom.
- **Card page hierarchy.** Headline first, then type and tags, then the note. Thread, Same recording, Links and Recording follow as separate, collapsed sections.
- **v1 scope decisions.** Mandarin and Simplified Chinese only (with an English UI and English samples). Ships in the mainland China storefront. No Enhanced (cloud) mode. Free.
- **Look.** Spotify-inspired: black or white background, purple accent, 8px corners, Figtree font, light/dark/system themes, English and Chinese.
