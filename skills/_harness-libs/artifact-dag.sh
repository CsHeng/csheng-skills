#!/usr/bin/env bash
set -euo pipefail

harness_bash_version_supported() {
  local major_version="$1"
  [[ "$major_version" =~ ^[0-9]+$ ]] && [[ "$major_version" -ge 4 ]]
}

if ! harness_bash_version_supported "${BASH_VERSINFO[0]:-0}"; then
  printf 'artifact harness requires Bash 4 or newer; found %s\n' "${BASH_VERSION:-unknown}" >&2
  return 1 2>/dev/null || exit 1
fi

declared_repo_path_ref_is_safe() {
  local ref="$1"

  [[ -n "$ref" ]] || return 1
  [[ "$ref" != /* ]] || return 1
  [[ "$ref" != */ ]] || return 1
  if printf '%s' "$ref" | grep -q '[[:cntrl:]]'; then
    return 1
  fi

  case "/$ref/" in
    *'/./'*|*'/../'*|*'//'*) return 1 ;;
  esac

  return 0
}

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

build_review_read_surface() {
  local design_file="$1"
  local key ref

  for key in impl_file_refs test_file_refs; do
    while IFS= read -r ref; do
      [[ -n "$ref" ]] || continue
      if ! declared_repo_path_ref_is_safe "$ref"; then
        printf 'unsafe design %s ref: %s\n' "$key" "$ref" >&2
        return 1
      fi
    done < <(extract_markdown_list "$design_file" "Implementation Surface" "$key" | awk 'NF > 0' | sort -u)
  done

  {
    extract_markdown_list "$design_file" "Implementation Surface" "impl_file_refs"
    extract_markdown_list "$design_file" "Implementation Surface" "test_file_refs"
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

path_matches_surface() {
  local surface="$1"
  local candidate="$2"

  [[ -n "$surface" ]] || return 1
  [[ -n "$candidate" ]] || return 1

  [[ "$candidate" == "$surface" || "$candidate" == "$surface"/* ]]
}

path_matches_any_surface() {
  local surfaces_name="$1"
  local candidate="$2"
  local -n surfaces_ref="$surfaces_name"
  local surface=""

  for surface in "${surfaces_ref[@]}"; do
    path_matches_surface "$surface" "$candidate" && return 0
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

intersect_paths_from_surfaces() {
  local surfaces_name="$1"
  shift || true

  local -n surfaces_ref="$surfaces_name"
  local -A emitted=()
  local path=""

  for path in "$@"; do
    [[ -n "$path" ]] || continue
    path_matches_any_surface "$surfaces_name" "$path" || continue
    [[ -z "${emitted[$path]:-}" ]] || continue
    emitted["$path"]=1
    printf '%s\n' "$path"
  done
}

subtract_paths_from_surfaces() {
  local surfaces_name="$1"
  shift || true

  local -A emitted=()
  local path=""

  for path in "$@"; do
    [[ -n "$path" ]] || continue
    path_matches_any_surface "$surfaces_name" "$path" && continue
    [[ -z "${emitted[$path]:-}" ]] || continue
    emitted["$path"]=1
    printf '%s\n' "$path"
  done
}

assert_plan_refs_within_design() {
  local plan_file="$1"
  local design_file="$2"
  local key ref
  local -a design_ref_array=()
  local plan_refs=""

  for key in impl_file_refs test_file_refs; do
    plan_refs="$(extract_markdown_list "$plan_file" "Implementation Scope" "$key" | awk 'NF > 0' | sort -u)"
    mapfile -t design_ref_array < <(extract_markdown_list "$design_file" "Implementation Surface" "$key" | awk 'NF > 0' | sort -u)

    for ref in "${design_ref_array[@]}"; do
      if ! declared_repo_path_ref_is_safe "$ref"; then
        printf 'unsafe design %s ref: %s\n' "$key" "$ref" >&2
        return 1
      fi
    done

    while IFS= read -r ref; do
      [[ -n "$ref" ]] || continue
      if ! declared_repo_path_ref_is_safe "$ref"; then
        printf 'unsafe plan %s ref: %s\n' "$key" "$ref" >&2
        return 1
      fi
      if ! path_matches_any_surface design_ref_array "$ref"; then
        printf 'plan %s ref not declared in design: %s\n' "$key" "$ref" >&2
        return 1
      fi
    done <<<"$plan_refs"
  done
}
