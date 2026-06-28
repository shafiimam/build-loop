# Build Loop — Design Spec

**Date:** 2026-06-29
**Status:** Approved
**Author:** shafi (with Claude)

## Purpose

A reusable autonomous build-loop usable across projects — both greenfield and
ongoing (brownfield with an existing `PLAN.md` + prompts + context). It is a
thin **router + glue** layer over already-installed plugins, not new engine
code.

Maps the video methodology (GStack → GSD → RalphLoop → Superpowers) onto the
user's installed tooling:

| Video term  | Installed tool                          | Role                          |
|-------------|------------------------------------------|-------------------------------|
| GStack      | `gstack` (office-hours, plan-*-review)    | Role-based brainstorm + votes |
| GSD         | `gsd-*` skills                            | Decompose to phases; loop     |
| RalphLoop   | `gsd-autonomous` (engine) / `ralph-loop`  | Autonomous per-phase loop     |
| Superpowers | `superpowers`                             | TDD backbone inside phases    |

## Decisions

- **Engine = `gsd-autonomous`** (approach B). It already runs
  discuss→plan→execute per phase, dispatching heavy work to fresh background
  subagents (per-phase context isolation = the context-rot defense). We do not
  reimplement a `claude -p` shell orchestrator.
- **Glue, not rebuild.** Reuse installed plugins. DRY/YAGNI.
- **Must work new + brownfield.** Overrides the video's "brownfield = use
  frameworks individually" advice.

## Components

All live in the `build-loop/` source repo.

1. **`SKILL.md`** — the router skill. Detects project state, routes to the
   correct entry, kicks off the loop. The only "brain."
2. **`scripts/detect-state.sh`** — pure detector, no side effects. Prints exactly
   one of: `greenfield` | `has-plan-docs` | `gsd-ready` | `ambiguous`.
3. **`RUNBOOK.md`** — human how-to for new + brownfield; token/plan notes (use
   Claude Max / API for token volume).
4. **`install.sh`** — idempotent symlink of the skill into
   `~/.claude/skills/build-loop`.
5. **`tests/detect-state.bats`** — asserts the detector on fixture layouts.

## Control Flow

```
/build-loop
  └─ detect-state.sh
       greenfield    → gstack role-brainstorm (CEO/Eng/Designer) → spec
                       → gsd-new-project (ROADMAP) → [confirm gate] → gsd-autonomous
       has-plan-docs → gsd-ingest-docs --mode new   (PLAN.md/prompts/context → .planning/)
                       → [review INGEST-CONFLICTS.md gate] → gsd-autonomous
       gsd-ready     → gsd-autonomous  (straight; resumes from STATE.md)
       ambiguous     → ASK the user, do not guess
```

- **Loop** = `gsd-autonomous` (per-phase fresh subagent).
- **TDD** = `superpowers`, inside each phase (gsd already enforces).
- **Blocker / gray-area vote** = `gstack` (`office-hours` / `plan-eng-review`),
  auto-dispatched on a gray-area decision; if still stuck → pause for human.

## State Detection Rules

`detect-state.sh` checks, in order:

1. `.planning/` directory present → `gsd-ready`.
2. `.planning/` absent **and** any of (`PLAN.md`, `.claude/prompts/`,
   `context/`) present → `has-plan-docs`.
3. None of the above, directory effectively empty of plan artifacts →
   `greenfield`.
4. Conflicting signals that cannot be classified → `ambiguous`.

## Brownfield Mapping

Existing `PLAN.md` + `.claude/prompts/*` + `context/*` →
`gsd-ingest-docs --mode new` synthesizes `.planning/` (PROJECT.md,
REQUIREMENTS.md, ROADMAP.md, STATE.md). Conflicts surface in
`.planning/INGEST-CONFLICTS.md` as a **human gate** before any loop runs.
Nothing is overwritten silently.

## Error Handling / Gates

- Detector `ambiguous` → ask the user; never guess.
- Unresolved ingest conflicts → hard-stop at gate.
- Phase blocker → gstack vote; still stuck → pause for human.
- Resume: re-run `/build-loop` → lands on `gsd-ready` → `gsd-autonomous`
  continues from `STATE.md`.

## Testing

- `detect-state.sh` is the only real logic → `bats` tests over fixture dirs:
  empty, PLAN-only, `.planning`-present, both-present (ambiguous).
- Router + loop = reuse of tested plugins; no new test burden there.

## YAGNI / Out of Scope

- No `claude -p` shell runner (approach A rejected).
- No custom queue/state file — `STATE.md` / `ROADMAP.md` already are it.
- No new TDD code — superpowers owns it.
- No global slash-command bootstrap beyond `install.sh` symlink.

## Success Criteria

- `/build-loop` in an empty dir runs brainstorm → roadmap → autonomous loop.
- `/build-loop` in the existing project (PLAN.md + prompts) ingests to
  `.planning/`, gates on conflicts, then runs the loop.
- `/build-loop` in a `.planning/`-ready project resumes the loop directly.
- Detector classifies all four fixture layouts correctly under test.
