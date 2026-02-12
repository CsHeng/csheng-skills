---
name: security-logging
description: "Security controls and structured logging implementation (auditability, redaction, detection). Activates for: security logging, audit logs, structured logging, log redaction, sensitive data in logs, tokens/passwords in config. 中文触发：安全日志/审计日志、结构化日志、日志脱敏、敏感信息泄露、配置里的 token/password/secret。"
allowed-tools:
  - Bash(shellcheck)
  - Bash(grep -E '^[[:space:]]*[^[:space:]]+[[:space:]]*=')
  - Bash(rg --pcre2 'password|secret|key|token')
---
## Purpose

Define security-focused logging and input validation standards so that services can detect, trace, and audit security-relevant events consistently.

## IO Semantics

Input: Application logs, inbound requests, and configuration surfaces that must be validated or monitored for security.

Output: Structured logging and validation patterns that flag suspicious input, support incident response, and integrate with monitoring systems.

Side Effects: When adopted, may increase log volume and require tuning of alerting rules and storage policies.

## Input Validation Security

Execute input validation at all system boundaries:
- Length validation with configurable limits
- SQL injection pattern detection
- XSS pattern detection
- Filename sanitization for uploads

## API Request Validation

Execute comprehensive API security:
- Rate limiting checks
- Request size validation (default: 10MB limit)
- Response status logging for 4xx/5xx errors
- IP address and user agent tracking

## Credential Security

### Secret Detection
Scan for hardcoded secrets:
- Password patterns in code
- API key patterns
- Token patterns
- Database URL patterns with credentials

### Secret Replacement
Replace hardcoded secrets with environment variables:
- Create backups before modification
- Add os import if missing
- Use os.getenv() for credential access

## Structured Logging

### Security Event Logging
- Timestamp in ISO 8601 format with timezone
- Service name and event type
- Severity levels: CRITICAL, HIGH, MEDIUM, INFO
- User ID and request details
- Integrity hash for tamper detection

### Event Types
- Authentication events (login success/failure)
- Authorization events (access granted/denied)
- Privilege escalation events
- Rate limit violations
- Suspicious activity detection

## Log Integrity

### Tamper-Evident Logging
- Chain log entries with previous hash
- Store hash chain separately
- Verify integrity on demand
- Calculate SHA256 for file verification

## Access Control

### Multi-Factor Authentication
- TOTP-based MFA with pyotp
- Provisioning URI generation
- Token verification with window tolerance
- Account lockout after failed attempts

### Account Lockout
- Track failed login attempts
- Lock after threshold (default: 5 attempts)
- Automatic unlock after duration (default: 15 minutes)
- Reset attempts on successful login

## Checklist

- [ ] Input validation at all boundaries
- [ ] SQL injection patterns detected
- [ ] XSS patterns detected
- [ ] Secrets scanned and replaced
- [ ] Structured logging implemented
- [ ] Security events logged with integrity hash
- [ ] Log chain for tamper detection
- [ ] MFA enabled for sensitive operations
- [ ] Account lockout configured

## References

- [Python Security Logging Examples](references/examples-python.md)
- [Secret Scanner Script](references/secret-scanner.md)
