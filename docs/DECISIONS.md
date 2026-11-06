---
doc: DECISIONS
last_verified_commit: e543be0
last_updated: 2026-11-05
owner: Harris Shamsi
status: draft
---

# DECISIONS — Dramatis

Append-only ADR log. Never edit an accepted ADR's decision; supersede it with a new one. Status: `proposed` · `accepted` · `superseded by ADR-NNN`. Threshold values live in `scripts/gates/thresholds.toml`; ADRs cite names only.

| ADR | Title | Status |
|---|---|---|
| ADR-001 | Scope: 3 stories, full eval | accepted |
| ADR-002 | Emotion comes from text; SER is the checker | accepted |
| ADR-003 | Chatterbox + Kokoro | accepted |
| ADR-004 | Two-axis casting (voice × emotion) | accepted, conditional on ADR-020 |
| ADR-005 | Seven labels; `other`/`unknown` = miss | accepted |
| ADR-006 | Annotator: interface, two passes, schema + verbatim | accepted |
| ADR-007 | CLI over plain files; no server or DB | accepted |
| ADR-008 | Groq Whisper for WER and timestamps; CPU fallback | accepted |
| ADR-009 | Langfuse best-effort plus local spans | accepted |
| ADR-010 | Eval design v2: three arms, validity statistics | accepted |
| ADR-011 | Day-2 spike / GATE-1 first | accepted |
| ADR-012 | Static Next.js demo; line-level then word-level read-along | accepted |
| ADR-013 | Corpus: three PD stories, PDFs built by script | accepted |
| ADR-014 | Licensing and watermark policy | accepted |
| ADR-015 | PDF library: pypdf or pdfminer.six | accepted |
| ADR-016 | ASDD minimal lessons layer | accepted |
| ADR-017 | Gates immutable to the agent | accepted |
| ADR-018 | Langfuse SDK pin (v3 vs v4) | proposed |
| ADR-019 | No HTTP API in v1 | accepted |
| ADR-020 | Emotion-*type* control hypothesis | proposed until spike |
| ADR-021 | Gate authorship in Mx.0, locked by author | accepted |
| ADR-022 | Voices policy: Kokoro-generated reference clips | accepted |
| ADR-023 | Guard design: file-level, signed tags, two test tiers | accepted; guarded-path list superseded by ADR-028 |
| ADR-024 | Environments: WSL2, two venvs, local GPU | accepted |
| ADR-025 | Schedule: 2 weeks target, 3 ceiling, drop order | accepted |
| ADR-026 | Export formats and watermark verification | accepted |
| ADR-027 | Gate runners and sign-off files | accepted |
| ADR-028 | Guard scope, draft window, re-lock, signed sign-offs | accepted |
| ADR-029 | Reproducibility means recomputation from committed artifacts | accepted |
| ADR-030 | Free-licensed source for per-emotion reference clips (fallback only) | accepted |

---

## ADR-001 — Scope: 3 stories, full eval
**Status:** accepted · 2026-11-05
**Context:** Smaller cuts were proposed (1 story, no Langfuse, fewer gates). Author rejected them: the point is portfolio proof of eval discipline plus testing ASDD.
**Decision:** Three stories, full eval (REQ-011), Langfuse, Groq, Next.js demo, five gates plus guard. Schedule risk is handled by ADR-025, not by cutting scope.
**Consequences:** Anything cut requires an ADR; the only pre-approved cuts are the drop order in ADR-025.

## ADR-002 — Emotion comes from text; SER is the checker
**Status:** accepted · 2026-11-05
**Context:** Emotion could be inferred from audio or from text. The pipeline generates audio from text.
**Decision:** The annotator assigns emotion from text. A speech-emotion model (emotion2vec+) scores the output audio as an independent checker, never as an input to generation.
**Consequences:** The loop is generate → measure; checker validity must be proven first (GATE-1, acted clips).

## ADR-003 — Chatterbox + Kokoro
**Status:** accepted · 2026-11-05
**Context:** Needs local TTS under 6 GB VRAM with emotion control and a neutral baseline.
**Decision:** Chatterbox (emotion exaggeration + cfg controls, voice from reference clip) for expressive lines; Kokoro for the secondary neutral baseline and for generating reference clips.
**Consequences:** Two engines, two dependency stacks (ADR-024). PerTh watermark is non-removable (ADR-014).

