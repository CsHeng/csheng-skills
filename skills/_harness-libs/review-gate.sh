#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

review_mode_for_artifact() {
  local artifact="$1"

  case "$artifact" in
    design) printf 'design\n' ;;
    plan) printf 'plan\n' ;;
    code-impl) printf 'code-impl\n' ;;
    *) return 1 ;;
  esac
}

default_review_runner_path() {
  local runner="$SCRIPT_DIR/../_review-libs/run-review.sh"
  [[ -f "$runner" ]] || return 1
  realpath "$runner"
}

run_review_gate() {
  local artifact="$1"
  local host="$2"
  local target_path="$3"
  shift 3 || true

  local mode=""
  local runner=""
  local -a args=()

  mode="$(review_mode_for_artifact "$artifact")"
  runner="$(default_review_runner_path)"

  args=(bash "$runner" --mode "$mode" --host "$host")

  case "$artifact" in
    design|plan)
      args+=(--plan "$target_path")
      ;;
    code-impl)
      args+=(--file "$target_path")
      ;;
  esac

  if [[ $# -gt 0 ]]; then
    args+=("$@")
  fi

  "${args[@]}"
}

usage() {
  cat <<'EOF'
Usage:
  review-gate.sh runner-path
  review-gate.sh mode <design|plan|code-impl>
  review-gate.sh run <design|plan|code-impl> <host> <path> [extra run-review args...]
EOF
}

main() {
  local command="${1:-}"

  case "$command" in
    runner-path)
      default_review_runner_path
      ;;
    mode)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      review_mode_for_artifact "$2"
      ;;
    run)
      [[ $# -ge 4 ]] || { usage >&2; return 1; }
      run_review_gate "$2" "$3" "$4" "${@:5}"
      ;;
    *)
      usage >&2
      return 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
