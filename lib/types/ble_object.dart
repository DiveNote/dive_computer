import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:dive_computer/framework/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart' as logging;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import './dc_iostream_t.dart' as io;
import '../framework/dive_computer_ffi_bindings_generated.dart';

final log = logging.Logger('DiveComputerFfi');

// Unfortunatly we need to use global variables here because
// Pointer.fromFunction is accepting only static functions
int _timeout = 12000; // 12 seconds from BLE_TIMEOUT
BluetoothService? _prefeeredService;
final List<Uint8List> _receivedPackets = [];

class BLEObject {
  final List<StreamSubscription<List<int>>> _characteristicSubscriptions = [];

  void dispose() {
    for (StreamSubscription<List<int>> subscription
        in _characteristicSubscriptions) {
      subscription.cancel();
    }
  }

  // ignore: non_constant_identifier_names
  static int set_timeout(Pointer<io.dc_iostream_t> iostream, int timeout) {
    log.info('Set BLE timeout to $timeout');
    _timeout = timeout;

    return dc_status_t.DC_STATUS_SUCCESS;
  }

  static int write(Pointer<io.dc_iostream_t> iostream, Pointer<Void> data,
      int size, Pointer<Uint64> actual) {
    //Subsurface qt-ble.cpp write, line 300

    if (actual != nullptr) {
      actual.value = 0;
    }

    if (_prefeeredService == null) {
      handleResult(dc_status_t.DC_STATUS_IO, 'No preferred service');
    }

    if (_receivedPackets.isNotEmpty) {
      log.info('Write HIT with still incoming packets in queue');
      do {
        _receivedPackets.removeAt(0);
      } while (_receivedPackets.isNotEmpty);
    }

    for (BluetoothCharacteristic characteristic
        in _prefeeredService!.characteristics) {
      if (!_isWriteCharacteristic(characteristic)) {
        continue;
      }

      Uint8List bytes = data.cast<Uint8>().asTypedList(size);

      characteristic.write(bytes,
          withoutResponse: characteristic.properties.writeWithoutResponse);
      if (actual != nullptr) {
        actual.value = size;
      }

      return dc_status_t.DC_STATUS_SUCCESS;
    }

    return dc_status_t.DC_STATUS_IO;
  }

  static int read(Pointer<io.dc_iostream_t> iostream, Pointer<Void> data,
      int size, Pointer<Uint64> actual) {
    //Subsurface qt-ble.cpp read, line 350

    if (actual != nullptr) {
      actual.value = 0;
    }

    final status = poll(_timeout);
    if (status != dc_status_t.DC_STATUS_SUCCESS) {
      return status;
    }

    if (_receivedPackets.isNotEmpty) {
      Uint8List packet = _receivedPackets.removeAt(0);

      // Did we get more than asked for?
      //
      // Put back the left-over at the beginning of the
      // received packet list, and truncate the packet
      // we got to just the part asked for.
      if (packet.length > size) {
        _receivedPackets.insert(0, packet.sublist(size));
        packet = packet.sublist(0, size);
      }

      Uint8List dataAsList = data.cast<Uint8>().asTypedList(packet.length);
      dataAsList.setRange(0, packet.length, packet);

      if (actual != nullptr) {
        actual.value += packet.length;
      }

      return dc_status_t.DC_STATUS_SUCCESS;
    }

    return dc_status_t.DC_STATUS_SUCCESS;
  }

  static int poll(int timeout) {
    //Subsurface qt-ble.cpp poll, line 332

    if (_receivedPackets.isEmpty) {
      final characteristics = _prefeeredService!.characteristics;
      if (characteristics.isEmpty) {
        return dc_status_t.DC_STATUS_IO;
      }

      _waitFor(_receivedPackets.isEmpty, timeout);
      if (_receivedPackets.isEmpty) {
        return dc_status_t.DC_STATUS_TIMEOUT;
      }
    }

    return dc_status_t.DC_STATUS_SUCCESS;
  }

  void selectPreferredService(BluetoothDevice device, int status) async {
    //Subsurface qt-ble.cpp select_preferred_service

    final services = await device.discoverServices();
    for (BluetoothService service in services) {
      bool hasRead = false;
      bool hasWrite = false;
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        // Check for read access
        if (_isReadCharacteristic(characteristic)) {
          hasRead = true;
        }
        // Check for write access
        if (_isWriteCharacteristic(characteristic)) {
          hasWrite = true;
        }
      }

      if (hasWrite && hasRead) {
        log.info('Set preferred service ${service.serviceUuid.toString()}');
        _prefeeredService = service;
        break;
      }
    }

    status = dc_status_t.DC_STATUS_SUCCESS;
    if (_prefeeredService == null) {
      status = dc_status_t.DC_STATUS_IO;
    }

    if (_prefeeredService != null) {
      for (BluetoothCharacteristic characteristic
          in _prefeeredService!.characteristics) {
        characteristic.onValueReceived.listen((value) {
          _characteristcStateChanged(characteristic, Uint8List.fromList(value));
        });
      }
    }
  }

  void enableNotifications(int status) async {
    //Subsurface qt-ble.cpp line 650
    //Currently we ignore Heinrichs Weikamp dive computer

    if (_prefeeredService == null) {
      status = dc_status_t.DC_STATUS_IO;
      return;
    }

    for (BluetoothCharacteristic characteristic
        in _prefeeredService!.characteristics) {
      if (!_isReadCharacteristic(characteristic)) {
        continue;
      }

      final descriptors = characteristic.descriptors;
      BluetoothDescriptor clientDescriptor = descriptors.first;

      // Get client characteristic configuration descriptor
      for (BluetoothDescriptor descriptor in descriptors) {
        if (descriptor.uuid == Guid("00002902-0000-1000-8000-00805f9b34fb")) {
          clientDescriptor = descriptor;
          break;
        }
      }

      try {
        // writing 0x0100 to the client characteristic configuration descriptor
        //await clientDescriptor.write([0x0100]);
        log.info(
            'Set notify value for ${characteristic.characteristicUuid.toString()}');
        final result = await characteristic.setNotifyValue(true);
        status =
            result ? dc_status_t.DC_STATUS_SUCCESS : dc_status_t.DC_STATUS_IO;
      } catch (e, s) {
        status = dc_status_t.DC_STATUS_IO;
      }
    }
  }

  static void _waitFor(bool expression, int timeout) async {
    //Subsurface qt-ble.cpp WAITFOR, line 36

    if (expression) {
      return;
    }

    final stopwatch = Stopwatch()..start();
    do {
      await Future.delayed(const Duration(milliseconds: 10));
    } while (!expression && stopwatch.elapsedMilliseconds < timeout);
  }

  static bool _isReadCharacteristic(BluetoothCharacteristic characteristic) {
    return characteristic.properties.notify ||
        characteristic.properties.indicate;
  }

  static bool _isWriteCharacteristic(BluetoothCharacteristic characteristic) {
    return characteristic.properties.write ||
        characteristic.properties.writeWithoutResponse;
  }

  void _characteristcStateChanged(
      BluetoothCharacteristic characteristic, Uint8List value) {
    //Subsurface qt-ble.cpp _characteristcStateChanged, line 65
    _receivedPackets.add(value);
  }
}
