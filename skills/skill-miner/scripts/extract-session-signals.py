#!/usr/bin/env python3
"""Extract skill-improvement signals from Codex and Claude history."""

from __future__ import annotations

import argparse
import json
import re
import shlex
import subprocess
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any


EXIT_RE = re.compile(r"Process exited with code (\d+)")
DOC_NAMES = {"AGENTS.md", "CLAUDE.md", "README.md"}

DOC_OFFLOAD_RE = re.compile(
    r"workflow|validation|troubleshoot|runbook|deploy|commit|skill|agent|"
    r"流程|排障|验证|部署|提交|技能|维护|运行",
    re.I,
)

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


@dataclass(frozen=True)
class SkillInventoryEntry:
    name: str
    path: str
    category: str
    disable_model_invocation: bool
    description: str


@dataclass(frozen=True)
class SkillUsageRecord:
    source: str
    category: str
    cwd: str
    session_id: str
    file: str
    line: int
    skills: tuple[str, ...]
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
    parser.add_argument(
        "--sources",
        default="codex,codex-memory,claude,claude-memory,context-docs",
        help="Comma-separated sources: codex,codex-memory,claude,claude-memory,context-docs.",
    )
    parser.add_argument("--format", choices=("markdown", "json"), default="markdown")
    parser.add_argument("--limit", type=int, default=5)
    parser.add_argument(
        "--skill-usage-root",
        action="append",
        default=None,
        help="Skill bundle or skill root to measure in session history. Repeat for multiple roots.",
    )
    parser.add_argument(
        "--skill-usage-prefix",
        default="",
        help="Skill namespace prefix to count, for example mattpocock-skills.",
    )
    parser.add_argument(
        "--skill-usage-before-date",
        default="",
        help="Optional exclusive YYYY-MM-DD cutoff for skill-usage counts.",
    )
    parser.add_argument(
        "--skill-usage-include-output",
        action="store_true",
        help="Include tool output records in skill-usage counts. Default excludes outputs to avoid inventory/listing noise.",
    )
    parser.add_argument(
        "--skill-usage-only",
        action="store_true",
        help="Only emit skill-usage data. Use for fast external-bundle retirement audits.",
    )
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
        or ("<skill>" in text and "</skill>" in text and len(text) > 100)
        or ("<INSTRUCTIONS>" in text and len(text) > 1000)
        or ("<skills_instructions>" in text and len(text) > 1000)
        or ("### Available skills" in text and len(text) > 1000)
    )


def parse_frontmatter(text: str) -> dict[str, str]:
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---", 4)
    if end == -1:
        return {}
    data: dict[str, str] = {}
    for raw_line in text[4:end].splitlines():
        if ":" not in raw_line:
            continue
        key, value = raw_line.split(":", 1)
        data[key.strip()] = value.strip().strip('"')
    return data


def iter_skill_inventory(paths: list[Path]) -> dict[str, SkillInventoryEntry]:
    entries: dict[str, SkillInventoryEntry] = {}
    for root in paths:
        expanded_root = root.expanduser().resolve()
        if not expanded_root.exists():
            continue
        inventory_root = expanded_root.parent if expanded_root.name == "SKILL.md" else expanded_root
        candidates = [expanded_root] if expanded_root.name == "SKILL.md" else sorted(expanded_root.rglob("SKILL.md"))
        for path in candidates:
            try:
                text = path.read_text(errors="replace")
            except OSError:
                continue
            metadata = parse_frontmatter(text)
            name = metadata.get("name") or path.parent.name
            try:
                rel_path = path.relative_to(inventory_root)
            except ValueError:
                rel_path = path
            category = rel_path.parts[1] if len(rel_path.parts) >= 3 and rel_path.parts[0] == "skills" else ""
            entries[name] = SkillInventoryEntry(
                name=name,
                path=str(rel_path),
                category=category,
                disable_model_invocation=metadata.get("disable-model-invocation", "").lower() == "true",
                description=metadata.get("description", ""),
            )
    return entries