## ADR-004 — Two-axis casting
**Status:** accepted, conditional on ADR-020 · 2026-11-05
**Decision:** Voice identity (profile) and emotion (label + intensity → params) are independent axes. Per-emotion reference clips are added only if the spike shows controls alone do not change emotion type.

## ADR-005 — Seven labels; `other`/`unknown` = miss
**Status:** accepted · 2026-11-05
**Decision:** Labels: neutral, happy, sad, angry, fearful, surprised, disgusted (one enum in `models.py`). emotion2vec outputs `other`/`unknown` are scored as misses and never remapped.
**Consequences:** Agreement numbers are conservative by construction.

## ADR-006 — Annotator: interface, two passes, schema + verbatim
**Status:** accepted · 2026-11-05
**Decision:** Swappable `LLMClient`. Pass 1 roster; pass 2 segmentation. Output validated against schema and the verbatim rule (REQ-004). One retry carrying the validation error; then neutral-narrator fallback with the original text. Story text is wrapped as data in the prompt (SEC-004).
**Consequences:** Provider choice deferred to M1.4 (own ADR, then EXT-03).

## ADR-007 — CLI over plain files; no server or DB
**Status:** accepted · 2026-11-05
**Decision:** Typer CLI, stages communicate through files, a run manifest records state, every stage is idempotent and keyed by content hash.
**Consequences:** Resume is trivial; no persistence layer to secure.

## ADR-008 — Groq Whisper for WER and timestamps; CPU fallback
**Status:** accepted · 2026-11-05
**Decision:** whisper-large-v3-turbo on Groq for transcripts, WER vs original text and word timestamps; faster-whisper small on CPU as fallback on outage or 429. Engine recorded per clip.
**Consequences:** Clips are public-domain text rendered by synthetic voices, so cloud upload is acceptable (SEC-005); 25 MB/file limit is far above clip size.

## ADR-009 — Langfuse best-effort plus local spans
**Status:** accepted · 2026-11-05
**Decision:** Every LLM call, TTS job and score emits a span to Langfuse and to `spans.jsonl`. A Langfuse failure never fails a stage; the gate checks the local file.

## ADR-010 — Eval design v2
**Status:** accepted · 2026-11-05
**Context:** v1 compared controlled Chatterbox to Kokoro, confounding engine with emotion control.
**Decision:** Three arms per line: `cb_controlled`, `cb_neutral` (same reference clip, default params), `kokoro_neutral`. The primary comparison is controlled vs `cb_neutral`. Report n, Wilson 95% intervals, insufficient flag (`min_eligible_lines_per_label`), chance level, exclusions, 30 blind rated clips, Cohen's kappa checker-vs-human, intensity unmeasured.
**Consequences:** Roughly 3× synthesis cost; mitigated by caching and the projected-runtime gate.

## ADR-011 — Day-2 spike / GATE-1 first
**Status:** accepted · 2026-11-05
**Decision:** Phase 0 proves the risky assumptions (A-1, A-2, A-3, A-4, A-5, A-8, A-9) before building. GATE-1 failing triggers the fallback in PHASES.md rather than continuing.

## ADR-012 — Static Next.js demo; line-level then word-level
**Status:** accepted · 2026-11-05
**Decision:** Pre-rendered static export. Read-along highlights lines using durations from clip lengths (`timing.json`); word-level from Groq timestamps is a stretch goal if Phase 3 is on time and is first in the drop order.

## ADR-013 — Corpus: three PD stories, PDFs built by script
**Status:** accepted · 2026-11-05
**Decision:** Poe, Wilde, O. Henry from Project Gutenberg plain text. `scripts/make_corpus_pdfs.py` builds text-layer PDFs; `corpus/PROVENANCE.md` records source and public-domain check; `make corpus-check` verifies.

## ADR-014 — Licensing and watermark policy
**Status:** accepted · 2026-11-05
**Decision:** Code MIT; weights fetched at runtime, never redistributed; NOTICE credits upstream; emotion2vec license read in Phase 0 (A-5) and re-confirmed at release, swapping the checker if it blocks public use. PerTh watermark is never stripped or disabled; CI greps for disabling code.

