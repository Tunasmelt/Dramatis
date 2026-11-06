---
doc: REVIEW
phase: N
gate: GATE-<N+1>   # phase N maps to GATE-(N+1): phase 0 → GATE-1 … phase 4 → GATE-5
reviewed_commit: <sha>
reviewer: Harris Shamsi
date: YYYY-MM-DD
---

# Phase N review

Parsed by `make review-check PHASE=N`: the file must exist, every `- [ ]` must be `- [x]`, and the file must be last changed in a commit signed by a key in `scripts/gates/allowed_signers`. The agent drafts; only the author ticks and signs.

## Human-judged checks
- [ ] (phase-specific item, e.g. intensity sweep outputs audibly differ)
- [ ] (phase 0 only) emotion2vec license text read; use permitted with attribution. Notes:
- [ ] (phase 0 only) blind listening: controlled clips differ in emotion type from `cb_neutral` on enough labels (ADR-020). Notes:
- [ ] (phase 0 only) Groq limits verified; full-run call budget recorded. Notes:
- [ ] (phase 2 only) Langfuse unreachable → `unknown` accepted by author (EXT-02). Notes:

## SECURITY §5 checklist
- [ ] Checklist for this gate filled with evidence; THR statuses flipped only on `pass`

## ASDD review
- [ ] Lessons pruned (wrong/irrelevant removed)
- [ ] Repeated mistakes this phase: <count and what>
- [ ] Guard blocked / flagged anything: <notes>
- [ ] Schedule vs plan: <days used>; drop-order items cut: <none|list>

## Sign-off
- [ ] Gate locked tag `gates-locked-pN` verified
- [ ] I approve moving to the next phase
