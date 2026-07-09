# Python Security Examples

## Secure Credential Access

```python
import os
from cryptography.fernet import Fernet

class SecureConfig:
    def __init__(self):
        self.cipher_suite = Fernet(self._get_encryption_key())

    def get_database_config(self):
        return {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': int(os.getenv('DB_PORT', '5432')),
            'username': os.getenv('DB_USER'),
            'password': self._decrypt(os.getenv('DB_PASSWORD')),
            'database': os.getenv('DB_NAME')
        }

    def _get_encryption_key(self):
        key_file = os.getenv('ENCRYPTION_KEY_FILE', '/app/.encryption_key')
        with open(key_file, 'rb') as f:
            return f.read()

    def _decrypt(self, encrypted_value):
        if not encrypted_value:
            return None
        return self.cipher_suite.decrypt(encrypted_value.encode()).decode()
```

## Input Validation

```python
import re
import bleach
from typing import Any, Dict
from pydantic import BaseModel, validator, constr

class UserInputValidator:
    SQL_INJECTION_PATTERNS = [
        r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION)\b)",
        r"(--|#|\/\*|\*\/)",
        r"(;|\|||\|&)",
        r"(\b(OR|AND)\s+\w+\s*=\s*\w+)"
    ]

    XSS_PATTERNS = [
        r"<script[^>]*>.*?</script>",
        r"javascript:",
        r"on\w+\s*=",
        r"<iframe[^>]*>",
        r"<object[^>]*>",
        r"<embed[^>]*>"
    ]

    @classmethod
    def sanitize_input(cls, user_input: str) -> str:
        clean_input = bleach.clean(user_input, tags=[], strip=True)
        clean_input = ' '.join(clean_input.split())
        return clean_input

    @classmethod
    def detect_sql_injection(cls, input_string: str) -> bool:
        upper_input = input_string.upper()
        for pattern in cls.SQL_INJECTION_PATTERNS:
            if re.search(pattern, upper_input, re.IGNORECASE):
                return True
        return False

    @classmethod
    def detect_xss(cls, input_string: str) -> bool:
        for pattern in cls.XSS_PATTERNS:
            if re.search(pattern, input_string, re.IGNORECASE | re.DOTALL):
                return True
        return False

class SecureUserRegistration(BaseModel):
    username: constr(regex=r'^[a-zA-Z0-9_]{3,30}$')
    email: constr(regex=r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
    password: constr(min_length=12, max_length=128)

    @validator('password')
    def validate_password_strength(cls, v):
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain uppercase letter')
        if not re.search(r'[a-z]', v):
            raise ValueError('Password must contain lowercase letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain digit')
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            raise ValueError('Password must contain special character')
        return v

    @validator('username')
    def validate_username_safe(cls, v):
        if UserInputValidator.detect_sql_injection(v):
            raise ValueError('Invalid characters in username')
        if UserInputValidator.detect_xss(v):
            raise ValueError('Invalid characters in username')
        return v
```

## Secure File Upload

```python
import magic
import hashlib
from werkzeug.utils import secure_filename

class SecureFileUploader:
    ALLOWED_MIME_TYPES = {
        'image/jpeg', 'image/png', 'image/gif',
        'application/pdf', 'text/plain'
    }

    MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
    UPLOAD_FOLDER = '/secure/uploads'

    @classmethod
    def validate_file(cls, file) -> Dict[str, Any]:
        result = {'valid': False, 'errors': []}

        # Check file size
        file.seek(0, 2)
        file_size = file.tell()
        file.seek(0)

        if file_size > cls.MAX_FILE_SIZE:
            result['errors'].append('File too large')
            return result

        # Check file type
        file_content = file.read(1024)
        file.seek(0)

        mime_type = magic.from_buffer(file_content, mime=True)
        if mime_type not in cls.ALLOWED_MIME_TYPES:
            result['errors'].append(f'File type {mime_type} not allowed')
            return result

        # Generate secure filename
        original_filename = file.filename
        secure_name = secure_filename(original_filename)

        # Add hash to prevent filename collisions
        file_hash = hashlib.sha256(file_content).hexdigest()[:8]
        final_filename = f"{file_hash}_{secure_name}"

        result.update({
            'valid': True,
            'secure_filename': final_filename,
            'mime_type': mime_type,
            'size': file_size
        })

        return result

    @classmethod
    def save_file(cls, file, filename: str) -> str:
        file_path = os.path.join(cls.UPLOAD_FOLDER, filename)

        os.makedirs(cls.UPLOAD_FOLDER, mode=0o700, exist_ok=True)

        with open(file_path, 'wb') as f:
            file.save(file_path)

        os.chmod(file_path, 0o600)

        return file_path
```

