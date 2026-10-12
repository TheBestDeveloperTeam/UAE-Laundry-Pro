# Secrets rotation (after exposure or go-live)

Perform on the **server** and **each store** — not in git.

## Cloud (cPanel)

1. Change MySQL password in cPanel → update `cloud-api/.env` `DB_PASS` / `CLOUD_DB_PASS`.
2. Generate new `JWT_SECRET` and `LICENSE_MASTER_SECRET` → update `.env` → restart PHP (or wait for opcache TTL).
3. Super-admin: change password via `/admin` profile or reset hash in DB using `password_hash()` in a one-off PHP CLI script.
4. Invalidate active sessions if JWT secret rotated (users re-login).

## Local store (`api/.env`)

1. Rotate `JWT_SECRET` only during a maintenance window (all POS sessions logout).
2. Rotate `INSTALL_SECRET` only before re-running install wizard.
3. Keep `CLOUD_API_URL` aligned with production cloud domain.

## Desktop

No secrets in MSIX; URLs come from `--dart-define` at build time. Rebuild and redeploy MSIX when cloud URL changes.
