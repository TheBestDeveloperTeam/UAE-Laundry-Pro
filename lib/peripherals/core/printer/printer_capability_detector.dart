import 'package:laundrypro_uae/peripherals/core/printer/printer_models.dart';

class PrinterCapabilityDetector {
  Map<String, dynamic> detect(PrinterDeviceModel device) {
    final port = device.portName.toUpperCase();
    final isNetwork = port.contains('IP_') || port.contains('TCP');
    final isUsb = port.contains('USB');
    final isEscPosLikely = isNetwork || isUsb || device.driverName.toLowerCase().contains('pos');
    return {
      'printerName': device.name,
      'isNetwork': isNetwork,
      'isUsb': isUsb,
      'supportsEscPosLikely': isEscPosLikely,
      'rawTcpPort': isNetwork ? 9100 : null,
    };
  }
}
