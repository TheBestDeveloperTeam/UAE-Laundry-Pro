import 'dart:convert';

class ScannerPacketModel {
  ScannerPacketModel({
    required this.deviceName,
    required this.deviceType,
    required this.connectionType,
    required this.rawData,
    required this.decodedValue,
    required this.hexData,
    required this.timestamp,
    required this.latencyMs,
  });

  final String deviceName;
  final String deviceType;
  final String connectionType;
  final String rawData;
  final String decodedValue;
  final String hexData;
  final DateTime timestamp;
  final int latencyMs;

  Map<String, dynamic> toJson() => {
        'deviceName': deviceName,
        'deviceType': deviceType,
        'connectionType': connectionType,
        'rawData': rawData,
        'decodedValue': decodedValue,
        'hexData': hexData,
        'timestamp': timestamp.toIso8601String(),
        'latencyMs': latencyMs,
      };

  String asPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
