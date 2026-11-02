# Interactive prototype (v10)

`index.html` is a single-file HTML prototype of every screen. Open it in Safari on an iPhone (or any browser at phone width). It needs no build and no network access, except Google Fonts.

Live version: https://claude.ai/artifact/52R4Bx5y2KFcNeujLyoPqc

`PRD.md` was updated on Nov 2, 2026 to match this prototype: the card model, split review, types and tags, threads, links, rich-text editing, Organize, the card page layout, the visual language, and the v1 decisions (Mandarin and Simplified only, mainland China storefront, no Enhanced mode, free). Build to match the prototype's layout and behavior; where the two disagree, the PRD wins.

Prototype-only details the PRD leaves open:

- Fonts: the prototype uses Figtree, Noto Sans SC and IBM Plex Mono from Google Fonts. The iOS font is an open question in the PRD.
- Notes are stored as sanitized HTML in the prototype. The PRD recommends a Markdown subset for the app.
- Splitting, model download and transcription are simulated with seeded sample data in English and Chinese.
