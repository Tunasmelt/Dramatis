---
doc: PRODUCT
last_verified_commit: e543be0
last_updated: 2026-11-05
owner: Harris Shamsi
status: draft
---

# PRODUCT — Dramatis

> Multi-voice, emotion-aware dramatizer for text-layer PDFs, with a closed-loop emotion eval. Solo build. Target 2 weeks, ceiling 3 (ADR-025). Portfolio-first (agentic-AI roles), learning second, real product third. Also the first real test of ASDD (adaptive spec-driven development), so the full ASDD mechanism stays in.

## 1. Summary

Dramatis turns three short public-domain stories (PDFs) into multi-voice audio. An LLM splits the text into speaker-attributed lines tagged with one of 7 emotions plus an intensity. Chatterbox renders each line with emotion controls; two controls render the same text neutrally (Chatterbox default params, and Kokoro). A speech-emotion model scores every clip against the intended label, Groq Whisper checks intelligibility, and Langfuse traces the run. Output: audio, a read-along demo, and an eval report that says honestly whether the emotions came through.

*Plain language:* read stories aloud with different voices and feelings, then measure whether the feelings actually came through, and show the numbers.

## 2. Goals & success

| ID | Goal | Success measure |
|---|---|---|
| G-1 | Portfolio proof of an agentic pipeline with eval discipline | Public repo, README reproduces results, static demo, eval report with honest findings |
| G-2 | Learn: structured LLM output, local TTS under 6 GB, eval design, Langfuse, Groq | Each used in the shipped pipeline by Gate 3 |
| G-3 | Emotion eval is trustworthy | Checker recognizes the author's acted emotions (GATE-1) and its agreement with human ratings is reported (kappa) |
| G-4 | Validate ASDD as an improvement over plain spec-driven development | Gates pass without weakening; Lessons rule exercised; repeat-mistake count recorded in each phase review |

## 3. Requirements

Status: `planned` · `active` · `done` · `retired`. IDs are never reused or deleted; retire them. Numeric thresholds are named here and valued only in `scripts/gates/thresholds.toml` (mirrored in PHASES.md).

### Functional

