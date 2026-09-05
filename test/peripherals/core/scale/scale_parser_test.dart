import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/peripherals/core/scale/scale_parser.dart';

void main() {
  test('parses stable packet payload', () {
    final parser = ScaleParser();
    final reading = parser.parse('ST,GS, 2.350 kg'.codeUnits);

    expect(reading.weight, '2.350');
    expect(reading.unit, 'kg');
    expect(reading.stable, true);
  });
}
