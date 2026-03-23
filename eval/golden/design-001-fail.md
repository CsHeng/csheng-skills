# Design: Payment Processing Service

## Overview

The Payment Processing Service handles charge, refund, and void operations for the
e-commerce platform. It acts as a facade over three external payment gateways: Stripe,
Braintree, and Adyen. Merchants configure a preferred gateway per region.

## Goals

- Provide a single API surface for all payment operations.
- Abstract gateway-specific request/response formats behind a unified contract.
- Support charge, refund, and void operations across all configured gateways.
- Persist a durable payment record for every operation.

## Non-Goals

- Fraud scoring (owned by the Risk service).
- Currency conversion (handled by the Currency service upstream).
- Merchant onboarding or gateway credential management.

## Architecture

```
Client -> API Gateway -> PaymentService -> [Stripe | Braintree | Adyen]
                                        -> PaymentsDB (Postgres)
```

### Components

#### PaymentService API

REST API exposing:
- `POST /charges` — create a new charge
- `POST /charges/{id}/refund` — refund a charge
- `POST /charges/{id}/void` — void an authorized charge

Requests are authenticated via API key passed in the `Authorization` header.

#### Gateway Adapter Layer

Each gateway has a dedicated adapter implementing the `GatewayAdapter` interface:

```go
type GatewayAdapter interface {
    Charge(ctx context.Context, req ChargeRequest) (ChargeResult, error)
    Refund(ctx context.Context, req RefundRequest) (RefundResult, error)
    Void(ctx context.Context, chargeID string) (VoidResult, error)
}
```

The `GatewayRouter` selects the adapter based on the merchant's region configuration.

#### PaymentsDB

Postgres database with a `payments` table:

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| merchant_id | UUID | Owning merchant |
| gateway | TEXT | Gateway used |
| gateway_ref | TEXT | Gateway's transaction ID |
| amount_cents | INT | Charge amount |
| currency | TEXT | ISO 4217 currency code |
| status | TEXT | pending, succeeded, failed, refunded, voided |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

All writes use `SELECT FOR UPDATE` to prevent concurrent status transitions.

## Data Flow

### Charge flow

1. Client sends `POST /charges` with merchant API key, amount, currency, and payment
   method token.
2. PaymentService validates the request and creates a payment record with status
   `pending`.
3. PaymentService calls the appropriate gateway adapter.
4. On success: update payment record to `succeeded`; return 200 with payment ID.
5. On gateway error: update payment record to `failed`; return 402.

### Refund flow

1. Client sends `POST /charges/{id}/refund`.
2. PaymentService loads the charge record; verifies status is `succeeded`.
3. Calls gateway adapter `Refund`.
4. On success: update status to `refunded`; return 200.

## Security

- API keys stored as bcrypt hashes in the database.
- All communication with gateways over TLS 1.2+.
- Payment method tokens are gateway-owned; we never store raw card data.
- Merchant API keys rotated on a 90-day schedule.

## Scalability

- PaymentService is stateless and horizontally scalable.
- PaymentsDB read replicas serve reporting queries.
- Each gateway adapter connection pool is sized per gateway SLA.

## Testing

- Unit tests for each gateway adapter using recorded fixtures.
- Integration tests against gateway sandbox environments.
- Contract tests verifying the `GatewayAdapter` interface for each implementation.
