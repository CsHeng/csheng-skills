from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "extract-session-signals.py"


def write_jsonl(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(row, ensure_ascii=False) + "\n" for row in rows))


class ExtractSessionSignalsCliTest(unittest.TestCase):
    def test_shell_wrapped_rg_exit_one_is_search_no_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            codex_home = root / "codex"
            repo_root = root / "repo"
            repo_root.mkdir()

            write_jsonl(
                codex_home / "sessions" / "2026" / "01" / "03" / "rollout-search.jsonl",
                [
                    {
                        "type": "session_meta",
                        "payload": {
                            "cwd": str(repo_root),
                            "id": "codex-search",
                            "timestamp": "2026-01-03T00:00:00Z",
                        },
                    },
                    {
                        "type": "response_item",
                        "payload": {
                            "type": "function_call",
                            "call_id": "call-search",
                            "name": "exec_command",
                            "arguments": json.dumps(
                                {
                                    "cmd": "bash -lc 'rg -n \"missing pattern\" README.md -S'",
                                }
                            ),
                        },
                    },
                    {
                        "type": "response_item",
                        "payload": {
                            "type": "function_call_output",
                            "call_id": "call-search",
                            "output": "Process exited with code 1\nOriginal token count: 0\nOutput:\n",
                        },
                    },
                ],
            )

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "--scope",
                    "all",
                    "--repo-root",
                    str(repo_root),
                    "--codex-home",
                    str(codex_home),
                    "--sources",
                    "codex",
                    "--format",
                    "json",
                    "--limit",
                    "0",
                ],
                check=True,
                text=True,
                capture_output=True,
            )

            counts = json.loads(result.stdout)["counts"]
            self.assertEqual(counts["search_no_match"], 1)
            self.assertNotIn("failure_other_nonzero", counts)

    def test_json_output_aggregates_multiple_homes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            codex_one = root / "codex-one"
            codex_two = root / "codex-two"
            claude_one = root / "claude-one"
            repo_root = root / "repo"
            repo_root.mkdir()

            write_jsonl(
                codex_one / "sessions" / "2026" / "01" / "01" / "rollout-a.jsonl",
                [
                    {
                        "type": "session_meta",
                        "payload": {
                            "cwd": str(repo_root),
                            "id": "codex-a",
                            "timestamp": "2026-01-01T00:00:00Z",
                        },
                    },
                    {
                        "type": "response_item",
                        "payload": {
                            "type": "message",
                            "role": "user",
                            "content": [{"text": "只分析，不要直接改"}],
                        },
                    },
                ],
            )
            write_jsonl(
                codex_two / "sessions" / "2026" / "01" / "02" / "rollout-b.jsonl",
                [
                    {
                        "type": "session_meta",
                        "payload": {
                            "cwd": str(repo_root),
                            "id": "codex-b",
                            "timestamp": "2026-01-02T00:00:00Z",
                        },
                    },
                    {
                        "type": "response_item",
                        "payload": {
                            "type": "message",
                            "role": "user",
                            "content": [{"text": "给我直接 command"}],
                        },
                    },
                ],
            )
            write_jsonl(
                claude_one / "projects" / "fixture.jsonl",
                [
                    {
                        "type": "user",
                        "cwd": str(repo_root),
                        "sessionId": "claude-a",
                        "message": {"content": [{"text": "不要猜，先查 runtime log"}]},
                    }
                ],
            )

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "--scope",
                    "all",
                    "--repo-root",
                    str(repo_root),
                    "--codex-home",
                    str(codex_one),
                    "--codex-home",
                    str(codex_two),
                    "--claude-home",
                    str(claude_one),
                    "--sources",
                    "codex,claude",
                    "--format",
                    "json",
                    "--limit",
                    "0",
                ],
                check=True,
                text=True,
                capture_output=True,
            )

            payload = json.loads(result.stdout)
            self.assertEqual(payload["counts"]["sessions_codex"], 2)
            self.assertEqual(payload["counts"]["sessions_claude"], 1)
            self.assertEqual(payload["counts"]["user_analysis_only"], 1)
            self.assertEqual(payload["counts"]["user_command_requested"], 1)
            self.assertEqual(payload["counts"]["user_runtime_evidence"], 1)
            self.assertEqual(payload["codex_homes"], [str(codex_one), str(codex_two)])
            self.assertEqual(payload["claude_homes"], [str(claude_one)])


if __name__ == "__main__":
    unittest.main()
