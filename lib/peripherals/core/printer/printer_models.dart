class PrinterDeviceModel {
  PrinterDeviceModel({
    required this.name,
    required this.isDefault,
    required this.driverName,
    required this.portName,
  });

  final String name;
  final bool isDefault;
  final String driverName;
  final String portName;

  factory PrinterDeviceModel.fromMap(Map<String, dynamic> map) {
    return PrinterDeviceModel(
      name: map['Name']?.toString() ?? 'Unknown',
      isDefault: map['Default'] == true,
      driverName: map['DriverName']?.toString() ?? 'Unknown',
      portName: map['PortName']?.toString() ?? 'Unknown',
    );
  }
}

class PrintJobModel {
  PrintJobModel({
    required this.printerName,
    required this.connectionType,
    required this.payload,
  });

  final String printerName;
  final String connectionType;
  final List<int> payload;
}
