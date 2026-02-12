---
name: logging-standards
description: "Structured logging standards and observability (format, levels, correlation, monitoring). Activates for: logging standards, log format, log levels, correlation ID, request tracing, log rotation, structured logging, log aggregation, ELK, Splunk. 中文触发：日志规范、日志格式、日志级别、关联ID、请求追踪、日志轮转、结构化日志、日志聚合。"
---

## Purpose

Define structured logging and observability standards for consistent log format, correlation, and monitoring across all services.

## IO Semantics

Input: Application logs, HTTP access logs, and observability requirements.

Output: Standardized log formats, correlation patterns, and monitoring configurations.

Side Effects: May require log aggregation infrastructure (ELK, Splunk) and storage policy tuning.

## App Log Format

Standard format: `+0800 2025-08-06 15:22:30 INFO main.go(180) | Descriptive message`

Components:
- Timezone offset (+0800 or appropriate)
- Timestamp: YYYY-MM-DD HH:MM:SS
- Level: DEBUG, INFO, WARN, ERROR, FATAL
- Source: file.extension(line)
- Separator: pipe character (|)
- Message: descriptive, actionable content

## HTTP Access Log Format

Use GoAccess-compatible format for web traffic analysis:
- Prefer NCSA Combined Log Format across services
- Use "with Virtual Host" variant when applicable
- Keep HTTP access logs separate from application logs
- Document chosen format per service in README or ops runbook

## Log Level Guidelines

| Level | Usage |
|-------|-------|
| DEBUG | Detailed diagnostic information (development only) |
| INFO | Application flow and state changes |
| WARN | Unexpected situations, application continues |
| ERROR | Error events, application continues |
| FATAL | Critical errors causing termination |

## Context and Correlation

Required fields for distributed tracing:
- `request_id`: Per-request identifier
- `correlation_id`: Cross-service tracing
- `user_id`, `session_id`: User context when appropriate
- `duration_ms`, `memory_usage`: Performance metrics
- `trace_id`, `span_id`: OpenTelemetry integration (preferred)

## Field Naming Conventions

- Use snake_case: `user_id`, `request_id`, `error_code`
- Consistent naming across all services
- Standard fields: `timestamp`, `level`, `message`
- Prefer Elastic Common Schema (ECS) when possible
- Document custom fields in project documentation

## Structured Logging

- Key-value pairs for context
- Consistent field naming
- Appropriate data types (strings, numbers, booleans)
- JSON serialization for complex objects
- Schema validation for structured fields (preferred)

## Security Logging

Required:
- Log authentication attempts (success/failure)
- Record authorization failures (resource, action)
- Log sensitive data access (purpose, user context)
- Implement audit logging for security events

Prohibited:
- Log passwords, API keys, credentials
- Include PII without redaction
- Expose stack traces in user-facing messages

## Performance Logging

- Operation durations for monitoring
- Resource usage (memory, CPU, disk)
- Database query performance and connection pool status
- External API latency and success rates
- Distributed tracing for end-to-end visibility

## Configuration Management

- Environment-specific log levels (dev, staging, prod)
- Log rotation to prevent disk space issues
- Retention periods based on compliance requirements
- Centralized log aggregation
- Environment-specific configuration files (preferred)

## Monitoring and Alerting

- Log-based monitoring for critical events
- Alerts for error rates, response times, system health
- Log volume and pattern anomaly detection
- Regular alerting configuration testing
- Automated dashboards for visualization (preferred)

## Compliance and Audit

- Audit logging for sensitive operations
- Log integrity and tamper prevention
- Logs available for required retention periods
- Secure archival and retrieval processes
- Write-once storage for compliance-critical logs (preferred)

## Tool Requirements

| Category | Requirement |
|----------|-------------|
| Libraries | Structured logging with language-appropriate libraries |
| Aggregation | Centralized system (ELK stack, Splunk, etc.) |
| Monitoring | Real-time log monitoring and alerting |
| Analysis | Log search and analysis capabilities |
| Observability | Integration with metrics and tracing (preferred) |

## Checklist

- [ ] App log format follows standard
- [ ] HTTP access logs use GoAccess-compatible format
- [ ] Log levels configured per environment
- [ ] Correlation IDs implemented
- [ ] Sensitive data excluded from logs
- [ ] Log rotation configured
- [ ] Monitoring and alerting set up
- [ ] Audit logging for sensitive operations

## References

- [Python Logging Examples](references/examples-python.md)
- [Go Logging Examples](references/examples-go.md)
