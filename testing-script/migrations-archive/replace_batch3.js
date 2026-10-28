// Batch 3: Remaining L10N key injection + string replacement

const fs = require('fs');
const path = require('path');
const projectRoot = 'e:/Projects/Flutter/UAE-Laundry-Pro';
const enPath = path.join(projectRoot, 'assets/lang/en.json');
const arPath = path.join(projectRoot, 'assets/lang/ar.json');
let en = JSON.parse(fs.readFileSync(enPath, 'utf8'));
let ar = JSON.parse(fs.readFileSync(arPath, 'utf8'));

const newKeys3 = {
    // Accounting
    "accounting_line_no": ["Line #{no}", "\u0627\u0644\u0633\u0637\u0631 #{no}"],
    "accounting_quickbooks_iif": ["QuickBooks IIF", "QuickBooks IIF"],
    "accounting_output_vat": ["Standard Output VAT (5%)", "\u0636\u0631\u064a\u0628\u0629 \u0627\u0644\u0642\u064a\u0645\u0629 \u0627\u0644\u0645\u0636\u0627\u0641\u0629 \u0627\u0644\u0645\u062e\u0631\u062c\u0627\u062a (5%)"],
    "accounting_input_vat": ["Recoverable Input VAT (5%)", "\u0636\u0631\u064a\u0628\u0629 \u0627\u0644\u0642\u064a\u0645\u0629 \u0627\u0644\u0645\u0636\u0627\u0641\u0629 \u0627\u0644\u0645\u062f\u062e\u0644\u0627\u062a \u0627\u0644\u0642\u0627\u0628\u0644\u0629 \u0644\u0644\u0627\u0633\u062a\u0631\u062f\u0627\u062f (5%)"],

    // Channels
    "channel_whatsapp": ["WhatsApp Business API", "WhatsApp Business API"],
    "channel_sms": ["Transactional SMS", "\u0631\u0633\u0627\u0626\u0644 \u0646\u0635\u064a\u0629 \u062a\u062c\u0627\u0631\u064a\u0629"],
    "channel_email_transactional": ["Transactional Email", "\u0628\u0631\u064a\u062f \u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a \u062a\u062c\u0627\u0631\u064a"],
    "channel_twilio": ["Twilio SMS / WhatsApp", "Twilio SMS / WhatsApp"],
    "channel_infobip": ["Infobip MENA Gateway", "Infobip MENA Gateway"],
    "channel_stub": ["Internal Stub (Diagnostic)", "\u0645\u062d\u0627\u0643\u0627\u0629 \u062f\u0627\u062e\u0644\u064a\u0629 (\u062a\u0634\u062e\u064a\u0635\u064a)"],
    "channel_no_channels": ["No channels configured yet.", "\u0644\u0627 \u062a\u0648\u062c\u062f \u0642\u0646\u0648\u0627\u062a \u0645\u0647\u064a\u0623\u0629 \u0628\u0639\u062f."],

    // Customer Portal
    "portal_request_delivery": ["Request Home Delivery / Pickup", "\u0637\u0644\u0628 \u062a\u0648\u0635\u064a\u0644 / \u0627\u0633\u062a\u0644\u0627\u0645 \u0645\u0646\u0632\u0644\u064a"],
    "portal_delivery_booked": ["Delivery request booked! Driver will contact before arrival.", "\u062a\u0645 \u062d\u062c\u0632 \u0637\u0644\u0628 \u0627\u0644\u062a\u0648\u0635\u064a\u0644! \u0633\u064a\u062a\u0648\u0627\u0635\u0644 \u0627\u0644\u0633\u0627\u0626\u0642 \u0642\u0628\u0644 \u0627\u0644\u0648\u0635\u0648\u0644."],
    "portal_confirm_delivery": ["Confirm Delivery Request", "\u062a\u0623\u0643\u064a\u062f \u0637\u0644\u0628 \u0627\u0644\u062a\u0648\u0635\u064a\u0644"],
    "portal_download_receipt": ["Download Receipt", "\u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0625\u064a\u0635\u0627\u0644"],
    "portal_schedule_delivery": ["Schedule Delivery", "\u062c\u062f\u0648\u0644\u0629 \u0627\u0644\u062a\u0648\u0635\u064a\u0644"],
    "portal_receipt_failed": ["Failed to generate receipt: {error}", "\u0641\u0634\u0644 \u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u0625\u064a\u0635\u0627\u0644: {error}"],

    // Expenses
    "expense_upload_failed": ["Failed to upload attachment: {error}", "\u0641\u0634\u0644 \u0631\u0641\u0639 \u0627\u0644\u0645\u0631\u0641\u0642: {error}"],
    "expense_total_items": ["Total Expenses ({count} items):", "\u0625\u062c\u0645\u0627\u0644\u064a \u0627\u0644\u0645\u0635\u0631\u0648\u0641\u0627\u062a ({count} \u0639\u0646\u0627\u0635\u0631):"],
    "expense_approved": ["Approved", "\u0645\u0648\u0627\u0641\u0642 \u0639\u0644\u064a\u0647"],

    // License
    "license_exported": ["Request file exported: {path}", "\u062a\u0645 \u062a\u0635\u062f\u064a\u0631 \u0645\u0644\u0641 \u0627\u0644\u0637\u0644\u0628: {path}"],
    "license_export_failed": ["Export failed: {error}", "\u0641\u0634\u0644 \u0627\u0644\u062a\u0635\u062f\u064a\u0631: {error}"],
    "license_paste_hint": ["Paste license content or key directly into input field above.", "\u0627\u0644\u0635\u0642 \u0645\u062d\u062a\u0648\u0649 \u0627\u0644\u062a\u0631\u062e\u064a\u0635 \u0623\u0648 \u0627\u0644\u0645\u0641\u062a\u0627\u062d \u0641\u064a \u062d\u0642\u0644 \u0627\u0644\u0625\u062f\u062e\u0627\u0644 \u0623\u0639\u0644\u0627\u0647."],

    // Operator
    "operator_no_employees": ["No employees found to certify. Add employees first.", "\u0644\u0627 \u064a\u0648\u062c\u062f \u0645\u0648\u0638\u0641\u0648\u0646 \u0644\u0644\u0627\u0639\u062a\u0645\u0627\u062f. \u0623\u0636\u0641 \u0645\u0648\u0638\u0641\u064a\u0646 \u0623\u0648\u0644\u0627\u064b."],
    "operator_issue_cert_title": ["Issue Operator Certification", "\u0625\u0635\u062f\u0627\u0631 \u0634\u0647\u0627\u062f\u0629 \u0627\u0644\u0645\u0634\u063a\u0644"],
    "operator_change_issue_date": ["Change Issue Date", "\u062a\u063a\u064a\u064a\u0631 \u062a\u0627\u0631\u064a\u062e \u0627\u0644\u0625\u0635\u062f\u0627\u0631"],
    "operator_change_expiry": ["Change Expiration Date", "\u062a\u063a\u064a\u064a\u0631 \u062a\u0627\u0631\u064a\u062e \u0627\u0644\u0627\u0646\u062a\u0647\u0627\u0621"],
    "operator_issue_cert_btn": ["Issue Certificate", "\u0625\u0635\u062f\u0627\u0631 \u0627\u0644\u0634\u0647\u0627\u062f\u0629"],
    "operator_certified_success": ["Operator certified successfully", "\u062a\u0645 \u0627\u0639\u062a\u0645\u0627\u062f \u0627\u0644\u0645\u0634\u063a\u0644 \u0628\u0646\u062c\u0627\u062d"],
    "operator_certify_failed": ["Failed to certify: {error}", "\u0641\u0634\u0644 \u0627\u0644\u0627\u0639\u062a\u0645\u0627\u062f: {error}"],
    "operator_certify_btn": ["Certify Operator", "\u0627\u0639\u062a\u0645\u0627\u062f \u0627\u0644\u0645\u0634\u063a\u0644"],

    // Pending Invoices
    "pending_payment_method": ["Payment Method", "\u0637\u0631\u064a\u0642\u0629 \u0627\u0644\u062f\u0641\u0639"],
    "pending_cash": ["Cash", "\u0646\u0642\u062f\u064a"],
    "pending_card": ["Card", "\u0628\u0637\u0627\u0642\u0629"],
    "pending_cheque": ["Cheque", "\u0634\u064a\u0643"],
    "pending_bank_transfer": ["Bank Transfer", "\u062a\u062d\u0648\u064a\u0644 \u0628\u0646\u0643\u064a"],
    "pending_payment_posted": ["Payment of AED {amount} posted successfully", "\u062a\u0645 \u062a\u0633\u062c\u064a\u0644 \u062f\u0641\u0639\u0629 \u0628\u0642\u064a\u0645\u0629 {amount} \u062f\u0631\u0647\u0645 \u0628\u0646\u062c\u0627\u062d"],
    "pending_payment_failed": ["Failed to post payment: {error}", "\u0641\u0634\u0644 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u0641\u0639\u0629: {error}"],
    "pending_receipt_options": ["Receipt Options", "\u062e\u064a\u0627\u0631\u0627\u062a \u0627\u0644\u0625\u064a\u0635\u0627\u0644"],
    "pending_view_thermal": ["View Thermal Receipt Preview", "\u0645\u0639\u0627\u064a\u0646\u0629 \u0625\u064a\u0635\u0627\u0644 \u062d\u0631\u0627\u0631\u064a"],
    "pending_thermal_desc": ["Text format with 5% VAT breakdown", "\u062a\u0646\u0633\u064a\u0642 \u0646\u0635\u064a \u0645\u0639 \u062a\u0641\u0635\u064a\u0644 \u0636\u0631\u064a\u0628\u0629 5%"],
    "pending_a4_invoice": ["Generate & View A4 Tax Invoice", "\u0625\u0646\u0634\u0627\u0621 \u0648\u0639\u0631\u0636 \u0641\u0627\u062a\u0648\u0631\u0629 \u0636\u0631\u064a\u0628\u064a\u0629 A4"],
    "pending_thermal_title": ["Thermal Receipt", "\u0625\u064a\u0635\u0627\u0644 \u062d\u0631\u0627\u0631\u064a"],
};

