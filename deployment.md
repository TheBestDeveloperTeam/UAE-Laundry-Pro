# LaundryPro UAE — Zero-Docker Manual Deployment Guide
## (cPanel / Apache / Direct PHP / FTP / Shared Hosting)

> **Deployment Mode:** Pure Custom Core PHP (Zero Docker, Zero Nginx, Zero Composer)  
> **Server Environment:** cPanel / Apache / LiteSpeed / Linux Shared or VPS (Non-Root, Non-Sudo)  
> **Target Cloud Domain:** `https://laundrypro-cloudapi.magnificentsolution.co.in/`  
> **Server Path:** `/home/ihgzplwh/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in/`  
> **Database:** MariaDB / MySQL (`ihgzplwh_laundrypro`)  

---

## Table of Contents

1. [Why Zero-Docker & Why No Nginx or Composer?](#1-why-zero-docker--why-no-nginx-or-composer)
2. [Prerequisites & Server Inventory](#2-prerequisites--server-inventory)
3. [Step 1: Database Setup in cPanel](#step-1-database-setup-in-cpanel)
4. [Step 2: Environment Configuration (.env)](#step-2-environment-configuration-env)
5. [Step 3: Web Server & URL Rewriting (.htaccess)](#step-3-web-server--url-rewriting-htaccess)
6. [Step 4: Running Database Migrations via Web & CLI](#step-4-running-database-migrations-via-web--cli)
7. [Step 5: Verifying Health, Docs, and Admin Portal](#step-5-verifying-health-docs-and-admin-portal)
8. [Step 6: Connecting Local Windows POS Terminals to Cloud Hub](#step-6-connecting-local-windows-pos-terminals-to-cloud-hub)
9. [Troubleshooting & Common Questions](#troubleshooting--common-questions)

---

## 1. Why Zero-Docker & Why No Nginx or Composer?

- **No Docker Required:** Standard shared hosting and cPanel accounts do not allow `sudo`, root privileges, or `docker` daemon commands (`bash: docker: command not found`, `bash: sudo: command not found`).
- **No Nginx Required:** Your hosting server (`pace.magnificentsolution.co.in`) is already powered by **Apache / LiteSpeed**. Adding Nginx is redundant and would conflict with your cPanel port bindings. Apache handles routing cleanly via `.htaccess`.
- **No Composer Required:** The LaundryPro Cloud and Local APIs are designed strictly under architectural constraint **AC-1 ("No third-party PHP framework")**. The micro-framework has **zero external vendor dependencies**; everything uses the built-in native PHP autoloader (`spl_autoload_register`).

---

## 2. Prerequisites & Server Inventory

From your terminal, your server directory is:
```
/home/ihgzplwh/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in/
```

Inside this directory, the cloud API lives in:
```
./cloud-api/
```

### Database Credentials Configured:
- **Host:** `localhost` (or `127.0.0.1` — **DO NOT use `cloud-db`**, which was a Docker container name)
- **Database Name:** `ihgzplwh_laundrypro`
- **Username:** `ihgzplwh_laundrypro`
- **Password:** `n33d@L0v3#0786`
- **Port:** `3306`

---

## Step 1: Database Setup in cPanel

1. Log into your **cPanel** dashboard:
   `https://pace.magnificentsolution.co.in:2083/`
2. Navigate to **Databases** -> **MySQL® Databases**:
   - Verify database `ihgzplwh_laundrypro` exists.
   - Verify user `ihgzplwh_laundrypro` is assigned to `ihgzplwh_laundrypro` with **ALL PRIVILEGES**.
3. (Optional) Open **phpMyAdmin** from cPanel to view tables.

---

## Step 2: Environment Configuration (.env)

Your terminal has two `.env` files:
1. Root: `/home/ihgzplwh/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in/.env`
2. Cloud API: `/home/ihgzplwh/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in/cloud-api/.env`

### Configure `cloud-api/.env` (or copy `.env.production`):

```bash
cd /home/ihgzplwh/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in/cloud-api
cp .env.production .env
```

Ensure the contents of `cloud-api/.env` match the following **exact production settings**:

```ini
APP_DEBUG=false
APP_ENV=production
APP_NAME=UAE Laundry Pro
APP_URL=https://laundrypro-cloudapi.magnificentsolution.co.in
API_BASE_URL=https://laundrypro-cloudapi.magnificentsolution.co.in/api/v1
CLOUD_API_BASE_URL=https://laundrypro-cloudapi.magnificentsolution.co.in/api/v1

# Security & Secrets
JWT_SECRET=MakeSureThisIsA64CharRandomHexSecretForProductionKeySigning12345
LICENSE_HMAC_SECRET=LaundryProCloudSecret2026
LICENSE_MASTER_SECRET=LP_CLOUD_MASTER_SIGNING_SECRET_KEY_2026_UAE_SECURITY_LAYER

# Super-Admin Contact
SUPERADMIN_EMAIL=superadmin@laundrypro-cloudapi.magnificentsolution.co.in

# Database Connection (Standard cPanel localhost)
DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=ihgzplwh_laundrypro
DB_USERNAME=ihgzplwh_laundrypro
DB_PASSWORD=n33d@L0v3#0786

# Alternative prefixes (supported by LaundryPro Cloud Database helper)
CLOUD_DB_HOST=localhost
CLOUD_DB_PORT=3306
CLOUD_DB_NAME=ihgzplwh_laundrypro
CLOUD_DB_USER=ihgzplwh_laundrypro
CLOUD_DB_PASS=n33d@L0v3#0786

# CORS
CORS_ALLOWED_ORIGINS=*

# Session configuration
SESSION_DRIVER=file
SESSION_LIFETIME=120
```

> **IMPORTANT:** Notice `DB_HOST=localhost`. In Docker setups this was `cloud-db`. In cPanel shared hosting, MariaDB runs locally, so **`localhost` is required**.

---

## Step 3: Web Server & URL Rewriting (.htaccess)

The application includes two pre-configured `.htaccess` files to route all incoming HTTP traffic to `cloud-api/public/index.php`.

### 1. Root `.htaccess`
Located at: `/home/ihgzplwh/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in/.htaccess`

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On

    # Forward Authorization header for JWT tokens to PHP
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    # Prevent direct web access to local desktop code and source control
    RewriteRule ^(\.git|api|lib|windows|test|scripts) - [F,L,NC]

    # Route API, Admin, and Cloud endpoints to the Cloud API entry point
    RewriteCond %{REQUEST_URI} ^/api/ [OR]
    RewriteCond %{REQUEST_URI} ^/admin/ [OR]
    RewriteCond %{REQUEST_URI} ^/cloud-api/
    RewriteRule ^ cloud-api/public/index.php [QSA,L]

    # Default root redirect to Super-Admin portal
    RewriteRule ^$ cloud-api/public/index.php [QSA,L]
</IfModule>
```

### 2. Cloud API `.htaccess`
Located at: `/home/ihgzplwh/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in/cloud-api/.htaccess`

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On

    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    # Protect internal folders
    RewriteRule ^(\.env|\.git|storage|logs|database|tests|src|config) - [F,L,NC]

    # Serve static assets directly if existing under public/
    RewriteCond %{DOCUMENT_ROOT}/public/$1 -f [OR]
    RewriteCond %{DOCUMENT_ROOT}/public/$1 -d
    RewriteRule ^(.*)$ public/$1 [L]

    # Route all traffic to public/index.php
    RewriteRule ^ public/index.php [QSA,L]
</IfModule>
```

---

## Step 4: Running Database Migrations via Web & CLI

### Option A: Using SSH CLI (Recommended)

From your SSH terminal as user `ihgzplwh`:

```bash
cd /home/ihgzplwh/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in/cloud-api
php database/migrate.php
```

*Expected output:*
```
✅ [APPLIED] 001_cloud_init — Applied successfully
✅ [APPLIED] 002_multi_tenant_schemas — Applied successfully
✅ [APPLIED] 003_cloud_audit_and_licenses — Applied successfully

Done. 3 migration(s) applied.
```

### Option B: Using cPanel phpMyAdmin (If CLI is restricted)

1. Open **phpMyAdmin** from your cPanel.
2. Select database `ihgzplwh_laundrypro`.
3. Click the **Import** tab.
4. Import the following SQL migration files in order:
   - `cloud-api/database/migrations/001_cloud_init.sql`
   - `cloud-api/database/migrations/002_multi_tenant_schemas.sql`
   - `cloud-api/database/migrations/003_cloud_audit_and_licenses.sql`
5. Click **Go** to execute.

### Seed Default Master Super-Admin

In phpMyAdmin -> **SQL** tab (or via mysql CLI), run:

```sql
INSERT INTO cloud_super_admins (id, username, email, password_hash, full_name, role, is_active)
VALUES (
  1,
  'superadmin',
  'superadmin@laundrypro-cloudapi.magnificentsolution.co.in',
  '$2y$10$eE0oI9uL5O9B7zT7w7Nq6.H.w187QjXo2bWqC6cZyS85Ewh9bK87y',
  'Master Super Administrator',
  'super_admin',
  1
) ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;
```

> **Default Super-Admin Credentials:**  
> - **Username:** `superadmin`  
> - **Password:** `SuperAdmin@LaundryPro2026!`

---

## Step 5: Verifying Health, Docs, and Admin Portal

Open your web browser and test the live URLs:

### 1. Health Check Endpoint
URL: `https://laundrypro-cloudapi.magnificentsolution.co.in/api/v1/health`

*Expected JSON response:*
```json
{
  "success": true,
  "code": "HEALTH_OK",
  "data": {
    "service": "LaundryPro Cloud API",
    "version": "2.0.0",
    "database": "connected"
  }
}
```

### 2. Interactive Swagger / OpenAPI Documentation
URL: `https://laundrypro-cloudapi.magnificentsolution.co.in/api/v1/docs`

Loads live Swagger UI showing all endpoints across 35 operational domains.

### 3. Super-Admin Web Portal
URL: `https://laundrypro-cloudapi.magnificentsolution.co.in/admin/login`

- Log in with `superadmin` and `SuperAdmin@LaundryPro2026!`.
- You can now issue store licenses, inspect tenant synchronization, and monitor audit trails.

---

## Step 6: Connecting Local Windows POS Terminals to Cloud Hub

On each local Windows POS workstation, update the `api/.env` file:

```ini
CLOUD_API_URL=https://laundrypro-cloudapi.magnificentsolution.co.in/api/v1
SYNC_INTERVAL_SECONDS=300
```

1. Launch the POS application.
2. In the setup wizard, enter the license key generated from the Cloud Admin portal (e.g. `LP-DUBAI-2026-X89K-M210`).
3. Click **Activate Station Online**.
4. The station will establish a 3-way handshake with your cPanel cloud server, bind the machine's UMAC code, and begin synchronization.

---

## Troubleshooting & Common Questions

### Q1: `php database/migrate.php` says "Could not connect to database"
- **Solution:** Verify `DB_HOST=localhost` inside `cloud-api/.env`. If set to `cloud-db` (from Docker), PHP cannot resolve the hostname. Also verify `DB_USER` and `DB_PASSWORD` in cPanel.

### Q2: Why does `curl -fsSL https://... | sudo gpg` fail?
- **Answer:** In shared cPanel hosting (`[ihgzplwh@pace ...]$`), you are a restricted shell user and cannot run `sudo` or install root OS packages. You do not need to install anything; Apache, PHP 8.2, and MariaDB are already running natively on the server.

### Q3: When I visit `https://.../api/v1/health`, I see 404 or Apache Directory Listing
- **Solution:** Ensure `mod_rewrite` is active and `.htaccess` exists in both the root directory and `cloud-api/`. If subdomain document root in cPanel is pointed directly to `cloud-api/public`, the routes will work natively without prefix rewriting.

### Q4: Permissions on `cloud-api/logs/`
- Ensure the log directory is writable by PHP:
  ```bash
  chmod 755 /home/ihgzplwh/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in/cloud-api/logs
  ```
