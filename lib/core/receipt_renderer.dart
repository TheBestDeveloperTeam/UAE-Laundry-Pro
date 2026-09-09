import 'package:laundrypro_uae/core/receipt_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptRenderer {
  static String toThermal(
    ReceiptModel receipt, {
    int width = 48,
    String businessName = 'LaundryPro UAE',
    String businessNameAr = 'لاندري برو الإمارات',
    String? trn,
  }) {
    final buf = StringBuffer();
    buf.writeln(businessName.padLeft((width + businessName.length) ~/ 2));
    buf.writeln(businessNameAr.padLeft((width + businessNameAr.length) ~/ 2));
    final activeTrn = trn ?? receipt.trn ?? '100XXXXXXXXX003';
    buf.writeln('TRN / الرقم الضريبي: $activeTrn'.padLeft((width + 25) ~/ 2));
    buf.writeln('=' * width);
    buf.writeln('TAX INVOICE / فاتورة ضريبية');
    buf.writeln('Order / الطلب: ${receipt.orderNo}');
    if (receipt.createdAt != null && receipt.createdAt!.isNotEmpty) {
      buf.writeln('Date / التاريخ: ${receipt.createdAt}');
    }
    if (receipt.customerName != null && receipt.customerName!.isNotEmpty) {
      buf.writeln('Customer / العميل: ${receipt.customerName}');
    }
    if (receipt.customerPhone != null && receipt.customerPhone!.isNotEmpty) {
      buf.writeln('Phone / الهاتف: ${receipt.customerPhone}');
    }
    buf.writeln('-' * width);
    for (final line in receipt.lines) {
      buf.writeln(line.description);
      if (line.modifiers.isNotEmpty) {
        buf.writeln('  [+ ${line.modifiers.join(', ')}]');
      }
      final discInfo = line.discount > 0 ? ' (Disc: -${line.discount.toStringAsFixed(2)})' : '';
      buf.writeln('  ${line.quantity} x ${line.rate.toStringAsFixed(2)}$discInfo = AED ${line.amount.toStringAsFixed(2)}');
    }
    buf.writeln('-' * width);
    buf.writeln('Subtotal / المجموع الفرعي: AED ${receipt.subtotal.toStringAsFixed(2)}');
    if (receipt.discount > 0) {
      buf.writeln('Discount / الخصم: -AED ${receipt.discount.toStringAsFixed(2)}');
    }
    buf.writeln('VAT (5%) / ضريبة القيمة المضافة: AED ${receipt.tax.toStringAsFixed(2)}');
    buf.writeln('Net Total / الإجمالي النهائي: AED ${receipt.grandTotal.toStringAsFixed(2)}');
    buf.writeln('Paid / المدفوع: AED ${receipt.amountPaid.toStringAsFixed(2)}');
    buf.writeln('Balance Due / المبلغ المستحق: AED ${receipt.balanceDue.toStringAsFixed(2)}');
    buf.writeln('=' * width);
    buf.writeln('Thank You / شكراً لزيارتكم'.padLeft((width + 22) ~/ 2));
    return buf.toString();
  }

  static Future<List<int>> toA4Pdf(
    ReceiptModel receipt, {
    String businessName = 'LaundryPro UAE',
    String businessNameAr = 'لاندري برو الإمارات',
    String? trn,
    String? address = 'Dubai, United Arab Emirates',
  }) async {
    final doc = pw.Document();
    final activeTrn = trn ?? receipt.trn ?? '100XXXXXXXXX003';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(businessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text(businessNameAr, style: const pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 4),
                    pw.Text('Address: $address', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('TRN (Tax Registration Number): $activeTrn', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.Text('Invoice #: ${receipt.orderNo}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${receipt.createdAt ?? DateTime.now().toString().substring(0, 10)}', style: const pw.TextStyle(fontSize: 10)),
                    if (receipt.promisedDate != null)
                      pw.Text('Due Date: ${receipt.promisedDate}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.blue900),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Billed To / العميل:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(receipt.customerName ?? 'Walk-In Customer', style: const pw.TextStyle(fontSize: 11)),
                      if (receipt.customerPhone != null)
                        pw.Text('Phone: ${receipt.customerPhone}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Status: ${(receipt.status ?? 'Confirmed').toUpperCase()}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Payment: ${(receipt.paymentStatus ?? 'Pending').toUpperCase()}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: receipt.balanceDue <= 0 ? PdfColors.green800 : PdfColors.red800)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Description', 'Qty', 'Unit Rate (AED)', 'Discount', 'Total (AED)'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellAlignment: pw.Alignment.centerLeft,
              data: List<List<String>>.generate(receipt.lines.length, (index) {
                final line = receipt.lines[index];
                final modSuffix = line.modifiers.isNotEmpty ? ' (+ ${line.modifiers.join(", ")})' : '';
                return [
                  '${index + 1}',
                  '${line.description}$modSuffix',
                  '${line.quantity}',
                  line.rate.toStringAsFixed(2),
                  line.discount > 0 ? line.discount.toStringAsFixed(2) : '-',
                  line.amount.toStringAsFixed(2),
                ];
              }),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 240,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Subtotal:'),
                          pw.Text('AED ${receipt.subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                      if (receipt.discount > 0)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Discount:'),
                            pw.Text('-AED ${receipt.discount.toStringAsFixed(2)}', style: const pw.TextStyle(color: PdfColors.red)),
                          ],
                        ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('UAE VAT (5%):'),
                          pw.Text('AED ${receipt.tax.toStringAsFixed(2)}'),
                        ],
                      ),
                      pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Grand Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                          pw.Text('AED ${receipt.grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue900)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Amount Paid:'),
                          pw.Text('AED ${receipt.amountPaid.toStringAsFixed(2)}'),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Balance Due:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('AED ${receipt.balanceDue.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: receipt.balanceDue > 0 ? PdfColors.red800 : PdfColors.green800)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('This is a computer-generated tax invoice.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                pw.Text('Thank you for choosing LaundryPro UAE!', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ],
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
