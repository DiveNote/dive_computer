import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Computer {
  Computer(
    this.vendor,
    this.product, {
    this.transports = const [],
  });

  final String vendor, product;
  final List<ComputerTransport> transports;
  BluetoothDevice? device;

  void addBleDevice(BluetoothDevice device) {
    this.device = device;
  }

  @override
  String toString() =>
      '$vendor $product ${device != null ? device.toString() : ''} [${transports.map((t) => t.name).join(', ')}]';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Computer &&
          runtimeType == other.runtimeType &&
          vendor == other.vendor &&
          product == other.product &&
          device == other.device;

  @override
  int get hashCode {
    // hash codes are not equal across isolates, so we need to generate a
    // consistent hash code for each computer
    return '$vendor $product'.codeUnits.fold(1, (a, b) => a * b);
  }
}

enum ComputerTransport { serial, usb, usbhid, irda, bluetooth, ble }
