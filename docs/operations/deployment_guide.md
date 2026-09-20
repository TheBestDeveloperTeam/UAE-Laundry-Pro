# Deployment Guide - LaundryPro UAE
> **Version:** 1.0.0

## Prerequisites
- Windows 10/11 (64-bit)
- 4 GB RAM minimum (8 GB recommended)
- 10 GB free disk space
- XAMPP installed with Apache, MariaDB, PHP 8.2

## Installation Steps
1. Install XAMPP and verify services start.
2. Run database baseline migration (001_baseline.sql).
3. Install MSIX package (double-click or sideload).
4. Launch LaundryPro UAE.
5. Complete first-time setup wizard.
6. Configure hardware (auto-discovery).
7. Verify with test transaction.

## Update Procedure
1. Backup database (backup.protocol).
2. Install new MSIX package (auto-updates or manual).
3. Run pending migrations (if any).
4. Verify functionality.
5. Rollback if critical issues found.