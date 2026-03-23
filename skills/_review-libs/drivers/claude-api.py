#!/usr/bin/env python3
"""
Claude API driver for cross-model review.
Uses Anthropic SDK for non-interactive automated reviews.
"""
import argparse
import json
import os
import sys
from pathlib import Path

try:
    import anthropic
except ImportError:
    print("[driver:claude-api] error: anthropic package not installed", file=sys.stderr)
    print("[driver:claude-api] install with: uv pip install anthropic", file=sys.stderr)
    sys.exit(1)


def die(msg: str) -> None:
    print(f"[driver:claude-api] error: {msg}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Claude API driver")
    parser.add_argument("--probe", action="store_true", help="Check if driver is available")
    parser.add_argument("--prompt", type=str, help="Prompt file path")
    parser.add_argument("--schema", type=str, help="JSON schema file path")
    parser.add_argument("--output", type=str, help="Output file path")
    parser.add_argument("--repo-root", type=str, help="Repository root (unused by API driver)")
    parser.add_argument("--timeout", type=int, default=1800, help="Timeout in seconds")

    args = parser.parse_args()

    if args.probe:
        # Check if ANTHROPIC_API_KEY is set
        if not os.getenv("ANTHROPIC_API_KEY"):
            sys.exit(1)
        sys.exit(0)

    if not args.prompt:
        die("--prompt is required")
    if not args.schema:
        die("--schema is required")
    if not args.output:
        die("--output is required")

    prompt_path = Path(args.prompt)
    schema_path = Path(args.schema)
    output_path = Path(args.output)

    if not prompt_path.exists():
        die(f"prompt file not found: {args.prompt}")
    if not schema_path.exists():
        die(f"schema file not found: {args.schema}")

    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        die("ANTHROPIC_API_KEY environment variable not set")

    prompt_text = prompt_path.read_text()
    schema_json = json.loads(schema_path.read_text())

    try:
        client = anthropic.Anthropic(api_key=api_key, timeout=args.timeout)

        response = client.messages.create(
            model="claude-opus-4-6",
            max_tokens=16000,
            messages=[{"role": "user", "content": prompt_text}],
            tools=[
                {
                    "name": "submit_review",
                    "description": "Submit the review findings",
                    "input_schema": schema_json
                }
            ],
            tool_choice={"type": "tool", "name": "submit_review"}
        )

        # Extract tool use result
        for block in response.content:
            if block.type == "tool_use" and block.name == "submit_review":
                output_path.write_text(json.dumps(block.input, indent=2))
                sys.exit(0)

        die("no tool_use block found in response")

    except anthropic.APITimeoutError:
        die(f"API request timed out after {args.timeout}s")
    except anthropic.APIError as e:
        die(f"API error: {e}")
    except Exception as e:
        die(f"unexpected error: {e}")


if __name__ == "__main__":
    main()
