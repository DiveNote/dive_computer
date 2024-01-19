import 'package:dive_computer/types/computer.dart';

List<ComputerTransport> parseTransportsBitmask(int transportsBitmask) {
  final transports = <ComputerTransport>[];

  if (transportsBitmask & 1 << 0 != 0) {
    transports.add(ComputerTransport.serial);
  }
  if (transportsBitmask & 1 << 1 != 0) {
    transports.add(ComputerTransport.usb);
  }
  if (transportsBitmask & 1 << 2 != 0) {
    transports.add(ComputerTransport.usbhid);
  }
  if (transportsBitmask & 1 << 3 != 0) {
    transports.add(ComputerTransport.irda);
  }
  if (transportsBitmask & 1 << 4 != 0) {
    transports.add(ComputerTransport.bluetooth);
  }
  if (transportsBitmask & 1 << 5 != 0) {
    transports.add(ComputerTransport.ble);
  }

  return transports;
}

int bitmaskFromTransport(ComputerTransport transport) {
  switch (transport) {
    case ComputerTransport.serial:
      return 1 << 0;
    case ComputerTransport.usb:
      return 1 << 1;
    case ComputerTransport.usbhid:
      return 1 << 2;
    case ComputerTransport.irda:
      return 1 << 3;
    case ComputerTransport.bluetooth:
      return 1 << 4;
    case ComputerTransport.ble:
      return 1 << 5;
    default:
      throw ArgumentError('Unknown transport: $transport');
  }
}
