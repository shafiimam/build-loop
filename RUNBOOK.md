# Build Loop — Runbook

A hybrid orchestrator over your installed tools. One command, new or ongoing.

```
gbrain       MEMORY   remembers decisions + code across sessions
gstack       BRAINS   front: plan/design   back: review/QA/ship
GSD          ENGINE   decompose into phases + autonomous build
superpowers  METHOD   TDD inside every phase
```

## Install (once)

    bash install.sh

Symlinks this repo to `~/.claude/skills/build-loop`. Re-run safely any time.

## Use

In any project, invoke the **build-loop** skill. It runs:

0. **Memory** — uses gbrain if connected; offers `setup-gbrain` if not (optional).
1. **Detect state** — greenfield / has-plan-docs / gsd-ready / ambiguous.
2. **Plan + design (gstack, front)** — route by state:

   | State          | What it does                                                          |
   |----------------|----------------------------------------------------------------------|
   | greenfield     | `office-hours` → (UI: `design-shotgun`→`plan-design-review`) → `plan-eng-review` → `autoplan` → `gsd-import` |
   | has-plan-docs  | `gsd-ingest-docs --mode new` → resolve conflicts                      |
   | gsd-ready      | skip straight to build (resumes from STATE.md)                        |
   | ambiguous      | stops and asks (partial `.planning/`)                                 |

3. **Build (GSD + superpowers)** — `gsd-autonomous`: discuss → plan → execute per
   phase, fresh subagent per phase (context-rot defense). TDD inside each phase
   via superpowers. Gray-area blocker → gstack vote (`plan-design-review` for UI,
   else `office-hours`) → resume.
4. **Review + test + ship (gstack, back)** — `review` → `qa` (real browser) →
   `ship` / `land-and-deploy`.
5. **Reflect** — optional `retro`; persists to gbrain if connected.

## Browser policy

All browser work — launch, navigate, screenshot, DevTools, QA — goes through
gstack's `browse` skill (and `qa`). Never the default Chrome integration or
`mcp__claude-in-chrome__*` / `chrome-devtools` tools.

## Brownfield (existing PLAN.md)

Detector returns `has-plan-docs`. Ingest merges `PLAN.md` + `.claude/prompts/` +
`context/` into `.planning/`. Review `.planning/INGEST-CONFLICTS.md` before the
loop runs — nothing is overwritten silently.

## Notes

- Token-heavy on long runs — use Claude Max or API.
- Resume any time: re-invoke build-loop; it continues from `STATE.md`.
- Detector standalone: `bash scripts/detect-state.sh /path/to/project`.
