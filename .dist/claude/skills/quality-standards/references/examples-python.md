# Python Quality Examples

## Complexity Example

```python
# Example of acceptable complexity (complexity = 5)
def process_user_data(user_data):
    if not user_data:
        return None

    if user_data.get('is_active'):
        if user_data.get('role') == 'admin':
            return process_admin_user(user_data)
        elif user_data.get('role') == 'user':
            return process_regular_user(user_data)
        else:
            return process_guest_user(user_data)
    else:
        return process_inactive_user(user_data)

# Example requiring refactoring (complexity > 15)
def complex_business_logic(data):  # REFACTOR: Too complex
    # This function needs to be split into smaller functions
    pass
```

## Ruff Configuration

```toml
[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = [
    "E",      # pycodestyle errors
    "W",      # pycodestyle warnings
    "F",      # pyflakes
    "I",      # isort
    "B",      # flake8-bugbear
    "C4",     # flake8-comprehensions
    "UP",     # pyupgrade
]
ignore = ["E501", "B008"]

[tool.ruff.lint.mccabe]
max-complexity = 10
```

## Code Review Automation

```python
class CodeReviewChecker:
    def __init__(self):
        self.checks = [
            self.check_functionality,
            self.check_security,
            self.check_performance,
            self.check_maintainability,
            self.check_tests
        ]

    def check_functionality(self, diff):
        """Validate functional requirements"""
        issues = []
        # Add functional validation logic
        return issues

    def check_security(self, diff):
        """Security vulnerability assessment"""
        issues = []
        # Check for common security issues
        security_patterns = [
            r'exec\(',          # Code execution
            r'shell=True',      # Shell injection risk
            r'password.*=',     # Hardcoded passwords
        ]
        return issues

    def check_performance(self, diff):
        """Performance impact assessment"""
        issues = []
        # Check for performance anti-patterns
        return issues

    def generate_review_report(self, diff):
        report = {
            "critical_issues": [],
            "warnings": [],
            "suggestions": [],
            "coverage": {}
        }

        for check in self.checks:
            issues = check(diff)
            report["critical_issues"].extend(issues)

        return report
```

## Review Assistant

```python
class ReviewAssistant:
    def suggest_improvements(self, code_diff):
        suggestions = []

        # Suggest variable renames for better clarity
        if 'temp' in code_diff or 'data' in code_diff:
            suggestions.append({
                "type": "naming",
                "message": "Consider using more descriptive variable names",
                "severity": "info"
            })

        # Suggest extracting complex logic
        complexity = self.calculate_complexity(code_diff)
        if complexity > 10:
            suggestions.append({
                "type": "refactoring",
                "message": f"Consider extracting complex logic (complexity: {complexity})",
                "severity": "warning"
            })

        # Suggest adding tests
        if 'def ' in code_diff and 'test_' not in code_diff:
            suggestions.append({
                "type": "testing",
                "message": "Consider adding unit tests for new functions",
                "severity": "info"
            })

        return suggestions
```

## Technical Debt Tracker

```python
class TechnicalDebtTracker:
    def __init__(self):
        self.debt_categories = {
            "code_quality": {
                "description": "Code that doesn't meet quality standards",
                "priority": "medium",
                "remediation": "refactoring"
            },
            "security": {
                "description": "Security vulnerabilities and risks",
                "priority": "critical",
                "remediation": "immediate_fix"
            },
            "performance": {
                "description": "Performance bottlenecks and inefficiencies",
                "priority": "high",
                "remediation": "optimization"
            },
            "documentation": {
                "description": "Missing or outdated documentation",
                "priority": "low",
                "remediation": "documentation_update"
            }
        }

    def identify_debt(self, codebase):
        debt_items = []

        # Code quality debt
        complex_functions = self.find_complex_functions(codebase)
        for func in complex_functions:
            debt_items.append({
                "type": "code_quality",
                "location": func["location"],
                "description": f"Function complexity: {func['complexity']}",
                "effort": self.estimate_refactoring_effort(func)
            })

        # Security debt
        security_issues = self.find_security_issues(codebase)
        for issue in security_issues:
            debt_items.append({
                "type": "security",
                "location": issue["location"],
                "description": issue["description"],
                "effort": "high"
            })

        return debt_items

    def prioritize_debt(self, debt_items):
        """Prioritize technical debt based on impact and effort"""
        priority_matrix = {
            ("critical", "low"): 1,
            ("critical", "medium"): 2,
            ("critical", "high"): 3,
            ("high", "low"): 4,
            ("high", "medium"): 5,
            ("high", "high"): 6,
            ("medium", "low"): 7,
            ("medium", "medium"): 8,
            ("medium", "high"): 9,
            ("low", "low"): 10,
            ("low", "medium"): 11,
            ("low", "high"): 12
        }

        return sorted(debt_items, key=lambda x: priority_matrix.get(
            (x["severity"], x["effort"]), 99))
```

