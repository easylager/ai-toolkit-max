#!/usr/bin/env bash
# ai-toolkit-max health check. Read-only — makes no changes.
# Sourced by install.sh; can also be run standalone: ./scripts/doctor.sh [toolkit-dir]

run_doctor() {
  local toolkit="$1"
  local problems=0
  local ppath="" found="" mkt_path=""

  echo
  log_step "ai-toolkit-max doctor"

  if claude_present; then
    log_ok "claude CLI: $(claude_version)"
  else
    log_err "claude CLI not found on PATH"
    problems=$((problems + 1))
  fi

  if [ -f "$toolkit/.claude-plugin/plugin.json" ] && [ -f "$toolkit/.claude-plugin/marketplace.json" ]; then
    log_ok "toolkit repo: $toolkit (v$(toolkit_version "$toolkit"))"
  else
    log_err "toolkit repo manifests missing at $toolkit"
    problems=$((problems + 1))
  fi

  if ! claude_present; then
    echo
    echo "${C_RED}${C_BOLD}NOT READY${C_RESET}"
    return 1
  fi

  mkt_path="$(json_find_marketplace "$(marketplace_list_json)")"
  if [ -n "$mkt_path" ]; then
    log_ok "marketplace '$MARKETPLACE_NAME' registered -> $mkt_path"
    if [ "$mkt_path" != "$toolkit" ]; then
      log_warn "registered path differs from this repo ($toolkit) — possible duplicate clone"
    fi
  else
    log_err "marketplace '$MARKETPLACE_NAME' not registered (run ./install.sh)"
    problems=$((problems + 1))
  fi

  found="$(json_find_plugin "$(plugin_list_json)")"
  if [ -n "$found" ]; then
    local pv pscope penabled
    IFS=$'\t' read -r pv pscope penabled ppath <<< "$found"
    if [ "$penabled" = "True" ] || [ "$penabled" = "true" ]; then
      log_ok "plugin installed: v$pv (scope: $pscope, enabled)"
    else
      log_err "plugin installed but disabled (v$pv, scope: $pscope) — run: claude plugin enable $PLUGIN_NAME"
      problems=$((problems + 1))
    fi
  else
    log_err "plugin not installed (run ./install.sh)"
    problems=$((problems + 1))
  fi

  if [ -n "$ppath" ] && [ -d "$ppath/skills" ]; then
    local repo_skills installed_skills
    repo_skills="$(skill_names_in "$toolkit")"
    installed_skills="$(skill_names_in "$ppath")"
    if [ "$repo_skills" = "$installed_skills" ]; then
      log_ok "$(printf '%s' "$repo_skills" | grep -c .) skills available, matches repo"
    else
      log_err "installed skills differ from repo (stale cache) — run ./install.sh to refresh"
      problems=$((problems + 1))
    fi
  elif [ -n "$found" ]; then
    log_warn "could not verify skill inventory (install path unreadable)"
  fi

  if [ -n "$found" ]; then
    local inv
    inv="$(claude plugin details "$PLUGIN_ID" 2>/dev/null || true)"
    if printf '%s' "$inv" | grep -q 'Agents (0)' && printf '%s' "$inv" | grep -q 'Hooks (0)' && printf '%s' "$inv" | grep -q 'MCP servers (0)'; then
      log_ok "no MCP servers, hooks, or agents installed (as intended)"
    else
      log_warn "unexpected component inventory — inspect with: claude plugin details $PLUGIN_ID"
    fi
  fi

  local rule_count
  rule_count=$(find "$toolkit/rules" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  if [ "${rule_count:-0}" -gt 0 ]; then
    log_ok "$rule_count rule files available at $toolkit/rules"
  else
    log_err "no rule files found under $toolkit/rules"
    problems=$((problems + 1))
  fi

  local cwd; cwd="$(pwd -P)"
  if [ "$cwd" != "$toolkit" ] && [ -f "$cwd/CLAUDE.md" ]; then
    if grep -q "ai-toolkit-max:rules:start" "$cwd/CLAUDE.md" 2>/dev/null; then
      log_ok "this project's CLAUDE.md already imports ai-toolkit-max rules"
    else
      log_info "this project has a CLAUDE.md without ai-toolkit-max rules (run: ./install.sh --project)"
    fi
  fi

  echo
  if [ "$problems" -eq 0 ]; then
    printf '%s\n' "${C_GREEN}${C_BOLD}READY${C_RESET}"
    return 0
  else
    printf '%s\n' "${C_RED}${C_BOLD}NOT READY${C_RESET} — $problems issue(s) above"
    return 1
  fi
}
