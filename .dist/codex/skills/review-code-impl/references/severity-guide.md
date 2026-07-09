Severity guide for code implementation review:

Critical — use when the code, as written, will:
- Create a security vulnerability (injection, authentication bypass, secret exposure, privilege escalation)
- Cause data loss or corruption under normal operating conditions
- Panic or crash under a realistic input or load scenario (nil dereference, out-of-bounds, unhandled error on critical path)
- Contradict the spec baseline in a way that breaks a stated acceptance criterion

Example: A route handler passes user-supplied input directly to a shell command without sanitization — remote code execution is possible.

Important — use when the code, as written, will:
- Fail silently in a way that is not observable (swallowed error, missing log, no metric)
- Have a race condition or shared-state bug that will manifest under concurrent load
- Miss a required test for a behavior specified in the plan or design
- Lack a required production-readiness signal (health endpoint, readiness probe, structured log on startup)

Example: A background goroutine writes to a shared map without a mutex — data race under any concurrent request.

Minor — use for issues that should be fixed but will not cause incidents in production:
- Unused imports or variables that increase cognitive load
- Missing but low-impact inline documentation
- Style or naming inconsistencies that deviate from the project's established conventions

Example: An exported function has no doc comment but its behavior is obvious from context and it is tested.
