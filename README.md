# build-loop

An autonomous **build loop** for [Claude Code](https://claude.com/claude-code) —
one skill that detects a project's state and drives it through brainstorm →
decompose → autonomous TDD build, by glueing together skills you already have.

It is a thin **router**, not an engine. It inspects the project, picks the right
entry point, and hands off to existing plugins. Works on **new** and **ongoing**
projects.

## How it works

Invoke the skill. It runs a state detector and routes:

| Your project has…                              | Detected        | What build-loop does                                              |
|------------------------------------------------|-----------------|-------------------------------------------------------------------|
| nothing (empty dir)                            | `greenfield`    | role-brainstorm → `gsd-new-project` → confirm → autonomous loop    |
| `PLAN.md` / `.claude/prompts/` / `context/`    | `has-plan-docs` | `gsd-ingest-docs --mode new` → review conflicts → autonomous loop  |
| `.planning/` with `ROADMAP.md` + `STATE.md`    | `gsd-ready`     | runs the loop straight (resumes from `STATE.md`)                   |
| partial / broken `.planning/`                  | `ambiguous`     | stops and asks you                                                 |

The **loop** = `gsd-autonomous`: discuss → plan → execute per phase, a fresh
subagent per phase (context-rot defense). TDD is enforced inside phases by
**superpowers**. Gray-area blockers trigger a role vote, then resume.

## Prerequisites

build-loop only routes — it depends on these being installed in Claude Code:

- **[superpowers](https://github.com/obra/superpowers)** — TDD backbone inside each phase
- **[GSD](https://github.com/open-gsd/gsd-core)** (`gsd-*` skills, incl. `gsd-autonomous`, `gsd-new-project`, `gsd-ingest-docs`) — phase decomposition + the loop engine
- **[gstack](https://github.com/garrytan/gstack)** (incl. `office-hours`) — role brainstorm + blocker votes

If those aren't installed, the detector still runs but the routed steps won't
resolve. Install them first.

## Install

```bash
git clone https://github.com/shafiimam/build-loop.git
cd build-loop
bash install.sh
```

`install.sh` symlinks this repo into `~/.claude/skills/build-loop` (idempotent —
re-run any time). Start a new Claude Code session to pick it up.

## Use

In any project, start Claude Code and invoke the **build-loop** skill (e.g. "run
build-loop"). It detects state and routes per the table above.

Standalone detector (no Claude needed):

```bash
bash scripts/detect-state.sh /path/to/project
# prints one of: greenfield | has-plan-docs | gsd-ready | ambiguous
```

## Notes

- Token-heavy on long runs — a higher-tier plan or API usage is recommended.
- Resume any time: re-invoke build-loop; it lands on `gsd-ready` and continues
  from `STATE.md`.
- Nothing is overwritten silently — brownfield ingest gates on a conflict review.

Full how-to: [RUNBOOK.md](RUNBOOK.md). Design + plan: [`docs/superpowers/`](docs/superpowers/).

## License

[MIT](LICENSE) © 2026 Shafi Imam
