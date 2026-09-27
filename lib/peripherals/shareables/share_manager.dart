import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ShareManager {
  Future<void> shareReceipt(String filePath, String text) async {
    await Share.shareXFiles([XFile(filePath)], text: text);
  }

  Future<void> shareViaWhatsApp(String phone, String text) async {
    final url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(text)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch WhatsApp');
    }
  }

  Future<void> shareViaEmail(String email, String subject, String body) async {
    final url = Uri.parse("mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

final shareManagerProvider = Provider<ShareManager>((ref) {
  return ShareManager();
});
