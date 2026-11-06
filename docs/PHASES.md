---
doc: PHASES
last_verified_commit: 9aa04b2
last_updated: 2026-11-05
owner: Harris Shamsi
status: draft
---

# PHASES — Dramatis

Phases → milestones → gates. Target 14 days, hard ceiling 21 (ADR-025). Each phase: **Mx.0** agent drafts gate scaffolding → author locks (`gates-locked-pN` signed tag) → build milestones → **Mx.9** phase review + SECURITY §5 checklist → gate. The agent never declares a phase done; it reports gate output.

## Drop order (ADR-025)

If behind schedule, cut in this order. Nothing else is cut without an ADR.

1. Word-level highlight (stretch in Phase 3)
2. Human-rated clips 30 → 15
3. Wilson intervals
4. Opus/MP3 export (ship FLAC)

## Thresholds (mirror; source of truth is `scripts/gates/thresholds.toml`, `threshold-sync` fails on mismatch)

| Name | Value | Used by |
|---|---|---|
| `vram_peak_gb_max` | 5.5 | GATE-1, GATE-3 |
| `acted_recognized_min` | 5 (of 7) | GATE-1 |
| `emotion_type_labels_pass_min` | 4 (of 6) | GATE-1 |
| `emotion_type_sentences_per_label` | 5 | GATE-1 |
| `projected_corpus_hours_max` | 4 | GATE-1, GATE-3 |
| `annotation_fallback_rate_max` | 0.10 | GATE-2 |
| `min_eligible_lines_per_label` | 10 | GATE-3 |
| `wer_median_max` | TBD (author sets at M0.9 from the Phase 0 spike clips, via re-lock; a TBD value fails GATE-3 and nothing else) | GATE-3 |
| `wer_clip_max` | TBD (set together with `wer_median_max`) | GATE-3 |
| `human_rated_clips` | 30 (min 15 under drop order) | GATE-3 |
| `watermark_detect_rate_min` | 1.0 | GATE-1, GATE-4 |

## Gate harness (built in M0.0, extended each Mx.0)

| Target | Purpose | Phase |
|---|---|---|
| `make gate-1` … `make gate-5` | Run all checks for that gate; non-zero on any failure | all |
| `make guard-test` | Prove the guard rejects a tampered guarded file | 0 |
| `make guard-verify` | Diff guarded paths against the latest signed `gates-locked-pN` tag | 0+ |
| `make threshold-sync` | `thresholds.toml` equals the mirror table above | 0+ |
| `make docs-check` | Security and API spec checkers | 0+ |
| `make secrets audit licenses` | SEC-001, SEC-009 | 0+ |
| `make review-check PHASE=N` | `docs/reviews/phaseN.md` exists, every box checked | 0+ |
| `make corpus-check` | PROVENANCE.md complete; PDFs have text layers | 1+ |
| `make voices-check` | `VOICES.md` lists every clip; no tracked file under `voices/own/` or own-voice WAV anywhere (SEC-008) | 0+ |
| `make env-check` | both envs match their lockfiles; `models.lock` pins valid (SEC-006) | 0+ |
| `make gate-traces` | `spans.jsonl` covers every LLM call, TTS job, score (SEC-013) | 2+ |
| `make site-check secrets-site` | AI-generated label, no third-party fetch; no secrets in `out/` (SEC-010, SEC-001) | 3+ |
| `make make-check` | `dev.mk` and any other included makefile define no `gate-*`, `guard-*`, `review-check`, `threshold-sync` target | 0+ |

**Guarded** (agent never edits after a lock): `Makefile` (thin: includes `gates.mk`, then `dev.mk`), `gates.mk`, `ruff.toml`, `mypy.ini`, `pytest.ini`, root `conftest.py`, `scripts/gates/` (incl. `thresholds.toml` and `allowed_signers`, the public keys that verify tags and review commits), `tests/gates/`, `.github/workflows/`, `.claude/settings.json`, `docs/reviews/`. **Unguarded:** `dev.mk` (developer targets only, policed by `make-check`), `pyproject.toml` (deps only), `src/`, `spike/`, `tests/unit/`, `tests/data/`. Gate tests run with `--confcutdir=tests/gates` so an unguarded `conftest.py` cannot affect them.

