import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart' as logging;

import '../utils/utils.dart';
import '../dive_computer_ffi_bindings_generated.dart';
import '../../types/computer.dart';

class Interfaces {
  final DiveComputerFfiBindings bindings;
  final ffi.Pointer<ffi.Pointer<dc_context_t>> context;
  final logging.Logger log;

  Interfaces({
    required this.bindings,
    required this.context,
    required this.log,
  });

  ffi.Pointer<dc_iostream_t> connect(
      ComputerTransport transport, ffi.Pointer<dc_descriptor_t> computer) {
    switch (transport) {
      case ComputerTransport.serial:
        return _connectSerial(computer);
      case ComputerTransport.usb:
        return _connectUsb(computer);
      case ComputerTransport.usbhid:
        return _connectUsbHid(computer);
      case ComputerTransport.ble:
      case ComputerTransport.bluetooth:
        return _connectBluetooth(computer);
      default:
        throw UnimplementedError();
    }
  }

  ffi.Pointer<dc_iostream_t> _connectSerial(
      ffi.Pointer<dc_descriptor_t> computer) {
    final iterator = calloc<ffi.Pointer<dc_iterator_t>>();

    handleResult(
      bindings.dc_serial_iterator_new(iterator, context.value, computer),
      'serial connection',
    );

    final names = <ffi.Pointer<Utf8>>[];

    int result;
    final desc = calloc<ffi.Pointer<dc_serial_device_t>>();
    while ((result = bindings.dc_iterator_next(iterator.value, desc.cast())) ==
        dc_status_t.DC_STATUS_SUCCESS) {
      final ffi.Pointer<Utf8> name =
          bindings.dc_serial_device_get_name(desc.value).cast();
      names.add(name);

      bindings.dc_serial_device_free(desc.value);
    }
    handleResult(result, 'iterator next');
    log.info(
      'Serial devices: ${names.map((e) => e.toDartString()).join(', ')}',
    );

    handleResult(
      bindings.dc_iterator_free(iterator.value),
      'iterator freeing',
    );

    if (names.isEmpty) {
      handleResult(dc_status_t.DC_STATUS_NODEVICE);
    }

    // ### Connecting to the device ### //
    final iostream = calloc<ffi.Pointer<dc_iostream_t>>();

    handleResult(
      bindings.dc_serial_open(
        iostream,
        context.value,
        names[0].cast(),
      ),
      'serial open',
    );

    return iostream.value;
  }

  ffi.Pointer<dc_iostream_t> _connectUsb(
      ffi.Pointer<dc_descriptor_t> computer) {
    final iterator = calloc<ffi.Pointer<dc_iterator_t>>();

    handleResult(
      bindings.dc_usb_iterator_new(iterator, context.value, computer),
      'usb connection',
    );

    final desc = calloc<ffi.Pointer<dc_usb_device_t>>();
    while (bindings.dc_iterator_next(iterator.value, desc.cast()) ==
        dc_status_t.DC_STATUS_SUCCESS) {
      break;
    }

    handleResult(
      bindings.dc_iterator_free(iterator.value),
      'iterator freeing',
    );

    if (desc.value == ffi.nullptr) {
      handleResult(dc_status_t.DC_STATUS_NODEVICE);
    }

    String vidHex = bindings
        .dc_usb_device_get_vid(desc.value)
        .toRadixString(16)
        .padLeft(4, '0');
    String pidHex = bindings
        .dc_usb_device_get_pid(desc.value)
        .toRadixString(16)
        .padLeft(4, '0');

    log.info('Opening USB device for $vidHex:$pidHex');

    final iostream = calloc<ffi.Pointer<dc_iostream_t>>();
    handleResult(
      bindings.dc_usb_open(
        iostream,
        context.value,
        desc.value,
      ),
      'usbhid open',
    );

    bindings.dc_usb_device_free(desc.value);

    return iostream.value;
  }

  ffi.Pointer<dc_iostream_t> _connectUsbHid(
      ffi.Pointer<dc_descriptor_t> computer) {
    final iterator = calloc<ffi.Pointer<dc_iterator_t>>();

    handleResult(
      bindings.dc_usbhid_iterator_new(iterator, context.value, computer),
      'usbhid connection',
    );

    final desc = calloc<ffi.Pointer<dc_usbhid_device_t>>();
    while (bindings.dc_iterator_next(iterator.value, desc.cast()) ==
        dc_status_t.DC_STATUS_SUCCESS) {
      break;
    }

    handleResult(
      bindings.dc_iterator_free(iterator.value),
      'iterator freeing',
    );

    if (desc.value == ffi.nullptr) {
      handleResult(dc_status_t.DC_STATUS_NODEVICE);
    }

    String vidHex = bindings
        .dc_usbhid_device_get_vid(desc.value)
        .toRadixString(16)
        .padLeft(4, '0');
    String pidHex = bindings
        .dc_usbhid_device_get_pid(desc.value)
        .toRadixString(16)
        .padLeft(4, '0');

    log.info('Opening USB HID device for $vidHex:$pidHex');

    final iostream = calloc<ffi.Pointer<dc_iostream_t>>();
    handleResult(
      bindings.dc_usbhid_open(
        iostream,
        context.value,
        desc.value,
      ),
      'usbhid open',
    );

    bindings.dc_usbhid_device_free(desc.value);

    return iostream.value;
  }

  ffi.Pointer<dc_iostream_t> _connectBluetooth(
      ffi.Pointer<dc_descriptor_t> computer) {
    final iterator = calloc<ffi.Pointer<dc_iterator_t>>();

    handleResult(
      bindings.dc_bluetooth_iterator_new(iterator, context.value, computer),
      'bluetooth connection',
    );

    final iostream = calloc<ffi.Pointer<dc_iostream_t>>();
    return iostream.value;
  }
}
