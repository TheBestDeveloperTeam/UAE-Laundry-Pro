import 'dart:typed_data';
import 'package:laundrypro_uae/models/challan_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Abstraction for rendering PDF documents with 3D QR and 2D Barcode
class DocumentRenderer {
  static Future<Uint8List> generateReceipt(Map<String, dynamic> invoiceData) async {
    // Implement pdf package logic here to generate the PDF bytes
    // Including Top-Right 3D QR and Bottom-Right 2D Barcode
    return Uint8List(0); // Placeholder
  }

  static Future<Uint8List> generateCreditMemo(Map<String, dynamic> memoData) async {
    return Uint8List(0); // Placeholder
  }

  static Future<Uint8List> generateChallan(Map<String, dynamic> challanData) async {
    return Uint8List(0); // Placeholder
  }

  static Future<Uint8List> generateReport(
    Map<String, dynamic> reportData, {
    String title = 'Business Management Report',
    String businessName = 'LaundryPro UAE',
    String businessNameAr = 'لاندري برو الإمارات',
    String trn = '100XXXXXXXXX003',
    String dateRange = '',
  }) async {
    final doc = pw.Document();

    // Flatten nested map for table presentation
    final flat = <String, String>{};
    void flatten(String prefix, dynamic value) {
      if (value is Map) {
        for (final e in value.entries) {
          flatten(prefix.isEmpty ? e.key.toString() : '$prefix.${e.key}', e.value);
        }
      } else if (value is List) {
        flat[prefix] = '${value.length} items';
      } else {
        flat[prefix] = value?.toString() ?? '-';
      }
    }
    flatten('', reportData);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(businessName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text(businessNameAr, style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 2),
                    pw.Text('TRN: $trn', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(title.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    if (dateRange.isNotEmpty)
                      pw.Text('Period: $dateRange', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Generated: ${DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' ')}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.blue900),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('LaundryPro UAE Enterprise Management Report', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: ['Metric / Parameter', 'Value'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 9),
            data: flat.entries.map((e) => [e.key.replaceAll('_', ' '), e.value]).toList(),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static String toThermal(ChallanModel item) {
    final sb = StringBuffer();
    sb.writeln('================================');
    sb.writeln('        DELIVERY CHALLAN        ');
    sb.writeln('================================');
    sb.writeln('Challan No : ${item.challanNo}');
    sb.writeln('Type       : ${item.challanType}');
    sb.writeln('Status     : ${item.status}');
    if (item.notes != null && item.notes!.isNotEmpty) {
      sb.writeln('Notes      : ${item.notes}');
    }
    sb.writeln('--------------------------------');
    for (final line in item.lines) {
      sb.writeln('${line.description.padRight(24)} x${line.quantity}');
    }
    sb.writeln('================================');
    return sb.toString();
  }

  static Future<Uint8List> toA4Pdf(dynamic doc) async {
    return Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]);
  }
}
