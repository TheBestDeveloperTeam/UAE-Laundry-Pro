# LaundryPro UAE — Production Deployment & DevOps Guide

> **Version:** 2.0.0 | **Authoritative Operations Manual**

---

## 1. Local Workstation & Branch Server Deployment

### 1.1 Apache VirtualHost Configuration
For the local Apache server (e.g., XAMPP or native Apache on Windows/Linux), configure the VirtualHost in `httpd-vhosts.conf`:

```apache
<VirtualHost *:80>
    ServerName laundrypro-api
    DocumentRoot "E:/Projects/Flutter/UAE-Laundry-Pro/api/public"
    <Directory "E:/Projects/Flutter/UAE-Laundry-Pro/api/public">
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog "E:/Projects/Flutter/UAE-Laundry-Pro/api/logs/error.log"
    CustomLog "E:/Projects/Flutter/UAE-Laundry-Pro/api/logs/access.log" common
</VirtualHost>
```

Add the hosts entry in `C:\Windows\System32\drivers\etc\hosts`:
```text
127.0.0.1    laundrypro-api
```

### 1.2 Windows Background Sync Daemon
To ensure non-blocking continuous synchronization between the local store and the central cloud, register `sync_scheduler.php` as a Windows Scheduled Task or background service:

```powershell
# PowerShell script to register background sync worker
$Action = New-ScheduledTaskAction -Execute "E:\xampp\php\php.exe" -Argument "E:\Projects\Flutter\UAE-Laundry-Pro\api\sync_scheduler.php"
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 365)
Register-ScheduledTask -TaskName "LaundryProSyncWorker" -Action $Action -Trigger $Trigger -Settings $Settings -User "SYSTEM"
```

---

## 2. Cloud Central API Gateway Deployment

### 2.1 Production VirtualHost (SSL / HTTPS)
```apache
<VirtualHost *:443>
    ServerName api.cloud.laundrypro.ae
    DocumentRoot "/var/www/laundrypro/cloud-api/public"
    
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/api.cloud.laundrypro.ae/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/api.cloud.laundrypro.ae/privkey.pem

    <Directory "/var/www/laundrypro/cloud-api/public">
        AllowOverride All
        Require all granted
    </Directory>

    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"

    ErrorLog /var/log/apache2/cloud_api_error.log
    CustomLog /var/log/apache2/cloud_api_access.log combined
</VirtualHost>
```

### 2.2 Docker Deployment
A containerized deployment is available via `Dockerfile`:

```dockerfile
FROM php:8.2-apache
RUN apt-get update && apt-get install -y \
    libmariadb-dev-compat \
    libmariadb-dev \
    libzip-dev \
    zip \
    && docker-php-ext-install pdo pdo_mysql bcmath opcache
RUN a2enmod rewrite headers ssl
COPY cloud-api/ /var/www/html/
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/logs
EXPOSE 80 443
CMD ["apache2-foreground"]
```

### 2.3 Cloud Maintenance Cron Jobs
Configure system crontab on the Cloud Linux host:
```bash
# Clean up expired CSRF tokens and inactive sessions every hour
0 * * * * php /var/www/laundrypro/cloud-api/scripts/clean_sessions.php >> /var/log/laundrypro_cron.log 2>&1

# Generate daily sync health snapshots every 15 minutes
*/15 * * * * php /var/www/laundrypro/cloud-api/scripts/sync_health_collector.php >> /var/log/laundrypro_cron.log 2>&1
```
