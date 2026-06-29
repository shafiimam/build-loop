# Build Loop — Runbook

Autonomous build loop over your installed plugins. One command, new or ongoing.

## Install (once)

    bash install.sh

Symlinks this repo to `~/.claude/skills/build-loop`. Re-run safely any time.

## Use

In any project, invoke the **build-loop** skill. It detects state and routes:

| State          | What it does                                                        |
|----------------|--------------------------------------------------------------------|
| greenfield     | gstack role-brainstorm → `gsd-new-project` → confirm → loop         |
| has-plan-docs  | `gsd-ingest-docs --mode new` → resolve conflicts → loop             |
| gsd-ready      | runs `gsd-autonomous` straight (resumes from STATE.md)              |
| ambiguous      | stops and asks (partial `.planning/`)                               |

The loop = `gsd-autonomous`: discuss → plan → execute per phase, a fresh
subagent per phase (context-rot defense). TDD enforced by superpowers. Gray-area
blockers trigger a gstack vote.

## Brownfield (existing PLAN.md)

Detector returns `has-plan-docs`. Ingest merges `PLAN.md` + `.claude/prompts/` +
`context/` into `.planning/`. Review `.planning/INGEST-CONFLICTS.md` before the
loop runs — nothing is overwritten silently.

## Notes

- Token-heavy on long runs — use Claude Max or API.
- Resume any time: re-invoke build-loop; it continues from `STATE.md`.
- Detector standalone: `bash scripts/detect-state.sh /path/to/project`.
