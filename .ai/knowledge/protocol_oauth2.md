# Knowledge: protocol_oauth2

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Protocol

## Reference

OAuth2 Resource Owner Password flow for first-party app. POST /api/v1/auth/login with username + password. Returns access_token + refresh_token. POST /api/v1/auth/refresh with refresh_token. POST /api/v1/auth/logout revokes tokens. All other endpoints require Authorization: Bearer {access_token}.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |