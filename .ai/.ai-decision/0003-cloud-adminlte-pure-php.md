# ADR 0003: Pure PHP Architecture for Cloud API & AdminLTE Super-Admin Portal

## Status
Accepted

## Context
A central cloud service is required to manage client licenses, multi-tenant synchronization, hardware telemetry, and remote tenant management. The client environment targets shared cPanel hosting or a standard Linux/Apache VPS where heavy PHP frameworks (Laravel, Symfony) require Composer runtime dependencies, command-line workers, and specific PHP extension setups that frequently fail or require complex devops.

## Decision
1. Build the central Cloud API in cloud-api/ using pure PHP 8.2 + MariaDB/MySQL PDO with strict types (declare(strict_types=1);).
2. Implement a standard /public document root structure with Apache .htaccess URL rewriting for universal cPanel compatibility.
3. Harvest necessary UI assets (dminlte.min.css, dminlte.min.js, logo, avatar) from AdminLTE v4 and place them cleanly in cloud-api/public/assets/.
4. Delete the heavy source directory AdminLTE-master/ from the repository root immediately after harvest to preserve repo speed and hygiene.
5. Implement server-rendered PHP templates (src/Views/) utilizing AdminLTE v4 Bootstrap 5 components.

## Consequences
- **Positive:** Zero composer/npm dependencies in production. Uploading cloud-api/ to any cPanel host instantly works.
- **Positive:** Minimal memory footprint (< 4MB per request) and sub-millisecond execution times.
- **Positive:** Full source code control and clean maintainability.
- **Trade-off:** Custom router and view rendering engine instead of framework-provided Blade/Twig.
