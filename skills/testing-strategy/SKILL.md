---
name: testing-strategy
description: "Comprehensive testing strategies and coverage standards. Activates for: testing strategy, test plan, unit/integration/e2e tests, coverage thresholds, CI tests. 中文触发：测试策略/测试方案、单元测试/集成测试/E2E、覆盖率阈值、CI 测试、测试分层。"
---
## Purpose

Provide comprehensive testing strategies and coverage standards that can be applied across services, including thresholds, critical path tests, and environment setup.

## IO Semantics

Input: Test suites, coverage reports, and service architectures that require structured testing guidance.

Output: Concrete coverage targets, configuration examples, and critical path testing patterns that can be enforced in CI.

Side Effects: Raising coverage thresholds or enforcing new critical paths may require additional tests and refactoring.

## Coverage Requirements

Apply mandatory coverage thresholds:
- Overall code coverage: ≥ 80%
- Critical business logic coverage: ≥ 95%
- Security-related code coverage: ≥ 90%
- New feature coverage: ≥ 85% before merge

## Test Categories

### Unit Tests
- Test individual functions and components in isolation
- Fast execution, no external dependencies
- Mock external services and databases

### Integration Tests
- Test interactions between components
- Use test containers for databases
- Verify API contracts and data flows

### End-to-End Tests
- Test complete user workflows
- Run against full application stack
- Validate critical business paths

### Performance Tests
- Test system behavior under load
- Verify response time thresholds
- Monitor memory and resource usage

## Test Quality Standards

### AAA Pattern
Apply Arrange-Act-Assert consistently:
1. **Arrange**: Set up test data and dependencies
2. **Act**: Execute the code under test
3. **Assert**: Verify expected outcomes

### Test Isolation
- Each test runs independently
- Use fixtures for setup/teardown
- No shared mutable state between tests

### Naming Conventions
- Descriptive test names explaining scenarios
- Pattern: `test_<action>_<condition>_<expected_result>`
- Group related tests in classes

## Critical Path Testing

Identify and prioritize critical paths:
- Payment processing flows
- User authentication/authorization
- Data integrity operations
- Security-sensitive operations

## Checklist

- [ ] Coverage thresholds configured in CI
- [ ] Unit tests for all business logic
- [ ] Integration tests for external dependencies
- [ ] E2E tests for critical user flows
- [ ] Performance tests for load-sensitive endpoints
- [ ] Test isolation verified (no shared state)
- [ ] AAA pattern followed consistently

## References

- [Python Testing Examples](references/examples-python.md)
- [Go Testing Examples](references/examples-go.md)
- [CI/CD Configuration](references/ci-config.md)
