# Build Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A reusable `/build-loop` router skill that detects a project's state and drives it through the autonomous build loop (gstack → gsd → gsd-autonomous → superpowers), for both greenfield and brownfield projects.

**Architecture:** Thin glue over installed plugins. A pure-shell detector (`detect-state.sh`) classifies the project into one of four states; a router skill (`SKILL.md`) branches on that state and invokes the right installed skills. No engine code is reimplemented.

**Tech Stack:** Bash (POSIX-ish, `bash`), Markdown skill files, installed plugins: `gstack`, `gsd-*`, `superpowers`. No external test framework — a pure-shell test runner is used (bats is not installed).

## Global Constraints

- Detector prints exactly one token, one of: `greenfield` | `has-plan-docs` | `gsd-ready` | `ambiguous`. Nothing else on stdout.
- Detector has **no side effects** (no writes, no mkdir).
- Detector accepts an optional first arg = project root; defaults to `.`.
- `gsd-ready` requires `.planning/` to contain **both** `ROADMAP.md` and `STATE.md`.
- Skill name is `build-loop`. Installed via symlink to `~/.claude/skills/build-loop`.
- Reuse installed plugins; do not reimplement the loop, TDD, or queue. DRY/YAGNI.

---

### Task 1: State detector + test runner

**Files:**
- Create: `scripts/detect-state.sh`
- Create: `tests/detect-state.test.sh`

**Interfaces:**
- Produces: `detect-state.sh [root]` → stdout one of `greenfield|has-plan-docs|gsd-ready|ambiguous`, exit 0.

- [ ] **Step 1: Write the failing test runner**

Create `tests/detect-state.test.sh`:

```bash
#!/usr/bin/env bash
# Pure-shell test runner for detect-state.sh (no bats dependency).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DETECT="$HERE/../scripts/detect-state.sh"
fails=0

assert_state() {
  local desc="$1" expected="$2" dir="$3"
  local got
  got="$(bash "$DETECT" "$dir")"
  if [ "$got" = "$expected" ]; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc: expected '$expected', got '$got'"
    fails=$((fails + 1))
  fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# greenfield: empty dir
mkdir -p "$tmp/green"
assert_state "empty dir -> greenfield" "greenfield" "$tmp/green"

# has-plan-docs: PLAN.md only
mkdir -p "$tmp/plan"
: > "$tmp/plan/PLAN.md"
assert_state "PLAN.md present -> has-plan-docs" "has-plan-docs" "$tmp/plan"

# has-plan-docs: context/ only
mkdir -p "$tmp/ctx/context"
assert_state "context/ present -> has-plan-docs" "has-plan-docs" "$tmp/ctx"

# gsd-ready: full .planning
mkdir -p "$tmp/ready/.planning"
: > "$tmp/ready/.planning/ROADMAP.md"
: > "$tmp/ready/.planning/STATE.md"
assert_state "full .planning -> gsd-ready" "gsd-ready" "$tmp/ready"

# gsd-ready wins even with PLAN.md present
mkdir -p "$tmp/both/.planning"
: > "$tmp/both/.planning/ROADMAP.md"
: > "$tmp/both/.planning/STATE.md"
: > "$tmp/both/PLAN.md"
assert_state "PLAN.md + full .planning -> gsd-ready" "gsd-ready" "$tmp/both"

# ambiguous: partial .planning (missing STATE.md)
mkdir -p "$tmp/partial/.planning"
: > "$tmp/partial/.planning/ROADMAP.md"
assert_state "partial .planning -> ambiguous" "ambiguous" "$tmp/partial"

echo "---"
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; exit 0; else echo "$fails FAILED"; exit 1; fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/detect-state.test.sh`
Expected: FAIL — every assert errors because `scripts/detect-state.sh` does not exist (`bash: .../detect-state.sh: No such file or directory`), final line `6 FAILED`.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/detect-state.sh`:

```bash
#!/usr/bin/env bash
# Classify a project's build-loop state. No side effects. Prints one token.
set -euo pipefail

root="${1:-.}"
planning="$root/.planning"

if [ -d "$planning" ]; then
  if [ -f "$planning/ROADMAP.md" ] && [ -f "$planning/STATE.md" ]; then
    echo "gsd-ready"
  else
    echo "ambiguous"
  fi
  exit 0
fi