## ADR-015 — PDF library
**Status:** accepted · 2026-11-05
**Decision:** pypdf or pdfminer.six (chosen in M1.2). No AGPL (PyMuPDF excluded).

## ADR-016 — ASDD minimal lessons layer
**Status:** accepted · 2026-11-05
**Decision:** Failure → executable fix first (test, lint, type, author-installed hook) → single-line `## Lessons` entry only if no executable fix exists. Cap about 15 lines, split project facts vs agent quirks. No LESSONS.md, IDs or metrics until a failure demands them. The agent proposes hooks; the author installs them.
**Consequences:** The Mx.9 review is the pruning mechanism and records repeated mistakes.

## ADR-017 — Gates immutable to the agent
**Status:** accepted · 2026-11-05
**Decision:** After a gate is locked, the agent does not edit gate commands, thresholds, checkers, schemas or gate tests. The verifier shares the builder's model and is not independent, so completion is never self-declared.

## ADR-018 — Langfuse SDK pin
**Status:** proposed
**Decision (proposed):** Decide v3 vs v4 in M0.1 after reading the current Langfuse docs; pin exactly; record in API.md EXT-02.

## ADR-019 — No HTTP API in v1
**Status:** accepted · 2026-11-05
**Decision:** No FastAPI/server. API.md Part 1 stays empty; the index markers remain so the checker passes.

## ADR-020 — Emotion-type control hypothesis
**Status:** proposed until the Phase 0 spike · 2026-11-05
**Context:** Chatterbox exaggeration and cfg_weight may change intensity/style but not emotion *type*.
**Decision (proposed):** Run only after the checker is validated on acted clips (M0.4). Test `emotion_type_sentences_per_label` matched sentences per non-neutral label across arms. A label is passed when `cb_controlled` has strictly more checker hits than `cb_neutral` over those sentences (ties do not count). Overall pass needs at least `emotion_type_labels_pass_min` of 6 labels **and** the author's blind listening check. Note the checker-only test is weak: with 5 sentences and a coin-flip per label, chance of passing ≥4 of 6 is about 34%, which is why the human check is required. On failure, per-emotion reference clips are allowed only from a free-licensed dataset per ADR-030 (Kokoro cannot supply emotion, so Kokoro-generated per-emotion clips do not count); if none passes the license check,  reframe the project as an honest negative-result eval. Retest once after any change.
**Consequences:** ADR-004 is conditional on this.

## ADR-021 — Gate authorship in Mx.0, locked by author
**Status:** accepted · 2026-11-05
**Decision:** The first milestone of each phase (Mx.0) is the agent drafting that phase's gate scaffolding from the PHASES.md inventory; the author reviews and locks via signed tag `gates-locked-pN`.

## ADR-022 — Voices policy
**Status:** accepted · 2026-11-05 · reverses the earlier LibriVox idea
**Context:** LibriVox readers are real people; cloning them conflicts with "no clone of a real person without consent".
**Decision:** Reference clips for all generated and published audio are generated from Kokoro presets (synthetic). The author's own voice is used only for the 7 local spike clips, kept in gitignored `voices/own/`, never uploaded or published.

## ADR-023 — Guard design
**Status:** accepted · 2026-11-05
**Decision:** File-level guard. Guarded: `gates.mk`, `ruff.toml`, `mypy.ini`, `pytest.ini`, `scripts/gates/`, `tests/gates/`, `.github/workflows/`, `.claude/settings.json`. Unguarded: `Makefile` (includes `gates.mk`), `dev.mk`, `pyproject.toml` (dependencies only), `src/`, `spike/`, `tests/unit/`, `tests/data/`. Enforcement: signed `gates-locked-pN` tag plus a diff check run locally (`make guard-verify`) and in CI. Two test tiers: locked black-box `tests/gates/` (call the CLI or read files only) and agent-owned `tests/unit/` + `tests/data/`. The agent proposes hooks; the author installs them.
**Consequences:** The agent can build freely; only the judgment layer is locked.

## ADR-024 — Environments
**Status:** accepted · 2026-11-05
**Decision:** Dev on Windows 11 + WSL2; all commands and the agent run in WSL2 on the GPU machine. Two venvs: `envs/chatterbox` (torch 2.6.0, transformers 5.2.0, numpy<2) and `envs/main`. Stages talk through files. M0.1 decides whether Kokoro/emotion2vec share `main` (A-9). `models.lock` pins weights and `resemble-perth` by commit.

