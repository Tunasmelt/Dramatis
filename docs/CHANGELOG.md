---
doc: CHANGELOG
last_verified_commit: 9aa04b2
last_updated: 2026-11-05
owner: Harris Shamsi
status: draft
---

# CHANGELOG — Dramatis

Format: newest first. Breaking changes to artifact schemas and gate changes are called out explicitly.

## Unreleased

- 2026-11-07: ADR-030 added: ADR-020 fallback uses a free-licensed (CC0/public-domain-class) speech dataset for per-emotion clips; ADR-022 otherwise unchanged.
- 2026-11-07: **Docs review fixes** (13 findings: 5 high, 7 medium, low). No code yet.
  - Guard (gate change): ADR-028 widens guarded paths (`Makefile`, root `conftest.py`, `docs/reviews/`, `allowed_signers`), adds draft window, re-lock tags `gates-locked-pN-rK`, signed review commits, `make-check`. ADR-023 guard list superseded.
  - Spike (gate change): acted-clip check is now M0.4, emotion-type test M0.5 with a blind human listening check; "beats" defined; GATE-1 gains secrets/audit/docs-check/voices-check/guard-verify/env-check/review-check and a Groq-limits check; ADR-020 fallback no longer pretends Kokoro can supply emotion.
  - Thresholds: `wer_median_max` set at M0.9 via re-lock; new `wer_clip_max`; a TBD value fails GATE-3 only.
  - Reproducibility: ADR-029 (seeds in cache key, committed `results/`, reproduce = recompute).
  - Eval: paired line set across arms, `line_id` format, paired significance test, single-rater kappa caveat, aggregate `results/`.
  - Harness inventory now includes `voices-check`, `env-check`, `gate-traces`, `site-check`, `secrets-site`, `make-check`. Review file naming fixed (`phase4.md`, `GATE-(N+1)`). Langfuse-unknown rule aligned. EXT-05 Gutenberg added. Repo to live in the WSL home (ADR-024 clarified in ARCHITECTURE).

- 2026-11-05: **v4 docs set rewritten from scratch** after two external reviews and a 19-finding audit. No code yet.
  - Scope confirmed: 3 stories, full eval, Langfuse, Groq, Next.js demo, 5 gates plus guard. Schedule 2 weeks target / 3 ceiling with a written drop order (ADR-025).
  - Eval v2: three arms (`cb_controlled`, `cb_neutral`, `kokoro_neutral`), matched-sentence emotion-type test, Wilson intervals, chance level, blind rated clips, kappa (ADR-010, ADR-020).
  - Voices: reference clips generated from Kokoro; own voice only for local spike clips (ADR-022, reverses the LibriVox idea).
  - Guard redesigned: file-level, signed `gates-locked-pN` tags, local + CI diff check, two test tiers, `threshold-sync` (ADR-023).
  - Added: verbatim rule (REQ-004), gate runners and review sign-off files (ADR-027), per-phase reviews (Mx.9), thresholds in `thresholds.toml`, corpus PDF script and provenance (ADR-013), license read in Phase 0, two environments and `models.lock` with Perth commit pin (ADR-024), export format and watermark verification (ADR-026), `line_id` everywhere.
- 2026-11-04: v1–v3 docs sets generated and patched (superseded).
