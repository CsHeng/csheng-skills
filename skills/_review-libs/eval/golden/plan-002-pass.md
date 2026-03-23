# Implementation Plan: Add Rate Limiting to API

## Goal

Protect all public API endpoints with per-client rate limiting. Clients exceeding the
limit receive 429 responses with a Retry-After header. The limit is configurable per
environment without a code deploy.

## Background

The API currently has no request throttling. A misbehaving client can saturate the
service and degrade availability for all users. This plan introduces a sliding-window
rate limiter backed by Redis.

## Scope

In scope:
- Sliding-window rate limiting on all `/api/*` routes
- Per-client identity keyed on authenticated user ID (fallback: IP address)
- Configurable limit and window via environment variables
- 429 response with `Retry-After` and `X-RateLimit-*` headers
- Observability: metrics and structured log events on limit hits

Out of scope:
- Per-endpoint or per-tier limits
- Admin bypass tokens

## Tasks

### 1. Redis client setup

1.1. Add Redis client library to dependencies.
1.2. Expose `REDIS_URL` environment variable; fail fast at startup if missing.
1.3. Implement connection health check in application startup probe.

### 2. Sliding-window implementation

2.1. Implement `SlidingWindowLimiter(key, limit, window)` using a Lua script executed
     atomically in Redis.
2.2. Unit-test the Lua script against a Redis test instance for: under-limit, at-limit,
     and over-limit cases, including window expiry.

### 3. Middleware

3.1. Extract client identity: authenticated user ID if present, else remote IP.
3.2. Call `SlidingWindowLimiter`; on limit exceeded return 429 with:
     - `Retry-After: <seconds>`
     - `X-RateLimit-Limit: <limit>`
     - `X-RateLimit-Remaining: 0`
     - `X-RateLimit-Reset: <unix-epoch>`
3.3. On Redis failure: fail open (allow request), emit `rate_limit_redis_error` metric.

### 4. Configuration

4.1. Read `RATE_LIMIT_MAX_REQUESTS` (default: 100) and `RATE_LIMIT_WINDOW_SECONDS`
     (default: 60) from environment.
4.2. Validate at startup; refuse to start if values are non-positive integers.
4.3. Document both variables in `.env.example`.

### 5. Observability

5.1. Emit `rate_limit_hit` counter (labels: `client_type=user|ip`) on each 429.
5.2. Emit `rate_limit_redis_latency` histogram on every Redis call.
5.3. Log structured event `{event: "rate_limited", client_id, path, limit, window}` at
     WARN level on every 429.

### 6. Testing

6.1. Integration test: confirm requests below limit succeed.
6.2. Integration test: confirm request at limit+1 receives 429 with correct headers.
6.3. Integration test: confirm window reset restores quota.
6.4. Integration test: confirm Redis failure results in fail-open (request passes).
6.5. Load test: 200 req/s sustained for 60 s against staging; confirm p99 < 20 ms added
     latency from middleware.

### 7. Rollback strategy

7.1. The middleware is guarded by a feature flag `RATE_LIMITING_ENABLED` (default: true).
7.2. To disable rate limiting without a deploy: set `RATE_LIMITING_ENABLED=false` and
     restart the application. This takes effect within one rolling-update cycle (~2 min).
7.3. If Redis is misconfigured and the fail-open logic is insufficient, remove the
     middleware registration line and redeploy. Estimated time to revert: 5 minutes.
7.4. Canary rollout: deploy to 10% of pods first; watch `rate_limit_hit` and error-rate
     dashboards for 30 minutes before promoting to 100%.

## Acceptance Criteria

- Requests above the configured limit receive 429 with correct headers.
- Requests below the limit succeed with no added failure modes.
- Redis failure does not cause a 5xx; the request is allowed through.
- `RATE_LIMIT_MAX_REQUESTS` and `RATE_LIMIT_WINDOW_SECONDS` change behavior without
  a code redeploy.
- All integration tests pass in CI.
- `rate_limit_hit` counter visible in the metrics dashboard.
- Canary rollout procedure documented in the runbook.

## Operational Runbook

### Monitoring

- Dashboard: "API Rate Limiting" panel in Grafana (link: internal/dashboards/rate-limit)
- Alert: `rate_limit_hit > 500/min` triggers PagerDuty P3.
- Alert: `rate_limit_redis_error_total > 0` triggers Slack #oncall-api.

### Scaling

- Increase `RATE_LIMIT_MAX_REQUESTS` via config map update; no redeploy needed.
- If Redis becomes a bottleneck, shard by client key prefix across two Redis instances.

### Disable (no-deploy path)

```
kubectl set env deployment/api RATE_LIMITING_ENABLED=false
kubectl rollout status deployment/api
```

## Timeline

| Task | Owner | Duration |
|------|-------|----------|
| Redis client | backend | 0.5 days |
| Sliding window | backend | 1 day |
| Middleware | backend | 0.5 days |
| Configuration | backend | 0.5 days |
| Observability | backend | 0.5 days |
| Testing | backend | 1 day |
| Canary rollout | SRE + backend | 0.5 days |

Total: ~4.5 days
