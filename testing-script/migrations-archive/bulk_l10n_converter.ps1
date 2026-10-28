#!/usr/bin/env pwsh
# Bulk L10N Converter for UAE-Laundry-Pro
# Converts ALL remaining hardcoded English strings in Dart views to l10n.t() calls.

$projectRoot = "e:\Projects\Flutter\UAE-Laundry-Pro"
$viewsDir = "$projectRoot\lib\views"
$posDir = "$projectRoot\lib\features\pos"
$printerDir = "$projectRoot\lib\peripherals\features\printer\widgets"
$enJsonPath = "$projectRoot\assets\lang\en.json"
$arJsonPath = "$projectRoot\assets\lang\ar.json"

# ===== NEW KEYS TO ADD (en + ar) =====
$newKeysEn = @{
    # Settings Screen
    "settings_global_paths" = "Global Paths & Directories"
    "settings_global_paths_desc" = "Backup, logs, receipts, images, and export directories"
    "settings_roles_perms" = "Roles & Permissions"
    "settings_roles_perms_desc" = "Manage user authorization and access roles"
    "settings_disaster_recovery" = "Disaster recovery, SHA-256 verification, and snapshot restore"
    "settings_backup_snapshots" = "Backup Snapshots History"
    "settings_no_backups" = "No backup archives created yet."
    "settings_file_label" = "File: {file}"
    "settings_target_archive" = "Target Archive: {file}"
    "settings_dry_run_status" = "Dry Run Status: {status} ({count} SQL statements)"

    # Sync Settings Screen
    "sync_outbox_queue" = "SQLite Outbox Queue ({count} Staged)"
    "sync_queued_label" = "Queued: {time}"
    "sync_conflict_audit_log" = "Sync Conflict Audit Log"
    "sync_inspect_payloads" = "Inspect Staged Payloads"
    "sync_view_conflicts" = "View Conflict History"
    "sync_merge_strategy_title" = "Deterministic 3-Way Merge Strategy Active"
    "sync_merge_strategy_desc" = "Cloud Master Sequence ID tracking with automated replay recovery."
    "sync_error" = "Sync Error: {error}"

    # Sterilization Screen
    "sterilization_supervisor_name" = "Certified Supervisor / QA Name *"
    "sterilization_supervisor_hint" = "e.g. Dr. Amina Al-Zaabi"
    "sterilization_pin" = "Operator Security PIN *"
    "sterilization_pin_hint" = "4-digit authorization code"
    "sterilization_attestation" = "Regulatory Attestation / Meaning *"
    "sterilization_sign_certify" = "Sign & Certify"
    "sterilization_enter_details" = "Please enter supervisor name and security PIN"
    "sterilization_lot_certified" = "Sterilization Lot certified with digital e-signature"
    "sterilization_signing_error" = "Signing error: {error}"
    "sterilization_affix_signature" = "Affix Electronic Signature"
    "sterilization_close_details" = "Close Details"
    "sterilization_needs_sign" = "Needs Sign"
    "sterilization_affix_sig_tooltip" = "Affix Signature"
    "sterilization_autoclave_program" = "Sterilization Autoclave Program"
    "sterilization_target_temp" = "Target Temp (°C)"
    "sterilization_pressure" = "Pressure (bar)"
    "sterilization_duration" = "Duration (min)"
    "sterilization_error" = "Error: {error}"

    # Setup Wizard Screen
    "wizard_install_complete" = "Installation & initial setup completed successfully!"
    "wizard_install_error" = "Installation error: {error}"
    "wizard_currency_aed" = "UAE Dirham (AED / Fils)"
    "wizard_currency_sar" = "Saudi Riyal (SAR / Halala)"
    "wizard_printer_80mm" = "Thermal Roll Paper (80mm / 48 chars)"
    "wizard_printer_58mm" = "Thermal Roll Paper (58mm / 32 chars)"
    "wizard_printer_a4" = "Laser/Inkjet A4 Standard"
    "wizard_printer_dot" = "Dot-Matrix 80-Col (Carbon Copy)"
    "wizard_email_label" = "Email"
    "wizard_emirate_label" = "Emirate"
    "wizard_address_label" = "Physical Address"
    "wizard_currency_label" = "Currency"
    "wizard_invoice_prefix" = "Invoice Prefix (e.g. INV-)"
    "wizard_receipt_prefix" = "Receipt Prefix (e.g. REC-)"
    "wizard_challan_prefix" = "Challan Prefix (e.g. CHL-)"
    "wizard_grn_prefix" = "GRN Prefix (e.g. GRN-)"
    "wizard_api_secret" = "API Installation Secret (from api/.env)"
    "wizard_backup_dir" = "Canonical Backup Directory (BACKUP_PATH)"
    "wizard_printer_label" = "Primary Slip Printer Default"
    "wizard_license_hint" = "Optional: Enter activation key or leave blank for 7-day evaluation"
    "wizard_license_stamp" = "Enter activation stamp or key"

    # Terminals Screen
    "terminal_lan_ip" = "LAN Binding IP Address"
    "terminal_lan_ip_hint" = "192.168.1.100"
    "terminal_mac" = "Hardware MAC Address"
    "terminal_mac_hint" = "XX:XX:XX:XX:XX:XX"
    "terminal_auth_token" = "Hardware Security Auth Token"
    "terminal_create_branch_first" = "Please create a branch first before pairing terminals"
    "terminal_regen_token" = "Regenerate Token"

    # Role Editor Screen
    "role_load_failed" = "Failed to load roles"
    "role_updated" = "Role updated successfully"
    "role_update_failed" = "Failed to update role"
    "role_grant_all" = "Grant All (*)"
    "role_clear_all" = "Clear All"
    "role_title_hint" = "Role Title (e.g. Branch Supervisor)"

    # Vendors Screen
    "vendor_save_failed" = "Failed to save vendor: {error}"
    "vendor_bank_hint" = "e.g. Emirates NBD, IBAN: AE070260000000000000000"
    "vendor_search_hint" = "Search by vendor name, phone, or TRN..."

    # Salary Advances Screen
    "salary_reason_notes" = "Reason / Notes"

    # RFID Screen
    "rfid_reader_ip" = "Reader IPv4 Address"
    "rfid_reader_ip_hint" = "192.168.1.180"
    "rfid_tcp_port" = "TCP Port (LLRP/ASCII)"
    "rfid_tcp_port_hint" = "5084"
    "rfid_reader_settings" = "Reader Hardware Settings"
    "rfid_clear_scanned" = "Clear Scanned"

    # Purchasing Screen
    "purchasing_product" = "Product"
    "purchasing_qty" = "Qty"
    "purchasing_unit_cost_label" = "Unit Cost"
    "purchasing_delivery_note" = "Supplier Delivery Note / Bill of Lading (BOL)"
    "purchasing_delivery_note_hint" = "e.g. DN-984321"
    "purchasing_inspector_notes" = "Receiving Inspector Notes / Quality Checks"
    "purchasing_inspector_notes_hint" = "Packaging intact, seals verified, stored in Bay A"

    # Production Screen
    "production_qc_notes" = "QC / Audit Notes (Optional)"

    # Pending Invoices Screen
    "pending_amount_label" = "Amount (AED) / المبلغ"

    # Operator Screen
    "operator_select_employee" = "Select Employee *"
    "operator_cert_program" = "Certification Program *"
    "operator_refresh" = "Refresh"

    # Leave Screen
    "leave_type_label" = "Leave Type"
    "leave_reason" = "Reason for Leave"
    "leave_approve_tooltip" = "Approve Leave"
    "leave_reject_tooltip" = "Reject Leave"

    # License Screen
    "license_enter_key" = "Enter activation stamp or key"

    # Expenses Screen
    "expense_amount_label" = "Amount (AED)"
    "expense_approve_tooltip" = "Approve"
    "expense_reject_tooltip" = "Reject"

    # Equipment Screen
    "equipment_technician" = "Technician / Performed By *"
    "equipment_technician_hint" = "e.g. Eng. Sarah Ahmed"
    "equipment_cert_ref" = "Certificate Reference / Report # *"
    "equipment_cert_ref_hint" = "e.g. CAL-2026-0891"
    "equipment_refresh" = "Refresh"

    # Employees Screen
    "employee_pin_label" = "PIN (Clock-In)"
    "employee_eid_hint" = "784-XXXX-XXXXXXX-X"

    # Customer Portal Screen
    "portal_address_label" = "Drop-off / Delivery Address *"
    "portal_time_slot" = "Preferred Time Slot"
    "portal_tracking_hint" = "e.g. ORD-2026-0042 or 8-char token"

    # Customers Screen
    "customer_phone_label" = "Phone Number (Mobile) *"
    "customer_name_label" = "Full Customer Name *"
    "customer_email_label" = "Email Address"
    "customer_trn_label" = "Tax TRN (B2B)"
    "customer_address_label" = "Delivery Address / Villa / Apt"
    "customer_loyalty_label" = "Loyalty Tier"

    # Challans Screen
    "challan_desc_hint" = "e.g. Clean Linen Bundles"

    # Branches Screen
    "branch_hours_hint" = "e.g. 08:00 - 22:00 (Sat-Thu), 14:00 - 22:00 (Fri)"

    # Attendance Screen
    "attendance_pin_hint" = "PIN or Badge Scan"

    # Advanced Cycle Screen
    "cycle_rack_hint" = "e.g. 101"
    "cycle_qty_hint" = "e.g. 1"

    # Global Config Screen
    "config_backup_path_hint" = "e.g. C:/LaundryPro/backups/"

    # Notifications Screen
    "notification_mark_read" = "Mark as read"

    # Reports Screen
    "reports_export_csv" = "Export CSV"
    "reports_export_pdf" = "Export PDF"
    "reports_refresh" = "Refresh"

    # POS Screen
    "pos_manual_sync" = "Manual Sync"
    "pos_settings_peripherals" = "Settings & Peripherals"

    # Printer Panel
    "printer_refresh" = "Refresh printers"
    "printer_discover_network" = "Discover network printers"
    "printer_remove_line" = "Remove line"
    "print_queue_refresh" = "Refresh"
    "print_queue_retry" = "Retry"
    "print_queue_delete" = "Delete"
    "printer_delete_template" = "Delete template"

    # General
    "error_label" = "Error"
    "confirm_action" = "Confirm"
    "delete_action" = "Delete"
    "edit_action" = "Edit"
    "add_action" = "Add"
    "approve_action" = "Approve"
    "reject_action" = "Reject"
    "refresh_action" = "Refresh"
}

