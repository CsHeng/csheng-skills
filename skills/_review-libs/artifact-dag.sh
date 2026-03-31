#!/usr/bin/env bash
set -euo pipefail

extract_markdown_list() {
  local file="$1"
  local section="$2"
  local key="$3"

  awk -v section="$section" -v key="$key" '
    BEGIN {
      in_section = 0
      in_key = 0
    }
    $0 ~ "^##[[:space:]]+" section "[[:space:]]*$" {
      in_section = 1
      in_key = 0
      next
    }
    in_section && $0 ~ "^##[[:space:]]+" {
      exit
    }
    in_section && $0 ~ "^[[:space:]]*-[[:space:]]*" key ":[[:space:]]*$" {
      in_key = 1
      next
    }
    in_section && in_key && $0 ~ "^[[:space:]]*-[[:space:]]*[A-Za-z0-9_-]+:[[:space:]]*$" {
      in_key = 0
      next
    }
    in_section && in_key && $0 ~ "^[[:space:]]*-[[:space:]]+" {
      line = $0
      sub(/^[[:space:]]*-[[:space:]]+/, "", line)
      print line
      next
    }
  ' "$file"
}

extract_markdown_scalar() {
  local file="$1"
  local section="$2"
  local key="$3"

  awk -v section="$section" -v key="$key" '
    BEGIN { in_section = 0 }
    $0 ~ "^##[[:space:]]+" section "[[:space:]]*$" {
      in_section = 1
      next
    }
    in_section && $0 ~ "^##[[:space:]]+" {
      exit
    }
    in_section && $0 ~ "^[[:space:]]*-[[:space:]]*" key ":[[:space:]]*" {
      line = $0
      sub(/^[[:space:]]*-[[:space:]]*[^:]+:[[:space:]]*/, "", line)
      print line
      exit
    }
  ' "$file"
}

resolve_plan_design_ref() {
  local repo_root="$1"
  local plan_file="$2"
  local design_ref design_version design_file plan_dir

  design_ref="$(extract_markdown_scalar "$plan_file" "Upstream Design" "design_ref")"
  design_version="$(extract_markdown_scalar "$plan_file" "Upstream Design" "design_version")"
  [[ -n "$design_ref" ]] || return 1
  [[ -n "$design_version" ]] || return 1

  if [[ "$design_ref" = /* ]]; then
    design_file="$design_ref"
  else
    plan_dir="$(cd -- "$(dirname -- "$plan_file")" && pwd)"
    if [[ -f "$plan_dir/$design_ref" ]]; then
      design_file="$(realpath "$plan_dir/$design_ref")"
    else
      design_file="$repo_root/$design_ref"
    fi
  fi

  if printf '%s' "$design_file" | grep -q '[[:cntrl:]]'; then
    return 1
  fi

  printf '%s\n%s\n' "$design_file" "$design_version"
}

build_allowed_touch_set() {
  local plan_file="$1"
  local design_file="$2"

  assert_plan_refs_within_design "$plan_file" "$design_file" || return 1

  {
    extract_markdown_list "$plan_file" "Implementation Scope" "impl_file_refs"
    extract_markdown_list "$plan_file" "Implementation Scope" "test_file_refs"
  } | awk 'NF > 0' | sort -u
}

path_is_within_allowed_roots() {
  local candidate="$1"
  shift || true

  local root=""
  for root in "$@"; do
    [[ -n "$root" ]] || continue
    if [[ "$candidate" == "$root" || "$candidate" == "$root"/* ]]; then
      return 0
    fi
  done

  return 1
}

intersect_paths_from_array() {
  local allowed_name="$1"
  shift || true

  local -n allowed_ref="$allowed_name"
  local -A allowed_map=()
  local -A emitted=()
  local path=""

  for path in "${allowed_ref[@]}"; do
    [[ -n "$path" ]] || continue
    allowed_map["$path"]=1
  done

  for path in "$@"; do
    [[ -n "$path" ]] || continue
    [[ -n "${allowed_map[$path]:-}" ]] || continue
    [[ -z "${emitted[$path]:-}" ]] || continue
    emitted["$path"]=1
    printf '%s\n' "$path"
  done
}

subtract_paths_from_array() {
  local allowed_name="$1"
  shift || true

  local -n allowed_ref="$allowed_name"
  local -A allowed_map=()
  local -A emitted=()
  local path=""

  for path in "${allowed_ref[@]}"; do
    [[ -n "$path" ]] || continue
    allowed_map["$path"]=1
  done

  for path in "$@"; do
    [[ -n "$path" ]] || continue
    [[ -z "${allowed_map[$path]:-}" ]] || continue
    [[ -z "${emitted[$path]:-}" ]] || continue
    emitted["$path"]=1
    printf '%s\n' "$path"
  done
}

assert_plan_refs_within_design() {
  local plan_file="$1"
  local design_file="$2"
  local key plan_refs design_refs ref

  for key in impl_file_refs test_file_refs; do
    plan_refs="$(extract_markdown_list "$plan_file" "Implementation Scope" "$key" | awk 'NF > 0' | sort -u)"
    design_refs="$(extract_markdown_list "$design_file" "Implementation Surface" "$key" | awk 'NF > 0' | sort -u)"

    while IFS= read -r ref; do
      [[ -n "$ref" ]] || continue
      if ! grep -Fqx "$ref" <<<"$design_refs"; then
        printf 'plan %s ref not declared in design: %s\n' "$key" "$ref" >&2
        return 1
      fi
    done <<<"$plan_refs"
  done
}
