import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceCache {
  final _cache = <int, BluetoothDevice?>{};
  int _bluetoothDeviceId = -1;

  BluetoothDeviceCache._privateConstructor();

  static final BluetoothDeviceCache _instance =
      BluetoothDeviceCache._privateConstructor();

  factory BluetoothDeviceCache() {
    return _instance;
  }

  void addBluetoothDevice(BluetoothDevice device) {
    _cache[device.hashCode] = device;
    _bluetoothDeviceId = device.hashCode;
  }

  BluetoothDevice? getBluetoothDevice() {
    return _cache[_bluetoothDeviceId];
  }
}

final BluetoothDeviceCache bluetoothDeviceCache = BluetoothDeviceCache();

class Computer {
  final String vendor, product;
  final List<ComputerTransport> transports;

  Computer(
    this.vendor,
    this.product, {
    this.transports = const [],
  });

  @override
  String toString() =>
      '$vendor $product [${transports.map((t) => t.name).join(', ')}]';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Computer &&
          runtimeType == other.runtimeType &&
          vendor == other.vendor &&
          product == other.product;

  @override
  int get hashCode {
    // hash codes are not equal across isolates, so we need to generate a
    // consistent hash code for each computer
    return '$vendor $product'.codeUnits.fold(1, (a, b) => a * b);
  }
}

enum ComputerTransport { serial, usb, usbhid, irda, bluetooth, ble }