## Quality Metrics Dashboard

```python
from datetime import datetime

class QualityMetrics:
    def __init__(self):
        self.metrics_history = []

    def collect_metrics(self, project):
        metrics = {
            "timestamp": datetime.now(),
            "code_quality": {
                "complexity_avg": self.calculate_average_complexity(project),
                "maintainability_index": self.calculate_maintainability(project),
                "code_coverage": self.get_coverage_percentage(project),
                "duplicate_code_ratio": self.find_duplicates_ratio(project)
            },
            "security": {
                "vulnerabilities_count": self.count_security_issues(project),
                "critical_vulnerabilities": self.count_critical_issues(project),
                "security_score": self.calculate_security_score(project)
            },
            "performance": {
                "build_time": self.measure_build_time(project),
                "test_execution_time": self.measure_test_time(project),
                "startup_time": self.measure_startup_time(project)
            },
            "process": {
                "pull_request_avg_time": self.calculate_pr_lifecycle(project),
                "review_turnaround": self.calculate_review_time(project),
                "deployment_frequency": self.calculate_deployment_frequency(project)
            }
        }

        self.metrics_history.append(metrics)
        return metrics

    def analyze_trends(self, days=30):
        """Analyze quality trends over time"""
        recent_metrics = self.metrics_history[-days:]

        trends = {}
        for metric_name in ["complexity_avg", "maintainability_index", "code_coverage"]:
            values = [m["code_quality"][metric_name] for m in recent_metrics]
            trends[metric_name] = {
                "trend": "improving" if values[-1] > values[0] else "declining",
                "change_percent": ((values[-1] - values[0]) / values[0]) * 100
            }

        return trends
```

## Team Skill Development

```python
class TeamSkillDevelopment:
    def __init__(self):
        self.skill_matrix = {
            "code_review": ["basic", "intermediate", "advanced"],
            "testing": ["unit", "integration", "e2e"],
            "security": ["basic_concepts", "threat_modeling", "secure_coding"],
            "performance": ["profiling", "optimization", "scaling"],
            "architecture": ["patterns", "design", "evolution"]
        }

    def assess_team_skills(self, team_members):
        skill_gaps = {}

        for skill, levels in self.skill_matrix.items():
            current_level = max(member.skills.get(skill, 0) for member in team_members)
            required_level = len(levels) - 1  # Advanced level

            if current_level < required_level:
                skill_gaps[skill] = {
                    "current_level": current_level,
                    "required_level": required_level,
                    "affected_members": [
                        member.name for member in team_members
                        if member.skills.get(skill, 0) < required_level
                    ]
                }

        return skill_gaps

    def create_training_plan(self, skill_gaps):
        training_plan = {
            "immediate_training": [],
            "ongoing_development": [],
            "knowledge_sharing": []
        }

        for skill, gap_info in skill_gaps.items():
            if gap_info["required_level"] - gap_info["current_level"] >= 2:
                training_plan["immediate_training"].append({
                    "skill": skill,
                    "format": "workshop",
                    "duration": "2-3 days",
                    "participants": gap_info["affected_members"]
                })
            else:
                training_plan["ongoing_development"].append({
                    "skill": skill,
                    "format": "mentorship",
                    "timeline": "4-6 weeks",
                    "participants": gap_info["affected_members"]
                })

            training_plan["knowledge_sharing"].append({
                "skill": skill,
                "activity": "brown bag session",
                "frequency": "bi-weekly",
                "presenter": "rotation"
            })

        return training_plan
```
