import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart' as logging;

import '../utils/utils.dart';
import '../dive_computer_ffi_bindings_generated.dart';
import '../../types/computer.dart';

final log = logging.Logger('DiveComputerFfi');

class Interfaces {
  final DiveComputerFfiBindings bindings;
  final ffi.Pointer<ffi.Pointer<dc_context_t>> context;

  Interfaces({
    required this.bindings,
    required this.context,
  });

  ffi.Pointer<dc_iostream_t> connect(
      ComputerTransport transport, ffi.Pointer<dc_descriptor_t> computer) {
    switch (transport) {
      case ComputerTransport.serial:
        return _connectSerial(computer);
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
}
