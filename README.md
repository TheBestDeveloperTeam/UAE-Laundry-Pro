# LaundryPro UAE

A fully integrated Point-of-Sale (POS) and Enterprise Resource Planning (ERP) application engineered specifically for the commercial laundry sector in the UAE.

## Architecture
- **Frontend:** Flutter (Windows Desktop App)
- **Backend:** Custom PHP 8.2 Micro-Framework
- **Database:** MariaDB (via XAMPP)
- **Offline-First:** Stores all data locally and synchronizes with a central cloud via an Outbox pattern.

## Prerequisites
- Flutter SDK (3.x+)
- PHP 8.2+
- MariaDB / MySQL
- Composer (for PHP dependencies)

## Installation & Setup

1. **Clone the repository:**
   `git clone https://github.com/TheBestDeveloperTeam/UAE-Laundry-Pro.git`
2. **Setup Backend:**
   - Navigate to `/api` and run `composer install`.
   - Setup a MySQL database and run the migrations found in `/api/migrations/`.
   - Copy `.env.example` to `.env` and configure your database credentials.
3. **Setup Frontend:**
   - Run `flutter pub get` from the root directory.
   - Run `flutter run -d windows` to launch the POS application.

## Packaging for Release
Run `.\build_windows.ps1` to compile the Flutter Windows executable and package it alongside the PHP API for deployment on terminal machines.

## License
Proprietary - Internal Use Only.
