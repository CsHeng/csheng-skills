Anti-pattern: vague, unanchored findings that cannot be verified.

Example (DO NOT produce this):

severity: Important
location: various
evidence: The plan lacks sufficient detail about error handling.
impact: Could cause issues.
fix: Consider adding more error handling.

Problems with this finding:
- location is "various" — not traceable to a specific section
- evidence does not quote or reference the plan text
- impact is vague ("could cause issues") — not a specific operational consequence
- fix is a suggestion, not an action ("consider adding")

DO NOT produce findings like this. Every finding must have a traceable location and quoted evidence.
