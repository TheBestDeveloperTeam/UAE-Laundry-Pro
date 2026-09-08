# ADR 0002: Local VirtualHost Node Isolation & Anti-Tamper Security

## Status
Accepted

## Context
The application runs as a local client workstation deployment on Windows machines with an embedded XAMPP environment. Without strict local network constraints, an external device on the client''s LAN could potentially issue unauthorized REST calls directly to the local PHP API, bypassing the Flutter UI. Furthermore, port-based URLs (http://localhost:8080) are fragile and conflict with client software.

## Decision
1. Map 127.0.0.1 laundrypro-localapi in C:\Windows\System32\drivers\etc\hosts.
2. Configure Apache VirtualHost in httpd-vhosts.conf for ServerName laundrypro-localapi pointing directly to the pi/public document root.
3. Enforce Apache security directive:
   `pache
   <Directory  .../api/public>
       AllowOverride All
       Require local
   </Directory>
   `
4. Set Flutter''s default compile-time API endpoint to http://laundrypro-localapi/api/v1.
5. Provide an automated PowerShell script scripts/setup-client-node.ps1 to configure these operating system settings in one step.

## Consequences
- **Positive:** Outside network attackers on the same WiFi/Ethernet cannot access or manipulate the local database or API.
- **Positive:** Professional domain-style hostname without exposed port numbers.
- **Positive:** Zero latency loopback calls.
- **Requirement:** Initial node setup requires Administrator privileges to edit hosts and restart Apache.
