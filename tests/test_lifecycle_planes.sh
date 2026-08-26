#!/usr/bin/env bash
# Black-box tests for the Control Plane / Reasoning Plane boundary (TASK-006).
# Static, content-level assertions against skill/rules markdown — this repo has
# no code to run /task or /status against, so these assert the documented
# contract forbids the expensive behavior, not that an LLM will actually obey it.
#
# Usage: ./tests/test_lifecycle_planes.sh
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TOOLKIT_DIR="$(cd "$TEST_DIR/.." && pwd -P)"

PASS=0
FAIL=0

assert() {
  local desc="$1" cond="$2"
  if [ "$cond" = "0" ]; then
    printf '  \033[32m✔\033[0m %s\n' "$desc"
    PASS=$((PASS + 1))
  else
    printf '  \033[31m✘\033[0m %s\n' "$desc"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  case "$haystack" in
    *"$needle"*) assert "$desc" 0 ;;
    *) assert "$desc" 1 ;;
  esac
}

assert_not_contains() {
  local desc="$1" haystack="$2" needle="$3"
  case "$haystack" in
    *"$needle"*) assert "$desc" 1 ;;
    *) assert "$desc" 0 ;;
  esac
}

echo "== ai-toolkit-max lifecycle-planes test suite =="
echo "toolkit: $TOOLKIT_DIR"
echo

PLANES="$TOOLKIT_DIR/rules/core/lifecycle-planes.md"
STATUS="$TOOLKIT_DIR/skills/status/SKILL.md"
TASK="$TOOLKIT_DIR/skills/task/SKILL.md"
EXEC_STATE="$TOOLKIT_DIR/rules/core/execution-state.md"
TASK_CTX="$TOOLKIT_DIR/rules/core/task-context.md"

echo "-- rules/core/lifecycle-planes.md exists and defines the boundary --"
assert "lifecycle-planes.md exists" "$([ -f "$PLANES" ] && echo 0 || echo 1)"
planes_content="$(cat "$PLANES" 2>/dev/null)"
assert_contains "lists /task under Control Plane" "$planes_content" '`/task`'
assert_contains "lists /status under Control Plane" "$planes_content" '`/status`'
assert_contains "has a Control Plane heading" "$planes_content" "## Control Plane"
assert_contains "has a Reasoning Plane heading" "$planes_content" "## Reasoning Plane"

echo
echo "-- skills/status/SKILL.md: scoped citations, explicit prohibitions --"
status_content="$(cat "$STATUS" 2>/dev/null)"
assert_not_contains "no unscoped bare 'See rules/core/execution-state.md.'" "$status_content" 'See `rules/core/execution-state.md`.'
assert_contains "cites lifecycle-planes.md" "$status_content" "rules/core/lifecycle-planes.md"
assert_contains "prohibits subagent spawning" "$status_content" "subagents"
assert_contains "prohibits Supervisor invocation" "$status_content" "Supervisor decision model"
assert_contains "still read-only" "$status_content" "Read-only. Do not modify any file."

echo
echo "-- skills/task/SKILL.md: bounded duplicate-check, ambiguous-root handling --"
task_content="$(cat "$TASK" 2>/dev/null)"
assert_contains "duplicate-check scoped to TASK-*.md" "$task_content" 'TASK-*.md'
assert_contains "ambiguous root asks the human" "$task_content" "ask the human directly"
assert_contains "cites lifecycle-planes.md" "$task_content" "rules/core/lifecycle-planes.md"

echo
echo "-- skills/next/SKILL.md: scoped citations, slice-scoped inspection, guardrail present (TASK-008) --"
next_content="$(cat "$TOOLKIT_DIR/skills/next/SKILL.md" 2>/dev/null)"
assert_not_contains "no bare 'See rules/core/execution-state.md.'" "$next_content" 'See `rules/core/execution-state.md`.'
assert_contains "guardrail bounds investigation/subagents/Supervisor" "$next_content" "no subagent or background-agent spawning"
assert_contains "repo-inspection bounded to slice Scope" "$next_content" "current/candidate slice's \`Scope:\` field when a slice map exists"

echo
echo "-- skills/estimate/SKILL.md: scoped citation, guardrail present (TASK-008) --"
estimate_content="$(cat "$TOOLKIT_DIR/skills/estimate/SKILL.md" 2>/dev/null)"
assert_not_contains "no bare 'see rules/core/execution-state.md and rules/core/task-context.md.'" "$estimate_content" 'see `rules/core/execution-state.md` and `rules/core/task-context.md`.'
assert_contains "guardrail bounds investigation/subagents/Supervisor" "$estimate_content" "no subagent or background-agent spawning"

echo
echo "-- skills/verify/SKILL.md: scoped citation, guardrail present (TASK-008) --"
verify_content="$(cat "$TOOLKIT_DIR/skills/verify/SKILL.md" 2>/dev/null)"
assert_not_contains "no bare 'See rules/core/execution-state.md and rules/core/task-context.md.'" "$verify_content" 'See `rules/core/execution-state.md` and `rules/core/task-context.md`.'
assert_contains "guardrail bounds investigation/subagents/Supervisor" "$verify_content" "no subagent or background-agent spawning"

echo
echo "-- rules/core/execution-state.md: Supervisor model and Execution History format untouched --"
exec_state_content="$(cat "$EXEC_STATE" 2>/dev/null)"
assert_contains "Supervisor decision model heading still present" "$exec_state_content" "## Supervisor decision model"
assert_contains "Execution History format heading still present" "$exec_state_content" "### Execution History format"
assert_contains "cross-references lifecycle-planes.md" "$exec_state_content" "rules/core/lifecycle-planes.md"

echo
echo "-- rules/core/task-context.md: schema smoke check (AC-006 — this task never edits this file) --"
task_ctx_content="$(cat "$TASK_CTX" 2>/dev/null)"
assert_contains "Schema section still present" "$task_ctx_content" "## Schema"
assert_contains "execution_mode field still present" "$task_ctx_content" "execution_mode: MANUAL | SUPERVISED | AUTONOMOUS"

echo
echo "== $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
