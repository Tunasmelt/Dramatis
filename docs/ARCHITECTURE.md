---
doc: ARCHITECTURE
last_verified_commit: e543be0
last_updated: 2026-11-05
owner: Harris Shamsi
status: draft
---

# ARCHITECTURE — Dramatis

## 1. Shape

A local, file-based batch pipeline driven by a Typer CLI. No server, no database. Each stage reads files and writes files; a run manifest records stage state. Cloud calls: annotation LLM, Groq Whisper, Langfuse. Everything else is local.

```
PDF ─► ingest ─► annotate ─► synth ─► check ─► transcribe ─► assemble ─► eval ─► build-site
       text.json  roster.json  audio/    scores.json  transcripts.json  chapter.wav   report.json  static site
                  lines.json   synth.json                               timing.json   + ratings.csv
```

`synth` renders three arms per line (Chatterbox controlled, Chatterbox neutral, Kokoro neutral). `check` and `transcribe` run on all arms. Stage order matters for VRAM: `synth` frees the GPU before `check` loads emotion2vec. One local model resident at a time.

*Plain language:* each stage is a small program that reads the previous stage's files and writes its own, so any stage can be rerun alone.

## 2. Components

| ID | Component | Responsibility | Runs | Key deps |
|---|---|---|---|---|
| COMP-01 | CLI & orchestrator | Typer commands, stage sequencing, run manifest, `assemble` stage, calling the Chatterbox venv as a subprocess over files | local | typer, pydantic |
| COMP-02 | Ingest | Text-layer PDF → clean text, paragraphs, dialogue boundaries; rejects scanned/oversize/malformed PDFs; corpus PDF builder script | local | pypdf or pdfminer.six |
| COMP-03 | Annotator | Pass 1 roster; pass 2 segmentation (≤250 chars, speaker, emotion, intensity); schema + verbatim validation; one retry; neutral-narrator fallback | cloud LLM | swappable `LLMClient` |
| COMP-04 | Voice library | ≤8 profiles `{id, kokoro_voice, reference_clip, description}`; reference clips generated from Kokoro; `VOICES.md` provenance | local files | — |
| COMP-05 | Synthesis | Chatterbox (controlled + neutral arms, own venv) and Kokoro (secondary baseline); `config/emotion_map.toml`; records peak VRAM and time | local GPU | chatterbox (torch 2.6.0), kokoro |
| COMP-06 | Cache & manifest | Content-hash cache for segment audio; stage state in `run.json`; idempotent resume | local files | — |
| COMP-07 | Emotion checker | emotion2vec+ large at 16 kHz; maps 9 outputs to 7 labels; `other`/`unknown` = miss | local | funasr / modelscope |
| COMP-08 | Transcription gate | Groq Whisper (whisper-large-v3-turbo) → transcript, WER vs original text, word timestamps; faster-whisper small on CPU as fallback | cloud / local | httpx, jiwer, faster-whisper |
| COMP-09 | Eval | Per-arm per-emotion agreement, Wilson intervals, chance level, kappa vs human ratings, WER summary; blind rating tool | local | — |
| COMP-10 | Tracing | Langfuse spans for LLM calls, TTS jobs, scores; flush at CLI exit; local `spans.jsonl` | cloud | langfuse SDK |
| COMP-11 | Demo site | Static Next.js export: 3 stories, read-along, eval dashboard, AI-generated label | static host | next |
| COMP-12 | Gate harness & guard | `Makefile` (thin), `gates.mk`, root `conftest.py`, `scripts/gates/` (checkers, `thresholds.toml`, `allowed_signers`, schemas, path guard, threshold-sync, make-check), `tests/gates/`, `docs/reviews/`, CI workflow, guard-verify against the newest signed lock tag (ADR-028) | local + CI | make, pytest, gitleaks |

## 3. Data model (plain files)

All under `runs/<run-id>/` (one run per story) unless noted. JSON validated by pydantic models in `src/dramatis/models.py`; schemas exported to `schemas/` and used by tests. Every record uses `line_id`, formatted `<story>-p<para>-l<n>`; a rating or score is valid only while the line's text hash is unchanged. The `eval` command takes all run ids and writes the cross-story aggregate to `results/` (committed, ADR-029): `lines.json`, `scores.json`, `transcripts.json`, `ratings.csv`, `report.json`.

