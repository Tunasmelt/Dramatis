---
doc: HANDOFF
last_verified_commit: e543be0
last_updated: 2026-11-05
owner: Harris Shamsi
status: draft
---

# HANDOFF — Dramatis

Overwritten at the end of every session. Keep it short.

## State

- Phase: 0 (Spike + harness), M0.0 in progress. Repo now at WSL ~/Dramatis (git init + 2 docs commits done 2026-11-07). The C: copy is stale; work only in WSL.
- Docs review fixes applied 2026-11-07 (ADR-028, ADR-029, M0.4/M0.5 swap, wer thresholds moved to M0.9). CLAUDE.md updated to match. Consistency re-read done: stale refs fixed (COMP-12).
- Next (author): GitHub remote + push; signing key + `scripts/gates/allowed_signers`; tag `gates-draft-p0`. Then agent drafts the gate harness; author locks `gates-locked-p0`. Tooling gap: `uv` and `gh` not installed in Ubuntu; python3 is 3.12 (uv provides 3.11).

## Open choices (author decides)

1. Langfuse SDK pin: v3 vs v4 (ADR-018, decided in M0.1).
2. Annotation LLM provider (own ADR in M1.4, then EXT-03).
3. ADR-020 spike outcome (emotion-type test) — if it fails, per-emotion clips come from a free-licensed dataset (ADR-030, chosen 2026-11-07); pick and license-check the dataset then.
4. `wer_median_max`, `wer_clip_max` — set at M0.9 from spike clips via re-lock `gates-locked-p0-r1`.
5. (done 2026-11-07) CLAUDE.md guard list and commands updated per ADR-028.

## Before first public release

- Re-confirm the emotion2vec license; tick the box in `docs/reviews/phase4.md` (A-5, GATE-5).

## Session notes (two lines, overwritten each session)

- Worked: (none yet)
- Didn't: (none yet)
