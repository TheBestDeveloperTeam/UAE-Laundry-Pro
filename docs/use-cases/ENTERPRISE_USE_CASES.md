# LaundryPro UAE — Enterprise Use-Cases & Field Scenarios

> **Version:** 2.0.0 | **Authoritative Operational Field Manual**

---

## Use-Case 1: Ramadan & Eid Festive High-Volume Kandora Rush

### Context & Operational Challenge
During the last 10 days of Ramadan and the days preceding Eid al-Fitr and Eid al-Adha, UAE dry cleaners experience an unprecedented surge in garment intake—frequently exceeding **2,000 Kandoras per day** per retail outlet. Front-desk queues form out the door, and customers demand guaranteed 24-hour turnaround with crisp, unyielding collar starch.

### System Solution & Execution
1. **Express Multi-Garment POS Mode**:
   - The cashier enables "Fast Intake Mode" on the Flutter POS touch interface.
   - Default modifiers are pre-set to: `Men's Kandora`, `Medium Starch`, `Wire Hanger`, `Due Date: Eid Eve`.
   - Cashier enters customer mobile number, taps `+5 Kandoras`, and completes checkout in **under 12 seconds**.
2. **High-Speed Thermal Batch Printing**:
   - The dual-printer system instantly spits out 5 heat-seal barcode tags from the thermal label printer while the receipt printer prints the customer collection ticket.
3. **Automated Factory Sorter Manifests**:
   - Plant sorting conveyors scan the tag barcodes and route the Kandoras automatically to the high-temperature steam collar-and-cuff press line.

---

## Use-Case 2: 5-Star Hotel Linen & Spa Turnaround (24h SLA)

### Context & Operational Challenge
A luxury Dubai beach resort contracts its daily linen processing (2,500 kg of bedsheets, duvet covers, pillowcases, bathrobes, and pool towels). Any delivery delay results in room turnaround delays and severe SLA financial penalties.

### System Solution & Execution
1. **Gross Weight Scale Integration**:
   - The hotel linen hampers are rolled onto a digital floor scale at the loading dock.
   - The driver scans the customer QR code and captures gross weight directly into the delivery tablet.
2. **Factory Processing & Flatwork Ironing**:
   - Items are routed through continuous batch tunnel washers with thermal disinfection ($\ge 71^\circ\text{C}$ for 3 minutes) and dried on automated flatwork ironer lines.
3. **Automated Gate-Pass Delivery**:
   - The clean linen bundles return with a digitally signed delivery gate-pass, automatically reconciling the clean weight against the intake weight.

---

## Use-Case 3: Cross-Branch Garment Transfer & Collection

### Context & Operational Challenge
A business traveler drops off three tailored suits at the Dubai International Financial Centre (DIFC) branch in the morning and requests to collect them after work at the Dubai Marina branch near their residence.

### System Solution & Execution
1. **Intake with Destination Routing**:
   - DIFC cashier selects `Collection Branch: Dubai Marina` in the POS order modal.
   - Garment tags print with destination code `DEST: MARINA`.
2. **Logistics Van Transfer**:
   - DIFC branch manifests garments onto the mid-day inter-branch transfer van via `/challans/dispatch`.
3. **Marina Intake & Rack Allocation**:
   - Marina cashier scans incoming van box; items are immediately marked `Ready` in Marina store's local database and assigned to Rack Slot `M-22`.
   - Customer receives a WhatsApp alert notifying them:
     > *"Your order #DIFC-2026-0891 is ready for collection at our Dubai Marina branch (Rack M-22)."*
