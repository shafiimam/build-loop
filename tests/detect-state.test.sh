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