def build_skill_usage_markers(
    skill_prefix: str,
    skill_roots: list[Path],
    inventory: dict[str, SkillInventoryEntry],
) -> tuple[dict[str, tuple[str, ...]], tuple[str, ...]]:
    resolved_roots = [root.expanduser().resolve() for root in skill_roots]
    skill_markers: dict[str, tuple[str, ...]] = {}
    for name, entry in inventory.items():
        markers = {
            f"{skill_prefix}:{name}" if skill_prefix else "",
            f"${skill_prefix}:{name}" if skill_prefix else "",
            entry.path,
        }
        for root in resolved_roots:
            markers.add(str((root / entry.path).resolve()))
        skill_markers[name] = tuple(marker for marker in sorted(markers) if marker)

    root_markers = {skill_prefix} if skill_prefix else set()
    root_markers.update(str(root) for root in resolved_roots)
    return skill_markers, tuple(marker for marker in sorted(root_markers) if marker)


def match_skill_usage_names(
    text: str,
    skill_markers: dict[str, tuple[str, ...]],
    root_markers: tuple[str, ...],
) -> tuple[str, ...]:
    names: set[str] = set()
    if not text:
        return ()

    for name, markers in skill_markers.items():
        if any(marker and marker in text for marker in markers):
            names.add(name)

    if not names and any(marker and marker in text for marker in root_markers):
        names.add("(repo)")
    return tuple(sorted(names))


def add_skill_usage_record(
    skill_usage_records: list[SkillUsageRecord],
    text: str,
    source: str,
    category: str,
    cwd: str,
    session_id: str,
    file: str,
    line: int,
    skill_markers: dict[str, tuple[str, ...]],
    root_markers: tuple[str, ...],
    limit_text: int = 300,
) -> None:
    if skip_injected_text(text):
        return
    if not any(marker and marker in text for marker in root_markers):
        return
    names = match_skill_usage_names(text, skill_markers, root_markers)
    if not names:
        return
    skill_usage_records.append(
        SkillUsageRecord(
            source,
            category,
            cwd,
            session_id,
            file,
            line,
            names,
            " ".join(text.split())[:limit_text],
        )
    )


def classify_failure(text: str) -> str:
    for name, pattern in FAILURE_PATTERNS:
        if pattern.search(text):
            return name
    return "other_nonzero"


def unwrap_shell_command(command: str) -> str:
    stripped = command.strip()
    if stripped.startswith("cd ") and "&&" in stripped:
        stripped = stripped.split("&&", 1)[1].strip()
    try:
        parts = shlex.split(stripped)
    except ValueError:
        return stripped
    if len(parts) >= 3 and Path(parts[0]).name in {"bash", "zsh", "sh"}:
        for index, part in enumerate(parts[1:], start=1):
            if "c" in part.lstrip("-") and index + 1 < len(parts):
                return unwrap_shell_command(parts[index + 1])
    return stripped


def is_search_no_match(command: str, output: str, code: int) -> bool:
    stripped = unwrap_shell_command(command)
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


def iter_jsonl_with_lines(path: Path) -> Any:
    try:
        with path.open(errors="replace") as handle:
            for line_number, line in enumerate(handle, start=1):
                try:
                    yield line_number, json.loads(line)
                except json.JSONDecodeError:
                    continue
    except OSError:
        return


