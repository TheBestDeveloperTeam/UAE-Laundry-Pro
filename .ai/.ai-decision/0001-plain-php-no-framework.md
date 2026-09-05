# ADR 0001: Plain PHP Without Framework

## Status
Accepted

## Context
README originally specified Slim or Laravel Lumen with Composer dependencies.

## Decision
Use plain PHP 8.x with a custom router, DI container, PDO repositories, and built-in security primitives (password_hash, hash_hmac JWT).

## Consequences
- No Composer packages in runtime
- Custom migration runner (`api/database/migrate.php`)
- Hand-written OpenAPI spec
- More bootstrap code owned by the team
