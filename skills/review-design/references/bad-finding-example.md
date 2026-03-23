Anti-pattern: vague, unanchored findings that cannot be verified.

Example (DO NOT produce this):

severity: Important
location: various
evidence: The design does not adequately address security concerns.
impact: Could lead to security vulnerabilities.
fix: Consider adding security measures throughout the design.

Problems with this finding:
- location is "various" — not traceable to a specific section or heading
- evidence does not quote or reference the design text
- impact is vague ("could lead to vulnerabilities") — not a specific attack vector or failure mode
- fix is a suggestion, not a concrete design decision ("consider adding")

DO NOT produce findings like this. Every finding must reference a specific section heading and quote or closely paraphrase the design text.