| Artifact | Producer | Shape |
|---|---|---|
| `text.json` | COMP-02 | `{source, paragraphs:[{para_id,text}]}` |
| `roster.json` | COMP-03 | `{characters:[{name, profile_id}], narrator_profile_id}` |
| `lines.json` | COMP-03 | `[{line_id, para_id, speaker, text, emotion, intensity, fallback:bool}]`; emotion ∈ 7 labels, intensity ∈ [0,1], text ≤250 chars; concatenated texts equal source paragraphs |
| `audio/<hash>.wav` | COMP-05 | 24 kHz mono WAV; hash = H(text, emotion, intensity, engine, engine_version, engine_params, emotion_map_version, seed, voice_fingerprint); fingerprint = Kokoro voice id or content hash of reference clip(s) |
| `synth.json` | COMP-05 | `[{line_id, arm, audio_hash, engine_used, engine_downgrade:bool}]`; `arm` ∈ {`cb_controlled`, `cb_neutral`, `kokoro_neutral`} |
| `scores.json` | COMP-07 | `[{line_id, arm, intended, predicted, probs{9}, hit:bool, eligible:bool}]`; `eligible` false for `fallback` or `engine_downgrade` lines; a line ineligible in any arm is ineligible in all (paired line set) |
| `transcripts.json` | COMP-08 | `[{line_id, arm, text, wer, words:[{w,start,end}], engine}]` |
| `chapter.wav`, `timing.json` | COMP-01 | chapter audio; `{chapter, lines:[{line_id, start, end, words?:[{w,start,end}]}]}` |
| `ratings.csv` | COMP-09 | `{clip_id (random), line_id, arm_hidden, rated_label, rater, ts}`; arm and intended label hidden during rating |
| `report.json` | COMP-09 | per-arm per-emotion agreement + n + Wilson CI + insufficient flag, chance level, WER stats, kappa, run metadata, hash of input artifacts |
| `run.json` | COMP-01 | `{run_id, stages:{name:{state,started,ended,error}}, vram_peak_mb, s_per_line, versions{}}` |
| `spans.jsonl` | COMP-10 | one JSON span per LLM call, TTS job, score |
| `config/emotion_map.toml` (repo) | author/agent | per label: intensity→`exaggeration`, `cfg_weight` ranges; version string included in cache key |
| `models.lock` (repo) | author/agent | weight repo ids and revisions; `resemble-perth` commit |

## 4. Environment

| Item | Value |
|---|---|
| Dev machine | RTX 4050 6 GB, 16 GB DDR5, Ryzen 5, 512 GB SSD; Windows 11 with WSL2 (CUDA); all commands and the agent run inside WSL2 on this machine. The repo lives in the WSL home filesystem (not `/mnt/c`: slow venvs, CRLF); `.gitattributes` forces LF |
| VRAM measurement | `torch.cuda.max_memory_reserved` per stage plus `nvidia-smi` peak sampled at 1 Hz, taken with the Windows desktop idle; the larger value is compared to `vram_peak_gb_max` |
| Data hygiene | `voices/own/` and any own-voice audio (including under `spike/`) are gitignored; `make voices-check` fails if one is tracked |
| Python | 3.11; `uv`; two locked environments: `envs/chatterbox` (hard pins torch 2.6.0, transformers 5.2.0, numpy<2) and `envs/main` (CLI, Kokoro, emotion2vec, eval). A-9 decides whether Kokoro/emotion2vec share `main`. |
| Secrets | `.env` (gitignored); names in SECURITY.md §4 |
| Model weights | Downloaded at runtime to a cache outside the repo; pinned in `models.lock`; never committed |
| CI | GitHub Actions, CPU only: lint, types, unit tests with mocked engines, gitleaks, audit, docs-check, guarded-path diff check, threshold-sync, watermark-disable grep. No GPU in CI. |
| GPU tests | Marked `gpu`, run locally via the `make gate-N` targets |
| Deploy | Demo static-exported to any free static host; audio served as static files |

## 5. Source-of-truth rules

| Fact | Lives in | Never in |
|---|---|---|
| What we build, requirements | PRODUCT.md | code comments |
| Components, data shapes | ARCHITECTURE.md + `models.py` (code wins on shape; update doc in the same commit) | — |
| Why a choice was made | DECISIONS.md | chat |
| Gate checks and commands | PHASES.md + `gates.mk` | CLAUDE.md (summaries only) |
| Threshold values | `scripts/gates/thresholds.toml` (PHASES.md mirrors; `threshold-sync` fails on mismatch) | PRODUCT, DECISIONS, SECURITY (they cite threshold names) |
| Emotion label set | `models.py::Emotion` (single enum) | duplicated lists |
| Label→params mapping | `config/emotion_map.toml` | code constants |
| Threats, guardrails | SECURITY.md | — |
| External API facts | API.md | code comments |
| Session state | HANDOFF.md | — |
| Agent lessons | CLAUDE.md `## Lessons` (after executable-fix attempt) | — |

## 6. Failure behavior

- Annotation schema or verbatim failure twice → neutral-narrator line, `fallback:true`, logged to Langfuse and `spans.jsonl`.
- Groq unavailable or 429 → faster-whisper CPU fallback; `engine` recorded in `transcripts.json`.
- Langfuse unavailable → pipeline continues; tracing is best-effort; spans still go to local `spans.jsonl`. `gate-traces` checks the local file and reports `unknown` if Langfuse cannot be queried.
- CUDA OOM in synth → free VRAM, retry once on that line with Kokoro, record `engine_downgrade`; the eval excludes downgraded and fallback lines from every arm (paired line set) and reports their count.
- Scanned or oversize PDF → `ingest` exits non-zero with a clear message.
- Watermark not detected on a generated Chatterbox WAV → gate fails; no export proceeds.

## 7. Open questions

- Chatterbox parameter names and valid ranges (spike).
- Whether Kokoro and emotion2vec share an environment (A-9, M0.1).
- Whether emotion2vec loads remote code and what revision to pin (SEC-006).
