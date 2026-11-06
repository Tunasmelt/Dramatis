---
doc: API
last_verified_commit: 9aa04b2
last_updated: 2026-11-05
owner: Harris Shamsi
status: draft
openapi_source: none (Dramatis exposes no HTTP API; see ADR-019)
---

# API — Dramatis

> Dramatis has no network API of its own. Part 1 is intentionally empty; the CLI stage contracts live in ARCHITECTURE.md §1 and §3. Part 2 documents the external services it calls. Never write secret values here.

## Conventions

- **Interface:** Typer CLI (`dramatis <stage>`); stages communicate through files under `runs/<run-id>/`.
- **Auth tiers (external):** all calls use API keys from environment variables listed in SECURITY.md §4.
- **Errors:** CLI exits non-zero with a one-line message; details in `run.json`.
- **IDs / dates:** run ids are `YYYYMMDD-HHMMSS-<story>`; dates ISO 8601 UTC.
- **Retry policy (external):** exponential backoff on 429/5xx, bounded by per-run caps (SEC-014).

## Change policy

- Breaking for artifacts: changing field names/types in `lines.json`, `synth.json`, `scores.json`, `transcripts.json`, `report.json`. Bump `schema_version` and update the demo site in the same commit.
- Non-breaking: new optional fields.
- Deprecations noted in CHANGELOG.md.

## Part 1 — Own API

Status: `planned` · `active` · `deprecated` · `retired`

No HTTP endpoints. The index is empty by design.

<!-- api-index:start -->
| ID | Method | Path | Summary | Auth | Rate limit | Component | Requirements | Guardrails | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
<!-- api-index:end -->

## Part 2 — External APIs

Status: `active` · `deprecated` · `removed`

| ID | Provider | Purpose | Component | API version | SDK | Secret | Data sent | Last verified | Status |
|---|---|---|---|---|---|---|---|---|---|
| EXT-01 | Groq | Whisper transcription (WER gate, word timestamps) | COMP-08 | OpenAI-compatible `/openai/v1/audio/transcriptions` | httpx (pin at M0.1) | GROQ_API_KEY | generated clip audio (public-domain text read aloud by synthetic voices) | 2026-11-05 | active |
| EXT-02 | Langfuse | Tracing of LLM calls, TTS jobs, scores | COMP-10 | Python SDK (v3 vs v4 pin: ADR-018) | langfuse (pin at M0.1) | LANGFUSE_SECRET_KEY | span metadata, public-domain text, metrics | 2026-11-05 | active |
| EXT-05 | Project Gutenberg | One-time plain-text download of the three stories by `scripts/make_corpus_pdfs.py` | COMP-02 | plain HTTPS GET | httpx | none | none (download only; URL and edition id logged in `corpus/PROVENANCE.md`) | 2026-11-07 | active |
| EXT-04 | Hugging Face Hub / ModelScope | Weight downloads (Chatterbox, Kokoro, emotion2vec+) and the `resemble-perth` git dependency | COMP-05 | n/a | huggingface_hub, modelscope/funasr (pin at M0.1) | HF_TOKEN | none (downloads only) | 2026-11-05 | active |

### EXT-01 — Groq

- **Docs used:** Groq speech-to-text docs (console.groq.com/docs/speech-to-text), checked 2026-11-05.
- **What we call:** `POST https://api.groq.com/openai/v1/audio/transcriptions`, model `whisper-large-v3-turbo` (fallback model `whisper-large-v3`), `response_format=verbose_json`, `timestamp_granularities[]=word` and `segment`.
- **Limits:** free tier 25 MB per file (100 MB on dev tier); rate limits per org/model. Clips are a few seconds, so size is not a concern; request count is, with three arms per line.
- **Timeout / retries:** 30 s timeout; 3 retries with backoff on 429/5xx; then CPU fallback (faster-whisper small), recorded in `transcripts.json` as `engine`.
- **Failure behavior:** stage continues on fallback; if both fail the line is marked `wer: null` and excluded from the WER summary, with a count in the report.
- **Gotchas / deprecations:** model names and limits change; re-verify every 30 days. Never upload the author's own-voice clips (SEC-005).

### EXT-02 — Langfuse

- **Docs used:** Langfuse Python SDK docs (langfuse.com/docs), checked 2026-11-05.
- **What we call:** spans around annotate, synth, check, transcribe; scores for emotion hit and WER; `flush()` before CLI exit (short-lived process).
- **Limits:** free tier event quota; self-host is the alternative.
- **Timeout / retries:** SDK-managed; tracing failures never fail a stage.
- **Failure behavior:** warn once, continue without traces; `gate-traces` always checks local `spans.jsonl`; if Langfuse is unreachable the gate reports `unknown` and blocks until the author checks the sign-off box in `docs/reviews/phase2.md` (GATE-3; PHASES.md matches).
- **Gotchas / deprecations:** v3 vs v4 APIs differ (OTel-based in the newer line); decide in ADR-018 and pin. Env vars: `LANGFUSE_SECRET_KEY`, `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_BASE_URL`.

**EXT-03 is reserved** for the annotation LLM provider. It is added in Phase 1 (M1.4), after the provider is chosen and its vendor docs are read. Until then there is no entry, so nothing is marked verified without a vendor check.

### EXT-04 — Hugging Face Hub / ModelScope

- **Docs used:** Chatterbox (PyPI/GitHub), Kokoro and emotion2vec+ model cards, checked 2026-11-05.
- **Chatterbox pins observed:** requires-python ≥3.10; torch==2.6.0, torchaudio==2.6.0, transformers==5.2.0, numpy<2 (py<3.13), librosa==0.11.0, diffusers==0.29.0, safetensors==0.5.3, gradio==6.8.0; `resemble-perth` comes from git master, so we pin it by commit hash in `models.lock` (SEC-006).
- **What we call:** model downloads at first run to a cache outside the repo.
- **Limits:** disk (about 5–10 GB total), bandwidth.
- **Timeout / retries:** resumable downloads.
- **Failure behavior:** stage fails fast naming the model; no partial-weights execution.
- **Gotchas / deprecations:** emotion2vec uses a custom license (FunASR model license): read in Phase 0, re-confirm at release (REQ-019). Chatterbox embeds a PerTh watermark; never disable (REQ-017).
