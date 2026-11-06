---
doc: SECURITY
last_verified_commit: 9aa04b2
last_updated: 2026-11-05
owner: Harris Shamsi
status: draft
---

# Security — Dramatis

> Living document. Threats map to `COMP-` IDs in ARCHITECTURE.md; guardrails are referenced by gates in PHASES.md. Never write secret values here.

## 1. Scope, data classification & trust boundaries

**In scope:** the local CLI pipeline, cloud calls (annotation LLM, Groq, Langfuse), model weight supply chain, voice policy, the gate harness and guard, and the static demo site.
**Out of scope / deferred:** formal pen test; multi-user auth (no accounts exist); live generation endpoints (non-goal).

| Data | Classification | Where it lives | Notes |
|---|---|---|---|
| Public-domain story text | public | repo `corpus/`, sent to LLM + Groq | no personal data |
| Author's acted spike clips | personal (own voice) | gitignored `voices/own/`, `spike/` | scored locally, never uploaded or published (ADR-022) |
| Kokoro-generated reference clips | public (synthetic) | `voices/ref/` | provenance in `VOICES.md` |
| Generated audio | public (labeled AI-generated) | `runs/`, demo `out/` | PerTh watermark kept |
| Human ratings | internal | `runs/<id>/ratings.csv` | rater id is the author only |
| API keys (LLM, Groq, Langfuse) | secret | `.env` only | see §4 |
| Model weights | public, third-party licensed | cache outside repo | not redistributed |
| Run manifests, scores, spans | public | `runs/` | versions and metrics, no secrets |

**Trust boundaries**
- PDF file ↔ ingest (COMP-02): file contents untrusted
- Story text ↔ annotation LLM (COMP-03): text is data, never instructions; LLM output untrusted
- CLI ↔ cloud services (COMP-03, COMP-08, COMP-10): outbound only, keys from env
- Downloaded weights ↔ local runtime (COMP-05, COMP-07): supply-chain boundary
- Agent ↔ gate harness (COMP-12): the agent builds code; it must not edit what judges it
- Build output ↔ public host (COMP-11): everything in `out/` is public

## 2. Threat model

Status: `open` · `mitigated` · `accepted` (needs EXC-) · `retired`. A threat is `mitigated` only once its enforcing guardrail test exists and has passed a gate; all start `open`. Planned mitigations are listed.

| ID | Component | Entry point | Threat (STRIDE) | Impact | Likelihood | Mitigations | Status |
|---|---|---|---|---|---|---|---|
| THR-001 | COMP-02 | Input PDF | Tampering / DoS: malformed or huge PDF crashes or exhausts the parser | Low | Medium | SEC-003 | open |
| THR-002 | COMP-03 | Story text in annotation prompt | Tampering: text containing instructions steers the LLM or breaks schema | Medium | Medium | SEC-004 | open |
| THR-003 | COMP-03 | LLM response | Tampering: malformed or paraphrased output reaches synthesis or builds file paths | Medium | High | SEC-004, SEC-012 | open |
| THR-004 | COMP-04 | Reference clips | Repudiation / legal: clip of a real person or unlicensed audio used to clone a voice | High | Low | SEC-008 | open |
| THR-005 | COMP-05 | Model weights and `resemble-perth` git dependency | Tampering: compromised or swapped weights or unpinned code executed locally | High | Low | SEC-006, SEC-009 | open |
| THR-006 | COMP-05 | Generated audio | Misuse: watermark stripped or lost in export, audio passed as human | Medium | Low | SEC-007, SEC-010 | open |
| THR-007 | COMP-06 | Cache directory and manifest | Tampering: path built from untrusted text escapes cache dir; stale cache serves wrong audio | Medium | Low | SEC-012 | open |
| THR-008 | COMP-07 | Downloaded emotion2vec model and remote code | Tampering: model package runs unpinned remote code | High | Low | SEC-006, SEC-009 | open |
| THR-009 | COMP-08 | Groq API | Info disclosure / cost: audio and text sent to a third party; runaway usage hits limits | Low | Medium | SEC-005, SEC-014, SEC-002 | open |
| THR-010 | COMP-01 | `.env`, logs, run manifests | Info disclosure: API keys leak into repo, logs or manifests | High | Medium | SEC-001, SEC-002, SEC-013 | open |
| THR-011 | COMP-09 | Eval report and ratings file | Tampering: report edited or computed from stale or partial inputs to fake results | Medium | Medium | SEC-015 | open |
| THR-012 | COMP-10 | Langfuse spans | Info disclosure: keys or unnecessary content in traces | Low | Low | SEC-013, SEC-002 | open |
| THR-013 | COMP-11 | Static export | Info disclosure / misuse: secrets in bundle; unlabeled AI audio; third-party runtime fetches | Medium | Low | SEC-010, SEC-001 | open |
| THR-014 | COMP-12 | Gate harness, thresholds, CI | Tampering: agent weakens a gate, threshold or test (directly, via Bash, or by moving a tag) to pass | High | Medium | SEC-011 | open |

