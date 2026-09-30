# LaundryPro UAE — "Purple Dark" Theme Specification

> **Version:** 2.0.0 | **Authoritative Design System** | **Theme:** Purple Dark Enterprise

---

## 1. Design Philosophy

The LaundryPro UAE user interface combines high-contrast ergonomic readability for POS cashiers operating under bright retail lighting with a sleek, luxury enterprise aesthetic for store managers and corporate franchise owners.

---

## 2. Core Color Palette Tokens

```css
:root {
  /* Surface & Background Layers */
  --lp-bg-canvas: #0d0f17;         /* Deep obsidian background */
  --lp-bg-surface: #161926;        /* Primary container & card surface */
  --lp-bg-surface-elevated: #1e2235;/* Modal dialogs, dropdowns, tooltips */
  --lp-bg-surface-hover: #262b42;   /* Hover state for table rows & cards */

  /* Primary Brand Violet Scale */
  --lp-primary-50: #f5f3ff;
  --lp-primary-100: #ede9fe;
  --lp-primary-400: #a78bfa;
  --lp-primary-500: #8b5cf6;
  --lp-primary-600: #7c3aed;        /* Primary button & brand accent */
  --lp-primary-700: #6d28d9;
  --lp-primary-900: #4c1d95;

  /* Accent & Functional Colors */
  --lp-accent-cyan: #06b6d4;        /* Sync active indicator & secondary CTA */
  --lp-success-emerald: #10b981;    /* Ready orders, paid invoices */
  --lp-warning-amber: #f59e0b;      /* Pending sync, delayed orders */
  --lp-danger-rose: #f43f5e;        /* Voided items, system alerts */

  /* Text & Border Contrasts */
  --lp-text-primary: #f8fafc;       /* Highest contrast header & body text */
  --lp-text-secondary: #cbd5e1;     /* Secondary details, timestamps */
  --lp-text-muted: #94a3b8;         /* Table headers, disabled states */
  --lp-border-subtle: rgba(255, 255, 255, 0.08);
  --lp-border-focused: rgba(124, 58, 237, 0.5);

  /* Shadows & Glassmorphism */
  --lp-shadow-card: 0 4px 20px -2px rgba(0, 0, 0, 0.5);
  --lp-shadow-glow: 0 0 15px rgba(124, 58, 237, 0.35);
  --lp-glass-blur: blur(12px);
}
```

---

## 3. Typography & Bilingual Type Hierarchy

- **English Typography**: Inter or Outfit (Google Fonts).
- **Arabic Typography**: Noto Sans Arabic or Cairo (Google Fonts).
- **Scale**:
  - `Display / KPI`: 32px / Bold (700)
  - `Page Header H1`: 24px / SemiBold (600)
  - `Card Header H2`: 18px / Medium (500)
  - `Body / Table Row`: 14px / Regular (400)
  - `Caption / Tag`: 12px / Medium (500)

---

## 4. AdminLTE v4 Web Portal Dark Overrides

For both Local Admin (`api/`) and Cloud Super-Admin (`cloud-api/`), AdminLTE v4 is customized via CSS overrides:

```css
body.dark-mode {
  background-color: var(--lp-bg-canvas) !important;
  color: var(--lp-text-primary) !important;
  font-family: 'Inter', 'Noto Sans Arabic', sans-serif;
}

.main-sidebar {
  background-color: var(--lp-bg-surface) !important;
  border-right: 1px solid var(--lp-border-subtle) !important;
}

.card {
  background-color: var(--lp-bg-surface) !important;
  border: 1px solid var(--lp-border-subtle) !important;
  border-radius: 12px !important;
  box-shadow: var(--lp-shadow-card) !important;
}

.btn-primary {
  background: linear-gradient(135deg, var(--lp-primary-600), var(--lp-primary-700)) !important;
  border: none !important;
  box-shadow: var(--lp-shadow-glow) !important;
}
```
