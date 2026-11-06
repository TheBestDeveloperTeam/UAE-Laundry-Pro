# Royal Futuristic Design System & UI Specification
**Version:** 3.0.0 "Royal Futuristic"  
**Scope:** Design tokens, elevation layers, 3D kinetic widgets, and vector asset guidelines.

---

## 1. Design Philosophy: UAE Royal Futuristic
The design identity balances **Dubai-tier luxury** (Imperial Gold `#D4AF37`, Cyber Neon Aqua `#00E5BC`, Deep Royal Abyss `#050B14`) with **industrial-grade POS performance**. It replaces flat, static card rectangles with dynamic frosted glass surfaces, procedural 3D perspective transforms, and smooth Bézier motion curves.

---

## 2. Atmospheric & Accent Color Token Matrix

| Token Name | Hex Code | Visual Application & Hierarchy |
| :--- | :--- | :--- |
| `royalAbyss` | `#050B14` | Atmospheric root viewport backing & window chrome |
| `brandMidnight` | `#081426` | Deep navy base container color |
| `brandNavy` | `#0D1E36` | Primary sidebar navigation container |
| `brandNavyBorder`| `#1F385C` | 1.0px subtle frosted glass dividers & sidebar boundary |
| `brandTeal` | `#00A896` | Primary interactive buttons, active tab indicators |
| `brandAqua` | `#02C39A` | Secondary accent, positive chart curves |
| `cyberAqua` | `#00E5BC` | Cyberpunk neon glow, active badge beacons |
| `royalGold` | `#D4AF37` | Imperial UAE Gold (VIP tiers, grand totals, luxury emblems) |
| `royalGoldGlow` | `#F59E0B` | Amber Topaz glow for finishing production status |
| `canvas` | `#F4F7FB` | Low-glare main workspace body canvas |
| `surfacePrimary`| `#FFFFFF` | Elevated cards, data tables, modals |
| `surfaceSubtle` | `#F8FAFC` | Table headers, secondary input backings |

---

## 3. The 9-Layer Granular Viewport Architecture

Every view composited in LaundryPro UAE follows this 9-tier layer stack:

```
┌────────────────────────────────────────────────────────┐
│ Layer 9: Global HUD & Overlays (Toasts, Thermal Print)  │
├────────────────────────────────────────────────────────┤
│ Layer 8: Command Hub (Ctrl+K Global Search, Modals)    │
├────────────────────────────────────────────────────────┤
│ Layer 7: Persistent Hardware Health Strip              │
├────────────────────────────────────────────────────────┤
│ Layer 6: Workspace Frosted Topbar Navigation          │
├────────────────────────────────────────────────────────┤
│ Layer 5: Interactive Workspace Canvas & Data Tables    │
├────────────────────────────────────────────────────────┤
│ Layer 4: 3D Kinetic Widgets (Matrix4 Tilt & Sheen)     │
├────────────────────────────────────────────────────────┤
│ Layer 3: Glass Containers & Neomorphic Bevels          │
├────────────────────────────────────────────────────────┤
│ Layer 2: Ambient Atmospheric Glow & Meshes             │
├────────────────────────────────────────────────────────┤
│ Layer 1: Viewport Foundation & Safe Canvas             │
└────────────────────────────────────────────────────────┘
```

---

## 4. 3D Kinetic Interaction Guidelines
- **Perspective:** `Matrix4.identity()..setEntry(3, 2, 0.001)`.
- **Mouse Coordinate Tracking:** Tilt normalized across card dimensions with a maximum deflection of $\pm 0.06\text{ rad}$.
- **Dynamic Specular Sheen:** Linear gradient sweep (`Colors.transparent` $\to$ `accentColor.withValues(alpha: 0.2)` $\to$ `Colors.transparent`) triggered on pointer entry.
- **Dynamic Drop-Shadow Offset:** Inverts tilt axis coordinates to cast a natural depth shadow opposite the virtual light source.

