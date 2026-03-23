A well-formed finding includes concrete evidence, not paraphrase.

Example:

severity: Critical
location: Section 3.2 — Rollback Strategy
evidence: "The plan states 'deploy the migration' but provides no mechanism to reverse it if the deployment fails. Section 3.2 has no rollback or revert procedure."
impact: If the migration fails in production, the service will remain degraded until a manual fix is applied, potentially causing extended downtime.
fix: Add a rollback step: "If migration fails, run `./scripts/rollback-migration.sh v2-to-v1` and verify table schema matches the previous version."
confidence: high

A good finding quotes or closely paraphrases the source text. The impact is user-visible or operational. The fix is specific and actionable.
