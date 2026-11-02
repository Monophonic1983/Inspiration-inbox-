#!/usr/bin/env python3
"""Scores saved model outputs against the cases. Mirrors EvalScorer in IntelligenceKit (keep the two in sync).
usage: score.py outputs.jsonl   (lines: {"id": "en-01", "output": {...schema JSON...} | null})"""
import json, re, sys, pathlib, collections
KINDS = {"idea", "task", "question", "reminder", "quote", "journal"}
STOP = {"a", "an", "the", "to", "of", "and", "or", "for", "in", "on", "with", "is", "it"}
root = pathlib.Path(__file__).parent
cases = {c["id"]: c for lang in ("en", "zh") for c in map(json.loads, (root / f"{lang}.jsonl").read_text().splitlines())}

def tokens(s): return re.findall(r"[a-z0-9]+", s.lower())
def valid(o):
    return (isinstance(o, dict) and str(o.get("title", "")).strip() and str(o.get("cleaned_text", "")).strip()
            and o.get("kind") in KINDS and isinstance(o.get("tags"), list) and isinstance(o.get("action_items"), list))
def faithful(o, transcript):
    src = transcript.lower()
    produced = [o["cleaned_text"], o.get("summary", ""), o["title"], *o["action_items"], *o["tags"]]
    return all(t in STOP or t in src or (len(t) > 4 and t[:-1] in src) for p in produced for t in tokens(str(p)))

stats = collections.defaultdict(lambda: collections.Counter())
for line in pathlib.Path(sys.argv[1]).read_text().splitlines():
    if not line.strip(): continue
    r = json.loads(line); c = cases[r["id"]]; o = r.get("output"); s = stats[c["language"]]
    s["n"] += 1
    if valid(o):
        s["valid"] += 1
        s["faithful"] += faithful(o, c["transcript"])
        s["kind"] += o["kind"] == c["expected_kind"]
failed = False
for lang, s in sorted(stats.items()):
    v, f = s["valid"] / s["n"], s["faithful"] / s["n"]
    passed = v >= 0.95 and f >= 0.90
    failed |= not passed
    print(f"{lang}: n={s['n']} valid={v:.0%} faithful={f:.0%} kind={s['kind']/s['n']:.0%}  Gate C: {'PASS' if passed else 'FAIL'}")
sys.exit(1 if failed else 0)
