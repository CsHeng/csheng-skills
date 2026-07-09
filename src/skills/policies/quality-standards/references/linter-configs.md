# Linter Configurations

## Go golangci-lint

```yaml
[linters-settings]
complexity:
  max-complexity: 10

funlen:
  lines: 100
  statements: 50

gocyclo:
  min-complexity: 15

[linters]
enable-all: true
disable:
  - funlen
  - gochecknoglobals
  - gochecknoinits
```

## JavaScript ESLint

```json
{
  "extends": ["eslint:recommended", "@typescript-eslint/recommended"],
  "rules": {
    "complexity": ["error", 10],
    "max-lines-per-function": ["error", 100],
    "max-depth": ["error", 4],
    "max-params": ["error", 5]
  }
}
```

## Security Scanning Workflow

```yaml
# GitHub Actions security scan
name: Security Scan
on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Bandit (Python)
        run: |
          pip install bandit
          bandit -r src/ -f json -o bandit-report.json

      - name: Run Gosec (Go)
        run: |
          go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest
          gosec ./... -fmt json -out gosec-report.json

      - name: Run Snyk security scan
        run: |
          npm install -g snyk
          snyk test --json > snyk-report.json
```

## Refactoring Planner

```python
class RefactoringPlanner:
    def create_refactoring_plan(self, technical_debt):
        plan = {
            "immediate_actions": [],
            "short_term_goals": [],
            "long_term_improvements": [],
            "estimated_timeline": {}
        }

        for debt_item in technical_debt:
            if debt_item["severity"] == "critical":
                plan["immediate_actions"].append({
                    "item": debt_item,
                    "timeline": "1-2 days",
                    "resources": "Senior developer"
                })
            elif debt_item["severity"] == "high":
                plan["short_term_goals"].append({
                    "item": debt_item,
                    "timeline": "1-2 weeks",
                    "resources": "Development team"
                })
            else:
                plan["long_term_improvements"].append({
                    "item": debt_item,
                    "timeline": "1-3 months",
                    "resources": "Team allocation"
                })

        return plan

    def implement_safe_refactoring(self, refactoring_item):
        """Implement refactoring with safety measures"""
        steps = [
            "Create comprehensive tests for existing behavior",
            "Implement refactoring in small, incremental steps",
            "Run full test suite after each step",
            "Monitor performance metrics",
            "Conduct peer review of changes",
            "Deploy with feature flag for easy rollback"
        ]

        return steps
```
