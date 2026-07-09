# TDD Vertical Slices

Use this reference when the user asks for TDD, test-first work, red-green-refactor, or when a risky behavior change needs a narrow executable contract before implementation.

## Rules

- Test observable behavior through the public interface, not private implementation shape.
- Write one failing test or reproducer for one behavior, implement the smallest change to pass it, then repeat.
- Do not write a batch of imagined tests before code. That horizontal flow often locks in guessed structure instead of verified behavior.
- Confirm the red state fails for the expected reason before implementing.
- Refactor only after the current slice is green.
- Keep tests resilient to internal refactors; a harmless rename or internal decomposition should not break behavior tests.

## Slice Gate

For each slice, record:

- behavior being tested
- public interface or command exercised
- red command and failure reason
- minimal green change
- follow-up verification command

If no correct seam exists for a regression test, state that as the finding and use the tightest substitute verification command.
