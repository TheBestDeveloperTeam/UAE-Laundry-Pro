import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ChallanLine {
  ChallanLine({
    required this.description,
    required this.quantity,
    this.notes,
  });

  final String description;
  final double quantity;
  final String? notes;

  factory ChallanLine.fromMap(Map<String, dynamic> map) {
    return ChallanLine(
      description: map['description']?.toString() ?? map['item_name']?.toString() ?? '',
      quantity: double.tryParse(map['quantity']?.toString() ?? '0') ?? 0,
      notes: map['notes']?.toString(),
    );
  }
}

class ChallanModel {
  ChallanModel({
    required this.challanNo,
    required this.challanType,
    required this.status,
    required this.lines,
    this.notes,
    this.referenceType,
    this.referenceId,
  });

  final String challanNo;
  final String challanType;
  final String status;
  final List<ChallanLine> lines;
  final String? notes;
  final String? referenceType;
  final int? referenceId;

  factory ChallanModel.fromMap(Map<String, dynamic> map) {
    final rawLines = map['lines'] as List? ?? [];
    return ChallanModel(
      challanNo: map['challan_no']?.toString() ?? '',
      challanType: map['challan_type']?.toString() ?? 'delivery',
      status: map['status']?.toString() ?? 'issued',
      notes: map['notes']?.toString(),
      referenceType: map['reference_type']?.toString(),
      referenceId: int.tryParse(map['reference_id']?.toString() ?? ''),
      lines: rawLines.map((e) => ChallanLine.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}

class DocumentRenderer {
  static String toThermal(ChallanModel challan, {int width = 48}) {
    final buf = StringBuffer();
    buf.writeln('LaundryPro UAE'.padLeft((width + 14) ~/ 2));
    buf.writeln('Challan: ${challan.challanNo}');
    buf.writeln('Type: ${challan.challanType}');
    buf.writeln('Status: ${challan.status}');
    if (challan.referenceType != null) {
      buf.writeln('Ref: ${challan.referenceType} #${challan.referenceId ?? ''}');
    }
    buf.writeln('-' * width);
    for (final line in challan.lines) {
      buf.writeln(line.description);
      buf.writeln('  Qty: ${line.quantity}');
      if (line.notes != null && line.notes!.isNotEmpty) {
        buf.writeln('  ${line.notes}');
      }
    }
    buf.writeln('-' * width);
    if (challan.notes != null && challan.notes!.isNotEmpty) {
      buf.writeln('Notes: ${challan.notes}');
    }
    return buf.toString();
  }

  static Future<List<int>> toA4Pdf(ChallanModel challan) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('LaundryPro UAE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Challan: ${challan.challanNo}'),
            pw.Text('Type: ${challan.challanType}'),
            pw.Text('Status: ${challan.status}'),
            if (challan.referenceType != null)
              pw.Text('Reference: ${challan.referenceType} #${challan.referenceId ?? ''}'),
            pw.Divider(),
            ...challan.lines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text(line.description)),
                    pw.Text(line.quantity.toStringAsFixed(0)),
                  ],
                ),
              ),
            ),
            pw.Divider(),
            if (challan.notes != null && challan.notes!.isNotEmpty) pw.Text('Notes: ${challan.notes}'),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
