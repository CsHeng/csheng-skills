# Design: User Notification Service

## Overview

The User Notification Service (UNS) delivers transactional and marketing notifications
to users via email and push channels. It decouples event producers from delivery
infrastructure and provides a unified audit trail for all sent notifications.

## Goals

- Accept notification events from internal services over a message queue.
- Route events to the correct delivery channel (email or push).
- Guarantee at-least-once delivery with deduplication on the consumer side.
- Provide an audit log of every delivery attempt and its outcome.
- Allow per-user channel preferences (opt-out per channel/category).

## Non-Goals

- SMS delivery (planned for a later phase).
- Templating engine — callers supply rendered content.
- User preference UI — exposed via a separate Preferences service.

## Architecture

```
ProducerService -> EventQueue (SQS) -> NotificationConsumer -> [EmailAdapter | PushAdapter]
                                                             -> NotificationsDB (Postgres)
```

### Components

#### EventQueue

AWS SQS FIFO queue with message deduplication on `idempotency_key` (set by the
producer). Messages have a visibility timeout of 30 seconds and a max receive count of
3 before routing to the dead-letter queue (DLQ).

#### NotificationConsumer

Long-polling SQS consumer. Processes one message at a time per worker goroutine. On
success it deletes the message; on permanent failure it allows the message to exhaust
retries and land in the DLQ.

#### Channel Adapters

Each adapter wraps a third-party SDK:

```go
type ChannelAdapter interface {
    Send(ctx context.Context, req SendRequest) (SendResult, error)
}
```

Adapters enforce per-channel timeouts:
- EmailAdapter: 10-second context deadline (calls SendGrid).
- PushAdapter: 5-second context deadline (calls Firebase FCM).

On timeout or transient error (5xx from provider), the consumer does NOT delete the
SQS message, allowing automatic retry up to the max receive count.

On permanent provider error (4xx, invalid token), the consumer writes a `failed`
record and deletes the SQS message to avoid infinite retry.

#### NotificationsDB

Postgres table `notification_events`:

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| idempotency_key | TEXT | Unique; prevents duplicate delivery |
| user_id | UUID | Target user |
| channel | TEXT | email or push |
| category | TEXT | transactional or marketing |
| status | TEXT | queued, sent, failed, skipped |
| provider_message_id | TEXT | Provider's delivery reference |
| created_at | TIMESTAMPTZ | |
| delivered_at | TIMESTAMPTZ | |

`idempotency_key` has a unique index. Inserts use `ON CONFLICT DO NOTHING` to skip
duplicates already processed.

## Failure Modes

### Provider timeout

Context deadline exceeded on adapter call. Consumer leaves message in-flight; SQS
re-delivers after visibility timeout. Up to 3 attempts before DLQ.

### Provider transient error (5xx)

Same retry path as timeout. Three attempts maximum.

### Provider permanent error (4xx)

Write `failed` status to DB, delete SQS message. Alert fires if `failed` rate exceeds
1% of messages over a 5-minute window.

### SQS unavailable

Consumer pauses polling (exponential backoff: 1s, 2s, 4s, up to 60s). Producers
continue enqueueing (SQS is durable). Alert fires after 60 seconds of consumer idle.

### NotificationsDB unavailable

Consumer treats write failure as a transient error and does not delete the SQS message.
After 3 attempts the message lands in the DLQ. On-call team triages DLQ manually.

### DLQ depth alarm

CloudWatch alarm: `DLQDepth > 10` triggers PagerDuty P2.

## Observability

- `notifications_sent_total` counter (labels: `channel`, `category`).
- `notifications_failed_total` counter (labels: `channel`, `category`, `reason`).
- `notification_delivery_latency_seconds` histogram (labels: `channel`).
- `dlq_depth` gauge polled every 60 seconds.
- Structured log line per delivery attempt: `{event, idempotency_key, user_id, channel, status, latency_ms}`.

## Security

- SQS access via IAM role; no credentials in application config.
- SendGrid and FCM API keys in AWS Secrets Manager; rotated on 90-day schedule.
- No PII in log fields; `user_id` is a UUID with no embedded personal data.

## Rollout Plan

1. Deploy NotificationConsumer in read-only probe mode (no deletes, no DB writes) to
   verify SQS connectivity and adapter reachability.
2. Enable writes for email channel only; monitor `notifications_sent_total` and
   `notifications_failed_total` for 24 hours.
3. Enable push channel; repeat monitoring.
4. Decommission the old in-process notification code path after 7 days of clean metrics.

### Rollback

- Disable the consumer by scaling to 0 replicas. SQS retains messages for 4 days.
- Re-enable the old code path via feature flag `USE_LEGACY_NOTIFIER=true`.
- Estimated time to rollback: 2 minutes (scale-down) + 1 minute (flag flip).

## Testing

- Unit tests for each adapter with recorded provider fixtures.
- Integration tests against SQS and Postgres test instances (LocalStack + Docker).
- Idempotency test: send same `idempotency_key` twice; verify only one DB record and
  one provider call.
- Timeout test: mock provider to hang; verify context deadline is respected and message
  is left for retry.
- DLQ test: mock provider to always fail; verify message lands in DLQ after 3 attempts.
