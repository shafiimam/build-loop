---
name: build-loop
description: "Use when the user wants to start, run, resume, or autonomously build a project end-to-end. Orchestrates gstack (plan/design/review/ship), GSD (phase decomposition + autonomous build), superpowers (TDD), and gbrain (memory) into one hybrid loop. Works on new and ongoing projects."
allowed-tools:
  - Bash
  - Read
  - Skill
  - AskUserQuestion
---

# Build Loop

A hybrid orchestrator. Four tools, each at its own altitude:

```
gbrain       MEMORY      remembers decisions + code across all sessions
gstack       BRAINS      front: plan/design   back: review/QA/ship
GSD          ENGINE      decompose into phases + run them autonomously
superpowers  METHOD      TDD inside every phase
```

Front and back are gstack. The middle is GSD. The method inside each phase is
superpowers. gbrain is the shared memory all of them read from.

Run the steps in order. Skip a step only when the rule for that step says so.

## Step 0 — Memory (gbrain)

Check whether gbrain is connected (any `gbrain` MCP tool available, or
`~/.gbrain`/`~/.gstack` present).

- If connected → throughout this loop, prefer gbrain **semantic search** over
  blind grep, and **recall** past decisions ("what did we decide about X?")
  before re-asking the user.
- If not connected → mention it once and offer `setup-gbrain` (PGLite local,
  ~30s). gbrain is optional — if the user declines, continue without it. Do not
  block the loop on it.

## Step 1 — Detect state

```bash
bash ~/.claude/skills/build-loop/scripts/detect-state.sh .
```

If that path is missing, check inline: `.planning/` with `ROADMAP.md`+`STATE.md`
→ `gsd-ready`; `.planning/` partial → `ambiguous`; else
`PLAN.md`/`.claude/prompts/`/`context/` → `has-plan-docs`; else `greenfield`.

## Step 2 — PLAN + DESIGN (gstack, front)

Route on the detected state. This is where human judgment lives — gstack owns it.

- **greenfield** → run the gstack planning chain, then hand the plan to GSD:
  1. `office-hours` — reframe the product, write the design doc.
  2. **If the work is UI/frontend:** `design-shotgun` (explore directions) →
     `plan-design-review` (rate dimensions, kill AI slop, lock choices).
  3. `plan-eng-review` — lock architecture + test plan.
  4. `autoplan` — turn it into a build plan; **save it to a file** (e.g.
     `docs/plan.md`).
  5. Hand off to GSD: `gsd-import --from docs/plan.md` (or `gsd-new-project` if
     you prefer GSD to build the ROADMAP from the design doc).
  **Gate:** confirm the ROADMAP with the user before building.

- **has-plan-docs** → `gsd-ingest-docs --mode new` to synthesize `.planning/`
  from the existing `PLAN.md` + `.claude/prompts/` + `context/`.
  **Gate:** if `.planning/INGEST-CONFLICTS.md` lists unresolved blockers, stop
  and surface them. Resolve before building.

- **gsd-ready** → skip to Step 3 (resumes from `STATE.md`).

- **ambiguous** → STOP. Show what was found (partial `.planning/`) and ask.
  Never guess.

## Step 3 — BUILD (GSD engine + superpowers method)

Invoke `gsd-autonomous` to run all remaining phases (discuss → plan → execute,
a fresh subagent per phase = context-rot defense).

Inside each phase, superpowers is the backbone — the builder works through:
`writing-plans` (phase → tasks) → `subagent-driven-development` (fresh subagent
per task) → `test-driven-development` (RED → GREEN → REFACTOR) →
`systematic-debugging` (on unexpected failures) → `verification-before-completion`
(gate before the phase is marked done).

**Blocker handling:** on a gray-area decision a phase pauses. Route the call to
gstack — `plan-design-review` for a UI/design choice, otherwise `office-hours` —
get the vote, then resume. If still stuck, pause for the user.

## Step 4 — REVIEW + TEST + SHIP (gstack, back)

After the phases build the code, hand it back to gstack:

1. `review` — find production bugs.
2. `qa` — open a real browser and test the running app (essential for UI).
3. `ship` (or `land-and-deploy`) — open the PR and verify fixes landed.

## Step 5 — REFLECT

Optionally run `retro` to capture learnings. If gbrain is connected, the
decisions, plan, and retro persist there — so the next session remembers this one.

## Guardrails

- Token-heavy. Recommend Claude Max or API usage for long runs.
- One source of truth: once a plan is imported into GSD, edit it in `.planning/`,
  not the original gstack doc. Re-import on big changes.
- Don't double-plan: gstack does the high-level plan once; GSD does the
  per-phase detail. Don't re-run `autoplan` inside each phase.
- Match process to size: a one-component tweak skips Steps 2–3 — just build and
  run `qa`. Bring the full loop only when there are multiple phases worth
  automating.
- Never overwrite existing plan docs silently — ingest goes through the conflict
  gate.
- Resume any time by re-invoking this skill: it lands on `gsd-ready` and continues.
