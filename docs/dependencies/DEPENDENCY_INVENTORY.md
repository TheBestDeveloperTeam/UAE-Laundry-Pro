# Dependency Graph & Package Inventory
**Framework:** Flutter 3.35.x (Windows Desktop Native) / Dart 3.9.x  
**Standard:** Strict zero bloat policy. Only vetted, high-performance packages allowed.

---

## 1. Production Runtime Dependencies

| Package | Version | Layer / Responsibility | Security & Stability Audit |
| :--- | :--- | :--- | :--- |
| `flutter` | SDK | Core UI framework & Skia/Impeller engine | Official Google SDK |
| `flutter_localizations` | SDK | Bilingual Arabic RTL & English LTR support | Official Google SDK |
| `flutter_riverpod` | `^2.5.1` | State management for hardware controllers & sync | Zero-dependency, reactive |
| `provider` | `^6.1.2` | Context-bound UI state (`AuthProvider`, `LocaleProvider`) | Stable, community benchmark |
| `go_router` | `^14.0.0`| Declarative URL-based navigation & route nesting | Maintained by Flutter team |
| `sqflite_common_ffi` | `^2.3.3` | Native Windows SQLite database engine | Offline-first primary store |
| `intl` | `^0.19.0`| Number, currency (`AED`), and date formatting | Official Dart package |
| `http` | `^1.2.1` | REST API transport to Cloud API & Edge relays | Pure Dart HTTP client |
| `crypto` | `^3.0.3` | SHA-256 backup verification & password hashing | Pure Dart security standard |
| `shared_preferences` | `^2.2.3` | Persistent local register preferences & tokens | Official Flutter plugin |

---

## 2. Hardware Peripheral Dependencies
- **Thermal Printer:** Native ESC/POS command generator with custom CP1256 Arabic character shaper (`ArabicFormatter`).
- **Barcode Scanner:** Raw keyboard event listener intercepting USB HID scanner inputs (`LogicalKeyboardKey`).
- **Weighing Scale:** Native serial COM port communication parser (`ScaleParser`).

---

## 3. Tooling & Test Dependencies
- `flutter_test`: Unit, widget, and reflow test harness.
- `flutter_lints`: `^4.0.0` enforcing strict zero-tolerance code quality.

