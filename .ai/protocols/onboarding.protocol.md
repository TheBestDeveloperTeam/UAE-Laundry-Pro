# Protocol: New Tenant Onboarding

## Steps
1. License key generated and bound to machine hash (UMAC).
2. MSIX package installed on tenant machine.
3. First-launch wizard:
   a. License activation (online verify or offline grace).
   b. Business profile setup (name, TRN, address, contact).
   c. Admin user creation (owner role).
   d. Branch configuration.
   e. Printer/scanner auto-discovery.
   f. Service catalog import (default or custom).
   g. Employee setup.
4. Initial data sync (if cloud-connected).
5. Training session scheduled.
6. Go-live confirmation.

## Validation Checklist
- [ ] License activated and verified
- [ ] Business profile complete with TRN
- [ ] Admin user can login
- [ ] At least one printer configured
- [ ] Service catalog populated
- [ ] Test order created successfully
- [ ] Test invoice printed successfully