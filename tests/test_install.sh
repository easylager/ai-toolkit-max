#!/usr/bin/env bash
# Black-box tests for install.sh. Runs against isolated CLAUDE_CONFIG_DIR and
# temp project directories — never touches the real ~/.claude or a real project.
#
# Usage: ./tests/test_install.sh
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TOOLKIT_DIR="$(cd "$TEST_DIR/.." && pwd -P)"
INSTALL="$TOOLKIT_DIR/install.sh"

PASS=0
FAIL=0
CLEANUP_DIRS=()

cleanup() {
  for d in "${CLEANUP_DIRS[@]:-}"; do
    [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d"
  done
}
trap cleanup EXIT

mk_tmp() {
  local d; d="$(mktemp -d)"
  CLEANUP_DIRS+=("$d")
  printf '%s' "$d"
}

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

echo "== ai-toolkit-max install.sh test suite =="
echo "toolkit: $TOOLKIT_DIR"
echo

command -v claude >/dev/null 2>&1 || { echo "claude CLI required to run these tests"; exit 1; }

echo "-- manifests --"
out="$(claude plugin validate "$TOOLKIT_DIR" 2>&1)"; rc=$?
assert "plugin/marketplace manifests validate" "$rc"

echo
echo "-- fresh install --"
CFG1="$(mk_tmp)"
out="$(CLAUDE_CONFIG_DIR="$CFG1" "$INSTALL" 2>&1)"; rc=$?
assert "install.sh exits 0 on a fresh config" "$rc"
assert_contains "reports READY" "$out" "READY"
assert_contains "does not report NOT READY" "$( [ "$(printf '%s' "$out" | grep -c 'NOT READY')" = "0" ] && echo yes || echo no)" "yes"

n_mkt="$(CLAUDE_CONFIG_DIR="$CFG1" claude plugin marketplace list --json 2>/dev/null | python3 -c 'import json,sys;print(len(json.load(sys.stdin)))')"
assert "exactly one marketplace registered" "$([ "$n_mkt" = "1" ] && echo 0 || echo 1)"
n_plg="$(CLAUDE_CONFIG_DIR="$CFG1" claude plugin list --json 2>/dev/null | python3 -c 'import json,sys;print(len(json.load(sys.stdin)))')"
assert "exactly one plugin installed" "$([ "$n_plg" = "1" ] && echo 0 || echo 1)"

echo
echo "-- idempotency: re-run does not duplicate --"
CLAUDE_CONFIG_DIR="$CFG1" "$INSTALL" >/dev/null 2>&1
n_mkt2="$(CLAUDE_CONFIG_DIR="$CFG1" claude plugin marketplace list --json 2>/dev/null | python3 -c 'import json,sys;print(len(json.load(sys.stdin)))')"
n_plg2="$(CLAUDE_CONFIG_DIR="$CFG1" claude plugin list --json 2>/dev/null | python3 -c 'import json,sys;print(len(json.load(sys.stdin)))')"
assert "marketplace count unchanged after second run" "$([ "$n_mkt2" = "1" ] && echo 0 || echo 1)"
assert "plugin count unchanged after second run" "$([ "$n_plg2" = "1" ] && echo 0 || echo 1)"

echo
echo "-- doctor after install --"
out="$(CLAUDE_CONFIG_DIR="$CFG1" "$INSTALL" --doctor 2>&1)"; rc=$?
assert "doctor exits 0 when installed" "$rc"
assert_contains "doctor reports READY" "$out" "READY"

echo
echo "-- doctor on a config with nothing installed --"
CFG2="$(mk_tmp)"
out="$(CLAUDE_CONFIG_DIR="$CFG2" "$INSTALL" --doctor 2>&1)"; rc=$?
assert "doctor exits 1 when nothing installed" "$([ "$rc" != "0" ] && echo 0 || echo 1)"
assert_contains "doctor names the missing marketplace" "$out" "not registered"
assert_contains "doctor names the missing plugin" "$out" "not installed"

echo
echo "-- --project on a directory with no CLAUDE.md --"
PROJ1="$(mk_tmp)"
out="$("$INSTALL" --project "$PROJ1" 2>&1)"; rc=$?
assert "project setup exits 0" "$rc"
assert "CLAUDE.md was created" "$([ -f "$PROJ1/CLAUDE.md" ] && echo 0 || echo 1)"
assert_contains "CLAUDE.md imports core engineering rule" "$(cat "$PROJ1/CLAUDE.md" 2>/dev/null)" "rules/core/engineering.md"

echo
echo "-- --project preserves existing unrelated content --"
PROJ2="$(mk_tmp)"
printf '# My Project\n\nExisting notes that must survive.\n' > "$PROJ2/CLAUDE.md"
echo "dummy" > "$PROJ2/requirements.txt"
"$INSTALL" --project "$PROJ2" >/dev/null 2>&1
assert_contains "original heading preserved" "$(cat "$PROJ2/CLAUDE.md")" "# My Project"
assert_contains "original note preserved" "$(cat "$PROJ2/CLAUDE.md")" "Existing notes that must survive."
assert_contains "backend rule detected from requirements.txt" "$(cat "$PROJ2/CLAUDE.md")" "rules/backend/python.md"

echo
echo "-- --project re-run does not duplicate the managed block --"
"$INSTALL" --project "$PROJ2" >/dev/null 2>&1
blocks="$(grep -c 'ai-toolkit-max:rules:start' "$PROJ2/CLAUDE.md")"
assert "exactly one managed block after two runs" "$([ "$blocks" = "1" ] && echo 0 || echo 1)"
assert_contains "original note still present after re-run" "$(cat "$PROJ2/CLAUDE.md")" "Existing notes that must survive."

echo
echo "-- --portable degrades instead of crashing when plugin commands fail --"
FAKEBIN="$(mk_tmp)"
cat > "$FAKEBIN/claude" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "--version" ]; then echo "0.0.0 (fake)"; exit 0; fi
if [ "$1" = "plugin" ] && [ "$2" = "validate" ]; then exit 0; fi
if [ "$1" = "plugin" ] && [ "$2" = "list" ]; then echo "[]"; exit 0; fi
exit 1
EOF
chmod +x "$FAKEBIN/claude"
out="$(PATH="$FAKEBIN:$PATH" "$INSTALL" --portable 2>&1)"; rc=$?
assert_contains "portable mode prints manual fallback instead of a raw error" "$out" "manual fallback"
assert "portable mode does not crash with a bash traceback" "$([ "$rc" -le 1 ] && echo 0 || echo 1)"

echo
echo "-- unknown flag fails clearly --"
out="$("$INSTALL" --bogus 2>&1)"; rc=$?
assert "unknown flag exits non-zero" "$([ "$rc" != "0" ] && echo 0 || echo 1)"
assert_contains "unknown flag names itself in the error" "$out" "--bogus"

echo
echo "== $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
