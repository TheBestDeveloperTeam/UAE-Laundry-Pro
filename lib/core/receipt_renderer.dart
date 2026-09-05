import 'package:laundrypro_uae/core/receipt_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptRenderer {
  static String toThermal(ReceiptModel receipt, {int width = 48}) {
    final buf = StringBuffer();
    buf.writeln('LaundryPro UAE'.padLeft((width + 14) ~/ 2));
    buf.writeln('Order: ${receipt.orderNo}');
    buf.writeln('-' * width);
    for (final line in receipt.lines) {
      buf.writeln(line.description);
      buf.writeln('  ${line.quantity} x ${line.rate} = ${line.amount}');
    }
    buf.writeln('-' * width);
    buf.writeln('Subtotal: ${receipt.subtotal}');
    buf.writeln('Total: ${receipt.grandTotal}');
    buf.writeln('Paid: ${receipt.amountPaid}');
    buf.writeln('Balance: ${receipt.balanceDue}');
    return buf.toString();
  }

  static Future<List<int>> toA4Pdf(ReceiptModel receipt) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('LaundryPro UAE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Order: ${receipt.orderNo}'),
            pw.Divider(),
            ...receipt.lines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text('${line.description} (${line.quantity} x ${line.rate})')),
                    pw.Text(line.amount.toStringAsFixed(2)),
                  ],
                ),
              ),
            ),
            pw.Divider(),
            pw.Text('Subtotal: ${receipt.subtotal.toStringAsFixed(2)}'),
            pw.Text('Total: ${receipt.grandTotal.toStringAsFixed(2)}'),
            pw.Text('Paid: ${receipt.amountPaid.toStringAsFixed(2)}'),
            pw.Text('Balance: ${receipt.balanceDue.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
