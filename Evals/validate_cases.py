#!/usr/bin/env python3
"""Checks the case files: 30 per language, 6 per category, unique ids, valid kinds."""
import json, pathlib, collections, sys
KINDS = {"idea", "task", "question", "reminder", "quote", "journal"}
CATS = {"short", "long", "rambling", "multi-topic", "mixed"}
root = pathlib.Path(__file__).parent
ok = True
for lang in ("en", "zh"):
    cases = [json.loads(l) for l in (root / f"{lang}.jsonl").read_text().splitlines() if l.strip()]
    ids = [c["id"] for c in cases]
    per_cat = collections.Counter(c["category"] for c in cases)
    problems = []
    if len(cases) != 30: problems.append(f"{len(cases)} cases, expected 30")
    if len(set(ids)) != len(ids): problems.append("duplicate ids")
    if any(c["expected_kind"] not in KINDS for c in cases): problems.append("bad kind")
    if set(per_cat) != CATS or any(n != 6 for n in per_cat.values()): problems.append(f"categories {dict(per_cat)}")
    print(lang, "OK" if not problems else problems)
    ok &= not problems
sys.exit(0 if ok else 1)
