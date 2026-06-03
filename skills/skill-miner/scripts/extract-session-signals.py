#!/usr/bin/env python3
"""Extract skill-improvement signals from Codex and Claude history."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any


EXIT_RE = re.compile(r"Process exited with code (\d+)")

FAILURE_PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("pytest_missing", re.compile(r"No module named pytest|Failed to spawn: pytest", re.I)),
    ("pytest_cov_addopts", re.compile(r"unrecognized arguments: --cov|pytest-cov", re.I)),
    ("python_yaml_missing", re.compile(r"No module named ['\"]?yaml|No module named PyYAML", re.I)),
    ("plugin_manifest_missing", re.compile(r"missing `\.codex-plugin/plugin\.json`|missing plugin\.json", re.I)),
    ("zsh_reserved_variable", re.compile(r"read-only variable: (status|path)", re.I)),
    ("rg_needs_pcre2", re.compile(r"look-around.*not supported|enable PCRE2", re.I | re.S)),
    ("path_not_found", re.compile(r"No such file or directory|FileNotFoundError|cannot access|sed: can.t read", re.I)),
    ("not_git_repo", re.compile(r"not a git repository", re.I)),
    ("command_not_found", re.compile(r"command not found", re.I)),
    ("review_artifact_invalid", re.compile(r"run-review\.sh|missing required upstream design|invalid upstream design", re.I)),
    ("permission_boundary", re.compile(r"Permission denied|Operation not permitted|sudo -n|root-owned|sticky", re.I)),
    ("remote_runtime", re.compile(r"timed out|timeout|connection refused|no route to host|100% packet loss", re.I)),
    ("test_assertion", re.compile(r"FAILED .*::|AssertionError|\d+ failed", re.I)),
    ("parse_schema", re.compile(r"parse error|JSON|YAML|jq:", re.I)),
]

USER_SIGNAL_PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("analysis_only", re.compile(r"只分析|先.*分析|不直接改|不要.*改|别.*改|别急.*改")),
    ("wrong_target", re.compile(r"不不不|不是.*(那个|这台|这个|这个repo|这个文件)|另外一台|另外.*repo|你.*看错|搞错")),
    ("scope_rejected", re.compile(r"没必要|别.*提交|不要.*提交|不要.*写|先不处理|这部分先不|别瞎加")),
    ("command_requested", re.compile(r"命令|直接.*命令|怎么.*跑|给我.*command|working command", re.I)),
    ("runtime_evidence", re.compile(r"实际|runtime|线上|现场|不要猜|别猜|log|日志|证据|先查|system log|git log", re.I)),
    ("approval_gate", re.compile(r"^(1|2|yes|yes do it)$|确认|批准|可以提交|只提交", re.I)),
    ("correction", re.compile(r"不对|错了|不应该|应该是|你忘了|失败|报错")),
]

EVENT_NAMES = {
    "turn_aborted",
    "context_compacted",
    "thread_rolled_back",
    "error",
    "task_complete",
}


@dataclass(frozen=True)
class Example:
    source: str
    category: str
    cwd: str
    session_id: str
    file: str
    text: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Mine local agent history for skill-improvement signals.")
    parser.add_argument("--scope", choices=("current", "all"), default="current")
    parser.add_argument("--repo-root", default="")
    parser.add_argument(
        "--codex-home",
        action="append",
        default=None,
        help="Codex home to scan. Repeat for multiple homes; comma-separated values are also accepted.",
    )
    parser.add_argument(
        "--claude-home",
        action="append",
        default=None,
        help="Claude home to scan. Repeat for multiple homes; comma-separated values are also accepted.",
    )
    parser.add_argument("--sources", default="codex,codex-memory,claude,claude-memory")
    parser.add_argument("--format", choices=("markdown", "json"), default="markdown")
    parser.add_argument("--limit", type=int, default=5)
    return parser.parse_args()


def resolve_home_args(values: list[str] | None, default: Path) -> list[Path]:
    if not values:
        return [default.expanduser()]

    homes: list[Path] = []
    seen: set[Path] = set()
    for value in values:
        for part in value.split(","):
            stripped = part.strip()
            if not stripped:
                continue
            home = Path(stripped).expanduser()
            if home in seen:
                continue
            seen.add(home)
            homes.append(home)
    return homes or [default.expanduser()]


def git_root(path: Path) -> Path:
    try:
        output = subprocess.check_output(
            ["git", "-C", str(path), "rev-parse", "--show-toplevel"],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return path.resolve()
    return Path(output).resolve()


def is_in_scope(cwd: str, repo_root: Path, scope: str) -> bool:
    if scope == "all":
        return True
    if not cwd or cwd == "(unknown)":
        return False
    try:
        Path(cwd).resolve().relative_to(repo_root)
    except (OSError, ValueError):
        return False
    return True


def flatten_text(value: Any) -> str:
    parts: list[str] = []

    def walk(item: Any) -> None:
        if isinstance(item, str):
            parts.append(item)
        elif isinstance(item, list):
            for child in item:
                walk(child)
        elif isinstance(item, dict):
            for key in ("text", "input_text", "content", "message", "result", "toolUseResult"):
                if key in item:
                    walk(item[key])

    walk(value)
    return "\n".join(part for part in parts if part)


def skip_injected_text(text: str) -> bool:
    return bool(
        ("# AGENTS.md instructions" in text and len(text) > 1000)
        or ("<skill>" in text and len(text) > 1000)
        or ("<INSTRUCTIONS>" in text and len(text) > 1000)
    )


def classify_failure(text: str) -> str:
    for name, pattern in FAILURE_PATTERNS:
        if pattern.search(text):
            return name
    return "other_nonzero"


def is_search_no_match(command: str, output: str, code: int) -> bool:
    stripped = command.strip()
    if stripped.startswith("cd ") and "&&" in stripped:
        stripped = stripped.split("&&", 1)[1].strip()
    tool = stripped.split(maxsplit=1)[0] if stripped else ""
    if tool not in {"rg", "grep", "fd", "find"} or code != 1:
        return False
    error_markers = (
        "error:",
        "No such file or directory",
        "not supported",
        "invalid",
        "regex parse error",
        "permission denied",
    )
    return not any(marker.lower() in output.lower() for marker in error_markers)


def add_example(examples: dict[str, list[Example]], example: Example, limit: int) -> None:
    if limit <= 0:
        return
    bucket = examples[example.category]
    if len(bucket) < limit:
        bucket.append(example)


def iter_jsonl(path: Path) -> Any:
    try:
        with path.open(errors="replace") as handle:
            for line in handle:
                try:
                    yield json.loads(line)
                except json.JSONDecodeError:
                    continue
    except OSError:
        return


def scan_codex_session(
    path: Path,
    repo_root: Path,
    scope: str,
    counts: Counter[str],
    examples: dict[str, list[Example]],
    event_counts: Counter[str],
    limit: int,
) -> None:
    cwd = "(unknown)"
    session_id = ""
    timestamp = ""
    calls: dict[str, tuple[str, dict[str, Any]]] = {}
    pending: list[dict[str, Any]] = []

    for obj in iter_jsonl(path):
        payload = obj.get("payload") or {}
        if obj.get("type") == "session_meta":
            cwd = payload.get("cwd") or cwd
            session_id = payload.get("id") or session_id
            timestamp = payload.get("timestamp") or timestamp
            continue
        pending.append(obj)

    if not is_in_scope(cwd, repo_root, scope):
        return

    counts["sessions_codex"] += 1
    if timestamp:
        counts[f"codex_session_date:{timestamp[:10]}"] += 1

    for obj in pending:
        payload = obj.get("payload") or {}
        obj_type = obj.get("type")
        if obj_type == "event_msg":
            event_type = payload.get("type") or "(unknown)"
            if event_type in EVENT_NAMES:
                event_counts[event_type] += 1
                if event_type == "error":
                    category = "event_error"
                    counts[category] += 1
                    add_example(
                        examples,
                        Example("codex", category, cwd, session_id, path.name, json.dumps(payload, ensure_ascii=False)[:300]),
                        limit,
                    )
            continue

        if obj_type != "response_item":
            continue
        item_type = payload.get("type")
        if item_type == "message" and payload.get("role") == "user":
            text = flatten_text(payload.get("content"))
            if not text or skip_injected_text(text):
                continue
            for name, pattern in USER_SIGNAL_PATTERNS:
                if pattern.search(text.strip()):
                    category = f"user_{name}"
                    counts[category] += 1
                    add_example(examples, Example("codex", category, cwd, session_id, path.name, " ".join(text.split())[:300]), limit)
        elif item_type == "function_call":
            arguments: dict[str, Any] = {}
            try:
                arguments = json.loads(payload.get("arguments") or "{}")
            except json.JSONDecodeError:
                pass
            calls[payload.get("call_id") or ""] = (payload.get("name") or "", arguments)
        elif item_type == "function_call_output":
            raw_output = payload.get("output") or ""
            output = raw_output if isinstance(raw_output, str) else flatten_text(raw_output)
            match = EXIT_RE.search(output)
            if not match or int(match.group(1)) == 0:
                continue
            code = int(match.group(1))
            call_name, arguments = calls.get(payload.get("call_id") or "", ("", {}))
            command = arguments.get("cmd") or arguments.get("command") or call_name
            if is_search_no_match(command, output, code):
                counts["search_no_match"] += 1
                continue
            category = f"failure_{classify_failure(command + chr(10) + output)}"
            counts[category] += 1
            add_example(
                examples,
                Example("codex", category, cwd, session_id, path.name, (command + " | " + " ".join(output.splitlines()[-4:]))[:300]),
                limit,
            )


def scan_claude_session(
    path: Path,
    repo_root: Path,
    scope: str,
    counts: Counter[str],
    examples: dict[str, list[Example]],
    event_counts: Counter[str],
    limit: int,
) -> None:
    objects = list(iter_jsonl(path))
    cwd = "(unknown)"
    session_id = ""
    for obj in objects:
        cwd = obj.get("cwd") or cwd
        session_id = obj.get("sessionId") or session_id
        if cwd != "(unknown)" and session_id:
            break
    if not is_in_scope(cwd, repo_root, scope):
        return

    counts["sessions_claude"] += 1
    for obj in objects:
        obj_type = obj.get("type") or ""
        if obj_type == "user":
            text = flatten_text(obj.get("message") or obj.get("content"))
            if not text or skip_injected_text(text):
                continue
            for name, pattern in USER_SIGNAL_PATTERNS:
                if pattern.search(text.strip()):
                    category = f"user_{name}"
                    counts[category] += 1
                    add_example(examples, Example("claude", category, cwd, session_id, path.name, " ".join(text.split())[:300]), limit)
        blob = json.dumps(obj, ensure_ascii=False)
        if re.search(r'"error"|Permission denied|No such file|command not found|failed|Traceback', blob, re.I):
            category = f"failure_{classify_failure(blob)}"
            counts[category] += 1
            add_example(examples, Example("claude", category, cwd, session_id, path.name, blob[:300]), limit)
        if obj_type in {"error", "summary"}:
            event_counts[f"claude_{obj_type}"] += 1


def scan_memory_file(
    path: Path,
    repo_root: Path,
    scope: str,
    counts: Counter[str],
    examples: dict[str, list[Example]],
    limit: int,
) -> None:
    try:
        text = path.read_text(errors="replace")
    except OSError:
        return
    if scope == "current":
        repo_text = str(repo_root)
        encoded_repo = repo_text.replace("/", "-")
        if repo_text in text:
            chunks = re.split(r"(?=^# Task Group:)", text, flags=re.M)
            text = "\n".join(chunk for chunk in chunks if repo_text in chunk)
        elif encoded_repo in str(path):
            pass
        else:
            return
    counts["memory_files"] += 1
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("- symptom:"):
            category = "memory_failure_pattern"
            counts[category] += 1
            add_example(examples, Example("memory", category, "(memory)", "", str(path), stripped[:300]), limit)
        elif stripped.startswith("- when the user"):
            category = "memory_user_preference"
            counts[category] += 1
            add_example(examples, Example("memory", category, "(memory)", "", str(path), stripped[:300]), limit)


def candidate_recommendations(counts: Counter[str]) -> list[str]:
    recommendations: list[str] = []
    if counts["failure_rg_needs_pcre2"]:
        recommendations.append("tool-decision-tree: require rg --pcre2 for lookaround/backreferences and treat rg exit 1 as no-match.")
    if counts["failure_pytest_missing"] or counts["failure_pytest_cov_addopts"]:
        recommendations.append("python-guidelines: preflight pytest dependencies, pytest-cov addopts, and subproject uv environments.")
    if counts["failure_zsh_reserved_variable"]:
        recommendations.append("shell-guidelines: avoid zsh reserved variables such as status and path in ad hoc probes.")
    if counts["user_analysis_only"] or counts["user_scope_rejected"]:
        recommendations.append("analyze/execute skills: honor analysis-only and rejected-scope signals before mutating files.")
    if counts["user_approval_gate"] or counts["memory_failure_pattern"]:
        recommendations.append("smart-commit/execute-change: keep explicit approval and completed-write gates machine-checkable.")
    if counts["failure_review_artifact_invalid"]:
        recommendations.append("review-change: validate design_ref/design_version before invoking lower-plane reviewers.")
    if counts["failure_python_yaml_missing"] or counts["failure_plugin_manifest_missing"]:
        recommendations.append("plugin workflows: run validation through uvx --with pyyaml and verify manifests before declaring success.")
    return recommendations


def print_counter(title: str, counter: Counter[str], prefix: str = "", limit: int = 12) -> None:
    print(f"\n## {title}")
    shown = 0
    for key, value in counter.most_common():
        if prefix and not key.startswith(prefix):
            continue
        print(f"- {key}: {value}")
        shown += 1
        if shown >= limit:
            break
    if shown == 0:
        print("- none")


def build_report(args: argparse.Namespace) -> dict[str, Any]:
    repo_root = Path(args.repo_root).resolve() if args.repo_root else git_root(Path.cwd())
    sources = {source.strip() for source in args.sources.split(",") if source.strip()}
    codex_homes = resolve_home_args(args.codex_home, Path.home() / ".codex")
    claude_homes = resolve_home_args(args.claude_home, Path.home() / ".claude")
    counts: Counter[str] = Counter()
    event_counts: Counter[str] = Counter()
    examples: dict[str, list[Example]] = defaultdict(list)

    if "codex" in sources:
        for codex_home in codex_homes:
            for path in sorted((codex_home / "sessions").rglob("*.jsonl")):
                scan_codex_session(path, repo_root, args.scope, counts, examples, event_counts, args.limit)
    if "claude" in sources:
        for claude_home in claude_homes:
            for path in sorted((claude_home / "projects").rglob("*.jsonl")):
                scan_claude_session(path, repo_root, args.scope, counts, examples, event_counts, args.limit)
    if "codex-memory" in sources:
        for codex_home in codex_homes:
            memory_path = codex_home / "memories" / "MEMORY.md"
            if memory_path.exists():
                scan_memory_file(memory_path, repo_root, args.scope, counts, examples, args.limit)
    if "claude-memory" in sources:
        for claude_home in claude_homes:
            memory_paths = set(claude_home.rglob("memory/*.md")) | set(claude_home.rglob("MEMORY.md"))
            for path in sorted(memory_paths):
                scan_memory_file(path, repo_root, args.scope, counts, examples, args.limit)

    for key in ("sessions_codex", "sessions_claude", "memory_files"):
        counts[key] += 0

    serialized_examples = {
        category: [example.__dict__ for example in items]
        for category, items in sorted(examples.items())
    }
    return {
        "scope": args.scope,
        "repo_root": str(repo_root),
        "sources": sorted(sources),
        "codex_homes": [str(path) for path in codex_homes],
        "claude_homes": [str(path) for path in claude_homes],
        "counts": dict(counts),
        "event_counts": dict(event_counts),
        "recommendations": candidate_recommendations(counts),
        "examples": serialized_examples,
    }


def print_markdown_report(report: dict[str, Any], limit: int) -> None:
    counts = Counter(report["counts"])
    event_counts = Counter(report["event_counts"])

    print("# Skill Mining Report")
    print(f"- scope: {report['scope']}")
    print(f"- repo_root: {report['repo_root']}")
    print(f"- sources: {','.join(report['sources'])}")
    print(f"- codex_homes: {','.join(report['codex_homes'])}")
    print(f"- claude_homes: {','.join(report['claude_homes'])}")
    print(f"- codex_sessions: {counts['sessions_codex']}")
    print(f"- claude_sessions: {counts['sessions_claude']}")
    print(f"- memory_files: {counts['memory_files']}")

    print_counter("Failure Signatures", counts, "failure_")
    print_counter("User Signals", counts, "user_")
    print_counter("Session Events", event_counts)
    print_counter("Memory Signals", counts, "memory_")

    print("\n## Candidate Recommendations")
    recommendations = report["recommendations"]
    if recommendations:
        for recommendation in recommendations:
            print(f"- {recommendation}")
    else:
        print("- none")

    print("\n## Examples")
    for category, items in report["examples"].items():
        print(f"\n### {category}")
        for example in items[:limit]:
            print(f"- [{example['source']}] cwd={example['cwd']} session={example['session_id']} file={example['file']}")
            print(f"  {example['text']}")


def main() -> int:
    args = parse_args()
    report = build_report(args)
    if args.format == "json":
        print(json.dumps(report, ensure_ascii=False, sort_keys=True, indent=2))
        return 0
    print_markdown_report(report, args.limit)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