**Draft window.** The path-guard hook allows guarded edits only while the latest tag is `gates-draft-pN` (author creates it at the start of Mx.0). The signed `gates-locked-pN` tag closes the window.

**Re-lock.** A guarded file may change after a lock only by the author: edit, commit, new signed tag `gates-locked-pN-rK`. `guard-verify` diffs against the newest signed `gates-locked-*` tag. Each re-lock is logged in CHANGELOG and the phase review. Drop-order cuts (Wilson intervals, 30 → 15 clips) are done this way, never by the agent.

**Review sign-off.** `review-check` also requires `docs/reviews/phaseN.md` to be last changed in a commit signed by a key in `allowed_signers` (the agent cannot tick the boxes).

---

## Phase 0 — Spike + harness (days 1–2; may spill to day 3 inside the ceiling)

Goal: prove the risky assumptions and stand up the gate machinery before building.

| Milestone | Work | Covers |
|---|---|---|
| M0.0 | Author: move repo into the WSL home (ADR-024), add `.gitattributes` (`* text=auto eol=lf`), `git init`, GitHub remote, generate signing key and `allowed_signers`, first docs commit, second commit setting `last_verified_commit`, tag `gates-draft-p0`. Agent drafts the full harness inventory above (`Makefile`, `gates.mk`, `scripts/gates/`, `tests/gates/`, CI, `thresholds.toml`, `guard-test`). Author locks `gates-locked-p0` | REQ-023 |
| M0.1 | Repo skeleton; two envs (`envs/chatterbox`, `envs/main`); `models.lock` incl. `resemble-perth` commit; decide A-9; pick Langfuse pin (ADR-018) | REQ-019, REQ-024 |
| M0.2 | Read emotion2vec license text; record sign-off in `docs/reviews/phase0.md` (A-5); swap checker if it blocks public use | REQ-019 |
| M0.3 | Chatterbox VRAM and speed on the 4050; generate Kokoro reference clips; projected corpus runtime | REQ-005, REQ-018, REQ-020 |
| M0.4 | Author records 7 acted clips (local only); run emotion2vec; confirm output order. The checker must be validated **before** it judges anything else | REQ-009 |
| M0.5 | Intensity sweep + emotion-type test: 5 matched sentences × 7 labels × arms (`cb_controlled`, `cb_neutral`, `kokoro_neutral`), scored by the validated checker, plus blind human listening check | REQ-006, REQ-007 |
| M0.6 | End-to-end on one paragraph incl. Groq transcription; PerTh detection on a generated WAV; verify Groq free-tier limits (audio-seconds/hour, requests/min) and compute the full-run call budget (A-4) | REQ-010, REQ-017 |
| M0.9 | Phase review; SECURITY §5 GATE-1 checklist; flip THR statuses; prune Lessons; author sets `wer_median_max` and `wer_clip_max` from the ~105 spike clips and re-locks (`gates-locked-p0-r1`) | REQ-022 |

### GATE-1 — `make gate-1`

| Check | Pass condition |
|---|---|
| vram | peak ≤ `vram_peak_gb_max` |
| runtime | projected corpus ≤ `projected_corpus_hours_max` |
| license | A-5 sign-off box checked in `docs/reviews/phase0.md` |
| intensities | sweep outputs audibly differ (checklist box) |
| acted (M0.4) | ≥ `acted_recognized_min` of 7 recognized |
| emotion-type (M0.5) | `cb_controlled` beats `cb_neutral` on ≥ `emotion_type_labels_pass_min` labels (ADR-020: "beats" = strictly more checker hits over the matched sentences, ties do not count) **and** the blind human listening box in `phase0.md` is checked |
| e2e | one paragraph through all spike stages |
| watermark | detect rate ≥ `watermark_detect_rate_min` |
| groq | limits verified and call budget recorded in `phase0.md` |
| secrets, audit, docs-check, voices-check | pass (SEC-001, SEC-009, SEC-008) |
| guard-test, guard-verify, threshold-sync, make-check, env-check, review-check 0 | pass |

