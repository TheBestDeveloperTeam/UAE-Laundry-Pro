# Local Windows branch server

## Apache (XAMPP)

`httpd-vhosts.conf`:

```apache
<VirtualHost *:80>
    ServerName laundrypro-api
    DocumentRoot "E:/Projects/Flutter/UAE-Laundry-Pro/api/public"
    <Directory "E:/Projects/Flutter/UAE-Laundry-Pro/api/public">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

`C:\Windows\System32\drivers\etc\hosts`:

```text
127.0.0.1    laundrypro-api
```

Or junction: `mklink /J E:\xampp\htdocs\laundrypro-api E:\Projects\Flutter\UAE-Laundry-Pro\api`

## Database

1. Create database `laundrypro` in phpMyAdmin.
2. `.\scripts\migrate.ps1` or `php api/database/migrate.php`

## Environment

Copy `api/.env.production.template` → `api/.env` and set secrets + `CLOUD_API_URL`.

## Scheduled tasks (Administrator PowerShell)

```powershell
.\scripts\setup-task-scheduler.ps1 -RepoRoot "E:\Projects\Flutter\UAE-Laundry-Pro"
```

## Flutter API URL

Build desktop with:

```powershell
.\scripts\build_prod.ps1 -ApiBaseUrl "https://laundrypro-api/api/v1" -CloudApiBaseUrl "https://CLOUD_DOMAIN/api/v1" -BuildMsix
```
