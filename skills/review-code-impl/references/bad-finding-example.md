Anti-pattern: vague, unanchored findings with no file:line reference.

Example (DO NOT produce this):

severity: Important
location: auth package
evidence: The code doesn't handle errors properly.
impact: Could cause runtime failures.
fix: Add better error handling throughout.

Problems with this finding:
- location is a package name, not a file:line reference — cannot be traced to specific code
- evidence does not quote any code or expression from the file
- impact is vague ("could cause runtime failures") — not a specific failure mode or scenario
- fix is generic ("add better error handling") — not a concrete change to a specific function

DO NOT produce findings like this. Every finding must include a file:line reference and quote the exact code or expression that is the source of the problem.
