# System Architecture & Technical Topology
**Architecture Pattern:** Clean Architecture + Layered Offline-First Edge Repository Pattern

---

## 1. High-Level Architecture Topology

```mermaid
graph TD
    subgraph Windows POS Terminal [Edge Hardware Tier]
        UI[Flutter Royal Futuristic UI - 33 Views]
        State[Riverpod & Provider Controllers]
        Repo[Offline-First Repositories]
        DB[(Local SQLite Schema V4)]
        Hardware[Thermal Printer CP1256 / Scanner / Scale]
    end

    subgraph Synchronization Engine
        Outbox[sync_outbox Queue]
        SyncEngine[SyncEngine Push / Pull]
    end

    subgraph Central Cloud Backend
        API[PHP 8.2 Micro-Framework REST API]
        CloudDB[(MariaDB Enterprise)]
        CloudOutbox[Cloud Change Feed]
    end

    UI --> State
    State --> Repo
    Repo --> DB
    State --> Hardware
    DB --> Outbox
    Outbox --> SyncEngine
    SyncEngine <-->|HTTPS REST| API
    API <--> CloudDB
```

---

## 2. Layer Separation & Responsibilities

1. **Presentation Layer (`lib/views`, `lib/widgets`):**
   - 9-layer composited UI architecture.
   - Decoupled from direct database/network logic; consumes state through Providers.
   - Pure vector and Lottie asset rendering.
2. **State & Domain Layer (`lib/providers`, `lib/models`):**
   - Encapsulates UI state machines, permission checks (RBAC), and transactional calculations.
   - Immutable data models with explicit JSON mapping and null safety.
3. **Repository Layer (`lib/services`):**
   - Offline-first boundary: queries local SQLite database first, falling back to network REST endpoints.
4. **Peripherals & Native Hardware Tier (`lib/peripherals`):**
   - Isolates direct COM, USB, and ESC/POS byte streams behind clean abstraction interfaces.
