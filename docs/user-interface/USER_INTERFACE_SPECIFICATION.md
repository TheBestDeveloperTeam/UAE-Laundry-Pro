# User Interface (UI) Standards, Typography & RTL Mirroring
**Design Language:** Royal Futuristic  
**Target Viewports:** 4K Wide Screen ($3840\times 2160$) down to Mobile POS ($360\times 640$)

---

## 1. Bilingual Typography & Line Heights

```
English (Inter / System Sans)       Arabic (Cairo / IBM Plex Sans Arabic)
Regular: 400                        Regular: 400
Semi-Bold: 600                      Medium: 500
Extra-Bold: 800                     Bold: 700
Line Height: 1.35                   Line Height: 1.55 (Extended ascenders/descenders)
```

---

## 2. Strict Bi-directional RTL Mirroring
1. **Layout Flow:** All horizontal alignments automatically invert (`leading` $\leftrightarrow$ `trailing`, `left` $\leftrightarrow$ `right`).
2. **Iconography Mirroring:** Directional icons (arrows, chevrons, steps) mirror horizontally in RTL mode; non-directional icons (printer, dollar symbol, clock) remain invariant.
3. **Number & Monetary Formatting:** Numbers formatted with English numerals (`123.45`) or Eastern Arabic numerals (`١٢٣٫٤٥`) based on operator terminal configuration, always with explicit `AED` currency prefix/suffix.

