import 'package:laundrypro_uae/peripherals/core/logging/app_logger.dart';
import 'package:laundrypro_uae/peripherals/core/scanner/scanner_models.dart';

class ScannerRepository {
  ScannerRepository({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  Future<void> persistPacket(ScannerPacketModel packet) async {
    await _logger.info(
      'Scanner packet persisted',
      scope: 'scanner_repository',
      payload: packet.toJson(),
    );
  }
}