## 3. Guardrails

Each guardrail has an enforcement method. "Manual review" flags a candidate for automation.

### Secrets & configuration
| ID | Rule | Enforcement | Mitigates |
|---|---|---|---|
| SEC-001 | No secrets committed; static bundle contains none | `make secrets` (gitleaks) and `make secrets-site` grep of `out/` | THR-010, THR-013 |
| SEC-002 | Keys only via environment / `.env` (gitignored); never in args, logs, manifests or spans | log-redaction unit test; `.gitignore` test | THR-009, THR-010, THR-012 |

### Input handling
| ID | Rule | Enforcement | Mitigates |
|---|---|---|---|
| SEC-003 | PDF ingest: max file size and page count, text-layer only, parse errors caught, no external fetches or code execution | `tests/unit/test_ingest.py` (oversize, malformed, scanned fixtures) | THR-001 |
| SEC-004 | Story text wrapped as data in prompts; LLM output validated by pydantic schema (enum emotions, intensity range, length cap) and the verbatim rule before use; invalid → retry once → neutral fallback | `tests/unit/test_annotator.py` (injection, bad-JSON, paraphrase fixtures) | THR-002, THR-003 |
| SEC-012 | File names derive only from content hashes and fixed ids, never from text or LLM output; resolved paths stay inside the run dir | path-traversal unit test | THR-003, THR-007 |

### Data egress & cost
| ID | Rule | Enforcement | Mitigates |
|---|---|---|---|
| SEC-005 | Only public-domain story text and generated clips leave the machine; the author's own-voice clips never leave it (ADR-022) | egress allow-list test (mock transport asserts payload kinds) | THR-009 |
| SEC-014 | Per-run caps on cloud calls (lines, tokens, STT seconds) with backoff; provider-side spend limit set | config limit unit test; provider dashboard (manual) | THR-009 |

### Models, voices & ethics
| ID | Rule | Enforcement | Mitigates |
|---|---|---|---|
| SEC-006 | Weights come only from official sources at pinned revisions; remote code disabled unless reviewed and pinned; `resemble-perth` pinned by commit hash | `models.lock` pin test fails on unpinned revision or branch ref | THR-005, THR-008 |
| SEC-007 | PerTh watermark is never stripped or bypassed; generated Chatterbox audio is detected as watermarked, including after export | local GPU gate (not in CI) on WAVs and exported files; CI grep for watermark-disable code | THR-006 |
| SEC-008 | Reference clips for generated audio are Kokoro-generated; the author's own voice stays local; `VOICES.md` lists source and license per clip; no clone of a real person without documented consent | `make voices-check` | THR-004 |
| SEC-010 | Demo audio and pages carry an "AI-generated" label; demo is static with no user input and no third-party runtime fetches | `tests/unit/test_site_label.py`, `make site-check` | THR-006, THR-013 |

### Dependencies & supply chain
| ID | Rule | Enforcement | Mitigates |
|---|---|---|---|
| SEC-009 | Both environments pinned via lockfiles; high/critical advisories block gates; no AGPL dependencies | `pip-audit` (both envs), `npm audit --audit-level=high`, `make licenses` | THR-005, THR-008 |

### Process integrity (ASDD)
| ID | Rule | Enforcement | Mitigates |
|---|---|---|---|
| SEC-011 | Guarded files (ADR-028 list, incl. `Makefile`, root `conftest.py`, `docs/reviews/`) cannot be changed by the agent after a phase lock; a gate cannot be satisfied by editing it or by overriding its recipe; review boxes count only in author-signed commits | author-installed path-guard hook with draft window; signed `gates-locked-pN[-rK]` tag verified against `scripts/gates/allowed_signers`; `make guard-verify` and CI diff against the tag; `make guard-test` proves rejection; `make make-check`; `threshold-sync`; `review-check` signature check | THR-014 |
| SEC-015 | Eval report records a hash of its input artifacts and is regenerated, never hand-edited; `report.json` hash must match artifacts at gate time | `tests/gates/test_report_hash.py` | THR-011 |

