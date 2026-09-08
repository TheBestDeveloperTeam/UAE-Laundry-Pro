# ADR 0004: Hardware UMAC Binding & Registry Pulse Anti-Tamper Guard

## Status
Accepted

## Context
Because the client application is an offline-first Windows desktop installation running locally, software piracy (copying the application directory or database to other computers) or date-tampering (turning back system time to extend trial licenses) poses a business risk.

## Decision
1. **Unique Machine Access Code (UMAC):** Form a hardware fingerprint by querying hardware properties through WMI (Win32_Processor.ProcessorId, Win32_BaseBoard.SerialNumber, and HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid).
2. **Cryptographic License Stamp:** License verification checks whether the signed .lic file contains a signature matching the machine''s UMAC and valid expiry window.
3. **Registry Heartbeat:** Maintain an encrypted monotonically increasing timestamp (InstallPulse) in HKCU\Software\LaundryProUAE\Evaluation. If current system clock is older than InstallPulse, system halts with clock tamper status.
4. **Hard Quota Guard:** In evaluation mode, enforce maximum 7 days lifespan, maximum 9 invoices, and maximum 9 customers.

## Consequences
- **Positive:** Unlicensed copying of application files to another machine immediately fails license validation.
- **Positive:** Clock manipulation fails gracefully and safely.
- **Positive:** Works 100% offline without needing an active internet connection.
- **Trade-off:** Replacing motherboard or CPU requires issuing a license update from the Super-Admin Portal.
