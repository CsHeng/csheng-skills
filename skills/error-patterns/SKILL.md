---
name: error-patterns
description: "Use when designing retry/circuit-breaker logic, defining error classification hierarchies, implementing resource cleanup, or adding resilience patterns. 中文触发：重试/熔断逻辑、错误分类、资源清理、弹性模式。"
---

# Error Patterns

## Purpose

Define cross-language error handling patterns and reliability conventions for robust, maintainable systems.

## Scope

In-scope:
- Generic error handling principles applicable across languages
- Resilience patterns (circuit breaker, retry, fallback)
- Resource management and cleanup
- Error classification and monitoring

Out-of-scope:
- Language-specific syntax (see `python-guidelines`, `go-guidelines`, `shell-guidelines`, `lua-guidelines`)
- Security-specific error handling (see `security-guardrails`)

## Rules (Hard Constraints)

### Absolute Prohibitions
PROHIBITED: Ignore errors or continue execution with invalid state.
PROHIBITED: Use generic exception handling without specific error types.
PROHIBITED: Log sensitive information in error messages.
PROHIBITED: Fail silently without error reporting.

### Defensive Programming
REQUIRED: Validate inputs at function boundaries.
REQUIRED: Handle edge cases explicitly.
REQUIRED: Use meaningful error messages with context.
REQUIRED: Fail fast when preconditions are not met.
REQUIRED: Include relevant variables and state in error messages.
REQUIRED: Use consistent debug prefixes: `===`, `---`, `SUCCESS:`, `ERROR:`.

### Exception Management
REQUIRED: Create custom exception classes inheriting from appropriate base exceptions.
REQUIRED: Use specific exception types for different error categories.
REQUIRED: Implement proper exception chaining with context.
REQUIRED: Design exception hierarchy that matches application domains.
REQUIRED: Catch specific exceptions, not generic ones.
REQUIRED: Log errors with sufficient context for debugging.
REQUIRED: Clean up resources in finally blocks or use-with patterns.
REQUIRED: Use structured error information for better debugging.

### Error Classification
REQUIRED: Categorize errors by severity: critical, error, warning, info.
REQUIRED: Use descriptive error names indicating the error type and context.
REQUIRED: Maintain consistent error naming conventions across projects.
REQUIRED: Document all custom error types and their usage scenarios.

### Error Communication
PROHIBITED: Use technical jargon in user-facing messages.
REQUIRED: Provide clear, actionable error messages.
REQUIRED: Include guidance for error resolution.
REQUIRED: Use consistent error response formats.
REQUIRED: Include error codes and descriptions.
REQUIRED: Use structured error formats for internal systems.
REQUIRED: Include correlation IDs for error tracking.
REQUIRED: Implement error propagation across service boundaries.

## Resilience Patterns

### Retry with Backoff
REQUIRED: Implement exponential backoff for transient failures.
REQUIRED: Set maximum retry attempts and timeouts.
REQUIRED: Log retry attempts and successes.

### Circuit Breaker
REQUIRED: Use circuit breakers to prevent cascading failures.
REQUIRED: Implement circuit breaker pattern when appropriate.

Example (Python):
```python
import time

class CircuitBreakerOpenError(Exception):
    """Raised when circuit breaker is open and calls are rejected."""

class CircuitBreaker:
    def __init__(self, failure_threshold=5, timeout=60):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN

    def call(self, func, *args, **kwargs):
        if self.state == "OPEN":
            if time.time() - self.last_failure_time > self.timeout:
                self.state = "HALF_OPEN"
            else:
                raise CircuitBreakerOpenError("Circuit breaker is OPEN")

        try:
            result = func(*args, **kwargs)
            if self.state == "HALF_OPEN":
                self.state = "CLOSED"
                self.failure_count = 0
            return result
        except Exception as e:
            self.failure_count += 1
            self.last_failure_time = time.time()

            if self.failure_count >= self.failure_threshold:
                self.state = "OPEN"

            raise e
```

### Recovery Strategies
REQUIRED: Implement fallback mechanisms for critical services.
REQUIRED: Provide alternative functionality when primary services fail.
REQUIRED: Implement automatic retry for transient failures.
REQUIRED: Use health checks to detect service recovery.
REQUIRED: Provide clear error messages for manual intervention.
REQUIRED: Implement diagnostic tools for troubleshooting.
REQUIRED: Provide rollback mechanisms for failed deployments.

PREFERRED: Use cached data when real-time data is unavailable.
PREFERRED: Implement read-only mode during maintenance.
PREFERRED: Implement automatic failover mechanisms.
PREFERRED: Use self-healing patterns where appropriate.
PREFERRED: Create runbooks for common error scenarios.

## Resource Management

### Cleanup
REQUIRED: Use context managers for resource cleanup.
REQUIRED: Implement proper disposal of connections and files.
REQUIRED: Use timeout-based resource cleanup.
REQUIRED: Monitor resource usage patterns.

### Connection Management
REQUIRED: Implement connection pooling.
REQUIRED: Handle connection failures gracefully.
REQUIRED: Use health checks for connection validation.
REQUIRED: Implement connection retry logic.

### Memory Management
REQUIRED: Monitor memory usage patterns.
REQUIRED: Implement memory cleanup procedures.
REQUIRED: Use memory-efficient data structures.
REQUIRED: Set memory limits and monitoring.

## Input Validation

REQUIRED: Validate all inputs at system boundaries.
REQUIRED: Use whitelist approach for allowed values.
REQUIRED: Implement comprehensive validation rules.
REQUIRED: Provide clear validation error messages.
REQUIRED: Remove or escape dangerous characters.
REQUIRED: Validate file paths and names.
REQUIRED: Sanitize user-generated content.
REQUIRED: Implement input length limits.
REQUIRED: Validate numeric ranges and formats.
REQUIRED: Check date and time validity.
REQUIRED: Validate string patterns and formats.
REQUIRED: Implement size limits for uploads and inputs.

## Monitoring And Alerting

REQUIRED: Use structured logging with consistent formats.
REQUIRED: Include correlation IDs for request tracking.
REQUIRED: Log errors with appropriate context and severity levels.
REQUIRED: Implement log aggregation and analysis.
REQUIRED: Track error rates and types.
REQUIRED: Monitor error trends over time.
REQUIRED: Set up alerts for error threshold breaches.
REQUIRED: Use error metrics for system health assessment.
REQUIRED: Implement multi-level alerting (warning, critical).
REQUIRED: Use different alert channels for different severities.
REQUIRED: Implement alert escalation procedures.
REQUIRED: Provide actionable alert messages.

## Error Testing

REQUIRED: Test system behavior under error conditions.
REQUIRED: Simulate various failure scenarios.
REQUIRED: Test error recovery mechanisms.
REQUIRED: Validate error handling procedures.
REQUIRED: Introduce controlled failures to test resilience.
REQUIRED: Test system behavior under stress conditions.
REQUIRED: Validate failover and recovery procedures.
REQUIRED: Test all error paths in code.
REQUIRED: Validate error messages and formats.
REQUIRED: Test error logging and monitoring.
REQUIRED: Verify error recovery procedures.

## Checklist

- Error handling follows defensive programming principles
- Custom exceptions defined for domain-specific errors
- Resilience patterns implemented for external dependencies
- Resources properly cleaned up in all code paths
- Error messages are actionable and include context
- Monitoring and alerting configured for error tracking
