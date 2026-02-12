# Infrastructure Security Examples

## Secret Rotation Script

```bash
#!/bin/bash
# secret-rotation.sh

rotate_database_credentials() {
    local service_name="$1"
    local max_age_days="${2:-90}"

    # Check credential age
    local credential_age=$(find /etc/secrets/ -name "${service_name}_db_*" -mtime +${max_age_days} | wc -l)

    if [ "$credential_age" -gt 0 ]; then
        echo "Rotating credentials for $service_name"

        # Generate new password
        new_password=$(openssl rand -base64 32)

        # Update database user password
        psql -h "$DB_HOST" -U "$DB_ADMIN" -c "ALTER USER ${service_name}_user WITH PASSWORD '$new_password';"

        # Store encrypted new password
        echo "$new_password" | gpg --encrypt --recipient "$GPG_RECIPIENT" > "/etc/secrets/${service_name}_db_password.gpg"

        echo "Credentials rotated successfully"
    fi
}
```

## TLS Configuration (Nginx)

```nginx
# TLS 1.3 only configuration
server {
    listen 443 ssl http2;
    server_name api.example.com;

    # Modern TLS configuration
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers on;

    # Forward secrecy cipher suites
    ssl_ciphers TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;

    # HSTS enforcement
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    # Certificate configuration
    ssl_certificate /etc/ssl/certs/api.crt;
    ssl_certificate_key /etc/ssl/private/api.key;
    ssl_trusted_certificate /etc/ssl/certs/chain.crt;
}
```

## Container Hardening (Dockerfile)

```dockerfile
# Multi-stage secure build
FROM alpine:3.18 AS builder

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Install build dependencies
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    && rm -rf /var/cache/apk/*

# Build application
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN python -m compileall .

# Production stage
FROM alpine:3.18

# Import user from builder stage
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Install runtime dependencies only
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    && rm -rf /var/cache/apk/* \
    && rm -rf /root/.cache

# Create app directory with proper permissions
WORKDIR /app
COPY --from=builder /app .

# Set ownership and permissions
RUN chown -R appuser:appgroup /app && \
    chmod -R 755 /app && \
    chmod -R 644 /app/*.py

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# Start application with security flags
CMD ["python", "-u", "app.py"]
```

## Security Scanning Workflow

```yaml
# GitHub Actions security workflow
name: Security Scan
on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Trivy vulnerability scanner
        run: |
          docker run --rm -v $PWD:/app aquasec/trivy:latest image --exit-code 0 --severity HIGH,CRITICAL myapp:latest

      - name: Run Bandit security linter
        run: |
          pip install bandit[toml]
          bandit -r src/ -f json -o bandit-report.json

      - name: Run Safety dependency check
        run: |
          pip install safety
          safety check --json --output safety-report.json

      - name: Run Semgrep security analysis
        run: |
          docker run --rm -v $PWD:/app returntocorp/semgrep:latest semgrep --config=auto --json --output=semgrep-report.json

      - name: Upload security reports
        uses: actions/upload-artifact@v3
        with:
          name: security-reports
          path: |
            bandit-report.json
            safety-report.json
            semgrep-report.json
```
