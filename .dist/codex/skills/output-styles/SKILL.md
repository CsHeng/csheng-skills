---
name: output-styles
description: "Use for response style selection in coding work: terse senior-engineering defaults, explanatory mode, review findings, implementation closeouts, evidence labels, and compact high-signal formatting."
---

# Output Styles

Select response shape without depending on a vendor-specific output-style feature.

## Mode Selection

- Default to `terse` for normal coding, operations, and project-state answers.
- Use `explanatory` when the user asks for why, mechanism, details, tradeoffs, or design reasoning.
- Use `review` when the user asks for a review or when a review gate requires findings-first output.
- Use `implementation-closeout` after completing edits, verification, deploy, install, or cleanup work.

## Baseline Rules

- Lead with conclusion, recommendation, finding, or exact state.
- Assume senior engineering context.
- Keep content actionable and verifiable.
- Avoid emotional language, praise, motivational tone, small talk, and filler.
- Do not restate the user request unless needed for ambiguity control.
- Distinguish `fact`, `inferred`, `judgment`, and `uncertain` when accuracy matters.
- Prefer tables for option comparisons when they improve scanability.
- Use globally unique list labels when one response contains multiple independent scopes. Do not restart `1. 2. 3.` under each heading if the user may need to refer back to items.
- For multi-scope answers, prefer heading prefixes plus item labels such as `A1`, `A2`, `B1`, `B2`, or numeric subsection labels such as `1.1`, `1.2`, `2.1`. Reserve plain `1. 2. 3.` for one ordered workflow in one scope.
- For planning summaries, use `C*` for confirmation clearance, `E*` for continuous execution ranges, and `X*` for runtime contingencies.
- Use bullets instead of numbered lists when item order is not semantically important.

## References

- Read `references/terse.md` for default concise answers.
- Read `references/explanatory.md` when the user asks for details or design reasoning.
- Read `references/review.md` for findings-first review output.
- Read `references/implementation-closeout.md` for final responses after work is complete.
