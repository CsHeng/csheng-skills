---
name: use-coding-skills
description: "Use when the user asks how local coding skills should be selected, when an ambiguous multi-stage coding request needs explicit routing, or when session-boundary, memory-boundary, or compact handoff guidance is required. Do not load as a mandatory bootstrap for unrelated work or tasks that directly match a workflow or policy skill."
---

# Use Coding Skills

Optional routing and session-boundary guidance for local coding work. Keep this skill small: it assists ambiguous selection and handoff without becoming a mandatory entry or a replacement for directly matched skills.

## Session Contract

- Treat repository-owned docs, code, scripts, tests, and skills as durable truth.
- Treat agent memories, sessions, logs, caches, and generated summaries as recall or staging evidence.
- Keep scope bound to the named repo, runtime surface, host, or workflow.
- Treat explicit read-only wording literally.
- Match response language to user input language unless file conventions require otherwise.
- Prefer current local evidence and live runtime checks over stale memory when verification is cheap.
- Verify current external facts before relying on versions, project support, APIs, protocols, pricing, laws, or ecosystem state.
- Do not write agent-specific rules when a skill can express the behavior in an agent-agnostic way.

## Default Routing

Use these routes only after this skill has matched an explicit routing or ambiguous multi-stage request. Direct workflow and policy matches do not need this skill first.

- Response shape and tone: use `output-styles`.
- Searches, refactors, command choice, and noisy output control: use `tool-decision-tree`.
- New code with unfixed implementation language: use `language-decision-tree`.
- Language-specific implementation: use the matching language guideline skill.
- Infrastructure, network, proxy, tunnel, container, GitOps, IaC, Secrets, Auth, or automation triage: use `infrastructure-triage`.
- README, AGENTS, CLAUDE, docs layout, docs search boundaries, or stage-artifact roots: use `organize-docs`.
- Memory, session, or context-doc mining: use `skill-miner`.
- Design, planning, execution, review, truth sync, and close gates: use the sovereign harness skills.

## Compact Instructions

When compacting or handing off long conversations, preserve in priority order:

1. Architecture decisions and durable contracts.
2. Modified files and key changes.
3. Current verification status.
4. Open TODOs, rollback notes, and next gates.
5. Tool outputs only as pass/fail or the smallest required evidence.

## References

- Read `references/routing.md` when task routing or skill selection is ambiguous.
- Read `references/memory-boundary.md` when a task touches memories, sessions, logs, generated summaries, or stale recalled facts.
- Read `references/preference-contract.md` when tuning session defaults, response style, or user preference capture.
