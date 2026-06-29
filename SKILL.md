---
name: build-loop
description: "Autonomous build loop for any project — detects state (greenfield / has-plan-docs / gsd-ready / ambiguous) and routes through gstack brainstorm, gsd ingest/new-project, and gsd-autonomous with superpowers TDD. Use when the user wants to run, start, or continue the autonomous build loop on a project."
allowed-tools:
  - Bash
  - Read
  - Skill
  - AskUserQuestion
---

# Build Loop

Router over installed plugins. One entry point for new and ongoing projects.

## Step 1 — Detect state

Run the detector. If the build-loop repo is symlinked into `~/.claude/skills/build-loop`,
the script sits beside this file at `scripts/detect-state.sh`:

```bash
bash ~/.claude/skills/build-loop/scripts/detect-state.sh .
```

If that path is missing, run the equivalent checks inline:
`.planning/` with `ROADMAP.md`+`STATE.md` → `gsd-ready`; `.planning/` partial →
`ambiguous`; else `PLAN.md`/`.claude/prompts/`/`context/` → `has-plan-docs`;
else `greenfield`.

## Step 2 — Route on the result

- **greenfield** → invoke `office-hours` (gstack) for a CEO/Engineer/Designer
  role brainstorm into a spec. Then invoke `gsd-new-project` to build the
  ROADMAP. **Gate:** confirm the ROADMAP with the user. Then go to Step 3.

- **has-plan-docs** → invoke `gsd-ingest-docs` with `--mode new` to synthesize
  `.planning/` from the existing `PLAN.md` + `.claude/prompts/` + `context/`.
  **Gate:** if `.planning/INGEST-CONFLICTS.md` lists unresolved blockers, stop
  and surface them to the user. Resolve before continuing. Then go to Step 3.

- **gsd-ready** → go straight to Step 3 (resumes from `STATE.md`).

- **ambiguous** → STOP. Show the user what was found (partial `.planning/`) and
  ask how to proceed. Never guess.

## Step 3 — Run the loop

Invoke `gsd-autonomous` to run all remaining phases (discuss → plan → execute
per phase, fresh subagent per phase). TDD is enforced inside phases by
superpowers. On a gray-area blocker a phase pauses; dispatch `office-hours`
(gstack) for a role vote, then resume. If still stuck, pause for the user.

## Guardrails

- Token-heavy. Recommend Claude Max or API usage for long runs.
- Never overwrite existing plan docs silently — ingest goes through the
  conflict gate.
- Resume any time by re-invoking this skill: it lands on `gsd-ready` and
  continues.