## ADR-025 — Schedule and drop order
**Status:** accepted · 2026-11-05
**Decision:** Target 2 weeks, hard ceiling 3. If behind, cut in this order: (1) word-level highlight; (2) rated clips 30 → 15; (3) Wilson intervals; (4) Opus/MP3 export (ship FLAC). Nothing else is cut without an ADR.

## ADR-026 — Export formats and watermark verification
**Status:** accepted · 2026-11-05
**Decision:** Demo audio is Opus (or MP3). GATE-4 runs PerTh detection on the exported files. If the watermark does not survive, ship FLAC. WAV never ships.

## ADR-027 — Gate runners and sign-off files
**Status:** accepted · 2026-11-05
**Decision:** `make gate-1`..`gate-5` run scripted checks. Human-judged checks are checkbox lines in `docs/reviews/phaseN.md`; the gate script fails if a box is unchecked or the file is missing.

## ADR-028 — Guard scope, draft window, re-lock, signed sign-offs
**Status:** accepted · 2026-11-07 · supersedes the guarded-path list in ADR-023
**Context:** Review found bypasses: an unguarded `Makefile` can override a gate recipe, an unguarded root `conftest.py` can alter gate tests, the agent could tick review boxes, nothing said where tag keys live, and later threshold edits (`wer_median_max`, drop-order cuts) had no legitimate path.
**Decision:** Guarded: `Makefile` (thin include), `gates.mk`, `ruff.toml`, `mypy.ini`, `pytest.ini`, root `conftest.py`, `scripts/gates/` (incl. `thresholds.toml`, `allowed_signers`), `tests/gates/`, `.github/workflows/`, `.claude/settings.json`, `docs/reviews/`. Unguarded: `dev.mk` (policed by `make make-check`), deps in `pyproject.toml`, `src/`, `spike/`, `tests/unit/`, `tests/data/`. Gate tests run with `--confcutdir=tests/gates`. Draft window: the hook allows guarded edits only while the latest tag is `gates-draft-pN`; signed `gates-locked-pN` closes it. Re-lock: only the author edits a locked file, then tags `gates-locked-pN-rK`; `guard-verify` uses the newest signed lock tag; each re-lock is logged. Review files count only if last changed in a commit signed by a key in `allowed_signers`.
**Consequences:** The author's signing key is a trust root; keep it off the agent's reachable environment where possible (note: the agent shares the WSL2 session, so the key needs a passphrase or hardware token).

## ADR-030 — Free-licensed source for per-emotion reference clips
**Status:** accepted · 2026-11-07 · narrows ADR-022 for the ADR-020 fallback only
**Context:** If the emotion-type test fails, Kokoro presets cannot supply emotion-specific references. The author chose a free external source over using their own voice.
**Decision:** Only if ADR-020 fails, per-emotion reference clips may come from a speech dataset whose license is CC0 or public domain, or an equivalent that explicitly permits reuse and derivative/voice-cloning use and publication of generated audio. Dataset and license are chosen and verified in the fallback milestone (not pre-selected here), each clip is logged in `VOICES.md` (source URL, license, speaker id), and `make voices-check` enforces it. Speakers must be anonymous dataset participants; no named or identifiable person, no scraped or "free to download" audio without a reuse license. The generic ADR-022 rule is unchanged for all other audio.
**Consequences:** Unblocks the ADR-020 fallback. Published audio may then be cloned from a real (dataset) speaker, so NOTICE and the demo credits must name the dataset and license. If no dataset passes the license check, reframe as a negative-result eval.

## ADR-029 — Reproducibility means recomputation
**Status:** accepted · 2026-11-07
**Context:** TTS sampling and LLM annotation are stochastic; audio and LLM output are not shipped, so regenerating cannot reproduce numbers.
**Decision:** Seeds are fixed, recorded and part of the cache key. The repo commits `results/` (`lines.json`, `scores.json`, `transcripts.json`, `ratings.csv`, `report.json`). "Reproduce" means recomputing `report.json` from those artifacts and matching its input hash. Full regeneration is supported but documented as non-deterministic.
**Consequences:** REQ-024 and GATE-5 are achievable; WAVs still never ship.
