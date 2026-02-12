# Secret Scanner Script

```bash
#!/bin/bash
# secret-scanner.sh

scan_for_secrets() {
    local scan_dir="$1"

    echo "Scanning for hardcoded secrets in: $scan_dir"

    # Scan for common secret patterns
    echo "=== Password patterns ==="
    rg -i --line-number "password\s*=\s*['\"][^'\"]{8,}['\"]" "$scan_dir" || echo "No password patterns found"

    echo "=== API key patterns ==="
    rg -i --line-number "(api[_-]?key|apikey)\s*=\s*['\"][a-zA-Z0-9]{16,}['\"]" "$scan_dir" || echo "No API key patterns found"

    echo "=== Token patterns ==="
    rg -i --line-number "token\s*=\s*['\"][a-zA-Z0-9]{20,}['\"]" "$scan_dir" || echo "No token patterns found"

    echo "=== Secret key patterns ==="
    rg -i --line-number "secret[_-]?key\s*=\s*['\"][a-zA-Z0-9]{16,}['\"]" "$scan_dir" || echo "No secret key patterns found"

    echo "=== Database URL patterns ==="
    rg -i --line-number "(database[_-]?url|db[_-]?url)\s*=\s*['\"][^'\"]*://[^'\"]*:[^'\"]*@" "$scan_dir" || echo "No database URL patterns found"
}

# Function to replace secrets with environment variables
replace_secrets_with_env() {
    local file="$1"

    # Create backup
    cp "$file" "$file.backup"

    # Replace common secret patterns
    sed -i.tmp \
        -e "s/password\s*=\s*'.*'/password = os.getenv('DB_PASSWORD')/g" \
        -e "s/password\s*=\s*\".*\"/password = os.getenv('DB_PASSWORD')/g" \
        -e "s/api_key\s*=\s*'.*'/api_key = os.getenv('API_KEY')/g" \
        -e "s/api_key\s*=\s*\".*\"/api_key = os.getenv('API_KEY')/g" \
        "$file"

    # Add import if not present
    if ! grep -q "import os" "$file"; then
        sed -i.tmp "1i import os" "$file"
    fi

    rm "$file.tmp"
    echo "Secrets replaced in $file (backup saved as $file.backup)"
}
```
