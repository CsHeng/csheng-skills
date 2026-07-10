# Analyze Project Output Contract

Use `output-styles` as the shared rendering baseline. This contract adds project-analysis semantics without imposing a second conversational style system.

## Output Ownership

- When the user's primary intent is broad project orientation or truth mapping, `analyze-project` owns the domain order and conclusion.
- When the primary intent is runtime, infrastructure, security, language, or another domain diagnosis, return project-truth evidence to that primary skill and do not render a standalone project report.
- Never concatenate independent report templates from multiple matched skills.

## Default: Selective Terse

Use this mode unless the user explicitly requests a comprehensive project audit.

1. Lead with one conclusion that answers the user's actual question.
2. Emit only the relevant facts, boundaries, status, operating guidance, or gaps.
3. Include a compact scope, document-health, or verification-basis line only when it changes how the conclusion should be trusted.
4. Include drift signals only when drift exists and affects the answer or warrants a follow-up.
5. Stop after the last useful action, risk, or unresolved point.

Project scope, truth roots, terminology, search boundaries, architecture, operations, status, and drift are required analysis axes. They are not mandatory headings. Omit axes that do not materially support the response.

## Full Audit Mode

Use full-audit mode only when the user explicitly requests comprehensive project orientation, a complete truth map, or an audit covering most analysis axes. A degraded or untrusted document-health result does not by itself authorize a long report.

Read `references/full-audit-output.md` for the full-audit semantic sections. Continue to use the selected `output-styles` mode inside those sections.

## Evidence

- Use the `output-styles` labels `fact`, `inferred`, `judgment`, and `uncertain` when the distinction matters.
- Distinguish evidence provenance as `documented`, `code`, `runtime`, or `external` only when it affects confidence or conflict resolution.
- Use paths relative to the selected project root unless the user explicitly requests absolute paths or the evidence necessarily lives outside that project.
- Give file references an exact start line in `path:line` form.
- Keep one or two short references with the claim or in one compact evidence bullet. Use a nested reference list for larger evidence sets.
- Do not repeat the conclusion to create a closing summary.

## Drift Signals

Emit no drift section when no drift exists. When drift exists, assign stable labels such as `D1`, `D2`, and preserve:

- type
- severity
- summary
- stable-source evidence
- verification evidence
- recommended action

A compact rendering is acceptable:

```md
- `D1` · `medium` · `doc_code_mismatch`: the operating guide names the retired command, while code and tests use the current entrypoint. → `run-organize-docs`
  - evidence: `docs/operations.md:18`; `scripts/run-current.sh:9`; `tests/test_entrypoint.py:21`
```

Allowed drift values and actions remain defined in `references/doc-health-and-drift.md`.
