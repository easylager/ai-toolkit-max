#!/usr/bin/env bash
# Shared helpers for ai-toolkit-max install/doctor/project scripts.
# Sourced, never executed directly.

PLUGIN_NAME="ai-toolkit-max"
MARKETPLACE_NAME="ai-toolkit-max"
PLUGIN_ID="${PLUGIN_NAME}@${MARKETPLACE_NAME}"

CLAUDE_MD_MARK_START="<!-- ai-toolkit-max:rules:start (managed by install.sh --project — do not hand-edit between markers) -->"
CLAUDE_MD_MARK_END="<!-- ai-toolkit-max:rules:end -->"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BOLD=$'\033[1m'; C_RESET=$'\033[0m'
else
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_BOLD=""; C_RESET=""
fi

log_step() { printf '%s\n' "${C_BOLD}==>${C_RESET} $*"; }
log_ok()   { printf '%s\n' "  ${C_GREEN}✔${C_RESET} $*"; }
log_warn() { printf '%s\n' "  ${C_YELLOW}!${C_RESET} $*"; }
log_err()  { printf '%s\n' "  ${C_RED}✘${C_RESET} $*" >&2; }
log_info() { printf '%s\n' "  - $*"; }

die() { log_err "$*"; exit 1; }

claude_present() { command -v claude >/dev/null 2>&1; }
claude_version() { claude --version 2>/dev/null | head -1; }

toolkit_version() {
  # $1 = toolkit root
  python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['version'])" "$1/.claude-plugin/plugin.json" 2>/dev/null
}

plugin_list_json()      { claude plugin list --json 2>/dev/null || echo "[]"; }
marketplace_list_json() { claude plugin marketplace list --json 2>/dev/null || echo "[]"; }

# Prints "version<TAB>scope<TAB>enabled<TAB>installPath" for our plugin, or nothing if not installed.
json_find_plugin() {
  python3 -c "
import json,sys
data=json.loads(sys.argv[1])
for p in data:
    if p.get('id','').startswith('${PLUGIN_NAME}@'):
        print(p.get('version',''), p.get('scope',''), p.get('enabled',''), p.get('installPath',''), sep='\t')
        break
" "$1"
}

# Prints the registered path for our marketplace, or nothing if not registered.
json_find_marketplace() {
  python3 -c "
import json,sys
data=json.loads(sys.argv[1])
for m in data:
    if m.get('name')=='${MARKETPLACE_NAME}':
        print(m.get('path', m.get('installLocation','')))
        break
" "$1"
}

# Lists skill directory names in a toolkit tree that contain SKILL.md, one per line, sorted.
skill_names_in() {
  local dir="$1/skills"
  [ -d "$dir" ] || return 0
  ( cd "$dir" && for d in */; do [ -f "${d}SKILL.md" ] && printf '%s\n' "${d%/}"; done | sort )
}

# Replace (or create/append) the managed CLAUDE.md block. $1=file $2=block content (no trailing marker newline needed).
# Prints "created"/"appended"/"updated" on stdout.
replace_managed_block() {
  local file="$1" block="$2"
  ATM_TARGET_FILE="$file" ATM_BLOCK="$block" \
  ATM_MARK_START="$CLAUDE_MD_MARK_START" ATM_MARK_END="$CLAUDE_MD_MARK_END" \
  python3 <<'PYEOF'
import os, re
path = os.environ["ATM_TARGET_FILE"]
block = os.environ["ATM_BLOCK"]
start = os.environ["ATM_MARK_START"]
end = os.environ["ATM_MARK_END"]
try:
    with open(path) as f:
        content = f.read()
except FileNotFoundError:
    content = ""
pattern = re.compile(re.escape(start) + r".*?" + re.escape(end), re.DOTALL)
if pattern.search(content):
    new_content = pattern.sub(lambda m: block, content)
    action = "updated"
elif content:
    sep = "" if content.endswith("\n\n") else ("\n" if content.endswith("\n") else "\n\n")
    new_content = content + sep + block + "\n"
    action = "appended"
else:
    new_content = block + "\n"
    action = "created"
with open(path, "w") as f:
    f.write(new_content)
print(action)
PYEOF
}
