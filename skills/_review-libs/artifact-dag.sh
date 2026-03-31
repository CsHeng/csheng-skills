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
  local design_ref design_version design_file

  design_ref="$(extract_markdown_scalar "$plan_file" "Upstream Design" "design_ref")"
  design_version="$(extract_markdown_scalar "$plan_file" "Upstream Design" "design_version")"
  [[ -n "$design_ref" ]] || return 1
  [[ -n "$design_version" ]] || return 1

  if [[ "$design_ref" = /* ]]; then
    design_file="$design_ref"
  else
    design_file="$repo_root/$design_ref"
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
