#!/usr/bin/env bash
# ai-toolkit-max installer.
#
#   ./install.sh                 install/update the plugin for this user (default)
#   ./install.sh --project [DIR] wire rules into a project's CLAUDE.md (default DIR: cwd)
#   ./install.sh --portable      same as default, but degrades to instructions instead of failing
#   ./install.sh --doctor        health check only, no changes
#   ./install.sh --help          show usage
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
INVOKED_FROM="$(pwd -P)"
TOOLKIT_DIR="$SCRIPT_DIR"

if [ ! -f "$SCRIPT_DIR/scripts/lib.sh" ] || [ ! -f "$SCRIPT_DIR/.claude-plugin/plugin.json" ]; then
  echo "✘ install.sh must stay inside its ai-toolkit-max checkout — scripts/ or .claude-plugin/ is missing next to it at $SCRIPT_DIR." >&2
  echo "  Re-clone the repo and run ./install.sh from there, rather than copying this file elsewhere." >&2
  exit 1
fi

# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/scripts/lib.sh"
# shellcheck source=scripts/doctor.sh
source "$SCRIPT_DIR/scripts/doctor.sh"
# shellcheck source=scripts/project.sh
source "$SCRIPT_DIR/scripts/project.sh"

usage() {
  cat <<EOF
ai-toolkit-max installer

Usage:
  ./install.sh                 Install/update the toolkit plugin for this user (default)
  ./install.sh --project [DIR] Wire rules into a project's CLAUDE.md (default DIR: current directory)
  ./install.sh --portable      Same as default, but degrades to manual instructions instead of failing
  ./install.sh --doctor        Health check only — makes no changes
  ./install.sh --help          Show this help

Never installs MCP servers, hooks, or agents. Skills come from the plugin;
rules are opt-in per project via --project. Safe to re-run at any time.
EOF
}

run_install() {
  local toolkit="$1" portable="$2"

  log_step "Detecting Claude Code"
  claude_present || die "claude CLI not found on PATH. Install Claude Code first, then re-run this script."
  log_ok "claude CLI: $(claude_version)"

  log_step "Detecting toolkit version"
  local version; version="$(toolkit_version "$toolkit")"
  [ -n "$version" ] || die "could not read version from $toolkit/.claude-plugin/plugin.json"
  log_ok "ai-toolkit-max v$version at $toolkit"
  if [ -d "$toolkit/.git" ] && command -v git >/dev/null 2>&1; then
    if ! git -C "$toolkit" diff --quiet 2>/dev/null || ! git -C "$toolkit" diff --cached --quiet 2>/dev/null; then
      log_warn "repo has uncommitted changes — the installed copy will reflect what's on disk right now"
    fi
  fi

  log_step "Validating plugin manifests"
  local tmp; tmp="$(mktemp)"
  if claude plugin validate "$toolkit" >"$tmp" 2>&1; then
    log_ok "manifests valid"
  else
    cat "$tmp" >&2
    rm -f "$tmp"
    die "manifest validation failed — fix .claude-plugin/*.json before installing"
  fi

  log_step "Registering marketplace"
  if claude plugin marketplace add "$toolkit" >"$tmp" 2>&1; then
    log_ok "marketplace '$MARKETPLACE_NAME' registered (idempotent — safe to re-run)"
  else
    if [ "$portable" = "1" ]; then
      log_warn "could not register marketplace automatically"
      log_info "manual fallback — inside a Claude Code session run:"
      log_info "  /plugin marketplace add $toolkit"
      log_info "  /plugin install $PLUGIN_ID"
    else
      cat "$tmp" >&2
      rm -f "$tmp"
      die "marketplace registration failed"
    fi
  fi

  log_step "Installing plugin (refreshing so the runtime always matches this repo)"
  local existing; existing="$(json_find_plugin "$(plugin_list_json)")"
  if [ -n "$existing" ]; then
    claude plugin uninstall "$PLUGIN_NAME" >/dev/null 2>&1 || true
  fi
  if claude plugin install "$PLUGIN_ID" --scope user >"$tmp" 2>&1; then
    log_ok "plugin installed (scope: user)"
  else
    if [ "$portable" = "1" ]; then
      log_warn "could not install the plugin automatically — see manual fallback above"
    else
      cat "$tmp" >&2
      rm -f "$tmp"
      die "plugin install failed"
    fi
  fi
  rm -f "$tmp"

  if [ "$portable" = "1" ]; then
    log_step "Checking final state (portable mode: some steps above may need the manual fallback)"
  fi
  run_doctor "$toolkit"
}

MODE="install"
PROJECT_DIR=""
PORTABLE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --project)
      MODE="project"; shift
      if [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; then PROJECT_DIR="$1"; shift; fi
      ;;
    --portable) PORTABLE=1; shift ;;
    --doctor) MODE="doctor"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1 (see --help)" ;;
  esac
done

command -v python3 >/dev/null 2>&1 || die "python3 is required (used for JSON parsing) but was not found on PATH."

case "$MODE" in
  doctor)  run_doctor "$TOOLKIT_DIR" ;;
  project) setup_project "$TOOLKIT_DIR" "${PROJECT_DIR:-$INVOKED_FROM}" ;;
  install) run_install "$TOOLKIT_DIR" "$PORTABLE" ;;
esac
