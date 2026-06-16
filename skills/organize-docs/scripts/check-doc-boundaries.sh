#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DOCS_DIR="$ROOT_DIR/docs"

cd "$ROOT_DIR"

[[ -f "$DOCS_DIR/.ignore" ]] || { echo "missing docs/.ignore" >&2; exit 1; }
rg -qx 'plans/' "$DOCS_DIR/.ignore"
HAS_SUPERPOWERS_BOUNDARY=0
if [[ -d "$DOCS_DIR/superpowers" ]] || rg -qx 'superpowers/' "$DOCS_DIR/.ignore"; then
  HAS_SUPERPOWERS_BOUNDARY=1
  rg -qx 'superpowers/' "$DOCS_DIR/.ignore"
fi

[[ -f "$DOCS_DIR/AGENTS.md" ]] || { echo "missing docs/AGENTS.md" >&2; exit 1; }
[[ -f "$DOCS_DIR/README.md" ]] || { echo "missing docs/README.md" >&2; exit 1; }

rg -n "stable truth|stage artifacts|search tools|Git tracking|docs/.ignore" \
  "$DOCS_DIR/AGENTS.md" >/dev/null

rg -n "avoid \`docs/plans/\`|docs/plans|--no-ignore|Keep stage artifacts in Git" \
  "$DOCS_DIR/README.md" >/dev/null

if (( HAS_SUPERPOWERS_BOUNDARY )) && git check-ignore -q docs/superpowers/example.md; then
  echo "docs/superpowers should not be Git-ignored" >&2
  exit 1
fi

if git check-ignore -q docs/plans/example.md; then
  echo "docs/plans should not be Git-ignored" >&2
  exit 1
fi

if (( HAS_SUPERPOWERS_BOUNDARY )) && rg --files docs | rg -q '^docs/superpowers/'; then
  echo "default docs file search unexpectedly listed stage artifacts" >&2
  exit 1
fi

if rg --files docs | rg -q '^docs/plans/'; then
  echo "default docs file search unexpectedly listed stage artifacts" >&2
  exit 1
fi

if (( HAS_SUPERPOWERS_BOUNDARY )); then
  rg --files --no-ignore docs | rg -q '^docs/superpowers/'
fi
rg --files --no-ignore docs | rg -q '^docs/plans/'

python3 - <<'PY'
from __future__ import annotations

from pathlib import Path
import re
import subprocess
import sys

ROOT = Path.cwd()

fence_re = re.compile(r'^\s*(```|~~~)')
heading_re = re.compile(r'^\s{0,3}#{1,6}\s')
thematic_re = re.compile(r'^\s{0,3}([-*_])(?:\s*\1){2,}\s*$')
list_re = re.compile(r'^\s{0,3}(?:[-+*]\s+|\d+[.)]\s+)')
blockquote_re = re.compile(r'^\s{0,3}>')
definition_re = re.compile(r'^\s{0,3}\[[^\]]+\]:\s+')
html_re = re.compile(r'^\s{0,3}</?[A-Za-z][^>]*>\s*$')
table_separator_re = re.compile(r'^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$')


def markdown_paths() -> list[Path]:
    try:
        output = subprocess.check_output(
            ['git', 'ls-files', '-z', '--', '*.md'],
            cwd=ROOT,
        )
    except (OSError, subprocess.CalledProcessError):
        return sorted(
            path
            for path in ROOT.rglob('*.md')
            if not any(part in {'.git', 'node_modules', '.venv', '__pycache__'} for part in path.parts)
        )
    return sorted(ROOT / item.decode() for item in output.split(b'\0') if item)


def table_line_numbers(lines: list[str]) -> set[int]:
    table_lines: set[int] = set()
    for index, line in enumerate(lines):
        if not table_separator_re.match(line.strip()):
            continue
        start = index
        while start > 0 and '|' in lines[start - 1] and lines[start - 1].strip():
            start -= 1
        end = index
        while end + 1 < len(lines) and '|' in lines[end + 1] and lines[end + 1].strip():
            end += 1
        table_lines.update(range(start, end + 1))
    return table_lines


def line_kind(line: str, *, in_fence: bool, in_frontmatter: bool, is_table: bool) -> str:
    if fence_re.match(line):
        return 'fence'
    if in_fence:
        return 'code'
    if in_frontmatter:
        return 'frontmatter'
    if not line.strip():
        return 'blank'
    if is_table:
        return 'table'
    if (
        heading_re.match(line)
        or thematic_re.match(line)
        or definition_re.match(line)
        or html_re.match(line)
    ):
        return 'struct'
    if re.match(r'^\s{4,}\S', line) and not list_re.match(line):
        return 'code'
    return 'text'


def hard_wrap_findings(path: Path) -> list[tuple[int, int, str]]:
    lines = path.read_text(encoding='utf-8', errors='replace').splitlines()
    table_lines = table_line_numbers(lines)
    in_fence = False
    in_frontmatter = bool(lines and lines[0].strip() == '---')
    paragraph: list[tuple[int, str]] = []
    findings: list[tuple[int, int, str]] = []

    def flush_paragraph() -> None:
        nonlocal paragraph
        if len(paragraph) >= 2:
            for line_number, text in paragraph[:-1]:
                stripped = text.rstrip()
                width = len(stripped)
                if 60 <= width <= 120 and not text.endswith(('  ', '\\')):
                    findings.append((line_number, width, text.strip()))
        paragraph = []

    for index, line in enumerate(lines):
        line_number = index + 1
        if line_number == 1 and in_frontmatter:
            flush_paragraph()
            continue
        if in_frontmatter and line_number > 1 and line.strip() == '---':
            in_frontmatter = False
            flush_paragraph()
            continue

        kind = line_kind(
            line,
            in_fence=in_fence,
            in_frontmatter=in_frontmatter,
            is_table=index in table_lines,
        )
        if kind == 'fence':
            flush_paragraph()
            in_fence = not in_fence
            continue
        if kind == 'text':
            if list_re.match(line) or blockquote_re.match(line):
                flush_paragraph()
            paragraph.append((line_number, line))
        else:
            flush_paragraph()

    flush_paragraph()
    return findings


all_findings: list[tuple[Path, list[tuple[int, int, str]]]] = []
for markdown_path in markdown_paths():
    if markdown_path.is_symlink():
        continue
    findings = hard_wrap_findings(markdown_path)
    if findings:
        all_findings.append((markdown_path, findings))

if all_findings:
    print('Markdown prose hard-wrap detected; unwrap prose paragraphs and list-item continuations.', file=sys.stderr)
    for path, findings in all_findings[:50]:
        line_number, width, text = findings[0]
        rel_path = path.relative_to(ROOT)
        print(f'{rel_path}:{line_number}: width={width}: {text[:160]}', file=sys.stderr)
    if len(all_findings) > 50:
        print(f'... {len(all_findings) - 50} more files omitted', file=sys.stderr)
    raise SystemExit(1)
PY
