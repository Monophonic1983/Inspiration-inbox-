# Evals

60 transcripts: 30 English (`en.jsonl`) and 30 Chinese (`zh.jsonl`). Each set has six cases in each of five categories: short, long, rambling, multi-topic and mixed (Chinese with English terms and names; English with foreign names and phrases).

These are **synthetic starter cases**. In Phase 0 you also record real thoughts on a physical iPhone, hand-correct the transcripts, and add them here. A synthetic set tests the model; only recorded speech tests the whole pipeline.

Each line: `{ "id", "language", "category", "transcript", "expected_kind" }`.

Rubric: valid JSON, faithful (no invented content), useful title, correct kind.
Bar (Gate C): at least 95% valid and 90% faithful, scored separately for English and Chinese.

## Running

- **On device (the real test):** a DEBUG-only "Run evals" action is the next step after the Mac arrives. `EvalRunner` in IntelligenceKit runs any `ThoughtProcessor` over these files, and `EvalScorer` writes the summary.
- **Offline scoring of saved outputs:** `python3 Evals/score.py outputs.jsonl` where each line is `{ "id", "output": <model JSON or null> }`.
- **Check the case files:** `python3 Evals/validate_cases.py`.

The automatic faithfulness check only catches invented names, numbers and Latin words. Spot-check a sample by hand before passing Gate C.