let addedEn = 0, addedAr = 0;
for (const [key, [enVal, arVal]] of Object.entries(newKeys3)) {
    if (!en[key]) { en[key] = enVal; addedEn++; }
    if (!ar[key]) { ar[key] = arVal; addedAr++; }
}
fs.writeFileSync(enPath, JSON.stringify(en, null, 4) + '\n', 'utf8');
fs.writeFileSync(arPath, JSON.stringify(ar, null, 4) + '\n', 'utf8');
console.log(`Keys injected: +${addedEn} en, +${addedAr} ar (${Object.keys(en).length} total)`);

function replaceInFile(filePath, replacements) {
    if (!fs.existsSync(filePath)) { console.log(`  [SKIP] ${filePath}`); return 0; }
    let content = fs.readFileSync(filePath, 'utf8');
    let count = 0;
    for (const [old, rep] of replacements) {
        if (content.includes(old)) { content = content.replace(old, rep); count++; }
    }
    if (count > 0) { fs.writeFileSync(filePath, content, 'utf8'); console.log(`  [${count}] ${path.basename(filePath)}`); }
    return count;
}

let total = 0;

// accounting_screen.dart
total += replaceInFile(path.join(projectRoot, 'lib/views/accounting_screen.dart'), [
    ["child: Text('QuickBooks IIF')", "child: Text(l10n.t('accounting_quickbooks_iif'))"],
    ["title: Text('Standard Output VAT (5%)')", "title: Text(l10n.t('accounting_output_vat'))"],
    ["title: Text('Recoverable Input VAT (5%)')", "title: Text(l10n.t('accounting_input_vat'))"],
]);

