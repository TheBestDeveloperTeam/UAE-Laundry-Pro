import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class ShareManager {
  
  /// Generates a rich PDF receipt digitally and shares it via OS native share modal
  Future<void> shareDigitalReceipt(Map<String, dynamic> invoiceData) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Laundry Pro UAE - Receipt", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text("Invoice ID: ${invoiceData['id']}"),
              pw.Text("Customer: ${invoiceData['customer']}"),
              pw.SizedBox(height: 20),
              pw.Text("Total: AED ${invoiceData['total']}", style: pw.TextStyle(fontSize: 18)),
            ]
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/receipt_${invoiceData['id']}.pdf");
    await file.writeAsBytes(await pdf.save());

    // Deep dive OS native share modal (iOS UIActivityViewController / Android Intent.ACTION_SEND)
    await Share.shareXFiles(
      [XFile(file.path)], 
      text: 'Your digital receipt from Laundry Pro UAE is attached.'
    );
  }

  /// Deep dive WhatsApp specific deep-linking for seamless social receipt delivery
  Future<void> shareViaWhatsApp(String phoneNumber, String message) async {
    // Standardize phone number for WhatsApp API
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (!cleanPhone.startsWith('971') && cleanPhone.startsWith('05')) {
      cleanPhone = '971${cleanPhone.substring(1)}';
    }
    
    final uri = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("WhatsApp protocol not supported or installed on this device.");
    }
  }

  /// Deep dive SMTP/Mailto protocol wrapper
  Future<void> shareViaEmail(String email, String subject, String body) async {
    final uri = Uri.parse("mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception("No mail client installed.");
    }
  }
}

final shareManagerProvider = Provider<ShareManager>((ref) {
  return ShareManager();
});