$newKeysAr = @{
    # Settings Screen
    "settings_global_paths" = "المسارات والمجلدات العامة"
    "settings_global_paths_desc" = "مجلدات النسخ الاحتياطي والسجلات والإيصالات والصور والتصدير"
    "settings_roles_perms" = "الأدوار والصلاحيات"
    "settings_roles_perms_desc" = "إدارة التفويضات وأدوار الوصول للمستخدمين"
    "settings_disaster_recovery" = "استعادة الكوارث، التحقق SHA-256، واستعادة اللقطات"
    "settings_backup_snapshots" = "سجل لقطات النسخ الاحتياطي"
    "settings_no_backups" = "لا توجد أرشيفات نسخ احتياطي بعد."
    "settings_file_label" = "الملف: {file}"
    "settings_target_archive" = "الأرشيف المستهدف: {file}"
    "settings_dry_run_status" = "حالة الاختبار التجريبي: {status} ({count} جمل SQL)"

    # Sync Settings Screen
    "sync_outbox_queue" = "قائمة انتظار SQLite ({count} مُرحّل)"
    "sync_queued_label" = "في الانتظار: {time}"
    "sync_conflict_audit_log" = "سجل تدقيق تعارضات المزامنة"
    "sync_inspect_payloads" = "فحص الحمولات المرحلة"
    "sync_view_conflicts" = "عرض سجل التعارضات"
    "sync_merge_strategy_title" = "استراتيجية الدمج ثلاثي الاتجاه نشطة"
    "sync_merge_strategy_desc" = "تتبع معرف التسلسل الرئيسي السحابي مع استرداد إعادة التشغيل التلقائي."
    "sync_error" = "خطأ في المزامنة: {error}"

    # Sterilization Screen
    "sterilization_supervisor_name" = "اسم المشرف المعتمد / ضمان الجودة *"
    "sterilization_supervisor_hint" = "مثال: د. أمينة الزعابي"
    "sterilization_pin" = "رمز أمان المشغل *"
    "sterilization_pin_hint" = "رمز تفويض من 4 أرقام"
    "sterilization_attestation" = "إقرار تنظيمي / المعنى *"
    "sterilization_sign_certify" = "توقيع واعتماد"
    "sterilization_enter_details" = "يرجى إدخال اسم المشرف ورمز الأمان"
    "sterilization_lot_certified" = "تم اعتماد دفعة التعقيم بتوقيع إلكتروني رقمي"
    "sterilization_signing_error" = "خطأ في التوقيع: {error}"
    "sterilization_affix_signature" = "تثبيت التوقيع الإلكتروني"
    "sterilization_close_details" = "إغلاق التفاصيل"
    "sterilization_needs_sign" = "يحتاج توقيع"
    "sterilization_affix_sig_tooltip" = "تثبيت التوقيع"
    "sterilization_autoclave_program" = "برنامج أوتوكلاف التعقيم"
    "sterilization_target_temp" = "درجة الحرارة المستهدفة (°م)"
    "sterilization_pressure" = "الضغط (بار)"
    "sterilization_duration" = "المدة (دقيقة)"
    "sterilization_error" = "خطأ: {error}"

    # Setup Wizard Screen
    "wizard_install_complete" = "اكتمل التثبيت والإعداد الأولي بنجاح!"
    "wizard_install_error" = "خطأ في التثبيت: {error}"
    "wizard_currency_aed" = "درهم إماراتي (AED / فلس)"
    "wizard_currency_sar" = "ريال سعودي (SAR / هللة)"
    "wizard_printer_80mm" = "ورق حراري ملفوف (80 مم / 48 حرف)"
    "wizard_printer_58mm" = "ورق حراري ملفوف (58 مم / 32 حرف)"
    "wizard_printer_a4" = "طابعة ليزر/حبر A4 قياسي"
    "wizard_printer_dot" = "طابعة نقطية 80 عمود (نسخة كربونية)"
    "wizard_email_label" = "البريد الإلكتروني"
    "wizard_emirate_label" = "الإمارة"
    "wizard_address_label" = "العنوان الفعلي"
    "wizard_currency_label" = "العملة"
    "wizard_invoice_prefix" = "بادئة الفاتورة (مثال: INV-)"
    "wizard_receipt_prefix" = "بادئة الإيصال (مثال: REC-)"
    "wizard_challan_prefix" = "بادئة السند (مثال: CHL-)"
    "wizard_grn_prefix" = "بادئة GRN (مثال: GRN-)"
    "wizard_api_secret" = "مفتاح أمان API (من api/.env)"
    "wizard_backup_dir" = "مجلد النسخ الاحتياطي الأساسي (BACKUP_PATH)"
    "wizard_printer_label" = "الطابعة الافتراضية للإيصالات"
    "wizard_license_hint" = "اختياري: أدخل مفتاح التفعيل أو اتركه فارغاً للتقييم لمدة 7 أيام"
    "wizard_license_stamp" = "أدخل رمز أو مفتاح التفعيل"

    # Terminals Screen
    "terminal_lan_ip" = "عنوان IP للشبكة المحلية"
    "terminal_lan_ip_hint" = "192.168.1.100"
    "terminal_mac" = "عنوان MAC للجهاز"
    "terminal_mac_hint" = "XX:XX:XX:XX:XX:XX"
    "terminal_auth_token" = "رمز أمان الجهاز"
    "terminal_create_branch_first" = "يرجى إنشاء فرع أولاً قبل ربط المحطات"
    "terminal_regen_token" = "إعادة إنشاء الرمز"

    # Role Editor Screen
    "role_load_failed" = "فشل في تحميل الأدوار"
    "role_updated" = "تم تحديث الدور بنجاح"
    "role_update_failed" = "فشل في تحديث الدور"
    "role_grant_all" = "منح الكل (*)"
    "role_clear_all" = "مسح الكل"
    "role_title_hint" = "عنوان الدور (مثال: مشرف الفرع)"

    # Vendors Screen
    "vendor_save_failed" = "فشل حفظ المورد: {error}"
    "vendor_bank_hint" = "مثال: بنك الإمارات دبي الوطني، IBAN: AE070260000000000000000"
    "vendor_search_hint" = "البحث باسم المورد أو الهاتف أو الرقم الضريبي..."

    # Salary Advances Screen
    "salary_reason_notes" = "السبب / ملاحظات"

    # RFID Screen
    "rfid_reader_ip" = "عنوان IPv4 للقارئ"
    "rfid_reader_ip_hint" = "192.168.1.180"
    "rfid_tcp_port" = "منفذ TCP (LLRP/ASCII)"
    "rfid_tcp_port_hint" = "5084"
    "rfid_reader_settings" = "إعدادات أجهزة القارئ"
    "rfid_clear_scanned" = "مسح الممسوح"

    # Purchasing Screen
    "purchasing_product" = "المنتج"
    "purchasing_qty" = "الكمية"
    "purchasing_unit_cost_label" = "تكلفة الوحدة"
    "purchasing_delivery_note" = "مذكرة تسليم المورد / بوليصة الشحن (BOL)"
    "purchasing_delivery_note_hint" = "مثال: DN-984321"
    "purchasing_inspector_notes" = "ملاحظات مفتش الاستلام / فحوصات الجودة"
    "purchasing_inspector_notes_hint" = "التغليف سليم، الأختام محققة، مخزن في الخليج A"

    # Production Screen
    "production_qc_notes" = "ملاحظات الجودة / التدقيق (اختياري)"

    # Pending Invoices Screen
    "pending_amount_label" = "المبلغ (درهم) / Amount"

    # Operator Screen
    "operator_select_employee" = "اختيار الموظف *"
    "operator_cert_program" = "برنامج الشهادة *"
    "operator_refresh" = "تحديث"

    # Leave Screen
    "leave_type_label" = "نوع الإجازة"
    "leave_reason" = "سبب الإجازة"
    "leave_approve_tooltip" = "الموافقة على الإجازة"
    "leave_reject_tooltip" = "رفض الإجازة"

    # License Screen
    "license_enter_key" = "أدخل رمز أو مفتاح التفعيل"

    # Expenses Screen
    "expense_amount_label" = "المبلغ (درهم)"
    "expense_approve_tooltip" = "موافقة"
    "expense_reject_tooltip" = "رفض"

    # Equipment Screen
    "equipment_technician" = "الفني / المنفذ *"
    "equipment_technician_hint" = "مثال: م. سارة أحمد"
    "equipment_cert_ref" = "مرجع الشهادة / رقم التقرير *"
    "equipment_cert_ref_hint" = "مثال: CAL-2026-0891"
    "equipment_refresh" = "تحديث"

    # Employees Screen
    "employee_pin_label" = "الرمز السري (الحضور)"
    "employee_eid_hint" = "784-XXXX-XXXXXXX-X"

    # Customer Portal Screen
    "portal_address_label" = "عنوان التسليم / الاستلام *"
    "portal_time_slot" = "الفترة الزمنية المفضلة"
    "portal_tracking_hint" = "مثال: ORD-2026-0042 أو رمز من 8 أحرف"

    # Customers Screen
    "customer_phone_label" = "رقم الهاتف (الجوال) *"
    "customer_name_label" = "اسم العميل الكامل *"
    "customer_email_label" = "البريد الإلكتروني"
    "customer_trn_label" = "الرقم الضريبي TRN (للشركات)"
    "customer_address_label" = "عنوان التوصيل / الفيلا / الشقة"
    "customer_loyalty_label" = "فئة الولاء"

    # Challans Screen
    "challan_desc_hint" = "مثال: حزم الكتان النظيف"

    # Branches Screen
    "branch_hours_hint" = "مثال: 08:00 - 22:00 (سبت-خميس)، 14:00 - 22:00 (الجمعة)"

    # Attendance Screen
    "attendance_pin_hint" = "الرمز السري أو مسح البطاقة"

    # Advanced Cycle Screen
    "cycle_rack_hint" = "مثال: 101"
    "cycle_qty_hint" = "مثال: 1"

    # Global Config Screen
    "config_backup_path_hint" = "مثال: C:/LaundryPro/backups/"

    # Notifications Screen
    "notification_mark_read" = "تعليم كمقروء"

    # Reports Screen
    "reports_export_csv" = "تصدير CSV"
    "reports_export_pdf" = "تصدير PDF"
    "reports_refresh" = "تحديث"

    # POS Screen
    "pos_manual_sync" = "مزامنة يدوية"
    "pos_settings_peripherals" = "الإعدادات والأجهزة الطرفية"

    # Printer Panel
    "printer_refresh" = "تحديث الطابعات"
    "printer_discover_network" = "اكتشاف طابعات الشبكة"
    "printer_remove_line" = "إزالة السطر"
    "print_queue_refresh" = "تحديث"
    "print_queue_retry" = "إعادة المحاولة"
    "print_queue_delete" = "حذف"
    "printer_delete_template" = "حذف القالب"

    # General
    "error_label" = "خطأ"
    "confirm_action" = "تأكيد"
    "delete_action" = "حذف"
    "edit_action" = "تعديل"
    "add_action" = "إضافة"
    "approve_action" = "موافقة"
    "reject_action" = "رفض"
    "refresh_action" = "تحديث"
}

