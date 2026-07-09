# Interface And Domain Language

Use this reference when shaping module boundaries, test seams, domain terminology, or caller contracts.

## Interface Contract

Treat an interface as every fact a caller must know, not only the type signature:

- inputs and outputs
- invariants
- ordering constraints
- error modes
- configuration requirements
- performance characteristics
- ownership of side effects and state

A good module puts meaningful behavior behind a small interface. Before adding a new abstraction, apply the deletion test: if deleting it only removes a pass-through layer, it is not carrying enough complexity.

Create a seam when behavior actually varies across adapters or when tests need to exercise behavior through the same contract callers use. Avoid speculative seams.

## Domain Language

- Prefer project-owned terms from stable docs, code, or glossary files.
- Call out conflicting or overloaded terms when they affect design or implementation.
- Propose one canonical term when ambiguous names would spread across files, APIs, logs, or docs.
- Keep implementation decisions out of glossary-like docs unless the repo already uses that file for design records.
