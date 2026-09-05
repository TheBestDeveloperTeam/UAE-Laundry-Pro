import 'dart:async';

import 'package:laundrypro_uae/peripherals/core/scanner/scanner_models.dart';

class ScannerEventBus {
  final StreamController<ScannerPacketModel> _controller =
      StreamController<ScannerPacketModel>.broadcast();

  Stream<ScannerPacketModel> get stream => _controller.stream;

  void publish(ScannerPacketModel packet) => _controller.add(packet);
}
