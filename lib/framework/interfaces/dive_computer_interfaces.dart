import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart' as logging;

import '../utils/utils.dart';
import '../dive_computer_ffi_bindings_generated.dart';
import '../../types/ble_object.dart';
import '../../types/computer.dart';
import '../../types/dc_iostream_t.dart' as io;

class Interfaces {
  final DiveComputerFfiBindings bindings;
  final ffi.Pointer<ffi.Pointer<dc_context_t>> context;
  final logging.Logger log;

  final BLEObject _bleObject = BLEObject();

  Interfaces({
    required this.bindings,
    required this.context,
    required this.log,
  });

  void dispose() {
    _bleObject.dispose();
  }

  ffi.Pointer<dc_iostream_t> connect(
    Computer computer,
    ComputerTransport transport,
    ffi.Pointer<dc_descriptor_t> computerDescriptor,
    ffi.Pointer<ffi.Pointer<dc_context_t>> context,
  ) {
    switch (transport) {
      case ComputerTransport.serial:
        return _connectSerial(computerDescriptor);
      case ComputerTransport.usb:
        return _connectUsb(computerDescriptor);
      case ComputerTransport.usbhid:
        return _connectUsbHid(computerDescriptor);
      case ComputerTransport.ble:
        return _connectBle(computer, computerDescriptor, context);
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

  ffi.Pointer<dc_iostream_t> _connectBle(
    Computer computer,
    ffi.Pointer<dc_descriptor_t> computerDescriptor,
    ffi.Pointer<ffi.Pointer<dc_context_t>> context,
  ) {
    handleResult(
        computer.device == null
            ? dc_status_t.DC_STATUS_NODEVICE
            : dc_status_t.DC_STATUS_SUCCESS,
        'No device found');

    //DONE  1. get dc_descriptor_t for device <- downloadfromdcthread.cpp line 90 <- LIBDIVECOMPUTER
    //      2. do_libdivecomputer_import <- downloadfromdcthread.cpp line 117
    //DONE      a. dc_context_new, libdivecompute.c line 1512 <- LIBDIVECOMPUTER
    //          b. divecomputer_device_open, libdivecompute.c line 1525
    //              BT: (most likely not supported with iOS and definitly not supported by flutter_blue_plus)
    //                I. rfcomm_stream_open, libdivecompute.c line 1420
    //              BLE:
    //                I. ble_packet_open, libdivecompute.c line 1432
    //                  a. qt_ble_open, qtserialbluetooth.cpp line 303
    //                      1. connectToDevice, qt-ble.cpp line 585
    //                      2. discoverServices, qt-ble.cpp line 630
    //DONE                  3. select_preferred_service, qt-ble.cpp line 638 <- The service which is providing read and write access
    //DONE                  4. get ClientCharacteristicConfiguration descriptor and write 0x0100 to enable notifications, qt-ble.cpp line 658-677
    //                      5. assign BLEObject to iostream, qt-ble.cpp line 689
    //                  b. dc_custom_open, qtserialbluetooth.cpp line 308  <- LIBDIVECOMPUTER
    //                      1. dc_iostream_allocate, custom.c line 84 <- LIBDIVECOMPUTER

    final iostream = calloc<ffi.Pointer<dc_iostream_t>>();
    _bleOpen(computer, context, iostream);

    log.info('Opening BLE device for ${computer.device!.platformName}');

    return iostream.value;
  }

  void _bleOpen(
    Computer computer,
    ffi.Pointer<ffi.Pointer<dc_context_t>> context,
    ffi.Pointer<ffi.Pointer<dc_iostream_t>> iostream,
  ) async {
    int status = dc_status_t.DC_STATUS_SUCCESS;
    _bleObject.selectPreferredService(computer.device!, status);
    handleResult(status, 'select preferred service');

    _bleObject.enableNotifications(status);
    handleResult(status, 'enable notifications');

    final io_str = calloc<io.dc_iostream_t>();
    final vtable = calloc<io.dc_iostream_vtable_t>();
    final ffi_iostream = calloc<ffi.Pointer<io.dc_iostream_t>>();
    ffi_iostream.value = io_str;
    ffi_iostream.value.ref.vtable = vtable;

    ffi_iostream.value.ref.context = context.value;
    ffi_iostream.value.ref.transport = dc_transport_t.DC_TRANSPORT_BLE;
    ffi_iostream.value.ref.vtable.ref.set_timeout = ffi.Pointer.fromFunction(
        BLEObject.set_timeout, dc_status_t.DC_STATUS_TIMEOUT);
    ffi_iostream.value.ref.vtable.ref.set_break = ffi.nullptr;
    ffi_iostream.value.ref.vtable.ref.set_dtr = ffi.nullptr;
    ffi_iostream.value.ref.vtable.ref.set_rts = ffi.nullptr;
    ffi_iostream.value.ref.vtable.ref.get_lines = ffi.nullptr;
    ffi_iostream.value.ref.vtable.ref.get_available = ffi.nullptr;
    ffi_iostream.value.ref.vtable.ref.configure = ffi.nullptr;
    ffi_iostream.value.ref.vtable.ref.poll = ffi
        .nullptr; //ffi.Pointer.fromFunction(_bleObject.poll, dc_status_t.DC_STATUS_IO);
    ffi_iostream.value.ref.vtable.ref.read =
        ffi.Pointer.fromFunction(BLEObject.read, dc_status_t.DC_STATUS_IO);
    ffi_iostream.value.ref.vtable.ref.write =
        ffi.Pointer.fromFunction(BLEObject.write, dc_status_t.DC_STATUS_IO);
    ffi_iostream.value.ref.vtable.ref.ioctl = ffi.nullptr;
    ffi_iostream.value.ref.vtable.ref.flush = ffi.nullptr;
    ffi_iostream.value.ref.vtable.ref.purge = ffi.nullptr;
    ffi_iostream.value.ref.vtable.ref.sleep = ffi.nullptr;
    ffi_iostream.value.ref.vtable.ref.close = ffi.nullptr;

    iostream = ffi_iostream.cast<ffi.Pointer<dc_iostream_t>>();
  }
}
