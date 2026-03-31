#!/usr/bin/env bash
# workspace.sh - Workspace preparation functions for review orchestrator
#
# Exports:
#   resolve_plan_path()
#   copy_file_into_workspace()
#   copy_repo_file_into_workspace()
#   copy_root_context_into_workspace()
#   collect_code_impl_scope()
#   run_pre_checks()
#   prepare_workspace()

resolve_plan_path() {
  local candidate_path=""
  if [[ -f "$PLAN_PATH" ]]; then
    candidate_path="$PLAN_PATH"
  elif [[ -f "$REPO_ROOT/$PLAN_PATH" ]]; then
    candidate_path="$REPO_ROOT/$PLAN_PATH"
  else
    die $EXIT_INPUT_NOT_FOUND "plan file not found: $PLAN_PATH"
  fi

  local resolved
  resolved="$(realpath "$candidate_path" 2>/dev/null)" || die $EXIT_INPUT_NOT_FOUND "failed to resolve plan path: $candidate_path"

  if printf '%s' "$resolved" | grep -q '[[:cntrl:]]'; then
    die $EXIT_INPUT_NOT_FOUND "plan path contains control characters: $PLAN_PATH"
  fi

  local allowed_roots=("$REPO_ROOT")
  if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    allowed_roots+=("$(realpath "$CLAUDE_PLUGIN_ROOT" 2>/dev/null || printf '%s' "$CLAUDE_PLUGIN_ROOT")")
  fi
  allowed_roots+=("$PLUGIN_ROOT")

  local contained=0
  local root=""
  for root in "${allowed_roots[@]}"; do
    if [[ "$resolved" == "$root"/* || "$resolved" == "$root" ]]; then
      contained=1
      break
    fi
  done
  [[ "$contained" -eq 1 ]] || die $EXIT_INPUT_NOT_FOUND "plan path outside allowed roots: $resolved"

  printf '%s\n' "$resolved"
}

copy_file_into_workspace() {
  local source_abs="$1"
  local destination_rel="$2"
  local dest="$WORKSPACE_ROOT/$destination_rel"
  mkdir -p "$(dirname -- "$dest")"
  cp -p "$source_abs" "$dest"
}

copy_repo_file_into_workspace() {
  local rel_path="$1"
  local source_abs="$REPO_ROOT/$rel_path"
  [[ -f "$source_abs" ]] || return 0
  source_abs="$(realpath "$source_abs")"
  [[ "$source_abs" == "$REPO_ROOT"/* || "$source_abs" == "$REPO_ROOT" ]] || die $EXIT_INPUT_NOT_FOUND "file outside repo root: $source_abs"
  copy_file_into_workspace "$source_abs" "$rel_path"
}

copy_root_context_into_workspace() {
  if [[ -f "$REPO_ROOT/AGENTS.md" ]]; then
    copy_repo_file_into_workspace "AGENTS.md"
    return
  fi
  if [[ -f "$REPO_ROOT/CLAUDE.md" ]]; then
    copy_repo_file_into_workspace "CLAUDE.md"
  fi
}

workspace_relative_path_for() {
  local source_abs="$1"
  local external_dir="$2"

  if [[ "$source_abs" == "$REPO_ROOT"/* ]]; then
    realpath --relative-to="$REPO_ROOT" "$source_abs"
    return
  fi

  printf '%s/%s\n' "$external_dir" "$(basename -- "$source_abs")"
}

collect_code_impl_scope() {
  local -A seen=()
  local path=""

  if [[ ${#CODE_IMPL_FILES[@]} -gt 0 ]]; then
    for path in "${CODE_IMPL_FILES[@]}"; do
      if [[ -f "$path" ]]; then
        path="$(realpath --relative-to="$REPO_ROOT" "$path" 2>/dev/null || printf '%s' "$path")"
      fi
      seen["$path"]=1
    done
  else
    while IFS= read -r -d '' path; do
      [[ -n "$path" ]] || continue
      seen["$path"]=1
    done < <(git -C "$REPO_ROOT" diff --name-only -z --)

    while IFS= read -r -d '' path; do
      [[ -n "$path" ]] || continue
      seen["$path"]=1
    done < <(git -C "$REPO_ROOT" diff --cached --name-only -z --)

    while IFS= read -r -d '' path; do
      [[ -n "$path" ]] || continue
      seen["$path"]=1
    done < <(git -C "$REPO_ROOT" ls-files --others --exclude-standard -z --)

    # Fallback: diff committed changes against base branch
    if [[ "${#seen[@]}" -eq 0 ]]; then
      local base_ref=""
      for candidate in main master origin/main origin/master; do
        if git -C "$REPO_ROOT" rev-parse --verify "$candidate" >/dev/null 2>&1; then
          base_ref="$candidate"
          break
        fi
      done
      if [[ -n "$base_ref" ]]; then
        log "step=scope_fallback base_ref=$base_ref"
        while IFS= read -r -d '' path; do
          [[ -n "$path" ]] || continue
          seen["$path"]=1
        done < <(git -C "$REPO_ROOT" diff --name-only -z "$base_ref"..HEAD --)
      fi
    fi
  fi

  if [[ "${#seen[@]}" -eq 0 ]]; then
    die $EXIT_EMPTY_SCOPE "implementation review scope is empty"
  fi

  CODE_IMPL_SCOPE=()
  for path in "${!seen[@]}"; do
    [[ -f "$REPO_ROOT/$path" ]] || continue
    CODE_IMPL_SCOPE+=("$path")
  done

  if [[ "${#CODE_IMPL_SCOPE[@]}" -eq 0 ]]; then
    die $EXIT_EMPTY_SCOPE "code implementation review scope has no existing files"
  fi

  IFS=$'\n' CODE_IMPL_SCOPE=($(printf '%s\n' "${CODE_IMPL_SCOPE[@]}" | sort))
  unset IFS
}

run_pre_checks() {
  local pre_check_script="$SCRIPT_DIR/pre-checks.sh"
  local findings_file="$TMP_DIR/pre-check-findings.json"

  if [[ ! -f "$pre_check_script" ]]; then
    log "step=pre_checks status=skipped reason=script_not_found"
    printf '{"findings":[]}\n' > "$findings_file"
    printf '%s\n' "$findings_file"
    return
  fi

  local files_arg=""
  if [[ "$MODE" == "code-impl" ]]; then
    for file in "${CODE_IMPL_SCOPE[@]}"; do
      files_arg+=" --files $REPO_ROOT/$file"
    done
  elif [[ -n "$RESOLVED_PLAN" ]]; then
    files_arg=" --files $RESOLVED_PLAN"
  fi

  log "step=pre_checks mode=$MODE timeout=10"
  local pre_check_rc=0
  bash "$pre_check_script" --mode "$MODE" $files_arg --timeout 10 > "$findings_file" 2>/dev/null || pre_check_rc=$?

  if [[ "$pre_check_rc" -ne 0 ]] || ! jq -e . "$findings_file" >/dev/null 2>&1; then
    log "step=pre_checks status=failed exit_code=$pre_check_rc action=continue_with_empty"
    printf '{"findings":[]}\n' > "$findings_file"
  else
    local finding_count
    finding_count="$(jq '.findings | length' "$findings_file" 2>/dev/null || echo 0)"
    log "step=pre_checks status=ok findings=$finding_count"
  fi

  printf '%s\n' "$findings_file"
}

filter_code_impl_scope_to_allowed_touch_set() {
  if ! declare -p ALLOWED_TOUCH_SET >/dev/null 2>&1; then
    return
  fi

  local -a touched_files=("${CODE_IMPL_SCOPE[@]}")
  mapfile -t CODE_IMPL_SCOPE < <(intersect_paths_from_array ALLOWED_TOUCH_SET "${touched_files[@]}")
  mapfile -t OUT_OF_SCOPE_TOUCHED_FILES < <(subtract_paths_from_array ALLOWED_TOUCH_SET "${touched_files[@]}")

  if [[ "${#CODE_IMPL_SCOPE[@]}" -eq 0 ]]; then
    die $EXIT_EMPTY_SCOPE "code implementation review scope has no in-scope files after allowed-touch filtering"
  fi
}

prepare_workspace() {
  WORKSPACE_ROOT="$TMP_DIR/workspace"
  WORKSPACE_PLAN_PATH=""
  WORKSPACE_DESIGN_PATH=""
  mkdir -p "$WORKSPACE_ROOT"
  copy_root_context_into_workspace

  if [[ -n "${DESIGN_PATH:-}" ]]; then
    local design_rel=""
    design_rel="$(workspace_relative_path_for "$DESIGN_PATH" "external-design")"
    copy_file_into_workspace "$DESIGN_PATH" "$design_rel"
    WORKSPACE_DESIGN_PATH="$design_rel"
  fi

  if [[ "$MODE" == "design" || "$MODE" == "plan" ]]; then
    local rel_path=""
    rel_path="$(workspace_relative_path_for "$RESOLVED_PLAN" "external-plan")"
    copy_file_into_workspace "$RESOLVED_PLAN" "$rel_path"
    WORKSPACE_PLAN_PATH="$rel_path"
    return
  fi

  filter_code_impl_scope_to_allowed_touch_set

  local rel_file=""
  for rel_file in "${CODE_IMPL_SCOPE[@]}"; do
    copy_repo_file_into_workspace "$rel_file"
  done

  if [[ -n "$RESOLVED_PLAN" ]]; then
    local plan_rel=""
    plan_rel="$(workspace_relative_path_for "$RESOLVED_PLAN" "external-plan")"
    copy_file_into_workspace "$RESOLVED_PLAN" "$plan_rel"
    WORKSPACE_PLAN_PATH="$plan_rel"
  fi
}
