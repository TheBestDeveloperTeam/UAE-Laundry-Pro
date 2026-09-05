import 'package:laundrypro_uae/peripherals/core/printer/esc_pos_generator.dart';
import 'package:laundrypro_uae/peripherals/core/printer/silent_print_engine.dart';

class DrawerStatusModel {
  DrawerStatusModel({
    required this.connected,
    required this.lastTriggerAt,
  });

  final bool connected;
  final DateTime? lastTriggerAt;
}

class DrawerPulseService {
  DrawerPulseService({required EscPosGenerator generator}) : _generator = generator;

  final EscPosGenerator _generator;

  List<int> buildPulse() => _generator.cashDrawerPulse();
}

class CashDrawerManager {
  CashDrawerManager({
    required DrawerPulseService pulseService,
    required SilentPrintEngine printEngine,
  })  : _pulseService = pulseService,
        _printEngine = printEngine;

  final DrawerPulseService _pulseService;
  final SilentPrintEngine _printEngine;
  DateTime? _lastTriggerAt;

  DrawerStatusModel status({bool connected = true}) =>
      DrawerStatusModel(connected: connected, lastTriggerAt: _lastTriggerAt);

  Future<void> trigger({required String host, required int port}) async {
    await _printEngine.printTcp(
      host: host,
      port: port,
      payload: _pulseService.buildPulse(),
    );
    _lastTriggerAt = DateTime.now().toUtc();
  }
}
