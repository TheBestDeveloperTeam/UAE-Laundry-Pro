# LaundryPro UAE — System Dependency & Compatibility Matrix

> **Version:** 2.0.0 | **Authoritative Engineering Reference**

---

## 1. Local Workstation Backend Environment (`api/`)

| Component | Minimum Version | Recommended | Mandatory Extensions / Packages | Notes |
|---|---|---|---|---|
| **PHP Runtime** | 8.2.0 | 8.2.12+ | `pdo_mysql`, `bcmath`, `mbstring`, `curl`, `openssl`, `gd`, `fileinfo` | Pure PHP implementation; zero framework overhead |
| **Web Server** | Apache 2.4.50+ | Apache 2.4.58 (XAMPP 8.2) | `mod_rewrite`, `mod_headers`, `mod_ssl` | Configured with `AllowOverride All` |
| **Database** | MariaDB 10.6.0+ | MariaDB 10.11 LTS | InnoDB Engine, `utf8mb4_unicode_ci` collation | WAL journaling recommended |
| **Operating System** | Windows 10 Pro (64-bit) | Windows 11 Pro 23H2 | PowerShell 5.1+ / 7.x, Windows Service Manager | Windows Home is NOT recommended |

---

## 2. Central Cloud Gateway Environment (`cloud-api/`)

| Component | Minimum Version | Production Specification | Security & Configuration Requirements |
|---|---|---|---|
| **Container / Host OS**| Ubuntu 22.04 LTS | Debian 12 / Ubuntu 24.04 LTS | Hardened Linux kernel; UFW firewall active |
| **PHP Runtime** | 8.2.0+ | PHP 8.2 FPM / Apache prefork | `opcache` enabled; memory limit $\ge 256\text{MB}$ |
| **Cloud MariaDB** | 10.6.0+ | MariaDB 10.11 Galera Cluster | SSL client certificate verification; read replicas |
| **SSL / TLS Certificate**| TLS 1.2 | TLS 1.3 Strict | Let's Encrypt / DigiCert wildcard; HSTS enabled |

---

## 3. Flutter POS Desktop Client (`lib/`)

| Package / SDK | Minimum Version | Purpose |
|---|---|---|
| **Flutter SDK** | 3.22.0 | Desktop Windows, macOS, Android cross-platform engine |
| **Dart SDK** | 3.4.0 | Language runtime with sound null safety |
| **`flutter_riverpod`** | 2.5.1 | Reactive state management & dependency injection |
| **`dio`** | 5.4.3 | HTTP networking client with custom interceptors & token rotation |
| **`sqflite_common_ffi`**| 2.3.3 | SQLite FFI native database engine for Windows desktop |
| **`go_router`** | 14.1.4 | Declarative application routing and screen navigation |
| **`esc_pos_utils_plus`**| 2.0.3 | ESC/POS binary command generator for 80mm thermal receipt printers |
| **`pdf` & `printing`** | 3.10.8 | PDF document rasterization for A4 invoices and reports |
| **`crypto`** | 3.0.3 | SHA-256 and HMAC cryptographic hash utilities |
