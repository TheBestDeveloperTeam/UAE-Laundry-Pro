import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/peripherals/core/scanner/scanner_models.dart';

void main() {
  test('scanner packet serializes expected keys', () {
    final model = ScannerPacketModel(
      deviceName: 'KeyboardWedge',
      deviceType: 'HID',
      connectionType: 'USB/HID',
      rawData: 'ABC123',
      decodedValue: 'ABC123',
      hexData: '41 42 43 31 32 33',
      timestamp: DateTime.utc(2026, 1, 1),
      latencyMs: 20,
    );

    final json = model.toJson();
    expect(json['deviceName'], 'KeyboardWedge');
    expect(json['decodedValue'], 'ABC123');
    expect(json.containsKey('timestamp'), true);
  });
}