# ===== Step 1: Update en.json with new keys =====
Write-Host "=== Step 1: Adding new localization keys to en.json ===" -ForegroundColor Cyan
$enJson = Get-Content $enJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$enHash = [ordered]@{}
foreach ($p in $enJson.PSObject.Properties) { $enHash[$p.Name] = $p.Value }
foreach ($k in $newKeysEn.Keys) {
    if (-not $enHash.Contains($k)) {
        $enHash[$k] = $newKeysEn[$k]
        Write-Host "  [+en] $k" -ForegroundColor Green
    }
}
$enHash | ConvertTo-Json -Depth 10 | Set-Content $enJsonPath -Encoding UTF8
Write-Host "  en.json: $($enHash.Count) keys total" -ForegroundColor Yellow

# ===== Step 2: Update ar.json with new keys =====
Write-Host "`n=== Step 2: Adding new localization keys to ar.json ===" -ForegroundColor Cyan
$arJson = Get-Content $arJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$arHash = [ordered]@{}
foreach ($p in $arJson.PSObject.Properties) { $arHash[$p.Name] = $p.Value }
foreach ($k in $newKeysAr.Keys) {
    if (-not $arHash.Contains($k)) {
        $arHash[$k] = $newKeysAr[$k]
        Write-Host "  [+ar] $k" -ForegroundColor Green
    }
}
$arHash | ConvertTo-Json -Depth 10 | Set-Content $arJsonPath -Encoding UTF8
Write-Host "  ar.json: $($arHash.Count) keys total" -ForegroundColor Yellow

Write-Host "`n=== Localization keys injection complete ===" -ForegroundColor Cyan
Write-Host "en.json: $($enHash.Count) keys | ar.json: $($arHash.Count) keys" -ForegroundColor Green