| ID | Requirement | Component | ADR | Status |
|---|---|---|---|---|
| REQ-001 | Ingest a text-layer PDF into clean text with paragraph and dialogue boundaries. Scanned, image-only, oversize or malformed PDFs are rejected with a clear error. | COMP-02 | ADR-013, ADR-015 | planned |
| REQ-002 | Roster pass: LLM builds the cast and assigns each character a voice profile from the library (≤8 profiles). | COMP-03 | ADR-006 | planned |
| REQ-003 | Segmentation pass: split text into lines ≤250 chars, each with `speaker`, `emotion` ∈ {neutral, happy, sad, angry, fearful, surprised, disgusted}, `intensity` ∈ [0,1]. Validated against a schema; one retry with the validation error; on second failure the line falls back to the neutral narrator and the failure is logged. | COMP-03 | ADR-005, ADR-006 | planned |
| REQ-004 | Verbatim rule: line texts, concatenated, must equal the source paragraph after whitespace normalization. Dropped or paraphrased text fails validation, gets one retry, then falls back to a neutral-narrator line carrying the original text. WER is always computed against original text. | COMP-03 | ADR-006 | planned |
| REQ-005 | Voice library: ≤8 profiles, each `{id, kokoro_voice, reference_clip, description}` where `reference_clip` is generated from `kokoro_voice` (synthetic). Every clip has provenance in `VOICES.md`. Optional per-emotion reference clips only if the spike requires them (ADR-020). | COMP-04 | ADR-004, ADR-020, ADR-022 | planned |
| REQ-006 | Synthesis, three arms per line: (a) Chatterbox controlled (label→params), (b) Chatterbox neutral control (same reference clip, default params), (c) Kokoro neutral secondary baseline (same `kokoro_voice`). One local model resident at a time; VRAM freed between stages. | COMP-05 | ADR-003, ADR-010 | planned |
| REQ-007 | Label→params mapping lives in `config/emotion_map.toml` (intensity 0–1 → Chatterbox exaggeration / cfg_weight, per label). It is versioned, tested, and part of the cache key. | COMP-05 | ADR-020 | planned |
| REQ-008 | Segment audio cached by hash of (text, emotion, intensity, engine + version, engine params, `emotion_map` version, seed, voice fingerprint); voice fingerprint = Kokoro voice id or content hash of the reference clip(s). Re-runs regenerate only changed segments. | COMP-06 | ADR-007 | planned |
| REQ-009 | Emotion check: score every clip of every arm with emotion2vec+ (16 kHz input); map its 9 outputs to the 7 labels; `other`/`unknown` count as a miss, never remapped. | COMP-07 | ADR-005 | planned |
| REQ-010 | Intelligibility: transcribe every clip with Groq Whisper; compute WER vs the original text; flag clips with WER over `wer_clip_max`; faster-whisper (CPU) fallback recorded per clip. Word timestamps are captured for the stretch word-level highlight. | COMP-08 | ADR-008 | planned |
| REQ-011 | Eval report: per-emotion agreement for each arm; `n` per emotion with Wilson 95% intervals; emotions with fewer than `min_eligible_lines_per_label` eligible lines flagged "insufficient"; chance level reported; lines with `fallback` or `engine_downgrade` excluded from **all** arms (so arms compare the same lines) and counted; paired significance test (exact sign/McNemar) for `cb_controlled` vs `cb_neutral`; WER summary; 30 clips rated blind, randomized, stratified by label by one rater (the author), so ~4 per label; checker-vs-human Cohen's kappa with bootstrap CI and a single-rater caveat; statement that intensity is unmeasured in v1. Ratings key on `line_id` plus text hash; a changed line invalidates its rating and is counted. Labels likely to fall under `min_eligible_lines_per_label` (disgusted, surprised) are reported "insufficient", not hidden. The eval spans all runs and writes to `results/` (ARCHITECTURE §3). | COMP-09 | ADR-010 | planned |
| REQ-012 | Tracing: every LLM call, TTS job and eval score recorded in Langfuse (latency, prompt version, scores); spans also written to local `runs/<id>/spans.jsonl`. | COMP-10 | ADR-009, ADR-018 | planned |
| REQ-013 | `assemble` stage: per-chapter audio (`chapter.wav`) plus `timing.json` with line-level timing from clip durations; word-level timing from Whisper when available. | COMP-01 | ADR-012 | planned |
| REQ-014 | Static demo (Next.js export): 3 stories, pre-rendered audio, read-along with line-level highlight (word-level is a stretch), eval dashboard, "AI-generated" label, credits. Demo audio is the `cb_controlled` arm with a toggle to `cb_neutral`. No live generation, no third-party runtime fetches. | COMP-11 | ADR-012, ADR-026 | planned |
| REQ-015 | Typer CLI: `ingest`, `annotate`, `synth`, `check`, `transcribe`, `assemble`, `eval`, `build-site`, `run` (all stages); plain-file artifacts (JSON, WAV, run manifest). | COMP-01 | ADR-007 | planned |
| REQ-016 | Resumable: each stage idempotent; a run manifest records stage state; failed runs resume without redoing finished work. | COMP-01, COMP-06 | ADR-007 | planned |

### Constraints & policy

