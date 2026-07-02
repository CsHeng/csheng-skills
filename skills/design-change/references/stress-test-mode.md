# Stress-Test Mode

Use this reference only when the user explicitly asks to grill, stress-test, harden, challenge, or interrogate a design or plan. Do not make this the default for ordinary implementation tasks.

## Rules

- Ask one decision-changing question at a time.
- Include the recommended answer and the tradeoff with each question.
- If code, docs, or runtime evidence can answer the question, inspect that evidence instead of asking.
- Prefer questions that resolve scope, non-goals, state ownership, permission boundaries, data paths, rollback, or verification.
- Stop when remaining questions would not change the design, plan, or execution gate.

## Output Shape

After the stress-test, convert answers into:

- confirmed assumptions
- rejected alternatives
- remaining open constraints
- design or plan changes
- verification and rollback implications