**Fallback if GATE-1 fails:** emotion-type fails → per-emotion reference clips from a free-licensed dataset (ADR-030, license verified and logged in `VOICES.md`); if none qualifies, reframe as a negative-result eval. Retest once after any change. Acted fails → swap checker model and retest. VRAM/runtime fails → shorten stories or drop to `cb_neutral` + Kokoro arms only (ADR required).

---

## Phase 1 — Core pipeline (days 3–6)

| Milestone | Work | Covers |
|---|---|---|
| M1.0 | Draft Phase 1 gate scaffolding; author locks `gates-locked-p1` | REQ-023 |
| M1.1 | Pydantic models, schemas export, `config/emotion_map.toml` with tests | REQ-003, REQ-007 |
| M1.2 | `ingest` + `scripts/make_corpus_pdfs.py` + `corpus/PROVENANCE.md` + `corpus-check` | REQ-001, REQ-021 |
| M1.3 | Voice library + `VOICES.md` | REQ-005, REQ-018 |
| M1.4 | Annotator (roster + segmentation, schema, verbatim, retry, fallback); choose provider (ADR), read vendor docs, add EXT-03 | REQ-002, REQ-003, REQ-004 |
| M1.5 | Synthesis, three arms; cache and manifest | REQ-006, REQ-008, REQ-016 |
| M1.6 | CLI: `ingest`, `annotate`, `synth`, `run` | REQ-015 |
| M1.9 | Phase review; SECURITY §5 GATE-2; prune Lessons | REQ-022 |

### GATE-2 — `make gate-2`

| Check | Pass condition |
|---|---|
| tests | `make lint typecheck test` clean |
| corpus | `corpus-check` passes |
| annotation | fallback rate ≤ `annotation_fallback_rate_max`; verbatim rule holds on all lines |
| cache | rerun regenerates 0 unchanged segments |
| resume | killed run resumes without redoing finished stages |
| secrets, audit, licenses, docs-check | pass |
| guard-verify, threshold-sync, review-check 1 | pass |

---

## Phase 2 — Checks and eval (days 7–9)

| Milestone | Work | Covers |
|---|---|---|
| M2.0 | Draft Phase 2 gates; author locks `gates-locked-p2` | REQ-023 |
| M2.1 | `check` (emotion2vec) | REQ-009 |
| M2.2 | `transcribe` (Groq + CPU fallback) | REQ-010 |
| M2.3 | `assemble` (`chapter.wav`, `timing.json`) | REQ-013 |
| M2.4 | `eval` + blind rating tool | REQ-011 |
| M2.5 | Langfuse tracing + `spans.jsonl` | REQ-012 |
| M2.6 | Full three-story run; sanity-check `wer_median_max` against the full-run WER distribution (change only by author re-lock, logged) | REQ-020 |
| M2.9 | Phase review; SECURITY §5 GATE-3; prune Lessons | REQ-022 |

### GATE-3 — `make gate-3`

| Check | Pass condition |
|---|---|
| full run | all three stories complete |
| vram / runtime | ≤ `vram_peak_gb_max`; ≤ `projected_corpus_hours_max` |
| eval report | per-arm per-label with n, Wilson CI, insufficient flag, chance, exclusions, paired significance for `cb_controlled` vs `cb_neutral`, intensity-unmeasured statement |
| ratings | `human_rated_clips` rated blind, stratified; kappa computed with bootstrap CI and single-rater caveat |
| WER | median ≤ `wer_median_max` (a TBD value fails); clips over `wer_clip_max` listed |
| traces | `make gate-traces` passes on `spans.jsonl`; Langfuse reachable, or `unknown` with the sign-off box in `phase2.md` checked (API.md EXT-02) |
| report hash | `report.json` input hash matches artifacts |
| guard-verify, threshold-sync, review-check 2 | pass |

---

## Phase 3 — Demo (days 10–12)

