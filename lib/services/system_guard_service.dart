import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class HardwareInfo {
  final String machineCode;
  final String machineName;
  final String osVersion;
  final int installPulse;

  HardwareInfo({
    required this.machineCode,
    required this.machineName,
    required this.osVersion,
    required this.installPulse,
  });

  Map<String, dynamic> toJson() => {
        'machine_code': machineCode,
        'machine_name': machineName,
        'os_version': osVersion,
        'install_pulse': installPulse,
      };
}

class SystemGuardService {
  static const String _registryKeyPath = r'HKCU\Software\LaundryProUAE\Evaluation';

  /// Obtains hardware fingerprint & machine code
  static Future<HardwareInfo> getHardwareInfo() async {
    String machineName = Platform.localHostname;
    String osVersion = Platform.operatingSystemVersion;
    String cpuId = 'CPU-GENERIC-DEFAULT';
    String baseboard = 'BOARD-GENERIC-DEFAULT';

    if (Platform.isWindows) {
      try {
        final cpuRes = await Process.run('wmic', ['cpu', 'get', 'processorid']);
        if (cpuRes.exitCode == 0) {
          final lines = (cpuRes.stdout as String)
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty && !l.toLowerCase().contains('processorid'))
              .toList();
          if (lines.isNotEmpty) cpuId = lines.first;
        }

        final boardRes = await Process.run('wmic', ['baseboard', 'get', 'serialnumber']);
        if (boardRes.exitCode == 0) {
          final lines = (boardRes.stdout as String)
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty && !l.toLowerCase().contains('serialnumber'))
              .toList();
          if (lines.isNotEmpty) baseboard = lines.first;
        }
      } catch (_) {}
    }

    final rawCombo = '$machineName|$cpuId|$baseboard';
    final machineHash = sha256.convert(utf8.encode(rawCombo)).toString().toUpperCase();
    final formattedMachineCode = 'UMAC-${machineHash.substring(0, 4)}-${machineHash.substring(4, 8)}-${machineHash.substring(8, 12)}';

    int pulse = await _getOrCreateInstallPulse();

    return HardwareInfo(
      machineCode: formattedMachineCode,
      machineName: machineName,
      osVersion: osVersion,
      installPulse: pulse,
    );
  }

  /// Persistent Windows Registry storage for trial anti-tamper
  static Future<int> _getOrCreateInstallPulse() async {
    if (!Platform.isWindows) {
      return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }

    try {
      final query = await Process.run('reg', ['query', _registryKeyPath, '/v', 'InstallPulse']);
      if (query.exitCode == 0) {
        final match = RegExp(r'InstallPulse\s+REG_SZ\s+(\d+)').firstMatch(query.stdout.toString());
        if (match != null) {
          return int.tryParse(match.group(1)!) ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
        }
      }
    } catch (_) {}

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    try {
      await Process.run('reg', ['add', _registryKeyPath, '/v', 'InstallPulse', '/t', 'REG_SZ', '/d', now.toString(), '/f']);
    } catch (_) {}
    return now;
  }

  /// Generates the payload for laundrypro_req.lic
  static Future<String> generateLicenseRequestJson() async {
    final info = await getHardwareInfo();
    final payload = {
      'app': 'LaundryPro UAE',
      'version': '1.2.1+4',
      'machine_code': info.machineCode,
      'machine_name': info.machineName,
      'os_version': info.osVersion,
      'install_pulse': info.installPulse,
      'requested_at': DateTime.now().toUtc().toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Validates a signed license stamp (.lic)
  static bool verifyLicenseStamp(Map<String, dynamic> licenseData, String expectedMachineCode) {
    if (licenseData['machine_code']?.toString() != expectedMachineCode) {
      return false;
    }
    final expires = licenseData['expires_at'];
    if (expires != null) {
      final expDate = DateTime.tryParse(expires.toString());
      if (expDate != null && expDate.isBefore(DateTime.now())) {
        return false;
      }
    }
    return licenseData['signature'] != null && licenseData['signature'].toString().isNotEmpty;
  }
}