if [ -f "$root/PLAN.md" ] || [ -d "$root/.claude/prompts" ] || [ -d "$root/context" ]; then
  echo "has-plan-docs"
  exit 0
fi

echo "greenfield"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `chmod +x scripts/detect-state.sh tests/detect-state.test.sh && bash tests/detect-state.test.sh`
Expected: 6 `ok` lines, final line `ALL PASS`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/detect-state.sh tests/detect-state.test.sh
git commit -m "feat: project state detector with shell tests"
```

---

### Task 2: Router skill

**Files:**
- Create: `SKILL.md`

**Interfaces:**
- Consumes: `scripts/detect-state.sh` (Task 1).
- Produces: a skill named `build-loop` that, when invoked, runs the detector and routes.

- [ ] **Step 1: Write the skill**

Create `SKILL.md`:

```markdown
---
name: build-loop
description: "Autonomous build loop for any project — detects state (new / has-PLAN / gsd-ready) and routes through gstack brainstorm, gsd ingest/new-project, and gsd-autonomous with superpowers TDD. Use when the user wants to run, start, or continue the autonomous build loop on a project."
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

\`\`\`bash
bash ~/.claude/skills/build-loop/scripts/detect-state.sh .
\`\`\`

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
```

- [ ] **Step 2: Verify the skill is well-formed**

Run: `head -8 SKILL.md`
Expected: valid YAML frontmatter with `name: build-loop` and `allowed-tools` listing `Bash`, `Read`, `Skill`, `AskUserQuestion`.

- [ ] **Step 3: Commit**

```bash
git add SKILL.md
git commit -m "feat: build-loop router skill"
```

---

### Task 3: Runbook + installer

**Files:**
- Create: `RUNBOOK.md`
- Create: `install.sh`

**Interfaces:**
- Consumes: `SKILL.md`, `scripts/detect-state.sh` (Tasks 1–2).
- Produces: `install.sh` symlinks the repo into `~/.claude/skills/build-loop`.

- [ ] **Step 1: Write the installer**

Create `install.sh`:

```bash
#!/usr/bin/env bash
# Symlink this repo as the build-loop skill. Idempotent.
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
dest="$HOME/.claude/skills/build-loop"

mkdir -p "$HOME/.claude/skills"

if [ -L "$dest" ]; then
  current="$(readlink "$dest")"
  if [ "$current" = "$repo" ]; then
    echo "Already linked: $dest -> $repo"
    exit 0
  fi
  echo "Replacing existing symlink ($current)"
  rm "$dest"
elif [ -e "$dest" ]; then
  echo "ERROR: $dest exists and is not a symlink. Move it aside first." >&2
  exit 1
fi

ln -s "$repo" "$dest"
echo "Linked: $dest -> $repo"
echo "Invoke with the build-loop skill in any project."
```

- [ ] **Step 2: Verify installer syntax (do not symlink yet)**

Run: `bash -n install.sh && echo SYNTAX_OK`
Expected: `SYNTAX_OK` (syntax check only; do not run the real symlink during the plan unless the user asks).

- [ ] **Step 3: Write the runbook**

Create `RUNBOOK.md`:

```markdown
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
```

- [ ] **Step 4: Commit**

```bash
git add RUNBOOK.md install.sh
git commit -m "docs: runbook and installer"
```

---

## Self-Review

**Spec coverage:**
- Router skill → Task 2. ✓
- `detect-state.sh` (4 states) → Task 1. ✓
- RUNBOOK.md → Task 3. ✓
- install.sh → Task 3. ✓
- tests → Task 1 (pure-shell runner; deviates from spec's `bats` because bats is not installed — same coverage: greenfield, has-plan-docs, gsd-ready, ambiguous, plus the both-present precedence case). ✓
- Control flow / routing (greenfield, has-plan-docs, gsd-ready, ambiguous) → Task 2 skill body. ✓
- Brownfield mapping (ingest → conflict gate) → Task 2 + Task 3. ✓
- Error gates (ambiguous asks, ingest conflict hard-stop, blocker vote) → Task 2. ✓
- YAGNI cuts (no claude -p, no custom queue) → honored; not built. ✓

**Placeholder scan:** No TBD/TODO; all code blocks complete. ✓

**Type consistency:** Detector output tokens identical across detector, tests, skill, runbook: `greenfield|has-plan-docs|gsd-ready|ambiguous`. ✓
