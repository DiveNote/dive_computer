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
      break;
    case dc_status_t.DC_STATUS_DONE:
      if (operation.isNotEmpty) {
        log.finer('$operation done');
      }
      break;
    case dc_status_t.DC_STATUS_UNSUPPORTED:
      if (operation.isNotEmpty) {
        log.finer('$operation Unsupported');
      }
      throw UnsupportedError('Unsupported');
    case dc_status_t.DC_STATUS_INVALIDARGS:
      if (operation.isNotEmpty) {
        log.finer('$operation Invalid arguments');
      }
      throw ArgumentError('Invalid arguments');
    case dc_status_t.DC_STATUS_TIMEOUT:
      if (operation.isNotEmpty) {
        log.finer('$operation Timeout');
      }
      throw TimeoutException("Timeout");
    case dc_status_t.DC_STATUS_NOMEMORY:
      if (operation.isNotEmpty) {
        log.finer('$operation Out of memory');
      }
      throw const OutOfMemoryError();
    case dc_status_t.DC_STATUS_NODEVICE:
      if (operation.isNotEmpty) {
        log.finer('$operation No device');
      }
      throw Exception("No device");
    case dc_status_t.DC_STATUS_NOACCESS:
      if (operation.isNotEmpty) {
        log.finer('$operation No access');
      }
      throw Exception("No access");
    case dc_status_t.DC_STATUS_IO:
      if (operation.isNotEmpty) {
        log.finer('$operation IO');
      }
      throw Exception("IO");
    case dc_status_t.DC_STATUS_PROTOCOL:
      if (operation.isNotEmpty) {
        log.finer('$operation Protocol');
      }
      throw Exception("Protocol");
    case dc_status_t.DC_STATUS_DATAFORMAT:
      if (operation.isNotEmpty) {
        log.finer('$operation Data format');
      }
      throw Exception("Data format");
    case dc_status_t.DC_STATUS_CANCELLED:
      if (operation.isNotEmpty) {
        log.finer('$operation Cancelled');
      }
      throw Exception("Cancelled");
    default:
      if (operation.isNotEmpty) {
        log.finer('$operation Unknown');
      }
      throw Exception("Unknown error");
  }
}
