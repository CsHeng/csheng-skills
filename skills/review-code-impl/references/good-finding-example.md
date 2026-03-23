A well-formed finding includes a file:line reference and code-level evidence.

Example:

severity: Critical
location: internal/auth/token.go:47
evidence: "The function `ValidateToken` returns `(nil, nil)` when the token signature check fails: `if err != nil { return nil, nil }`. A nil error with nil token is indistinguishable from a valid empty result to callers."
impact: Any caller that checks only `err == nil` will treat a forged or expired token as valid, bypassing authentication entirely.
fix: Return a sentinel error: `return nil, ErrInvalidToken`. Update all callers to handle this error explicitly.
confidence: high

A good finding quotes the exact code or expression from the file. The impact is a specific runtime failure or security consequence. The fix names the exact change required.