// channels_screen.dart
total += replaceInFile(path.join(projectRoot, 'lib/views/channels_screen.dart'), [
    ["child: Text('WhatsApp Business API')", "child: Text(l10n.t('channel_whatsapp'))"],
    ["child: Text('Transactional SMS')", "child: Text(l10n.t('channel_sms'))"],
    ["child: Text('Transactional Email')", "child: Text(l10n.t('channel_email_transactional'))"],
    ["child: Text('Twilio SMS / WhatsApp')", "child: Text(l10n.t('channel_twilio'))"],
    ["child: Text('Infobip MENA Gateway')", "child: Text(l10n.t('channel_infobip'))"],
    ["child: Text('Internal Stub (Diagnostic)')", "child: Text(l10n.t('channel_stub'))"],
    ["const Text('No channels configured yet.', style: TextStyle(color: Colors.grey))", "Text(l10n.t('channel_no_channels'), style: const TextStyle(color: Colors.grey))"],
]);

// customer_portal_screen.dart
total += replaceInFile(path.join(projectRoot, 'lib/views/customer_portal_screen.dart'), [
    ["Text('Request Home Delivery / Pickup')", "Text(l10n.t('portal_request_delivery'))"],
    ["content: Text('Delivery request booked! Driver will contact before arrival.')", "content: Text(l10n.t('portal_delivery_booked'))"],
    ["child: const Text('Confirm Delivery Request')", "child: Text(l10n.t('portal_confirm_delivery'))"],
    ["label: const Text('Download Receipt', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold))", "label: Text(l10n.t('portal_download_receipt'), style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold))"],
    ["label: const Text('Schedule Delivery', style: TextStyle(fontWeight: FontWeight.bold))", "label: Text(l10n.t('portal_schedule_delivery'), style: const TextStyle(fontWeight: FontWeight.bold))"],
    ["SnackBar(content: Text('Failed to generate receipt: $e'))", "SnackBar(content: Text(l10n.t('portal_receipt_failed').replaceAll('{error}', e.toString())))"],
]);

