import 'dart:async';

import 'package:laundrypro_uae/peripherals/core/logging/app_logger.dart';
import 'package:laundrypro_uae/peripherals/core/scale/scale_parser.dart';

class ScaleManager {
  ScaleManager({
    required ScaleParser parser,
    required AppLogger logger,
  })  : _parser = parser,
        _logger = logger;

  final ScaleParser _parser;
  final AppLogger _logger;
  final StreamController<ScaleReading> _streamController =
      StreamController<ScaleReading>.broadcast();

  Stream<ScaleReading> get stream => _streamController.stream;

  Future<void> ingestPacket(List<int> bytes) async {
    final reading = _parser.parse(bytes);
    _streamController.add(reading);
    await _logger.info(
      'Scale packet parsed',
      scope: 'scale',
      payload: reading.toJson(),
    );
  }
}