## Flask Security Configuration

```python
from flask import Flask
from flask_cors import CORS
from flask_talisman import Talisman

app = Flask(__name__)

# Strict CORS configuration
CORS(app,
     resources={
         r"/api/*": {
             "origins": ["https://app.example.com"],
             "methods": ["GET", "POST", "PUT", "DELETE"],
             "allow_headers": ["Content-Type", "Authorization"],
             "max_age": 86400
         }
     })

# Security headers with Talisman
csp = {
    'default-src': "'self'",
    'script-src': [
        "'self'",
        "'nonce-${nonce}'",
        "https://trusted-cdn.example.com"
    ],
    'style-src': [
        "'self'",
        "'unsafe-inline'",
        "https://fonts.googleapis.com"
    ],
    'font-src': ["'self'", "https://fonts.gstatic.com"],
    'img-src': ["'self'", "data:", "https:"],
    'connect-src': ["'self'", "https://api.example.com"]
}

Talisman(app,
         force_https=True,
         strict_transport_security=True,
         content_security_policy=csp,
         referrer_policy='strict-origin-when-cross-origin',
         feature_policy={
             'geolocation': "'none'",
             'camera': "'none'",
             'microphone': "'none'"
         })
```

## Security Monitoring

```python
import json
import logging
from datetime import datetime
from typing import Dict, Any

class SecurityMonitor:
    def __init__(self):
        self.logger = logging.getLogger('security')
        self.security_events = []

    def log_security_event(self, event_type: str, severity: str, details: Dict[str, Any]):
        event = {
            'timestamp': datetime.utcnow().isoformat(),
            'event_type': event_type,
            'severity': severity,
            'details': details,
            'source_ip': details.get('source_ip'),
            'user_agent': details.get('user_agent')
        }

        self.security_events.append(event)

        log_entry = json.dumps(event)

        if severity == 'CRITICAL':
            self.logger.critical(log_entry)
            self._send_alert(event)
        elif severity == 'HIGH':
            self.logger.error(log_entry)
        elif severity == 'MEDIUM':
            self.logger.warning(log_entry)
        else:
            self.logger.info(log_entry)

    def detect_anomalous_login(self, user_id: str, ip_address: str, user_agent: str):
        recent_logins = [e for e in self.security_events
                        if e['event_type'] == 'login' and e['details']['user_id'] == user_id
                        and (datetime.utcnow() - datetime.fromisoformat(e['timestamp'])).seconds < 3600]

        known_ips = {e['details']['ip_address'] for e in recent_logins}

        if ip_address not in known_ips and len(known_ips) > 0:
            self.log_security_event(
                'suspicious_login_location',
                'HIGH',
                {
                    'user_id': user_id,
                    'new_ip': ip_address,
                    'known_ips': list(known_ips),
                    'source_ip': ip_address,
                    'user_agent': user_agent
                }
            )

    def detect_brute_force(self, ip_address: str):
        failed_attempts = len([e for e in self.security_events
                             if e['event_type'] == 'failed_login'
                             and e['details']['ip_address'] == ip_address
                             and (datetime.utcnow() - datetime.fromisoformat(e['timestamp'])).seconds < 300])

        if failed_attempts >= 5:
            self.log_security_event(
                'brute_force_detected',
                'CRITICAL',
                {
                    'ip_address': ip_address,
                    'failed_attempts': failed_attempts,
                    'timeframe': '5 minutes',
                    'source_ip': ip_address
                }
            )

    def _send_alert(self, event: Dict[str, Any]):
        alert_message = f"Security Alert: {event['event_type']} - {event['details']}"
        # send_to_slack(alert_message)
        # send_to_pagerduty(alert_message)
```
