# Sprint 4 Implementation Plan: Sterilization & Compliance

## Goal Description
Implement the Sterilization and Compliance features for the Advanced Garment Care module, specifically focusing on API endpoints, data persistence, auto-quarantining for failed biological indicators, and e-signatures, culminating with a UI integration in Flutter.

## Proposed Changes

### Backend Controllers & Repositories
#### [NEW] `api/src/Controllers/SterilizationController.php`
- `batchCreate()`: Create a new batch lot linked to a sales order.
- `batchScan()`: Record an IN or OUT scan for a batch lot.
- `logSterilization()`: Record autoclave metrics (pressure, temperature, duration, validation result). If validation result is 'rejected', trigger auto-quarantine.
- `signElectronic()`: Append an electronic signature for compliance against a cycle.

#### [NEW] `api/src/Repositories/SterilizationRepository.php`
- Handle queries for inserting batch_lots, batch_scan_events.
- Insert sterilization_logs.
- If a sterilization log is 'rejected', update the associated `advanced_cycle_runs` status to 'exception' (auto-quarantine).
- Handle inserting electronic_signatures using SHA-256 for integrity.

### API Routing
#### [MODIFY] `api/src/routes.php` or `api/public/index.php` (wherever routes are managed)
- Add the necessary endpoints grouped under `/api/v1/sterilization`

### Flutter UI
#### [NEW] `lib/services/sterilization_service.dart`
- Dart bindings for the new API endpoints.

#### [NEW] `lib/views/sterilization_screen.dart`
- UI to create batches, record sterilization metrics, and attach electronic signatures.

#### [MODIFY] `lib/views/app_shell.dart`
- Add routing/navigation for the new Sterilization Screen.

## Verification Plan
### Automated Tests
- Create `api/tests/cases/35_sterilization.json` to test:
  1. Batch creation & scanning.
  2. Sterilization logging (approved).
  3. Electronic signature.
  4. Sterilization logging (rejected) -> verifies the cycle run is moved to 'exception'.

### Manual Verification
- View the UI, trigger a failed validation, and ensure the UI shows exception.

