import 'dart:async';
import 'package:logging/logging.dart' as logging;

import '../dive_computer_ffi_bindings_generated.dart';

final log = logging.Logger('DiveComputerFfi');

void handleResult(int result, [String operation = '']) {
  switch (result) {
    case dc_status_t.DC_STATUS_SUCCESS:
      if (operation.isNotEmpty) {
        log.finer('$operation successful');
      }
    case dc_status_t.DC_STATUS_DONE:
      if (operation.isNotEmpty) {
        log.finer('$operation done');
      }
      break;
    case dc_status_t.DC_STATUS_UNSUPPORTED:
      throw UnsupportedError('Unsupported');
    case dc_status_t.DC_STATUS_INVALIDARGS:
      throw ArgumentError('Invalid arguments');
    case dc_status_t.DC_STATUS_TIMEOUT:
      throw TimeoutException("Timeout");
    case dc_status_t.DC_STATUS_NOMEMORY:
      throw const OutOfMemoryError();
    case dc_status_t.DC_STATUS_NODEVICE:
      throw Exception("No device");
    case dc_status_t.DC_STATUS_NOACCESS:
      throw Exception("No access");
    case dc_status_t.DC_STATUS_IO:
      throw Exception("IO");
    case dc_status_t.DC_STATUS_PROTOCOL:
      throw Exception("Protocol");
    case dc_status_t.DC_STATUS_DATAFORMAT:
      throw Exception("Data format");
    case dc_status_t.DC_STATUS_CANCELLED:
      throw Exception("Cancelled");
  }
}
