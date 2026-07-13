# Ad Hoc Command Composition

## Purpose

Keep agent ad hoc execution easy to review, mechanically predictable, and bounded when a command fails. This reference governs temporary task execution, not the language of persisted repository tools.

## Preference Order

1. Run one purpose-built command directly.
2. Use a structured tool such as `rg`, `fd`, `jq`, `yq`, or `ast-grep`.
3. Use a small single-layer Shell pipeline when its data flow remains visible.
4. Put procedural logic in a repo-external scratch script, review and syntax-check it, then invoke it directly.
5. Use nested interpreters only when the preceding forms are materially worse for the bounded task.

## Nested Interpreter Guidance

AVOID nesting `bash -c` around `python -c`, embedding Python in a Shell heredoc, or generating source code through interpolated command strings. These forms combine multiple parsers, make quoting failures harder to diagnose, and can obscure which layer owns an error or mutation.

This is avoid-by-default guidance, not a blanket ban. An agent may use a nested interpreter when it remains the smallest bounded option and the exact command, inputs, and effects are still reviewable.

Prefer an external scratch script when logic needs loops, exception handling, multiple data structures, non-trivial regular expressions, or more than one quoting layer. Place it under `$TMPDIR` or another repo-external scratch root, use the environment's file-editing capability rather than generating source through Shell interpolation, run the language syntax check, and remove it after the task when practical.

## Hard Safety Boundaries

PROHIBITED: Interpolate untrusted input into a Shell, Python, or other executable source string.

PROHIBITED: Use opaque nested code for an irreversible or state-changing operation before COUNT and PREVIEW establish the exact target set, expected mutation, and rollback or recovery boundary.

AVOID splitting one mutation across nested language layers when failure in an inner layer can leave the outer layer continuing with partial or unvalidated state. If this shape is still the smallest bounded option, make failure propagation and post-mutation verification explicit.

Pass variable data through arguments, standard input, environment variables, or structured files. Keep code static and data separate.

## Mutation Workflow

For multi-file, remote, destructive, or otherwise irreversible operations:

1. COUNT the candidate set without mutation.
2. PREVIEW representative and boundary cases.
3. Validate the active repository, host, and path.
4. Identify rollback, backup, idempotency, or recovery behavior.
5. EXECUTE with the simplest reviewable command shape.
6. Verify the resulting state independently.

If the target set or recovery path cannot be made explicit, stop instead of hiding uncertainty inside a more elaborate command string.
