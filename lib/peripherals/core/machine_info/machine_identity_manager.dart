import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:laundrypro_uae/peripherals/core/logging/app_logger.dart';

class MachineIdentityManager {
  MachineIdentityManager({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  Future<Map<String, dynamic>> readIdentity() async {
    final computerName = Platform.localHostname;
    final cpu = await _runJson(
      'Get-CimInstance Win32_Processor | Select-Object Name,ProcessorId,NumberOfCores | ConvertTo-Json',
    );
    final bios = await _runJson(
      'Get-CimInstance Win32_BIOS | Select-Object Manufacturer,SerialNumber,SMBIOSBIOSVersion | ConvertTo-Json',
    );
    final baseBoard = await _runJson(
      'Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer,Product,SerialNumber | ConvertTo-Json',
    );
    final memory = await _runJson(
      'Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer,Capacity,SerialNumber | ConvertTo-Json',
    );
    final network = await _runJson(
      'Get-NetAdapter | Select-Object Name,MacAddress,Status,InterfaceDescription | ConvertTo-Json',
    );
    final storage = await _runJson(
      'Get-PhysicalDisk | Select-Object FriendlyName,SerialNumber,MediaType,Size | ConvertTo-Json',
    );
    final printers = await _runJson(
      'Get-Printer | Select-Object Name,PortName,DriverName | ConvertTo-Json',
    );
    final comPorts = await _runJson(
      'Get-CimInstance Win32_SerialPort | Select-Object DeviceID,Name,Description | ConvertTo-Json',
    );
    final usbDevices = await _runJson(
      'Get-PnpDevice -PresentOnly | Where-Object { \$_.Class -eq "USB" } | Select-Object FriendlyName,InstanceId,Status | ConvertTo-Json -Depth 4',
    );

    final payload = <String, dynamic>{
      'computerName': computerName,
      'cpu': cpu,
      'bios': bios,
      'motherboard': baseBoard,
      'memory': memory,
      'networkAdapters': network,
      'storage': storage,
      'printers': printers,
      'comPorts': comPorts,
      'usbDevices': usbDevices,
    };
    payload['fingerprintSha256'] = _fingerprint(payload);
    await _logger.info('Machine identity refreshed', scope: 'machine_info');
    return payload;
  }

  Future<dynamic> _runJson(String cmd) async {
    final result = await Process.run('powershell', ['-NoProfile', '-Command', cmd]);
    if (result.exitCode != 0) {
      return {'error': result.stderr.toString()};
    }
    final text = result.stdout.toString().trim();
    if (text.isEmpty) return {};
    try {
      return jsonDecode(text);
    } catch (_) {
      return {'raw': text};
    }
  }

  String _fingerprint(Map<String, dynamic> payload) {
    final encoded = jsonEncode(payload);
    return sha256.convert(utf8.encode(encoded)).toString();
  }
}
