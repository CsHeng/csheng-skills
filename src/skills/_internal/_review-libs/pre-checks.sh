#!/usr/bin/env bash
# Pre-review static analysis checks for code-impl mode.
# Runs available linters/validators and returns JSON findings.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  pre-checks.sh --mode <design|plan|code-impl> --files <file1> [--files <file2> ...] [options]

Options:
  --mode <design|plan|code-impl>  Review mode. Required.
  --files <path>                  File to check (repeatable). Required.
  --timeout <seconds>             Total timeout for all checks. Default: 10.
  -h, --help                      Show this help.

Output:
  JSON array of findings: [{"source": "shellcheck", "file": "x.sh", "line": 10, "message": "..."}]
USAGE
}

log() { printf '[pre-checks] %s\n' "$*" >&2; }
die() { printf '[pre-checks] error: %s\n' "$*" >&2; exit 1; }

MODE=""
FILES=()
TIMEOUT=10

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    --files)
      FILES+=("$2")
      shift 2
      ;;
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "$MODE" ]] || die "--mode is required"
[[ "${#FILES[@]}" -gt 0 ]] || die "--files is required"

case "$MODE" in
  design|plan|code-impl) ;;
  *) die "invalid mode: $MODE" ;;
esac

# Findings accumulator
FINDINGS="[]"

# Helper: add finding to accumulator
add_finding() {
  local source="$1"
  local file="$2"
  local line="$3"
  local message="$4"

  local escaped_message
  escaped_message=$(printf '%s' "$message" | jq -Rs .)
  local escaped_file
  escaped_file=$(printf '%s' "$file" | jq -Rs .)

  FINDINGS=$(printf '%s' "$FINDINGS" | jq --arg src "$source" \
    --argjson file "$escaped_file" \
    --argjson line "$line" \
    --argjson msg "$escaped_message" \
    '. += [{"source": $src, "file": $file, "line": $line, "message": $msg}]')
}

# Detect language from file extension
detect_language() {
  local file="$1"
  case "$file" in
    *.sh|*.bash|*.zsh) echo "shell" ;;
    *.py) echo "python" ;;
    *.go) echo "go" ;;
    *.json) echo "json" ;;
    *.md) echo "markdown" ;;
    *) echo "unknown" ;;
  esac
}

# Check functions for each tool
check_shellcheck() {
  local file="$1"
  command -v shellcheck >/dev/null 2>&1 || return 0

  local output
  # shellcheck exits non-zero when it finds issues, so capture both success and failure
  output=$(timeout 3 shellcheck -f json "$file" 2>&1) || true

  # Parse shellcheck JSON output and add findings
  if [[ -n "$output" ]]; then
    while IFS='|' read -r line message; do
      [[ -n "$line" && -n "$message" ]] && add_finding "shellcheck" "$file" "$line" "$message"
    done < <(echo "$output" | jq -r '.[] | "\(.line)|\(.message)"' 2>/dev/null)
  fi
}

check_ruff() {
  local file="$1"
  command -v ruff >/dev/null 2>&1 || return 0

  local output
  if output=$(timeout 3 ruff check --output-format json "$file" 2>&1); then
    if [[ -n "$output" && "$output" != "[]" ]]; then
      while IFS='|' read -r line message; do
        [[ -n "$line" && -n "$message" ]] && add_finding "ruff" "$file" "$line" "$message"
      done < <(echo "$output" | jq -r '.[] | "\(.location.row)|\(.code): \(.message)"' 2>/dev/null)
    fi
  fi
}

check_go_vet() {
  local file="$1"
  command -v go >/dev/null 2>&1 || return 0

  local output
  if output=$(timeout 3 go vet "$file" 2>&1); then
    return 0
  fi

  # Parse go vet output: file.go:line:col: message
  echo "$output" | grep -E '^[^:]+:[0-9]+:' | while IFS=: read -r f line rest; do
    [[ -n "$line" && -n "$rest" ]] && add_finding "go-vet" "$file" "$line" "$rest"
  done
}

check_jq() {
  local file="$1"
  command -v jq >/dev/null 2>&1 || return 0

  local output
  if ! output=$(timeout 2 jq . "$file" 2>&1 >/dev/null); then
    # Extract line number from jq error if available
    local line=1
    if [[ "$output" =~ line\ ([0-9]+) ]]; then
      line="${BASH_REMATCH[1]}"
    fi
    add_finding "jq" "$file" "$line" "JSON syntax error: $output"
  fi
}

check_markdown() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  # Check heading structure: no skipped levels
  local prev_level=0
  local line_num=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))
    if [[ "$line" =~ ^(#+)\ .+ ]]; then
      local level=${#BASH_REMATCH[1]}
      if ((prev_level > 0 && level > prev_level + 1)); then
        add_finding "markdown" "$file" "$line_num" "Heading level skipped: h$prev_level to h$level"
      fi
      prev_level=$level
    fi
  done < "$file"

  # Check for broken internal links (basic check for #anchor references)
  line_num=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))
    if [[ "$line" =~ \[([^\]]+)\]\(#([^\)]+)\) ]]; then
      local anchor="${BASH_REMATCH[2]}"
      if ! grep -qE "^#+.*$(echo "$anchor" | tr '-' ' ')" "$file" 2>/dev/null; then
        add_finding "markdown" "$file" "$line_num" "Potentially broken internal link: #$anchor"
      fi
    fi
  done < "$file"
}

# Main execution with timeout
START_TIME=$(date +%s)

for file in "${FILES[@]}"; do
  # Check total timeout
  ELAPSED=$(($(date +%s) - START_TIME))
  if ((ELAPSED >= TIMEOUT)); then
    log "timeout reached, stopping checks"
    break
  fi

  [[ -f "$file" ]] || continue

  lang=$(detect_language "$file")

  case "$MODE" in
    design|plan)
      # Only markdown checks for design/plan mode
      [[ "$lang" == "markdown" ]] && check_markdown "$file"
      ;;
    code-impl)
      # Language-specific checks for code-impl mode
      case "$lang" in
        shell) check_shellcheck "$file" ;;
        python) check_ruff "$file" ;;
        go) check_go_vet "$file" ;;
        json) check_jq "$file" ;;
        markdown) check_markdown "$file" ;;
      esac
      ;;
  esac
done

# Output findings
printf '%s\n' "$FINDINGS"

