---
description: Define and validate a change design, run bounded agent-native review, and hold for human approval
argument-hint: "[--design <path>]"
allowed-tools: ["Agent", "Read", "Glob", "Grep", "Bash", "Edit", "MultiEdit"]
---

Use `coding:design-change`.

Build a classification record with `request_kind`, `change_class`, `design_strength`, `truth_impact`, `boundary_impact`, and `recommended_next_phase`. Run bounded Decision Discovery when objective, terminology, ownership, acceptance, or non-goals are unclear. Then write a design artifact with goals, non-goals, boundaries, validation, rollback, `Implementation Surface`, and `approval_status: pending`. Do not hard-wrap Markdown prose; use globally unique labels for independent scopes. Validate it with `skills/_harness-libs/design-runner.sh`.

Run mandatory design review through `coding:review-change`. Construct a bounded design brief and prefer one reviewer subagent for non-trivial review; review directly when small or delegation is unavailable. The reviewer returns candidate findings only. The main agent adjudicates them and repairs only accepted, causally linked current-design blockers.

After validation and review pass, stop at the explicit human approval gate. Only explicit approval changes `approval_status` to `approved` and allows `coding:plan-change`.
