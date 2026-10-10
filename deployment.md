# LaundryPro UAE — End-to-End Production Deployment Guide

> **Target Version:** 2.0.0 Production  
> **Document Role:** Step-by-Step ("Baby Steps") Production Deployment Manual  
> **Target Audience:** System Administrators, DevOps Engineers, Store IT Technicians  
> **Architecture:** Offline-First Windows POS Terminal + Central Linux Multi-Tenant Cloud Hub  

---

## Table of Contents

1. [Architecture Overview & Topologies](#1-architecture-overview--topologies)
2. [Prerequisites & System Requirements](#2-prerequisites--system-requirements)
3. [Phase 1: Central Cloud Hub Deployment (Linux / Docker)](#phase-1-central-cloud-hub-deployment-linux--docker)
   - [Step 1.1: Server Provisioning & OS Setup](#step-11-server-provisioning--os-setup)
   - [Step 1.2: Clone Repository & Configure Environment](#step-12-clone-repository--configure-environment)
   - [Step 1.3: Launch Cloud Hub Containers](#step-13-launch-cloud-hub-containers)
   - [Step 1.4: Apply Cloud Database Migrations & Seed Super-Admin](#step-14-apply-cloud-database-migrations--seed-super-admin)
   - [Step 1.5: Setup Nginx SSL & Domain Reverse Proxy](#step-15-setup-nginx-ssl--domain-reverse-proxy)
   - [Step 1.6: Verify Cloud Hub Health & Super-Admin Login](#step-16-verify-cloud-hub-health--super-admin-login)
4. [Phase 2: Local Store Server & Workstation Deployment (Windows POS)](#phase-2-local-store-server--workstation-deployment-windows-pos)
   - [Step 2.1: Local Store Prerequisites (XAMPP / MariaDB / PHP 8.2)](#step-21-local-store-prerequisites-xampp--mariadb--php-82)
   - [Step 2.2: Directory Structure & File Permissions](#step-22-directory-structure--file-permissions)
   - [Step 2.3: Local API Environment Configuration](#step-23-local-api-environment-configuration)
   - [Step 2.4: Run Database Migrations & Initial UAE Seeds](#step-24-run-database-migrations--initial-uae-seeds)
   - [Step 2.5: Build & Install Flutter Desktop Application](#step-25-build--install-flutter-desktop-application)
   - [Step 2.6: Configure Windows Scheduled Tasks (Sync & Daily Backups)](#step-26-configure-windows-scheduled-tasks-sync--daily-backups)
5. [Phase 3: Hardware Peripheral Setup](#phase-3-hardware-peripheral-setup)
   - [Step 3.1: ESC/POS Thermal Receipt Printer (USB & LAN)](#step-31-escpos-thermal-receipt-printer-usb--lan)
   - [Step 3.2: Cash Drawer Kick-Pulse](#step-32-cash-drawer-kick-pulse)
   - [Step 3.3: 1D/2D Barcode & QR Scanner (HID Keyboard / Serial COM)](#step-33-1d2d-barcode--qr-scanner-hid-keyboard--serial-com)
   - [Step 3.4: UHF RFID Reader Antenna (Serial COM3)](#step-34-uhf-rfid-reader-antenna-serial-com3)
6. [Phase 4: License Activation & 3-Way Cloud Handshake](#phase-4-license-activation--3-way-cloud-handshake)
   - [Step 4.1: Issue Tenant License from Cloud Super-Admin](#step-41-issue-tenant-license-from-cloud-super-admin)
   - [Step 4.2: Activate Store Terminal via Setup Wizard](#step-42-activate-store-terminal-via-setup-wizard)
   - [Step 4.3: Hardware Fingerprint (UMAC) Binding Verification](#step-43-hardware-fingerprint-umac-binding-verification)
7. [Phase 5: Smoke Testing & Day-1 Go-Live Checklist](#phase-5-smoke-testing--day-1-go-live-checklist)
   - [Step 5.1: Cashier Sales & UAE FTA 5% Tax Invoice Test](#step-51-cashier-sales--uae-fta-5-tax-invoice-test)
   - [Step 5.2: Offline Mode Verification (Simulated Network Disconnect)](#step-52-offline-mode-verification-simulated-network-disconnect)
   - [Step 5.3: Two-Way Sync Verification (Outbox Push & Pull)](#step-53-two-way-sync-verification-outbox-push--pull)
8. [Phase 6: Maintenance, Disaster Recovery & Troubleshooting](#phase-6-maintenance-disaster-recovery--troubleshooting)
   - [Step 6.1: Automated & Manual Database Backups](#step-61-automated--manual-database-backups)
   - [Step 6.2: Restoring from a Snapshot](#step-62-restoring-from-a-snapshot)
   - [Step 6.3: Log Inspection & Diagnostic Endpoints](#step-63-log-inspection--diagnostic-endpoints)
   - [Step 6.4: Troubleshooting Common Issues](#step-64-troubleshooting-common-issues)

---

## 1. Architecture Overview & Topologies

```
┌────────────────────────────────────────────────────────────────────────┐
│                        CENTRAL CLOUD HUB                               │
│  - Docker Compose: PHP 8.2-FPM (Alpine) + MariaDB 10.11 + Nginx (SSL)  │
│  - Multi-Tenant Licensing, Central Telemetry, Super-Admin Portal       │
│  - Endpoint: https://cloud.magnificentsolution.co.in                   │
└──────────────────────────────────▲─────────────────────────────────────┘
                                   │ HTTPS / TLS 1.3
                         (Sync Push / Pull / License)
                                   │
┌──────────────────────────────────▼─────────────────────────────────────┐
│                      LOCAL STORE POS TERMINAL                          │
│                                                                        │
│  ┌──────────────────────────┐         ┌─────────────────────────────┐  │
│  │      Flutter Desktop     │◄───────►│    Local PHP 8.2 Core API   │  │
│  │    (Windows EXE / MSIX)  │  HTTP   │   (XAMPP / Port 8000)       │  │
│  └─────────────┬────────────┘         └──────────────┬──────────────┘  │
│                │                                     │                 │
│                ▼                                     ▼                 │
│      Hardware Peripherals                  Local MariaDB (Port 3306)   │
│      - Thermal Printer (USB/LAN)           - Offline-First Storage     │
│      - Barcode / QR Scanner                - 5-Min Scheduled Sync      │
│      - UHF RFID Serial Antenna             - 02:00 AM Automated Backup │
│      - Cash Drawer (RJ11 Kick)                                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Prerequisites & System Requirements

### 2.1 Hardware Requirements

| Component | Minimum Specification | Recommended Specification |
|:---|:---|:---|
| **Cloud Server** | 2 vCPU, 4 GB RAM, 40 GB NVMe SSD | 4 vCPU, 8 GB RAM, 80 GB NVMe SSD |
| **Local Store POS Workstation** | Intel Core i3 / Ryzen 3, 8 GB RAM, 128 GB SSD | Intel Core i5 / Ryzen 5, 16 GB RAM, 256 GB SSD |
| **Operating System (Cloud)** | Ubuntu 22.04 LTS or Debian 12 | Ubuntu 22.04 / 24.04 LTS (x64) |
| **Operating System (POS)** | Windows 10 Pro / Enterprise 64-bit | Windows 11 Pro 64-bit (23H2+) |

### 2.2 Software & Tools

- **Cloud:** Docker Engine (`v24.0+`), Docker Compose (`v2.20+`), Git, Nginx, Certbot (Let's Encrypt).
- **Local POS:** XAMPP for Windows (with PHP `8.2.x` and MariaDB `10.4+`), Git for Windows, PowerShell 5.1+.
- **Build Machine (Optional):** Flutter SDK (`3.24+`), Visual Studio 2022 Community with *Desktop development with C++*.

---

## Phase 1: Central Cloud Hub Deployment (Linux / Docker)

### Step 1.1: Server Provisioning & OS Setup

Log into your target cloud server via SSH as `root` or a `sudo` user:

```bash
ssh user@your-cloud-ip
```

Update system packages and install baseline utilities:

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y curl git ufw ca-certificates gnupg lsb-release
```

Install Docker and Docker Compose Plugin:

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Enable the Docker service:

```bash
sudo systemctl enable --now docker
```

Configure the firewall:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

---

### Step 1.2: Clone Repository & Configure Environment

Create the application directory:

```bash
sudo mkdir -p /var/www/laundrypro
sudo chown $USER:$USER /var/www/laundrypro
cd /var/www/laundrypro
```

Clone the repository:

```bash
git clone https://github.com/TheBestDeveloperTeam/UAE-Laundry-Pro.git .
git checkout main
```

Set up the production environment file for the Cloud API:

```bash
cp cloud-api/.env.production.example cloud-api/.env
```

Edit `cloud-api/.env` using `nano`:

```bash
nano cloud-api/.env
```

Ensure the following production values are configured:

```ini
APP_ENV=production
APP_DEBUG=false
APP_URL=https://cloud.yourdomain.ae

# Database connection inside Docker network
DB_HOST=cloud-db
DB_PORT=3306
DB_DATABASE=laundrypro_cloud
DB_USERNAME=laundrypro_user
DB_PASSWORD=YourStrongSecretDbPassword2026!

# Cloud Security & JWT Secrets
JWT_SECRET=MakeSureThisIsA64CharRandomHexSecretForProductionKeySigning12345
LICENSE_HMAC_SECRET=LaundryProCloudSecret2026

# Super-Admin Default
SUPERADMIN_EMAIL=superadmin@yourdomain.ae
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

Update `docker-compose.yml` passwords to match your `.env`:

```bash
nano docker-compose.yml
```

Verify `MYSQL_PASSWORD` and `DB_PASSWORD` align with `YourStrongSecretDbPassword2026!`.

---

### Step 1.3: Launch Cloud Hub Containers

Build and spin up the multi-stage Alpine PHP 8.2 and MariaDB 10.11 containers:

```bash
docker compose up -d --build
```

Verify containers are running:

```bash
docker compose ps
```

*Expected output:*
```
NAME                    IMAGE               COMMAND                  SERVICE      STATUS      PORTS
laundrypro-cloud-api    laundrypro-cloud    "/usr/bin/supervisor…"   cloud-api    running     0.0.0.0:8080->80/tcp
laundrypro-cloud-db     mariadb:10.11       "docker-entrypoint.s…"   cloud-db     running     0.0.0.0:3307->3306/tcp
```

---

### Step 1.4: Apply Cloud Database Migrations & Seed Super-Admin

Run the automated migration runner inside the `cloud-api` container:

```bash
docker compose exec cloud-api php /var/www/html/database/migrate.php
```

*Expected output:*
```
Migration applied: 001_cloud_init.sql
Migration applied: 002_multi_tenant_schemas.sql
Migration applied: 003_cloud_audit_and_licenses.sql
All cloud migrations executed successfully.
```

Seed the default Master Super-Administrator account:

```bash
docker compose exec cloud-db mariadb -u laundrypro_user -pYourStrongSecretDbPassword2026! laundrypro_cloud -e "
INSERT INTO cloud_super_admins (id, username, email, password_hash, full_name, role, is_active)
VALUES (
  1,
  'superadmin',
  'superadmin@yourdomain.ae',
  '\$2y\$10\$eE0oI9uL5O9B7zT7w7Nq6.H.w187QjXo2bWqC6cZyS85Ewh9bK87y',
  'Master Super Administrator',
  'super_admin',
  1
) ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;"
```

> **Default Super-Admin Credentials:**  
> - Username: `superadmin`  
> - Password: `SuperAdmin@LaundryPro2026!` *(Change immediately after first login)*

---

### Step 1.5: Setup Nginx SSL & Domain Reverse Proxy

Install host Nginx and Certbot:

```bash
sudo apt-get install -y nginx certbot python3-certbot-nginx
```

Create an Nginx configuration file for the Cloud Hub domain:

```bash
sudo nano /etc/nginx/sites-available/laundrypro-cloud.conf
```

Paste the reverse proxy configuration:

```nginx
server {
    server_name cloud.yourdomain.ae;

    client_max_body_size 64M;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site and reload Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/laundrypro-cloud.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

Obtain a trusted SSL certificate via Let's Encrypt:

```bash
sudo certbot --nginx -d cloud.yourdomain.ae
```

Follow the prompts to enable automatic HTTPS redirection.

---

### Step 1.6: Verify Cloud Hub Health & Super-Admin Login

1. **Verify Health Endpoint:**
   ```bash
   curl -i https://cloud.yourdomain.ae/api/v1/health
   ```
   *Expected response:*
   ```json
   HTTP/2 200
   {"success":true,"code":"HEALTH_OK","data":{"service":"LaundryPro Cloud API","version":"2.0.0","database":"connected"}}
   ```

2. **Verify Interactive Swagger Documentation:**
   Navigate in your browser to:
   `https://cloud.yourdomain.ae/api/v1/docs`

3. **Verify Super-Admin Web Portal:**
   Navigate in your browser to:
   `https://cloud.yourdomain.ae/admin/login`  
   Log in with `superadmin` / `SuperAdmin@LaundryPro2026!`. You should see the Cloud Tenants, Licenses, and Sync Inspector dashboard.

---

## Phase 2: Local Store Server & Workstation Deployment (Windows POS)

### Step 2.1: Local Store Prerequisites (XAMPP / MariaDB / PHP 8.2)

1. Download and install **XAMPP for Windows** with PHP `8.2.x` to the default directory `C:\xampp`.
2. Open the **XAMPP Control Panel** as Administrator:
   - Start the **Apache** service.
   - Start the **MySQL** (MariaDB) service.
3. Open `C:\xampp\php\php.ini` in Notepad and verify the following extensions are enabled (remove leading `;`):
   ```ini
   extension=pdo_mysql
   extension=mbstring
   extension=bcmath
   extension=curl
   extension=fileinfo
   extension=openssl
   ```
4. Restart Apache in the XAMPP Control Panel.

---

### Step 2.2: Directory Structure & File Permissions

Open PowerShell as Administrator on the POS workstation and run:

```powershell
# Create runtime root storage folders
$RuntimeDirs = @(
  "E:\LaundryPro",
  "E:\LaundryPro\invoices",
  "E:\LaundryPro\images",
  "E:\LaundryPro\backups",
  "E:\LaundryPro\logs",
  "E:\LaundryPro\exports"
)

foreach ($dir in $RuntimeDirs) {
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
}
Write-Host "Runtime directories successfully initialized under E:\LaundryPro" -ForegroundColor Green
```

---

### Step 2.3: Local API Environment Configuration

Clone or copy the project code to `E:\Projects\Flutter\UAE-Laundry-Pro`:

```powershell
Set-Location "E:\Projects\Flutter"
git clone https://github.com/TheBestDeveloperTeam/UAE-Laundry-Pro.git
Set-Location "E:\Projects\Flutter\UAE-Laundry-Pro"
git checkout main
```

Create `api/.env`:

```powershell
Copy-Item "api\.env.example" "api\.env"
```

Edit `api\.env`:

```ini
APP_ENV=production
APP_DEBUG=false
APP_KEY=LocalStationSecretKey2026!
PORT=8000

DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=laundrypro_local
DB_USER=root
DB_PASS=

CLOUD_API_URL=https://cloud.yourdomain.ae/api/v1
SYNC_INTERVAL_SECONDS=300

# Hardware Serial Ports
RFID_SERIAL_PORT=COM3
RFID_BAUD_RATE=9600
```

---

### Step 2.4: Run Database Migrations & Initial UAE Seeds

Execute the automated one-click setup script in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\laundrypro-setup.ps1
```

This script will:
- Create the `laundrypro_local` MariaDB database.
- Apply all DDL migrations in order.
- Seed default roles (*Administrator, Cashier, Manager, Storekeeper, HR, Auditor*).
- Seed the UAE 5% VAT rate, UAE currency units (`AED` / `Fils`), and TRN settings.
- Seed the comprehensive UAE Product & Service catalog (*Kandora, Abaya, 2-Piece Suit, Steam Pressing, Carpet Cleaning*).

Verify local API starts and passes integration tests:

```powershell
powershell -Command "C:\xampp\php\php.exe api/tests/run_api_tests.php"
```
*Expected result:* `Passed: 190, Failed: 0, Skipped: 7`.

---

### Step 2.5: Build & Install Flutter Desktop Application

To generate the production Windows executable, run the build script:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_prod.ps1
```

The output will be placed in `build\prod_release\LaundryProApp\`.

1. Copy the entire `LaundryProApp` folder to `C:\Program Files\LaundryProUAE\`.
2. Right-click `LaundryProApp.exe` -> **Create shortcut**.
3. Move the shortcut to the Windows Desktop and rename it to **LaundryPro UAE POS**.
4. Set shortcut properties -> **Advanced** -> check **Run as administrator** (required for Windows Registry license binding).

---

### Step 2.6: Configure Windows Scheduled Tasks (Sync & Daily Backups)

Run the Task Scheduler setup script in an elevated Administrator PowerShell prompt:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-task-scheduler.ps1 -PhpExe "C:\xampp\php\php.exe"
```

This registers two tasks in Windows Task Scheduler:
1. **`LaundryPro_SyncOutbox`:** Executes `api/scripts/sync_scheduler.php` every 5 minutes to push local POS transactions to the Cloud Hub and pull remote updates.
2. **`LaundryPro_DailyBackup`:** Executes a database backup daily at 02:00 AM, writing compressed `.sql.gz` snapshots to `E:\LaundryPro\backups\`.

---

## Phase 3: Hardware Peripheral Setup

### Step 3.1: ESC/POS Thermal Receipt Printer (USB & LAN)

#### For USB Printers (Epson TM-T20 / Bixolon / Xprinter):
1. Connect printer via USB and turn power ON.
2. Install the manufacturer's virtual COM/USB driver or standard receipt driver.
3. In the Windows Control Panel -> **Printers & Scanners**, rename the printer to `POS-80`.
4. Ensure the paper roll is standard **80mm thermal paper**.

#### For LAN / Ethernet Printers:
1. Assign a static IP address to the printer (e.g., `192.168.1.200`).
2. In the LaundryPro Flutter App:
   - Navigate to **Settings** -> **Peripherals** -> **Printers**.
   - Select **Network Printer Discovery** or enter `192.168.1.200` on port `9100`.
   - Click **Print Test Receipt**. The printer will feed and print a bilingual UAE FTA test receipt with TLV QR code.

---

### Step 3.2: Cash Drawer Kick-Pulse

1. Plug the standard **RJ11/RJ12 cable** from the cash drawer into the back of the thermal receipt printer (DK port).
2. The LaundryPro software automatically issues the ESC/POS kick pulse (`ESC p 0 25 250`) upon payment confirmation or cashier manual pop (`F5`).
3. Test drawer pop under **Pending Invoices** -> click **Open Drawer**.

---

### Step 3.3: 1D/2D Barcode & QR Scanner (HID Keyboard / Serial COM)

1. Connect the USB Barcode Scanner (Honeywell / Datalogic / Zebra).
2. Scan the barcode manual code: **Set to USB HID Keyboard Mode** (or **Virtual COM Mode** if using serial mode).
3. Ensure suffix is set to **[CR] (Enter)**.
4. Scan any garment tag in the POS cart. The item will automatically appear in the active sales basket.

---

### Step 3.4: UHF RFID Reader Antenna (Serial COM3)

1. Connect the USB-to-RS232 Serial adapter from the RFID antenna to the POS terminal.
2. Open **Windows Device Manager** -> **Ports (COM & LPT)** -> Note assigned COM port (default: `COM3`).
3. Verify `api/.env` has:
   ```ini
   RFID_SERIAL_PORT=COM3
   RFID_BAUD_RATE=9600
   ```
4. Place a batch of UHF RFID-tagged garments on the counter antenna.
5. In the app, navigate to **RFID Scan** -> click **Read Antenna**. The tags will be captured in bulk.

---

## Phase 4: License Activation & 3-Way Cloud Handshake

### Step 4.1: Issue Tenant License from Cloud Super-Admin

1. Open a browser and navigate to `https://cloud.yourdomain.ae/admin/login`.
2. Log in with your Super-Admin credentials.
3. Click **Tenants** -> **Register New Tenant**:
   - Business Name: *Al Majed Premium Laundry LLC*
   - City: *Dubai*
   - TRN: *100000000000003*
4. Click **Licenses** -> **Issue New License**:
   - Tenant: *Al Majed Premium Laundry LLC*
   - Plan Type: *Enterprise*
   - Validity: *1 Year*
5. Copy the generated license key:
   Example: `LP-DUBAI-2026-X89K-M210`

---

### Step 4.2: Activate Store Terminal via Setup Wizard

1. Launch the **LaundryPro UAE** desktop application.
2. If unactivated, the **Setup & Activation Wizard** will appear.
3. The wizard automatically calculates the hardware fingerprint:
   Example: `UMAC-9F1B-4A2C-7E81`
4. Enter the issued License Key: `LP-DUBAI-2026-X89K-M210`.
5. Click **Activate Station Online**.

---

### Step 4.3: Hardware Fingerprint (UMAC) Binding Verification

1. The Local API contacts `https://cloud.yourdomain.ae/api/v1/license/verify` sending the key, UMAC, and hostname.
2. The Cloud API cryptographically validates the plan, signs the token with HMAC-SHA256, and returns `LICENSE_VALID`.
3. The Local POS writes the write-once activation lock to the Windows Registry at:
   `HKLM\Software\LaundryProUAE\LicenseKey`
4. The application transitions immediately to the **Cashier POS Screen**.

---

## Phase 5: Smoke Testing & Day-1 Go-Live Checklist

Complete this checklist before opening the store to customers:

### Step 5.1: Cashier Sales & UAE FTA 5% Tax Invoice Test

- [ ] Select customer or leave as "Walk-In".
- [ ] Add **Kandora (Dry Clean)** (`AED 18.00`) and **Steam Pressing** (`AED 7.00`). Total = `AED 25.00`.
- [ ] Verify tax breakdown:
  - Subtotal (Excl. Tax): `AED 23.81`
  - UAE FTA VAT (5%): `AED 1.19`
  - Grand Total: `AED 25.00`
- [ ] Select payment method **Cash** -> enter `AED 25.00` -> click **Confirm Sale**.
- [ ] Verify cash drawer opens and 80mm thermal receipt prints with bilingual text and scanning TLV QR code.

---

### Step 5.2: Offline Mode Verification (Simulated Network Disconnect)

- [ ] Disconnect the Ethernet cable / turn off Wi-Fi on the POS terminal.
- [ ] Observe top status bar: Status changes to yellow/grey **Offline Mode**.
- [ ] Ring up a new sale for `AED 35.00` -> Confirm sale.
- [ ] Verify sale completes locally with zero latency; receipt prints normally.
- [ ] Query local outbox in MariaDB:
  ```sql
  SELECT id, entity_type, operation, status FROM sync_outbox WHERE status = 'pending';
  ```
  *Result should show the order queued with `status = 'pending'`.*

---

### Step 5.3: Two-Way Sync Verification (Outbox Push & Pull)

- [ ] Reconnect the network cable / Wi-Fi.
- [ ] Run the scheduler manually or wait up to 5 minutes:
  ```powershell
  C:\xampp\php\php.exe E:\Projects\Flutter\UAE-Laundry-Pro\api\scripts\sync_scheduler.php
  ```
- [ ] Verify outbox record changes to `status = 'synced'`.
- [ ] Open the Cloud Admin Portal -> **Sync Inspector**:
  Confirm the offline order appears in central reporting with matching totals and timestamp.

---

## Phase 6: Maintenance, Disaster Recovery & Troubleshooting

### Step 6.1: Automated & Manual Database Backups

#### Manual Snapshot Trigger via PowerShell:
```powershell
C:\xampp\php\php.exe -r "require_once 'E:/Projects/Flutter/UAE-Laundry-Pro/api/src/Services/BackupService.php';"
```

Snapshots are stored in `E:\LaundryPro\backups\` using standard gzip compression:
`backup_laundrypro_YYYY-MM-DD_HHMMSS.sql.gz`

---

### Step 6.2: Restoring from a Snapshot

In the event of hardware failure or database corruption:

1. Locate the latest verified backup file in `E:\LaundryPro\backups\`.
2. Extract the `.sql` archive using 7-Zip or PowerShell:
   ```powershell
   Expand-Archive -Path backup_latest.zip -DestinationPath E:\LaundryPro\backups\restore\
   ```
3. Open a command prompt and restore into MariaDB:
   ```cmd
   mysql -u root -p laundrypro_local < E:\LaundryPro\backups\restore\backup_file.sql
   ```
4. Restart the Local API and launch the POS application.

---

### Step 6.3: Log Inspection & Diagnostic Endpoints

| Log Description | Location |
|:---|:---|
| **Local API Daily Logs** | `E:\Projects\Flutter\UAE-Laundry-Pro\api\storage\logs\app-YYYY-MM-DD.log` |
| **Cloud API Daily Logs** | `/var/www/laundrypro/cloud-api/logs/cloud-app-YYYY-MM-DD.log` |
| **Flutter Crash Diagnostics** | `E:\LaundryPro\logs\crash.log` |
| **MariaDB Error Log** | `C:\xampp\mysql\data\mysqld.err` |
| **Nginx Access / Error Logs** | `/var/log/nginx/access.log` and `/var/log/nginx/error.log` |

Diagnostic Health Check Endpoints:
- Local POS: `http://localhost:8000/api/v1/health`
- Cloud Hub: `https://cloud.yourdomain.ae/api/v1/health`

---

### Step 6.4: Troubleshooting Common Issues

| Symptom | Probable Cause | Corrective Action |
|:---|:---|:---|
| **POS shows "Backend Offline (503)"** | Apache/PHP service stopped in XAMPP | Open XAMPP Control Panel, verify Apache is running on port 8000/80. Check `api/storage/logs/` for fatal errors. |
| **License Invalid or Hardware Mismatch** | Machine motherboard or MAC address changed | Open Cloud Super-Admin, locate license, click **Rebind UMAC**, and enter the new machine UMAC from the POS setup screen. |
| **Thermal Printer Does Not Cut Paper** | Print driver paper size mismatch | Open Windows printer preferences, set paper size to **80mm x Receipt** and cutter to **Full Cut at End of Page**. |
| **Sync Outbox Stuck in Pending** | Firewall blocking outbound port 443 | Verify POS can reach `https://cloud.yourdomain.ae/api/v1/health` using `curl` or browser. Check credentials in `api/.env`. |
| **RFID Reader Not Detecting Garments** | Serial COM port conflicts or baud mismatch | Open Device Manager, confirm COM port number matches `api/.env` (`RFID_SERIAL_PORT=COM3`, `9600` baud). |

---

## 7. Sign-Off & Handover Confirmation

This deployment guide certifies that **LaundryPro UAE Version 2.0.0** is ready for repeatable, dependable production deployment across single-terminal, multi-workstation, and multi-branch laundry facilities in the UAE and wider GCC region.