// expenses_screen.dart
total += replaceInFile(path.join(projectRoot, 'lib/views/expenses_screen.dart'), [
    ["SnackBar(content: Text('Failed to upload attachment: $e'))", "SnackBar(content: Text(l10n.t('expense_upload_failed').replaceAll('{error}', e.toString())))"],
    ["const ButtonSegment(value: 'approved', label: Text('Approved'))", "ButtonSegment(value: 'approved', label: Text(l10n.t('expense_approved')))"],
]);

// license_screen.dart
total += replaceInFile(path.join(projectRoot, 'lib/views/license_screen.dart'), [
    ["const SnackBar(content: Text('Paste license content or key directly into input field above.'))", "SnackBar(content: Text(l10n.t('license_paste_hint')))"],
]);

// operator_screen.dart
total += replaceInFile(path.join(projectRoot, 'lib/views/operator_screen.dart'), [
    ["content: Text('No employees found to certify. Add employees first.')", "content: Text(l10n.t('operator_no_employees'))"],
    ["Text('Issue Operator Certification', style: TextStyle(fontSize: 18))", "Text(l10n.t('operator_issue_cert_title'), style: const TextStyle(fontSize: 18))"],
    ["label: const Text('Change Issue Date')", "label: Text(l10n.t('operator_change_issue_date'))"],
    ["label: const Text('Change Expiration Date')", "label: Text(l10n.t('operator_change_expiry'))"],
    ["child: const Text('Issue Certificate')", "child: Text(l10n.t('operator_issue_cert_btn'))"],
    ["content: Text('Operator certified successfully')", "content: Text(l10n.t('operator_certified_success'))"],
    ["content: Text('Failed to certify: $e')", "content: Text(l10n.t('operator_certify_failed').replaceAll('{error}', e.toString()))"],
    ["label: const Text('Certify Operator')", "label: Text(l10n.t('operator_certify_btn'))"],
]);

// pending_invoices_screen.dart
total += replaceInFile(path.join(projectRoot, 'lib/views/pending_invoices_screen.dart'), [
    ["child: Text('Cash / \u0646\u0642\u062f\u064a')", "child: Text(l10n.t('pending_cash'))"],
    ["child: Text('Card / \u0628\u0637\u0627\u0642\u0629 \u0627\u0626\u062a\u0645\u0627\u0646')", "child: Text(l10n.t('pending_card'))"],
    ["child: Text('Cheque / \u0634\u064a\u0643')", "child: Text(l10n.t('pending_cheque'))"],
    ["child: Text('Bank Transfer / \u062a\u062d\u0648\u064a\u0644 \u0628\u0646\u0643\u064a')", "child: Text(l10n.t('pending_bank_transfer'))"],
    ["Text('Payment Method / \u0637\u0631\u064a\u0642\u0629 \u0627\u0644\u062f\u0641\u0639:', style: Theme.of(context).textTheme.bodySmall)", "Text(l10n.t('pending_payment_method'), style: Theme.of(context).textTheme.bodySmall)"],
    ["title: const Text('View Thermal Receipt Preview')", "title: Text(l10n.t('pending_view_thermal'))"],
    ["subtitle: const Text('Text format with 5% VAT breakdown')", "subtitle: Text(l10n.t('pending_thermal_desc'))"],
    ["title: const Text('Generate & View A4 Tax Invoice')", "title: Text(l10n.t('pending_a4_invoice'))"],
]);

console.log(`\nBatch 3 total replacements: ${total}`);
