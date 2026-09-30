# LaundryPro UAE — Backup & Disaster Recovery Runbook

> **Version:** 2.0.0 | **Authoritative Operations Manual** | **Strategy:** 3-2-1 Enterprise Backup

---

## 1. The 3-2-1 Backup Strategy

LaundryPro UAE implements a resilient 3-2-1 disaster recovery architecture:
1. **3 Copies of Data**:
   - Production MariaDB/SQLite database on local workstation/branch server.
   - Nightly local automated snapshot saved to dedicated local storage partition.
   - Offsite encrypted snapshot streamed to central Cloud API storage.
2. **2 Different Storage Media**:
   - Local NVMe/SSD high-speed disk.
   - S3-compatible cloud object storage or secure external network storage.
3. **1 Offsite Replica**:
   - Central Cloud API storage repository located in an alternate geographic availability zone.

---

## 2. Automated Local MariaDB Backup Procedure

The local backup is driven by `BackupController.php` or CLI script:

```bash
# Automated local backup execution script
BACKUP_DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="E:/Projects/Flutter/UAE-Laundry-Pro/api/storage/backups/db_${BACKUP_DATE}.sql.gz"

# Perform compressed mysqldump with single transaction consistency
mysqldump -u laundry_user -p'SecurePassword' \
    --single-transaction \
    --quick \
    --routines \
    --triggers \
    laundrypro_local | gzip > "$BACKUP_FILE"

# Rotate backups: Retain last 30 daily snapshots locally
find "E:/Projects/Flutter/UAE-Laundry-Pro/api/storage/backups" -name "db_*.sql.gz" -mtime +30 -exec rm {} \;
```

---

## 3. Offsite Transmission to Cloud Storage

Once the local compressed snapshot is created, `BackupController::upload()` encrypts the file with AES-256-CBC and streams it to the Cloud API:

```http
POST /api/v1/sync/backup
Host: api.cloud.laundrypro.ae
Authorization: Bearer <tenant_cloud_token>
Content-Type: application/json

{
  "filename": "db_branch01_20260930_0200.sql.gz.enc",
  "checksum": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "backup_data": "<base64_encrypted_payload>"
}
```

---

## 4. Disaster Recovery Restoration Runbook

### Scenario: Total Hardware Failure of Local Workstation

```mermaid
sequenceDiagram
    participant Eng as Field Support Engineer
    participant NewPC as Replacement Workstation
    participant Cloud as Cloud API Gateway

    Eng->>NewPC: Install Windows 11 & LaundryPro Setup MSIX
    Eng->>NewPC: Launch App; Enter Enterprise License Key & Cloud Token
    NewPC->>Cloud: POST /license/validate (Registers New Hardware UMAC)
    NewPC->>Cloud: GET /sync/backup/latest (Fetches Latest Encrypted DB Dump)
    Cloud-->>NewPC: Returns Latest Backup Archive
    NewPC->>NewPC: Decrypt & Restore MariaDB / SQLite Tables
    NewPC->>Cloud: GET /sync/pull?since=backup_timestamp
    Cloud-->>NewPC: Replays all delta mutations since last backup
    NewPC->>NewPC: System 100% Restored to exact point in time
```

1. Deploy new replacement workstation hardware.
2. Install standard software package and initialize `laundrypro_local` database.
3. Fetch the latest tenant snapshot from Cloud Admin portal or via CLI:
   ```powershell
   & "E:\xampp\php\php.exe" "api/scripts/restore_from_cloud.php" --token="tenant_token"
   ```
4. The system restores database tables and immediately triggers a delta sync pull for all mutations recorded between the snapshot timestamp and the present minute.
5. Downtime objective: **< 15 minutes Recovery Time Objective (RTO)** with **Zero Transaction Loss (RPO = 0)**.
