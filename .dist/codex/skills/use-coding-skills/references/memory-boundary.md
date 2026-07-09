# Memory Boundary

Agent memory is a recall layer, not the primary source of truth.

## Durable Truth Order

1. Repo-owned code, tests, scripts, and configs.
2. Repo-owned stable docs and skills.
3. Live runtime or external source evidence.
4. Generated memories, session summaries, and logs.

## Use Memory When

- The task depends on prior user preferences, recurring failures, or known local topology.
- The target repo, runtime, module, or workflow appears in memory.
- A current question asks about previous decisions or consistency with prior work.

## Verify Memory When

- The fact can drift and is cheap to verify.
- The answer depends on current install state, live runtime, tool versions, service behavior, or external project support.
- A memory note conflicts with repository truth or current command output.

## Promotion Rule

Promote repeated or durable behavior into repo docs, repo-local skills, or generic skills. After promotion, treat the memory entry as a cleanup candidate rather than a parallel rule source.
