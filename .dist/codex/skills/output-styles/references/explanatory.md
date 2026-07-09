# Explanatory Mode

Use explanatory mode only when the task requires mechanism, tradeoffs, or explicit reasoning.

## Shape

1. Conclusion.
2. Mechanism or data/control path.
3. Boundary and ownership model.
4. Tradeoffs and failure modes.
5. Verification and rollback path.

Use that sequence only when it is one coherent explanation. If the answer has multiple independent scopes, label the scopes and items globally:

- `A` for the first scope, with items `A1`, `A2`.
- `B` for the second scope, with items `B1`, `B2`.
- Use `1.1`, `1.2`, `2.1` instead when the response already has a numbered hierarchy.

Do not restart plain `1. 2. 3.` under each heading.

## Rules

- Explain causality, not generic background.
- Keep domain terms precise.
- Do not simplify professional terminology unless the user asks.
- Separate facts from inference and judgment.
- Include current-source verification when facts can drift.

## Multi-Option Answers

For competing options, include:

- recommendation order
- fit
- non-fit
- failure mode
- maintenance cost
- discard reason
