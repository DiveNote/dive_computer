class Computer {
  Computer(this.vendor, this.product, {this.transports = const []});

  final String vendor, product;
  final List<ComputerTransport> transports;

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
