# LaundryPro UAE — UI Form Field & Validation Specifications

> **Version:** 2.0.0 | **Authoritative Frontend Engineering Reference**

---

## 1. Customer Registration & Profile Form

| Field Label | Field Key | Input Type | Validation Rules | Error Message (Bilingual) |
|---|---|---|---|---|
| **Mobile Number** | `phone` | Tel / Numeric | Required; Regex: `^(05\|+9715)[0-9]{8}$` | Invalid UAE mobile number / رقم الهاتف المتحرك غير صحيح |
| **Customer Name** | `name` | Text | Required; Min 3, Max 100 characters | Name is required / يرجى إدخال اسم العميل |
| **Customer Type** | `customer_type` | Radio / Select | Required; Options: `personal`, `corporate`, `walk_in` | Select customer type / حدد نوع العميل |
| **Tax Number (TRN)**| `tax_number` | Text | Optional for retail; Required for corporate: 15 digits | 15-digit TRN required / الرقم الضريبي يتكون من 15 رقماً |
| **Emirate** | `emirate` | Dropdown | Required; UAE 7 Emirates list (Dubai, Abu Dhabi, etc.) | Select Emirate / اختر الإمارة |
| **Area / Street** | `address_line1` | Text | Optional for walk-in; Required for delivery | Address required for delivery / العنوان مطلوب للتوصيل |
| **Credit Limit** | `credit_limit` | Currency | Optional; Numeric $\ge 0.00$; Default: `0.00` | Enter valid credit limit / أدخل حد ائتمان صالح |

---

## 2. Order Line Item Customization Modal

| Field Label | Field Key | Input Type | Validation Rules |
|---|---|---|---|
| **Garment Category** | `category_id` | Quick Touch Tiles | Required; Filters child services (e.g., Traditional Men, Ladies Silk) |
| **Service Type** | `service_id` | Quick Touch Tiles | Required; Auto-loads base price and default turnaround time |
| **Quantity** | `quantity` | Stepper / Numpad | Integer; Min 1, Max 999; Default: `1` |
| **Starch Level** | `modifier_starch` | Segmented Button | Optional; Options: `None`, `Light`, `Medium`, `Heavy` |
| **Hanger / Packing** | `modifier_hanger` | Segmented Button | Optional; Options: `Wire Hanger`, `Wooden Hanger`, `Folded Box` |
| **Express Surcharge** | `is_express` | Toggle Switch | Boolean; If true, applies configured express multiplier (+25% / +50%) |
| **Damage Notes** | `defect_notes` | Text Area | Optional; Text describing tears, missing buttons, or stubborn stains |

---

## 3. Expense Voucher Entry Form

| Field Label | Field Key | Input Type | Validation Rules |
|---|---|---|---|
| **Expense Category** | `category_id` | Dropdown | Required; (e.g., Shop Utilities, Fuel for Van, Detergent Supplies) |
| **Amount (AED)** | `amount` | Decimal Input | Required; $> 0.00$; Max 5,000.00 AED per petty cash voucher |
| **Paid From** | `paid_from` | Radio | Required; Options: `Cash Drawer Till` or `Bank Card` |
| **Vendor / Payee** | `payee_name` | Text | Required; Name of petrol station, utility company, or vendor |
| **Invoice / Receipt #**| `receipt_ref`| Text | Optional; Supplier's receipt number |
| **Attach Receipt Photo**| `attachment` | Camera / File | Mandatory if Amount $> 100.00\text{ AED}$ (auditor compliance rule) |
