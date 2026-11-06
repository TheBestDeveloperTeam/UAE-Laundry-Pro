# Pending Tasks, Future Enhancements & Defect Register
**Target:** v3.1.0 Roadmap  
**Quality Policy:** Zero Minor Visual Defect Tolerance

---

## 1. High Priority Enhancements (v3.1.0)

- [ ] **Lottie Animation Asset Pack Integration:**
  - Embed lightweight Lottie JSON animations for empty states, stage promotions, and payment success checkmarks into `assets/animations/`.
  - Replace static fallback icons in `EmptyState` with animated vector graphics.
- [ ] **Advanced Customer Loyalty Engine:**
  - Automated tier upgrade calculation (Silver $\to$ Gold $\to$ Platinum) based on rolling 90-day spend.
  - WhatsApp Business Cloud API integration for direct tax invoice PDF dispatch.
- [ ] **Multi-Camera Barcode & QR Reader:**
  - Integrate USB webcams for hands-free QR code customer lookup at drive-through counters.
- [ ] **Corporate Customer Portal:**
  - B2B portal interface allowing hotel and corporate clients to schedule batch pickups and download monthly consolidated VAT statements.

---

## 2. Technical Debt & Quality Maintenance
- [ ] Continuous synchronization of local and cloud OpenAPI contracts (`swagger/`).
- [ ] Periodic SQLite index defragmentation and automated backup rotation test runs.
- [ ] Automated regression testing on physical Windows touchscreen hardware.

