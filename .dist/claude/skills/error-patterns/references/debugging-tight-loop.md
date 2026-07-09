# Debugging Tight Loop

Use this reference for hard bugs, performance regressions, flaky behavior, or repeated runtime failures.

## Gate

Build a red-capable feedback loop before hypothesizing. A valid loop is:

- specific to the reported symptom
- deterministic, or high-reproduction for flaky bugs
- fast enough to run repeatedly
- agent-runnable without hidden manual state

Acceptable loops include a focused test, CLI command with fixture input, curl script, Playwright probe, trace replay, throwaway harness, property/fuzz loop, or bisect command.

If no loop can be built, stop and state what was tried. Ask for runtime access, captured logs/traces, or permission to add temporary instrumentation instead of guessing.

## Workflow

1. Reproduce the symptom with the loop.
2. Minimize inputs, config, state, and steps one at a time.
3. Generate 3 to 5 ranked falsifiable hypotheses.
4. Test one hypothesis per probe.
5. Tag temporary instrumentation with a unique prefix and remove it before closeout.
6. Add or preserve a regression check at the correct seam when one exists.
7. Rerun the original loop and the regression check before declaring the bug fixed.

For performance regressions, establish a measurement baseline before changing code or config.