| ID | Requirement | Component | ADR | Status |
|---|---|---|---|---|
| REQ-017 | PerTh watermark never stripped or disabled. The local GPU gate verifies it on generated WAVs and on exported demo files; CI greps for any watermark-disable code. | COMP-05, COMP-11 | ADR-014, ADR-026 | planned |
| REQ-018 | Voices policy: reference clips for generated audio are Kokoro-generated (synthetic). The author's own voice is used only for local spike clips (gitignored `voices/own/`), never uploaded or published. No clone of any real person without documented consent. | COMP-04 | ADR-022 | planned |
| REQ-019 | Licensing: code MIT; weights downloaded at runtime and never redistributed; `NOTICE` credits Chatterbox, Kokoro, emotion2vec, Perth; emotion2vec license read in Phase 0 and re-confirmed at release; permissive PDF library (pypdf or pdfminer.six), no AGPL; every dependency pinned, including `resemble-perth` by commit. | all | ADR-014, ADR-015 | planned |
| REQ-020 | Hardware fit: peak VRAM ≤ `vram_peak_gb_max`; seconds per line and projected full-corpus runtime ≤ `projected_corpus_hours_max`; both recorded per stage. | COMP-05 | ADR-011 | planned |
| REQ-021 | Corpus: three public-domain stories (Poe "The Tell-Tale Heart", Wilde "The Happy Prince", O. Henry "The Gift of the Magi"), each <~5,000 words. Text-layer PDFs are built by `scripts/make_corpus_pdfs.py` from Gutenberg plain text; `corpus/PROVENANCE.md` records URL, edition id and public-domain check. | COMP-02 | ADR-013 | planned |
| REQ-022 | ASDD adaptive layer: after a gate failure or user correction, encode the fix as a unit test, lint rule, type or author-installed hook first; only then a single `## Lessons` line in CLAUDE.md; Lessons capped ~15 lines, split into project facts and agent quirks; every phase ends with a review that prunes Lessons and records whether a mistake repeated. | process | ADR-016 | planned |
| REQ-023 | Gate integrity: gate harness (Makefile gate includes, checker scripts, thresholds, gate tests, CI) is drafted by the agent once per phase, reviewed and locked by the author via signed tag, and cannot be edited by the agent afterwards. Locked-file drift is detected locally and in CI. | COMP-12 | ADR-017, ADR-021, ADR-023 | planned |
| REQ-024 | Reproducibility (ADR-029): WSL2 dev environment (repo inside the WSL filesystem), two locked environments (Chatterbox venv, main venv) per ADR-024; seeds fixed and recorded; committed `results/` artifacts let the README recompute every reported number and match the `report.json` input hash; `models.lock` pins weights and revisions. | COMP-01 | ADR-024 | planned |

## 4. Non-goals

- Cloning real or living people's voices
- Scanned PDFs / OCR
- Real-time streaming or live generation in the demo
- Accounts, multi-user, or a database
- Any model that needs more than 6 GB VRAM (Orpheus 3B, Dia 1.6B, Qwen3-TTS, Sesame CSM)
- Copyrighted source texts in the repo or demo
- Measuring intensity accuracy (v1 reports intensity as unmeasured)
- Productizing ASDD as a deliverable (it is the workflow, with its results reported in reviews)

## 5. Assumptions (verify; each has an owner phase)

| ID | Assumption | Verified in |
|---|---|---|
| A-1 | Chatterbox runs on the RTX 4050 6 GB under `vram_peak_gb_max` | Phase 0 spike |
| A-2 | Chatterbox controls (exaggeration, cfg_weight) change perceived emotion *type*, not only intensity (ADR-020) | Phase 0 spike (emotion-type test) |
| A-3 | emotion2vec+ recognizes the author's acted emotions well enough to be a trustworthy metric | Phase 0 spike |
| A-4 | Groq free tier (25 MB/file, rate limits) covers clip-sized transcription | Phase 0 spike (e2e), Phase 2 (full run) |
| A-5 | emotion2vec's custom ("FunASR model") license permits public attribution-based use | Phase 0 (before M0.3), re-confirmed at release |
| A-6 | The three stories are public domain on Gutenberg | Phase 1 (`corpus-check`) |
| A-7 | A free-tier cloud LLM does reliable roster + segmentation with schema retries | Phase 1 |
| A-8 | Projected full-corpus synthesis (3 arms × 3 stories) fits `projected_corpus_hours_max` on the 4050 | Phase 0 spike |
| A-9 | Kokoro and emotion2vec can share one venv; Chatterbox needs its own because of hard pins | Phase 0 (M0.1) |
| A-10 | PerTh watermark survives the chosen demo export format | Phase 3 (else ship FLAC, ADR-026) |

## 6. Open questions

- Exact Chatterbox parameter names and valid ranges (spike, then record in `config/emotion_map.toml` and ARCHITECTURE).
- Annotation LLM provider/model (chosen in M1.4, recorded as an ADR, then EXT-03 added).
- `wer_median_max` and `wer_clip_max` values (set at M0.9 from the spike clips via re-lock, ADR-028).
- Which free-licensed dataset supplies per-emotion clips if ADR-020 fails (policy fixed in ADR-030; dataset chosen then).
- Mapping of emotion2vec output order to the 7 labels (confirm in spike).
- Langfuse SDK pin: v3 vs v4 (ADR-018).
