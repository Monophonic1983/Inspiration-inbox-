# Evals

60 transcripts: 30 English (`en/`) and 30 Chinese (`zh/`), each set covering short, long, rambling, multi-topic and mixed-language thoughts (Chinese with English terms and names).

Each case is `<id>.json`: `{ "transcript": "...", "expected_kind": "idea|task|question|reminder|quote|journal", "notes": "" }`.

Rubric: valid JSON, faithful (no invented content), useful title, correct kind.
Bar: at least 95% valid and 90% faithful, scored separately for English and Chinese.
Run on every prompt, model or quantization change. The runner arrives in Phase 2.