def iter_context_doc_paths(repo_root: Path) -> list[Path]:
    try:
        output = subprocess.check_output(
            ["git", "-C", str(repo_root), "ls-files", "-z"],
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return sorted(path for path in repo_root.rglob("*") if path.name in DOC_NAMES)

    paths: list[Path] = []
    for raw in output.split(b"\0"):
        if not raw:
            continue
        relative = Path(raw.decode("utf-8", errors="replace"))
        if relative.name in DOC_NAMES:
            paths.append(repo_root / relative)
    return sorted(paths)


def context_doc_reason(path: Path, text: str) -> str:
    lines = text.splitlines()
    line_count = len(lines)
    fence_count = text.count("```") // 2
    workflow_hits = len(DOC_OFFLOAD_RE.findall(text))

    if path.name in {"AGENTS.md", "CLAUDE.md"} and line_count >= 80:
        return "large AI context doc"
    if path.name == "README.md" and line_count >= 160:
        return "large human-facing doc"
    if fence_count >= 4:
        return "many command or code examples"
    if workflow_hits >= 12:
        return "workflow-heavy durable knowledge"
    return ""


def scan_context_docs(
    repo_root: Path,
    counts: Counter[str],
    examples: dict[str, list[Example]],
    limit: int,
) -> None:
    seen_realpaths: set[Path] = set()
    for path in iter_context_doc_paths(repo_root):
        try:
            realpath = path.resolve()
        except OSError:
            continue
        if realpath in seen_realpaths:
            counts["context_doc_symlink_or_duplicate"] += 1
            continue
        seen_realpaths.add(realpath)

        try:
            text = path.read_text(errors="replace")
        except OSError:
            continue

        try:
            rel_path = path.relative_to(repo_root)
        except ValueError:
            rel_path = path
        line_count = text.count("\n") + (1 if text else 0)
        byte_count = len(text.encode("utf-8"))
        counts["context_docs"] += 1
        counts[f"context_doc_name:{path.name}"] += 1
        counts["context_doc_lines"] += line_count
        counts["context_doc_bytes"] += byte_count

        reason = context_doc_reason(path, text)
        if not reason:
            continue
        counts["context_doc_offload_candidate"] += 1
        add_example(
            examples,
            Example(
                "context-doc",
                "context_doc_offload_candidate",
                str(repo_root),
                "",
                str(rel_path),
                f"{rel_path}: {line_count} lines, {byte_count} bytes; {reason}",
            ),
            limit,
        )


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


def scan_codex_skill_usage(
    path: Path,
    repo_root: Path,
    scope: str,
    cutoff_date: str,
    include_output: bool,
    skill_markers: dict[str, tuple[str, ...]],
    root_markers: tuple[str, ...],
    records: list[SkillUsageRecord],
) -> None:
    cwd = "(unknown)"
    session_id = ""
    timestamp = ""
    pending: list[tuple[int, dict[str, Any]]] = []

    for line_number, obj in iter_jsonl_with_lines(path):
        payload = obj.get("payload") or {}
        if obj.get("type") == "session_meta":
            cwd = payload.get("cwd") or cwd
            session_id = payload.get("id") or session_id
            timestamp = payload.get("timestamp") or timestamp
            continue
        pending.append((line_number, obj))

    if cutoff_date and timestamp[:10] >= cutoff_date:
        return
    if not is_in_scope(cwd, repo_root, scope):
        return

    for line_number, obj in pending:
        payload = obj.get("payload") or {}
        if obj.get("type") != "response_item":
            continue
        item_type = payload.get("type")
        if item_type == "message" and payload.get("role") in {"user", "assistant"}:
            role = payload.get("role") or "message"
            text = flatten_text(payload.get("content"))
            add_skill_usage_record(
                records,
                text,
                "codex",
                "user_explicit" if role == "user" else "assistant_reference",
                cwd,
                session_id,
                path.name,
                line_number,
                skill_markers,
                root_markers,
            )
        elif item_type == "function_call":
            arguments: dict[str, Any] = {}
            try:
                arguments = json.loads(payload.get("arguments") or "{}")
            except json.JSONDecodeError:
                pass
            text = json.dumps({"name": payload.get("name"), "arguments": arguments}, ensure_ascii=False)
            add_skill_usage_record(
                records,
                text,
                "codex",
                "tool_call",
                cwd,
                session_id,
                path.name,
                line_number,
                skill_markers,
                root_markers,
            )
        elif item_type == "function_call_output":
            if not include_output:
                continue
            raw_output = payload.get("output") or ""
            text = raw_output if isinstance(raw_output, str) else flatten_text(raw_output)
            add_skill_usage_record(
                records,
                text,
                "codex",
                "tool_output",
                cwd,
                session_id,
                path.name,
                line_number,
                skill_markers,
                root_markers,
            )


def scan_claude_skill_usage(
    path: Path,
    repo_root: Path,
    scope: str,
    cutoff_date: str,
    include_output: bool,
    skill_markers: dict[str, tuple[str, ...]],
    root_markers: tuple[str, ...],
    records: list[SkillUsageRecord],
) -> None:
    objects = list(iter_jsonl_with_lines(path))
    cwd = "(unknown)"
    session_id = ""
    timestamp = ""
    for _, obj in objects:
        cwd = obj.get("cwd") or cwd
        session_id = obj.get("sessionId") or session_id
        timestamp = obj.get("timestamp") or timestamp
        if cwd != "(unknown)" and session_id and timestamp:
            break

    if cutoff_date and timestamp[:10] >= cutoff_date:
        return
    if not is_in_scope(cwd, repo_root, scope):
        return

    for line_number, obj in objects:
        obj_type = obj.get("type") or ""
        category = ""
        text = ""
        if obj_type == "user":
            category = "user_explicit"
            text = flatten_text(obj.get("message") or obj.get("content"))
        elif obj_type == "assistant":
            category = "assistant_reference"
            text = flatten_text(obj.get("message") or obj.get("content"))
        elif include_output:
            blob = json.dumps(obj, ensure_ascii=False)
            if "toolUseResult" in blob or "tool_use" in blob or "hook" in blob:
                category = "tool_output"
                text = blob
        if not category:
            continue
        add_skill_usage_record(
            records,
            text,
            "claude",
            category,
            cwd,
            session_id,
            path.name,
            line_number,
            skill_markers,
            root_markers,
        )


def build_skill_usage_report(
    args: argparse.Namespace,
    repo_root: Path,
    sources: set[str],
    codex_homes: list[Path],
    claude_homes: list[Path],
) -> dict[str, Any]:
    skill_roots = [Path(value) for value in args.skill_usage_root or []]
    skill_prefix = args.skill_usage_prefix.strip()
    if not skill_roots and not skill_prefix:
        return {}

    inventory = iter_skill_inventory(skill_roots)
    skill_markers, root_markers = build_skill_usage_markers(skill_prefix, skill_roots, inventory)
    records: list[SkillUsageRecord] = []

    if "codex" in sources:
        for codex_home in codex_homes:
            for path in sorted((codex_home / "sessions").rglob("*.jsonl")):
                scan_codex_skill_usage(
                    path,
                    repo_root,
                    args.scope,
                    args.skill_usage_before_date,
                    args.skill_usage_include_output,
                    skill_markers,
                    root_markers,
                    records,
                )
    if "claude" in sources:
        for claude_home in claude_homes:
            for path in sorted((claude_home / "projects").rglob("*.jsonl")):
                scan_claude_skill_usage(
                    path,
                    repo_root,
                    args.scope,
                    args.skill_usage_before_date,
                    args.skill_usage_include_output,
                    skill_markers,
                    root_markers,
                    records,
                )

    by_category: Counter[str] = Counter()
    by_skill: Counter[str] = Counter()
    by_skill_session: Counter[str] = Counter()
    skill_sessions: dict[str, set[str]] = defaultdict(set)
    session_ids: set[str] = set()

    for record in records:
        by_category[record.category] += 1
        session_key = record.session_id or f"{record.source}:{record.file}"
        session_ids.add(session_key)
        for name in record.skills:
            by_skill[name] += 1
            skill_sessions[name].add(session_key)

    for name, sessions in skill_sessions.items():
        by_skill_session[name] = len(sessions)

    inventory_by_category = Counter(entry.category or "(root)" for entry in inventory.values())
    inventory_by_invocation = Counter(
        "disable-model-invocation" if entry.disable_model_invocation else "model-invoked"
        for entry in inventory.values()
    )

    return {
        "prefix": skill_prefix,
        "roots": [str(path.expanduser().resolve()) for path in skill_roots],
        "before_date": args.skill_usage_before_date,
        "include_output": args.skill_usage_include_output,
        "inventory_total": len(inventory),
        "inventory_by_category": dict(inventory_by_category),
        "inventory_by_invocation": dict(inventory_by_invocation),
        "records": len(records),
        "sessions": len(session_ids),
        "by_category": dict(by_category),
        "by_skill": dict(by_skill.most_common()),
        "by_skill_session": dict(by_skill_session.most_common()),
        "inventory": [entry.__dict__ for entry in sorted(inventory.values(), key=lambda item: (item.category, item.name))],
        "examples": [record.__dict__ for record in records[: args.limit if args.limit > 0 else 0]],
    }


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
        recommendations.append("smart-commit/implement-change: keep explicit approval and completed-write gates machine-checkable.")
    if counts["failure_review_artifact_invalid"]:
        recommendations.append("review-change: validate design_ref/design_version before invoking lower-plane reviewers.")
    if counts["failure_python_yaml_missing"] or counts["failure_plugin_manifest_missing"]:
        recommendations.append("plugin workflows: run validation through uvx --with pyyaml and verify manifests before declaring success.")
    if counts["context_doc_offload_candidate"]:
        recommendations.append("skill-miner/organize-docs: review large or workflow-heavy AGENTS/README docs for skill or reference offload while preserving stable truth summaries.")
    if counts["memory_failure_pattern"] or counts["memory_user_preference"]:
        recommendations.append("skill-miner: extract memory-derived durable facts into repo docs/code/skills, then list corresponding memory cleanup candidates.")
    return recommendations


def print_counter(title: str, counter: Counter[str], prefix: str = "", limit: int = 12) -> None:
    print(f"\n## {title}")
    shown = 0
    for key, value in counter.most_common():
        if value <= 0:
            continue
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

    if args.skill_usage_only:
        return {
            "scope": args.scope,
            "repo_root": str(repo_root),
            "sources": sorted(sources),
            "codex_homes": [str(path) for path in codex_homes],
            "claude_homes": [str(path) for path in claude_homes],
            "counts": {},
            "event_counts": {},
            "recommendations": [],
            "examples": {},
            "skill_usage": build_skill_usage_report(args, repo_root, sources, codex_homes, claude_homes),
        }

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
    if "context-docs" in sources:
        scan_context_docs(repo_root, counts, examples, args.limit)

    skill_usage = build_skill_usage_report(args, repo_root, sources, codex_homes, claude_homes)

    for key in ("sessions_codex", "sessions_claude", "memory_files", "context_docs"):
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
        "skill_usage": skill_usage,
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
    print(f"- context_docs: {counts['context_docs']}")

    print_counter("Failure Signatures", counts, "failure_")
    print_counter("User Signals", counts, "user_")
    print_counter("Session Events", event_counts)
    print_counter("Memory Signals", counts, "memory_")
    print_counter("Project Context Signals", counts, "context_")

    skill_usage = report.get("skill_usage") or {}
    if skill_usage:
        print("\n## Skill Usage")
        print(f"- prefix: {skill_usage['prefix']}")
        print(f"- roots: {','.join(skill_usage['roots'])}")
        if skill_usage["before_date"]:
            print(f"- before_date: {skill_usage['before_date']}")
        print(f"- include_output: {skill_usage['include_output']}")
        print(f"- inventory_total: {skill_usage['inventory_total']}")
        print(f"- records: {skill_usage['records']}")
        print(f"- sessions: {skill_usage['sessions']}")
        print("- inventory_by_category:")
        for key, value in Counter(skill_usage["inventory_by_category"]).most_common():
            print(f"  - {key}: {value}")
        print("- inventory_by_invocation:")
        for key, value in Counter(skill_usage["inventory_by_invocation"]).most_common():
            print(f"  - {key}: {value}")
        print("- by_category:")
        for key, value in Counter(skill_usage["by_category"]).most_common():
            print(f"  - {key}: {value}")
        print("- by_skill_sessions:")
        for key, value in Counter(skill_usage["by_skill_session"]).most_common(20):
            print(f"  - {key}: {value}")
        if limit > 0:
            print("- examples:")
            for example in skill_usage["examples"][:limit]:
                skills = ",".join(example["skills"])
                print(
                    f"  - [{example['source']}] {example['category']} skills={skills} "
                    f"cwd={example['cwd']} session={example['session_id']} "
                    f"file={example['file']}:{example['line']}"
                )
                print(f"    {example['text']}")

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
