# Spike report (Phase 0 deliverable)

Fill this in on a Mac with a physical iPhone. Pick and go/no-go for each section. Nothing here is measured yet.

Test devices: _oldest target iPhone (model, RAM, iOS)_ · _newest iPhone_

## Spike 1: Action Button to recording
| Case | Press to recording (s) | Notes |
| --- | --- | --- |
| Warm | | |
| Cold | | |
| Control Center | | |
| Lock Screen | | |

Go / no-go: ___ · If cold > 1.5 s: ___

## Bake-off 1: speech (error rate on the 60 recorded thoughts)
| Engine | English WER | Mandarin CER | Mixed CER | Latency | Peak memory |
| --- | --- | --- | --- | --- | --- |
| Apple SpeechAnalyzer | | | | | |
| WhisperKit large-v3-turbo | | | | | |
| SenseVoice Small | | | | | |

Pick (live): ___ · Pick (accuracy pass, or none): ___ · Go / no-go: ___

## Bake-off 2: structuring (`Evals/` rubric)
| Model | EN valid | EN faithful | ZH valid | ZH faithful | p50 / p95 saved-to-structured |
| --- | --- | --- | --- | --- | --- |
| Qwen3.5-2B 4-bit | | | | | |
| Qwen3.5-4B 4-bit | | | | | |
| Apple Foundation Models | | | | | |
| Gemma 4 E2B / E4B (only if licence allows commercial use) | | | | | |

Pick per RAM tier: ___ · Go / no-go: ___ · LoRA needed? ___

## Spike 2: MLX Swift on device
| Model | Load time | Tokens/s | Peak memory | Needs increased-memory-limit? |
| --- | --- | --- | --- | --- |
| | | | | |

Go / no-go (fall back to llama.cpp?): ___
