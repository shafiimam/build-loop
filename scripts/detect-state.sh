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
