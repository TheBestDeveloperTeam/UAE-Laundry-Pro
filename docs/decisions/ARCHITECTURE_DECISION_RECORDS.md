# Architecture Decision Records (ADR)
**Status:** Living Architectural Registry  
**Standard:** Michael Nygard ADR Format

---

## ADR-001: Offline-First Local SQLite Primary Data Store
- **Status:** Accepted & Implemented
- **Context:** UAE laundry plants and retail counters frequently operate in high-density commercial strips where internet interruptions or router drops can halt counter transactions.
- **Decision:** All critical read/write business paths query a native local SQLite database (`LocalBusinessDatabase`) on the edge Windows PC first. The cloud backend is synchronized asynchronously via an outbox queue.
- **Consequences:** POS operations have near 0ms latency; sales continue seamlessly offline; complex sync reconciliation rules required.

---

## ADR-002: Dual Scrollbar Controllers with Depth Isolation in AppDataTable
- **Status:** Accepted & Implemented
- **Context:** Nesting vertical and horizontal scrollbars with `thumbVisibility: true` resulted in assertion errors (`scrollController != null`) because Flutter attempted to locate a single `PrimaryScrollController`.
- **Decision:** Converted `AppDataTable` to a `StatefulWidget` owning explicit, disposed `_verticalController` and `_horizontalController` instances with `notificationPredicate: (notif) => notif.depth == 1` on the inner horizontal scrollbar.
- **Consequences:** Smooth, dual-axis independent scrolling across huge 10,000+ row datasets without framework assertion failures.

---

## ADR-003: Pure Custom Vector Graphics Over Raster Images
- **Status:** Accepted & Implemented
- **Context:** High-DPI Windows desktop screens (4K, Surface displays) caused bitmap blurriness on legacy PNG icons and brand marks.
- **Decision:** Mandate pure Flutter vector rendering (`CustomPainter`, scalable Bézier math) and hardware-accelerated Lottie animations exclusively.
- **Consequences:** Zero resolution degradation across any display scale; reduced application bundle footprint.

---

## ADR-004: Strict Fractional Currency Modeling via String/DECIMAL(18,2)
- **Status:** Accepted & Implemented
- **Context:** IEEE 754 floating-point inaccuracies cause minor fractional fils rounding discrepancies in VAT calculations.
- **Decision:** All monetary transactions are formatted and stored as strict `DECIMAL(18,2)` numbers or formatted strings in JSON payloads. Floats are prohibited in ledger paths.
- **Consequences:** 100% compliance with UAE FTA tax auditing rules.

