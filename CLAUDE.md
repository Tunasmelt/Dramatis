# Dramatis

Multi-voice, emotion-aware PDF dramatizer with a closed-loop emotion eval. Solo build, 2 weeks target (3 ceiling), portfolio-first. Read `docs/HANDOFF.md` first every session.

## Claude Responses
When reporting to me, be extremely concise, load-bearing words only. Priorities: user understanding > concision > grammar. Directive not recap → never padding. Split-second read. Do not compromise on meaning. Presenting data: use tables.
End with: *DO THIS* block → concrete next actions for user, numbered, priority-first. Spell out reply options on decisions. Omit only when no user action.

## Docs map (source of truth)

| Need | File |
|---|---|
| What / requirements (REQ-) | `docs/PRODUCT.md` |
| Components (COMP-), data shapes | `docs/ARCHITECTURE.md` |
| Why (ADR-) | `docs/DECISIONS.md` |
| Phases, gates (GATE-), commands, thresholds mirror, drop order | `docs/PHASES.md` |
| Threats, guardrails (SEC-) | `docs/SECURITY.md` |
| External APIs (EXT-) | `docs/API.md` |
| Session state | `docs/HANDOFF.md` |
| Phase/gate review sign-offs | `docs/reviews/` |

IDs are never reused or deleted: retire them. Update the doc in the same commit as the code that changes it. Threshold values live only in `scripts/gates/thresholds.toml`; cite names elsewhere.

## Hard constraints

- Hardware: RTX 4050 6 GB VRAM, 16 GB RAM. One local model resident at a time; free VRAM between stages. No model needing more than 6 GB.
- Engines: Chatterbox (controlled + neutral arms), Kokoro (neutral baseline, reference-clip generation). Never strip or bypass the PerTh watermark.
- Emotion labels: the 7 in `models.py::Emotion` only. emotion2vec `other`/`unknown` = miss, never remapped.
- Files, not servers: Python CLI (Typer) writing JSON/WAV. No FastAPI, no DB.
- Cloud: annotation LLM (swappable `LLMClient`), Groq Whisper, Langfuse. Keys from `.env` only; never in code, logs, spans, docs.
- Text sent to cloud: public-domain stories and generated clips only.
- Voices: reference clips for generated audio are Kokoro-generated. My own voice is for local spike clips only (`voices/own/`, gitignored) and never leaves the machine. No clone of any real person. Log every clip in `VOICES.md`.
- Verbatim rule: annotated line texts concatenated must equal the source paragraph (whitespace-normalized).
- PDF libs: pypdf or pdfminer.six. No AGPL (no PyMuPDF).
- Weights: downloaded at runtime outside the repo, pinned in `models.lock` (incl. `resemble-perth` by commit). Never committed or redistributed.
- Demo audio is labeled "AI-generated". WAV never ships.

## Commands

```
make lint typecheck test          # CPU, mocked engines
make gate-1 … make gate-5         # run a gate (definitions in docs/PHASES.md)
make guard-test guard-verify      # guard proof / diff vs signed gates-locked-pN tag
make threshold-sync review-check  # thresholds mirror; review sign-off boxes
make secrets audit licenses docs-check corpus-check
make voices-check env-check make-check gate-traces site-check secrets-site
```

Run the current phase's gate before saying a phase is done.

## Workflow rules (ASDD)

1. One milestone at a time from `docs/PHASES.md`. Reference REQ-/COMP-/SEC- IDs in commits.
2. Tests first for anything with a schema, a mapping, a cache key, or a fallback.
3. **Gates are human-locked.** Mx.0 (first milestone of each phase): draft that phase's gate scaffolding per the PHASES.md inventory, then stop. I open the draft window with tag `gates-draft-pN`, then review and lock with a signed tag `gates-locked-pN`. After that, never edit guarded paths (ADR-028): `Makefile`, `gates.mk`, `ruff.toml`, `mypy.ini`, `pytest.ini`, root `conftest.py`, `scripts/gates/` (incl. `thresholds.toml`, `allowed_signers`), `tests/gates/`, `.github/workflows/`, `.claude/settings.json`, `docs/reviews/`. Unguarded: `dev.mk` (no gate targets), `pyproject.toml` (deps only), `src/`, `spike/`, `tests/unit/`, `tests/data/`. Only I change a locked file (re-lock tag `gates-locked-pN-rK`). `tests/gates/` are black-box (CLI or files only). If a gate seems wrong, stop and tell me.
4. After a gate failure or a correction from me: first encode the fix as a unit test, lint rule, type, or a hook (you propose it, I install it). Only if impossible, add one line to `## Lessons` with date and commit.
5. Never claim a phase done on your own judgment; report gate output. You share a model with the builder, so you are not an independent verifier.
6. Before finishing a session: overwrite `docs/HANDOFF.md` (state, next step, two-line worked/didn't).
7. Mx.9 in every phase: phase review in `docs/reviews/phaseN.md` (prune wrong Lessons, note any repeated mistake), that gate's SECURITY §5 checklist, flip THR statuses on evidence.
8. Risky assumptions are proven in Phase 0 before building on them. If GATE-1 fails, follow the fallback in `docs/PHASES.md`.
9. If behind schedule, cut only per the drop order in `docs/PHASES.md`; anything else needs an ADR.
10. No LESSONS.md, LES- IDs, metrics or tiers unless a specific failure shows the need.

## Conventions

- Python 3.11, `uv`, ruff, mypy strict on `src/`, pytest. GPU tests marked `gpu`, never in CI.
- Dev on Windows 11 + WSL2; run everything in WSL2. Two envs: `envs/chatterbox` (torch 2.6.0, transformers 5.2.0, numpy<2) and `envs/main`. Stages talk via files.
- Pydantic models are the single source of artifact shapes; export JSON schemas to `schemas/`. Every record uses `line_id`.
- Filenames come from hashes or fixed ids, never from LLM or PDF text (SEC-012).
- Every cloud call has a timeout, bounded retries, and counts against per-run caps (SEC-014).
- Tracing is best-effort; a Langfuse failure never fails a stage.
- Explain technical choices with both the technical detail and a one-line plain-language version.

## Lessons

Cap about 15 lines total. Format: `- YYYY-MM-DD (commit): fact`. Only when no executable fix was possible.

### Project facts (durable)

- (none yet)

### Agent quirks (prune on model switch)

- (none yet)