### Logging & monitoring
| ID | Rule | Enforcement | Mitigates |
|---|---|---|---|
| SEC-013 | Logs and Langfuse spans contain no keys or auth headers; span payloads limited to public-domain text and metrics | redaction unit test; span-attribute allow-list test | THR-010, THR-012 |

## 4. Secrets inventory

Names only. Never values.

| Name | Purpose | Stored in | Read by | Rotation |
|---|---|---|---|---|
| GROQ_API_KEY | Whisper transcription | `.env` | COMP-08 | on exposure; quarterly |
| LLM_API_KEY | Annotation LLM (provider TBD, M1.4) | `.env` | COMP-03 | on exposure; quarterly |
| LANGFUSE_SECRET_KEY | Tracing write | `.env` | COMP-10 | on exposure |
| LANGFUSE_PUBLIC_KEY | Tracing project id | `.env` | COMP-10 | on exposure |
| LANGFUSE_BASE_URL | Langfuse endpoint (not secret) | `.env` | COMP-10 | n/a |
| HF_TOKEN (optional) | Weight download if gated | `.env` | COMP-05, COMP-07 | on exposure |

## 5. Gate security checklist

Each gate lists the triggers that add checks (new secret, external API, dependency, public surface). Results: `pass` · `fail` · `unknown`, always with evidence. Filled at each Mx.9; entries below are the pre-filled plan. THR statuses flip to `mitigated` only on a `pass` with evidence.

### GATE-1 — Spike
- Commit range: `none..HEAD`
- Triggers hit: new secret (Groq key), new external API (Groq), new dependencies (torch, chatterbox, funasr, resemble-perth), new gate harness

| Check | Guardrail | Result | Evidence |
|---|---|---|---|
| No secrets in repo | SEC-001 | unknown | `make secrets` not yet run |
| Keys from env only | SEC-002 | unknown | pending |
| Weights and Perth pinned | SEC-006 | unknown | pending |
| Watermark detected | SEC-007 | unknown | pending |
| Own-voice clips local only | SEC-005, SEC-008 | unknown | pending |
| Guard rejects tampering | SEC-011 | unknown | `make guard-test`, `make-check`, signed-tag verify pending |
| Own-voice files untracked | SEC-008 | unknown | `make voices-check` pending |

**Verdict:** unknown — plan only; fill at gate.

### GATE-2 — Core pipeline
- Triggers: new LLM provider and secret, PDF parsing, file writes
- Checks: SEC-003, SEC-004, SEC-012, SEC-005, SEC-014, SEC-009, SEC-008 (VOICES.md) — all `unknown`
**Verdict:** unknown — plan only.

### GATE-3 — Checks & eval
- Triggers: Langfuse, new cloud flow for all arms, ratings data
- Checks: SEC-013, SEC-015, SEC-014, SEC-005 — all `unknown`
**Verdict:** unknown — plan only.

### GATE-4 — Demo
- Triggers: public bundle, export format
- Checks: SEC-001 (site), SEC-010, SEC-007 on exported files, SEC-009 (npm) — all `unknown`
**Verdict:** unknown — plan only.

### GATE-5 — Release
- Triggers: public repo
- Checks: all guardrails re-run; SEC-011 final guard-verify; licenses and NOTICE; history scan for secrets — all `unknown`
**Verdict:** unknown — plan only.

## 6. Exceptions & accepted risks

Every exception must cite an ADR in DECISIONS.md.

| ID | Waives | Scope | Reason | Compensating control | Decision | Review by |
|---|---|---|---|---|---|---|
| — | — | — | none yet | — | — | — |

## 7. Incident basics

- Alerts: none automated; the author checks provider dashboards.
- Key exposure: rotate in provider → update `.env` → check provider usage logs since exposure → purge from git history if committed.
- Watermark or voice-provenance problem: take the demo down, remove the audio, fix `VOICES.md`, republish.
- Gate tampering suspected: run `make guard-verify`; restore guarded files from the signed tag; note in the phase review.

## 8. Open questions

- emotion2vec may load remote code via FunASR; confirm whether `trust_remote_code` is required and pin the revision (SEC-006). THR-008 stays `open` until resolved.
- Annotation LLM provider and its data-retention terms (chosen M1.4).
- Langfuse cloud vs self-hosted (affects SEC-013 scope).
