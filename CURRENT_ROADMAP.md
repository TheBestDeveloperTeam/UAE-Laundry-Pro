# Laundry Pro Desktop — Current Roadmap

## Phase: Advanced Garment Care Module Integration

### [COMPLETED] Sprint 1: Baseline Architecture & Database Migrations
- `002_advanced_module.sql` schema merged
- Core relationships maintained
- Cloud Agent ID added to auth tables

### [COMPLETED] Sprint 2: Core Permissions & Authorization
- RBAC rules merged (`advanced.cycle.run`, `advanced.equipment.manage`, etc.)
- JWT scopes updated
- `PermissionMiddleware` verified for new routes
- Test suite regressions fixed (166 tests passing)

### [COMPLETED] Sprint 3: Advanced Core APIs
- Implementation of `AdvancedCycleController.php`
- Implementation of `AdvancedCycleRepository.php`
- Integration of Process Logs (pH, Temperature)
- UI: `advanced_cycle_screen.dart`

### [COMPLETED] Sprint 4: Sterilization & Compliance
- `SterilizationController` and UI
- Batch tracking and e-signatures
- Auto-quarantine logic for failed biological indicators

### [COMPLETED] Sprint 5: Equipment Calibration Management
- `EquipmentController` for calibration logs
- Blocking logic for out-of-calibration machines
- Reminders and dashboard alerts

### [COMPLETED] Sprint 6: Operator Certification
- `OperatorController` for tracking training and certifications
- Expiration logic to block uncertified operators from starting cycles
- HR module integration

### [COMPLETED] Sprint 7: RFID & Batch Tracking
- Integration with external UHF RFID middleware via `HardwareAdapterInterface`
- Real-time garment tracking UI
- Bulk scanning and automated status transitions

### [COMPLETED] Sprint 8-16: Admin Consoles, Licensing, & Cloud Sync
- Local XAMPP Admin Console
- Cloud Super-Admin Console (cPanel / AdminLTE)
- Registry-backed Licensing system
- Universal background sync outbox coverage
- Multi-platform packaging (MSIX, APK, AppImage)

