# Notification Service Design

## Goals

- Deliver user-facing notifications (email, SMS, push) from a single internal API
- Decouple notification dispatch from application business logic via an event bus
- Support per-channel rate limiting and retry with exponential backoff
- Provide per-notification delivery status observable by producers
- Allow new channels to be added without modifying existing producers

## Non-Goals

- Storing notification content long-term beyond delivery audit window (90 days)
- Building a user preference UI (preference reads/writes are out of scope; the service enforces preferences set externally)
- Handling inbound messages or two-way communication
- Real-time read receipts or delivery receipt forwarding back to end users
- Replacing existing transactional email service in the short term

## Architecture

The notification service is composed of four bounded components:

### Event Ingestion

Producers publish `NotificationRequest` events to a Kafka topic (`notifications.requests`).
The ingestion layer validates schema, rejects malformed events with a dead-letter record to
`notifications.dlq`, and writes valid events to the `notification_events` Postgres table
for durable tracking.

### Dispatcher

A pool of workers consumes `notification_events` rows in `pending` state. For each event the
dispatcher selects the appropriate channel adapter (email, SMS, push) based on
`channel` field. The dispatcher enforces per-user, per-channel rate limits stored in Redis
(sliding window counters, TTL-aligned to rate limit window). On rate limit breach the event is
rescheduled without incrementing attempt count.

### Channel Adapters

Each channel is a thin adapter behind a common `Adapter` interface:

```
type Adapter interface {
    Send(ctx context.Context, req AdapterRequest) (AdapterResult, error)
}
```

Adapters wrap third-party clients (SendGrid for email, Twilio for SMS, FCM for push).
Adapter errors are classified as `transient` or `permanent`; only transient errors trigger retry.

### Status Tracker

After each dispatch attempt the dispatcher writes a status record to `notification_attempts`.
Producers can query delivery status via a gRPC `StatusService`. A background job archives
attempts older than 90 days to cold storage and deletes them from Postgres.

## API Design

### Internal Kafka Event (Producer Interface)

```json
{
  "notification_id": "uuid-v4",
  "user_id": "string",
  "channel": "email | sms | push",
  "template_id": "string",
  "template_vars": { "key": "string" },
  "idempotency_key": "string",
  "priority": "high | normal | low",
  "requested_at": "ISO8601"
}
```

### gRPC Status API

```protobuf
service StatusService {
  rpc GetStatus(GetStatusRequest) returns (NotificationStatus);
  rpc ListAttempts(ListAttemptsRequest) returns (ListAttemptsResponse);
}

message GetStatusRequest {
  string notification_id = 1;
}

message NotificationStatus {
  string notification_id = 1;
  string channel = 2;
  string status = 3;         // pending | dispatched | delivered | failed | suppressed
  int32  attempt_count = 4;
  google.protobuf.Timestamp last_updated_at = 5;
}
```

Rate limit errors return gRPC status `RESOURCE_EXHAUSTED` with a `retry_delay_seconds` header.
Permanent delivery failures return `status = "failed"` with a `failure_reason` field.

## Data Model

### notification_events

| Column           | Type        | Notes                                  |
|------------------|-------------|----------------------------------------|
| id               | uuid        | primary key                            |
| idempotency_key  | text        | unique; prevents duplicate dispatch    |
| user_id          | text        |                                        |
| channel          | text        | email / sms / push                     |
| template_id      | text        |                                        |
| template_vars    | jsonb       |                                        |
| priority         | text        |                                        |
| status           | text        | pending / dispatched / failed          |
| attempt_count    | int         | default 0                              |
| next_attempt_at  | timestamptz | null = eligible immediately            |
| created_at       | timestamptz |                                        |
| updated_at       | timestamptz |                                        |

### notification_attempts

| Column            | Type        | Notes                                 |
|-------------------|-------------|---------------------------------------|
| id                | uuid        | primary key                           |
| notification_id   | uuid        | foreign key → notification_events     |
| attempt_number    | int         |                                       |
| channel           | text        |                                       |
| outcome           | text        | delivered / transient_error / permanent_error |
| provider_response | jsonb       | raw provider response summary         |
| attempted_at      | timestamptz |                                       |

Index: `(notification_id, attempt_number)`.
Partition by month on `attempted_at` to simplify archive job.

## Risks and Operability

### Rate Limit Redis Dependency

If Redis is unavailable, rate limit checks fail open to avoid blocking all notifications.
This creates a window where per-user limits are not enforced. Mitigation: monitor Redis
availability with a circuit breaker; alert on >1% error rate on limit checks.

### Kafka Lag Leading to Late Delivery

High Kafka lag causes notification delivery delays. Mitigation: consumer lag alerting at
>5 min p95; priority field drives separate consumer group for `high` priority events.

### Idempotency Key Expiry

Idempotency keys must survive producer retry windows. The `idempotency_key` unique constraint
in Postgres covers this for the 90-day retention window. Keys older than 90 days could allow
re-delivery on producer replay; document this limit in the API contract.

### Dead Letter Queue Monitoring

Malformed events routed to `notifications.dlq` are not automatically retried. Ops runbook
required for DLQ inspection and replay. Alert on DLQ depth > 0.

### Template Rendering

Template rendering is currently proposed in-process inside the dispatcher. If templates
are large or rendering is slow, this blocks the dispatch loop. Risk is low for MVP but
should be extracted to a sidecar in a follow-up if p99 dispatch latency exceeds 200 ms.

### Cold Storage Archive Job

If the archive job falls behind, Postgres storage grows unbounded. Mitigation: partition
the `notification_attempts` table and monitor row count per partition; alert at 80% of
target archive throughput.

## Rollout Plan

1. Deploy ingestion layer with Kafka consumer and Postgres writer in shadow mode (log-only, no dispatch).
2. Enable dispatch for internal test users only, validate end-to-end delivery for all three channels.
3. Canary to 5% of production users for email channel only. Monitor error rate, latency, and Kafka lag.
4. Expand to 100% email traffic. Validate rate limiting under load.
5. Enable SMS and push channels sequentially, one per week, with same canary pattern.
6. Migrate remaining transactional email volume from legacy service.
7. Deprecate legacy service after 30-day parallel run with metric parity confirmed.

Feature flags control per-channel enablement. Rollback is channel flag disable + consumer group pause.

## Acceptance Criteria

- End-to-end notification delivered (email) within 30 seconds for `high` priority under normal load.
- Per-user rate limit enforced: no more than 5 notifications per channel per hour for `normal` priority.
- Duplicate events with the same `idempotency_key` produce exactly one delivery attempt.
- Dead-letter queue depth alerted within 2 minutes of first malformed event.
- Delivery status queryable via gRPC within 5 seconds of dispatch completion.
- Archive job processes at least 100k rows per hour to stay ahead of 90-day window at expected volume.
- Zero data loss on dispatcher crash: in-progress events resume on restart via `pending` status requery.
