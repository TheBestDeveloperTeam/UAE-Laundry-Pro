# Knowledge: protocol_jwt

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Protocol

## Reference

JWT (JSON Web Token) for API authentication. Access token: 15-minute expiry, contains user_id, business_owner_id, role, scopes. Refresh token: 7-day expiry, stored in http-only cookie. Token rotation: new refresh token on each refresh. Revocation: blacklist in token_blacklist table. Algorithm: HS256 with server-side secret. Never store access tokens in localStorage.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |