class ScannerDeviceModel {
  ScannerDeviceModel({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.isConnected,
  });

  final String id;
  final String name;
  final String connectionType;
  final bool isConnected;
}
