# LaundryPro UAE — Technical & Industry Glossary

> **Version:** 2.0.0 | **Authoritative Technical & Textile Care Glossary**

---

## 1. Laundry & Textile Care Terminology

- **Dry Cleaning**: A non-aqueous textile cleaning process utilizing chemical solvents (typically hydrocarbon, silicone, or perchloroethylene) rather than water. Critical for woolens, tailored suits, and beaded garments that shrink or distort in water.
- **Wet Cleaning**: An eco-friendly, computer-controlled aqueous cleaning process that employs specialized gentle mechanical drum action, biodegradable detergents, and controlled drying temperatures to safely wash delicate fabrics traditionally labeled "Dry Clean Only".
- **Hydrocarbon Solvent**: A gentle, synthetic petroleum-based dry cleaning solvent with low odor and mild solvency, ideal for luxury garments and sensitive trims.
- **Perchloroethylene (Perc)**: A heavy, non-flammable chlorinated solvent with aggressive grease-stripping properties, traditionally used in heavy-duty commercial dry cleaning.
- **Spotting Board**: A specialized vacuum and compressed steam table equipped with chemical spotting reagents used by professional spotters to remove wine, blood, ink, and grease stains prior to washing.
- **Flatwork Ironer**: A heavy motorized heated cylinder roller machine designed to press, dry, and fold flat linen (bed sheets, duvet covers, table cloths) at high speeds.
- **Kandora (Thobe / Dishdasha)**: Traditional Emirati ankle-length white tailored garment, requiring crisp collar pressing, cuff stiffness, and optional starch finishing.
- **Abaya**: Traditional flowing black cloak worn by Emirati women, frequently adorned with delicate crystals, lace, or silk embroidery requiring specialized gentle cycle hand care.
- **Starch Sizing**: A starch or carboxymethyl cellulose finishing additive applied during the final rinse to impart body, crispness, and stain resistance to shirts and cotton Kandoras.

---

## 2. UAE Fiscal & Regulatory Terms

- **FTA**: The **Federal Tax Authority** of the United Arab Emirates, responsible for administering and collecting federal taxes (VAT and Excise Tax).
- **TRN (Tax Registration Number)**: A unique 15-digit number issued by the FTA to a taxable business entity in the UAE.
- **TLV (Tag-Length-Value)**: A binary data encoding structure used to serialize mandatory invoice fields (Seller, TRN, Timestamp, Gross, VAT) into high-density 2D QR codes on thermal tax receipts.
- **WPS (Wages Protection System)**: An electronic salary transfer system overseen by the Ministry of Human Resources and Emiratisation (MOHRE) and UAE Central Bank, requiring private companies to pay salaries via approved financial institutions.
- **SIF (Salary Information File)**: The standardized comma-delimited text file format mandated by the UAE Central Bank for electronic salary disbursement batches.

---

## 3. System Architecture & Distributed Systems Terms

- **UMAC (Unique Machine Authentication Code)**: A deterministic cryptographic hash generated from immutable hardware components (Motherboard UUID, CPU Serial, Physical MAC Address) used to bind workstation licenses to physical hardware.
- **Offline-First**: An architectural pattern where the application writes to a local embedded database first, guaranteeing 100% functionality without relying on active network availability.
- **3-Way Merge**: A conflict resolution algorithm that compares two diverging branches of data (Local vs. Cloud) against their common ancestor base version to automatically reconcile changes.
- **Vector Clock**: An entity version tracking mechanism that maintains an incrementing counter per mutation to establish strict causal ordering of events across distributed nodes.
- **WAL (Write-Ahead Logging)**: A database journaling mode in MariaDB and SQLite where changes are recorded to a dedicated sequential log before being applied to the database file, providing maximum crash durability and high concurrent read performance.
- **Idempotency Key**: A unique client-generated UUID sent in the HTTP `X-Idempotency-Key` header ensuring that retried network requests do not trigger duplicate orders or credit card charges.
