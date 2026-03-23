A well-formed finding includes concrete evidence anchored to a specific section or heading.

Example:

severity: Critical
location: Section 4 — Authentication Boundary
evidence: "The design states 'the API gateway forwards all headers to downstream services' but does not specify how authorization tokens are validated or stripped before forwarding. Section 4 has no authentication enforcement mechanism."
impact: Downstream services will receive raw caller-supplied authorization headers with no validation, allowing any client to impersonate an authenticated user if the gateway is bypassed.
fix: Add an explicit step in Section 4: "The gateway validates the Authorization header against the identity service before forwarding. Tokens are stripped and replaced with a signed internal claim set."
confidence: high

A good finding quotes or closely paraphrases the design text. The impact is a concrete security or operational consequence. The fix is a specific design decision, not a suggestion.
