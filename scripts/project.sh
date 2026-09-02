#!/usr/bin/env bash
# ai-toolkit-max project setup — wires rules into a project's CLAUDE.md.
# Sourced by install.sh.

# Prints extra (non-core) rule paths that plausibly apply to $1, one per line.
detect_project_rules() {
  local dir="$1"
  if find "$dir" -maxdepth 2 \( -iname "*.py" -o -iname "pyproject.toml" -o -iname "requirements.txt" \) 2>/dev/null | grep -q .; then
    echo "backend/python.md"
  fi
  if [ -f "$dir/package.json" ]; then
    echo "frontend/design.md"
    if grep -q '"react"' "$dir/package.json" 2>/dev/null; then
      echo "frontend/react.md"
    fi
  fi
}

setup_project() {
  local toolkit="$1" project="$2"
  project="$(cd "$project" 2>/dev/null && pwd -P)" || die "project directory not found: $2"

  log_step "Configuring project: $project"

  local claude_md="$project/CLAUDE.md"
  local core_rules="core/engineering.md core/architecture.md core/quality.md core/security.md core/execution-state.md core/task-context.md core/project-state.md core/capabilities.md"

  local block="$CLAUDE_MD_MARK_START"
  block="${block}
<!-- Edits outside these markers are preserved; this block is regenerated on re-run of install.sh --project. -->"
  for r in $core_rules; do
    block="${block}
@$toolkit/rules/$r"
  done

  local extra=""
  while IFS= read -r r; do
    if [ -n "$r" ]; then
      block="${block}
@$toolkit/rules/$r"
      extra="${extra}${extra:+, }$r"
    fi
  done < <(detect_project_rules "$project")

  block="${block}
$CLAUDE_MD_MARK_END"

  local action
  action="$(replace_managed_block "$claude_md" "$block")"
  case "$action" in
    created)  log_ok "created $claude_md" ;;
    appended) log_ok "appended rules block to existing $claude_md (existing content preserved)" ;;
    updated)  log_ok "refreshed managed rules block in $claude_md (existing content preserved)" ;;
    *)        log_err "could not update $claude_md"; return 1 ;;
  esac

  log_info "core rules: $core_rules"
  [ -n "$extra" ] && log_info "detected project rules: $extra"
  log_info "first load of this project may show a one-time Claude Code prompt approving external CLAUDE.md includes (the imported paths point outside the project, at $toolkit)"
  return 0
}
