# build-loop

An autonomous **build loop** for [Claude Code](https://claude.com/claude-code) —
one skill that takes a project from idea to shipped by orchestrating four tools
you already have, each at its own altitude:

```
gbrain       MEMORY   remembers decisions + code across sessions
gstack       BRAINS   front: plan/design   back: review/QA/ship
GSD          ENGINE   decompose into phases + autonomous build
superpowers  METHOD   TDD inside every phase
```

It is a thin **router**, not an engine. It inspects the project, picks the right
entry point, and hands the work between these tools. Works on **new** and
**ongoing** projects.

## How it works

Invoke the skill. It runs a hybrid loop:

0. **Memory** — uses gbrain if connected (semantic code search + recall of past
   decisions); offers `setup-gbrain` if not. Optional.
1. **Detect state** — then route through the front:

   | Your project has…                            | Detected        | Plan + design (gstack, front)                                     |
   |----------------------------------------------|-----------------|-------------------------------------------------------------------|
   | nothing (empty dir)                          | `greenfield`    | `office-hours` → (UI: `design-shotgun`→`plan-design-review`) → `plan-eng-review` → `autoplan` → `gsd-import` |
   | `PLAN.md` / `.claude/prompts/` / `context/`  | `has-plan-docs` | `gsd-ingest-docs --mode new` → review conflicts                   |
   | `.planning/` with `ROADMAP.md` + `STATE.md`  | `gsd-ready`     | skip straight to build (resumes from `STATE.md`)                  |
   | partial / broken `.planning/`                | `ambiguous`     | stops and asks you                                                |

2. **Build** — `gsd-autonomous`: discuss → plan → execute per phase, a fresh
   subagent per phase (context-rot defense). TDD enforced inside each phase by
   **superpowers**. Gray-area blocker → gstack vote, then resume.
3. **Review + test + ship** (gstack, back) — `review` → `qa` (real browser) →
   `ship` / `land-and-deploy`. Optional `retro` persists learnings to gbrain.

## Prerequisites

build-loop only routes — it depends on these being installed in Claude Code:

- **[superpowers](https://github.com/obra/superpowers)** — TDD backbone inside each phase
- **[GSD](https://github.com/open-gsd/gsd-core)** (`gsd-*` skills, incl. `gsd-autonomous`, `gsd-import`, `gsd-ingest-docs`, `gsd-new-project`) — phase decomposition + the loop engine
- **[gstack](https://github.com/garrytan/gstack)** (incl. `office-hours`, `plan-design-review`, `plan-eng-review`, `autoplan`, `review`, `qa`, `ship`) — planning, design, review, QA, ship
- **[gbrain](https://github.com/garrytan/gbrain)** (via gstack's `setup-gbrain`) — *optional* persistent memory: semantic code search + cross-session recall

The first three are required; gbrain is optional. If the required ones aren't
installed, the detector still runs but the routed steps won't resolve — install
them first.

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
- All browser work (testing, screenshots, DevTools) routes through gstack's
  `browse` skill — not the default Chrome integration.

Full how-to: [RUNBOOK.md](RUNBOOK.md). Design + plan: [`docs/superpowers/`](docs/superpowers/).

## License

[MIT](LICENSE) © 2026 Shafi Imam
