import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:laundrypro_uae/peripherals/core/logging/app_logger.dart';
import 'package:laundrypro_uae/peripherals/core/printer/printer_models.dart';

class BluetoothPrinterEngine {
  BluetoothPrinterEngine({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  Future<List<PrinterDeviceModel>> discoverPairedDevices() async {
    try {
      final List<BluetoothInfo> listResult = await PrintBluetoothThermal.pairedBluetooths;
      return listResult.map((e) => PrinterDeviceModel(
        name: e.name,
        driverName: 'Bluetooth Thermal',
        portName: e.macAdress,
        isDefault: false,
      )).toList();
    } catch (e) {
      await _logger.error('Failed to discover bluetooth devices', scope: 'bluetooth_printer', payload: {'error': e.toString()});
      return [];
    }
  }

  Future<void> printViaBluetooth({
    required String macAddress,
    required List<int> payload,
  }) async {
    try {
      final bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      if (!connected) {
        throw Exception('Failed to connect to bluetooth printer at $macAddress');
      }

      final bool result = await PrintBluetoothThermal.writeBytes(payload);
      if (!result) {
        throw Exception('Failed to write bytes to bluetooth printer');
      }

      await PrintBluetoothThermal.disconnect;

      await _logger.info(
        'Bluetooth print completed',
        scope: 'bluetooth_printer_engine',
        payload: {'macAddress': macAddress, 'bytes': payload.length},
      );
    } catch (e) {
      await _logger.error('Bluetooth print failed', scope: 'bluetooth_printer_engine', payload: {'error': e.toString()});
      rethrow;
    }
  }
}
