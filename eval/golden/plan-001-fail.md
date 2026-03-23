# Implementation Plan: Add User Authentication

## Goal

Add session-based user authentication to the web application. Users must be able to
register, log in, and log out. Authenticated sessions expire after 24 hours of
inactivity.

## Background

The application currently has no authentication layer. All API endpoints are publicly
accessible. This plan covers the server-side session management and the minimal UI
changes needed to expose registration and login flows.

## Scope

In scope:
- User registration with email and password
- Password hashing using bcrypt (cost factor 12)
- Session token issuance and cookie-based transport
- Session expiry at 24 hours of inactivity
- Login and logout endpoints
- Middleware to guard authenticated-only routes

Out of scope:
- OAuth or SSO integration
- Multi-factor authentication
- Password reset flow

## Tasks

### 1. Data model

1.1. Add `users` table: `id`, `email` (unique), `password_hash`, `created_at`.
1.2. Add `sessions` table: `id`, `user_id` (FK), `token` (unique), `last_active_at`, `expires_at`.
1.3. Write and apply database migration.

### 2. Registration endpoint

2.1. Implement `POST /auth/register`.
2.2. Validate email format and password length (minimum 10 characters).
2.3. Reject duplicate emails with a 409 response.
2.4. Hash password with bcrypt before insert.
2.5. Return 201 on success with no sensitive data in body.

### 3. Login endpoint

3.1. Implement `POST /auth/login`.
3.2. Look up user by email; compare bcrypt hash.
3.3. On success: create session row, issue `HttpOnly; Secure; SameSite=Strict` cookie.
3.4. Return 401 for invalid credentials without revealing which field is wrong.

### 4. Logout endpoint

4.1. Implement `POST /auth/logout`.
4.2. Delete session row for the current token.
4.3. Clear the session cookie.

### 5. Auth middleware

5.1. Extract session token from cookie on each request.
5.2. Validate token against `sessions` table; check `expires_at`.
5.3. Refresh `last_active_at` on each authenticated request.
5.4. Return 401 for missing or expired sessions.

### 6. Route protection

6.1. Apply auth middleware to all `/api/*` routes except `/auth/register` and `/auth/login`.
6.2. Verify unauthenticated requests to protected routes receive 401.

### 7. Testing

7.1. Unit tests for password hashing utility.
7.2. Integration tests for registration, login, logout flows.
7.3. Integration tests for middleware rejection of expired and missing sessions.
7.4. Verify 401 response body does not leak internal error details.

## Acceptance Criteria

- A new user can register and immediately log in.
- Login returns a valid session cookie.
- Authenticated requests to `/api/*` succeed.
- Unauthenticated requests to `/api/*` return 401.
- Sessions expire after 24 hours of inactivity.
- Passwords are never stored in plaintext; bcrypt hash is verified in tests.
- All new endpoints covered by integration tests.

## Timeline

| Task | Owner | Duration |
|------|-------|----------|
| Data model | backend | 0.5 days |
| Registration + Login | backend | 1 day |
| Logout + Middleware | backend | 0.5 days |
| Route protection | backend | 0.5 days |
| Testing | backend | 1 day |
| Review and merge | team | 0.5 days |

Total: ~4 days
