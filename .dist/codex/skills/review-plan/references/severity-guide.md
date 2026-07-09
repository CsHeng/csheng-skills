Severity guide for implementation plan review:

Critical — use when the plan, if implemented as written, will:
- Cause data loss, corruption, or irrecoverable state
- Have no rollback strategy for irreversible operations
- Miss a stated acceptance criterion entirely
- Create a security vulnerability (e.g., secret stored in plain text)

Example: Plan migrates the database schema but has no rollback procedure — if migration fails, data is in an inconsistent state with no recovery path.

Important — use when the plan, if implemented as written, will:
- Likely cause a production incident that requires manual intervention
- Miss a required integration or dependency that will block completion
- Have no observable success signal (no metrics, no health check)
- Have an ambiguous acceptance criterion that cannot be verified

Example: Plan adds a new service but does not specify how to verify it is healthy after deployment.

Minor — use for issues that should be fixed but will not cause incidents:
- Unclear wording that could be misinterpreted
- Missing but low-impact documentation
- Stylistic inconsistencies in the plan

Example: Task ordering is unclear but the plan is otherwise complete.