| Milestone | Work | Covers |
|---|---|---|
| M3.0 | Draft Phase 3 gates; author locks `gates-locked-p3` | REQ-023 |
| M3.1 | Site export from run artifacts | REQ-014 |
| M3.2 | `build-site` command; line-level read-along; dashboard | REQ-014, REQ-015 |
| M3.3 | Labels, credits, AI-generated notice | REQ-014 |
| M3.4 | Export format; PerTh detection on exported files (A-10); FLAC if it fails | REQ-017 |
| M3.5 | Stretch: word-level highlight (only if on schedule) | REQ-013 |
| M3.9 | Phase review; SECURITY §5 GATE-4; prune Lessons | REQ-022 |

### GATE-4 — `make gate-4`

| Check | Pass condition |
|---|---|
| build | `build-site` succeeds, static export only |
| no third-party fetch | built site makes no external requests |
| labels | AI-generated label and credits present |
| watermark | detect rate ≥ `watermark_detect_rate_min` on exported files |
| CLI complete | all nine commands present and documented |
| guard-verify, threshold-sync, review-check 3 | pass |

---

## Phase 4 — Release (days 13–14)

| Milestone | Work | Covers |
|---|---|---|
| M4.0 | Draft Phase 4 gates; author locks `gates-locked-p4` | REQ-023 |
| M4.1 | README reproduces every number by recomputing `report.json` from the committed `results/` artifacts (REQ-024); full regeneration is documented as non-deterministic | REQ-024 |
| M4.2 | NOTICE, emotion2vec license reconfirm, VOICES.md final | REQ-019, REQ-018 |
| M4.3 | Dependency, secrets and license audits; clean-clone rebuild | REQ-019, REQ-024 |
| M4.9 | Final phase review incl. ASDD retrospective (repeat-mistake count, Lessons kept/pruned, what the guard blocked) | REQ-022 |

### GATE-5 — `make gate-5`

| Check | Pass condition |
|---|---|
| clean clone | README steps recompute `report.json` from committed `results/` artifacts; hash matches; CPU unit tests with mocked engines pass |
| licenses | NOTICE complete; emotion2vec reconfirm box checked |
| audits | secrets, audit, licenses clean |
| docs | `docs-check` passes; every REQ `done` or documented |
| guard-verify, threshold-sync, review-check 4 | pass |

---

## Requirement coverage

| REQ | Milestone(s) | Gate |
|---|---|---|
| REQ-001 | M1.2 | GATE-2 |
| REQ-002 | M1.4 | GATE-2 |
| REQ-003 | M1.1, M1.4 | GATE-2 |
| REQ-004 | M1.4 | GATE-2 |
| REQ-005 | M0.3, M1.3 | GATE-1, GATE-2 |
| REQ-006 | M0.5, M1.5 | GATE-1, GATE-2 |
| REQ-007 | M0.5, M1.1 | GATE-1, GATE-2 |
| REQ-008 | M1.5 | GATE-2 |
| REQ-009 | M0.4, M2.1 | GATE-1, GATE-3 |
| REQ-010 | M0.6, M2.2 | GATE-1, GATE-3 |
| REQ-011 | M2.4 | GATE-3 |
| REQ-012 | M2.5 | GATE-3 |
| REQ-013 | M2.3, M3.5 | GATE-3, GATE-4 |
| REQ-014 | M3.1–M3.3 | GATE-4 |
| REQ-015 | M1.6, M3.2 | GATE-2, GATE-4 |
| REQ-016 | M1.5 | GATE-2 |
| REQ-017 | M0.6, M3.4 | GATE-1, GATE-4 |
| REQ-018 | M0.3, M1.3, M4.2 | GATE-1, GATE-5 |
| REQ-019 | M0.1, M0.2, M4.2, M4.3 | GATE-1, GATE-5 |
| REQ-020 | M0.3, M2.6 | GATE-1, GATE-3 |
| REQ-021 | M1.2 | GATE-2 |
| REQ-022 | every Mx.9 | all |
| REQ-023 | every Mx.0, M0.0 | all |
| REQ-024 | M0.1, M4.1, M4.3 | GATE-1, GATE-5 |
