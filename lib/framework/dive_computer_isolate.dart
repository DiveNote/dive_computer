import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:developer' as developer;

import 'package:dive_computer/framework/dive_computer_interface.dart';
import 'package:dive_computer/framework/dive_computer_ffi.dart';
import 'package:dive_computer/framework/interfaces/ble_interface.dart';
import 'package:dive_computer/types/computer.dart';
import 'package:dive_computer/types/dive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logging/logging.dart';

enum DiveComputerMethod {
  openConnection,
  closeConnection,
  enableDebugLogging,
  supportedComputers,
  download,
  fetchBleDevices,
}

typedef IsolateMessage = (DiveComputerMethod method, List<dynamic> args);

class DiveComputer implements DiveComputerInterface {
  late ReceivePort _receivePort, _errorPort;
  late Completer<SendPort> _sendPort;

  static DiveComputer? _instance;
  static DiveComputer get instance => _instance ??= DiveComputer._();

  Completer<List<Computer>>? _supportedComputers;
  Completer<List<Dive>>? _downloadedDives;
  Completer<List<BleDevice>>? _bleDevices;

  DiveComputer._() {
    _receivePort = ReceivePort();
    _errorPort = ReceivePort();
    _sendPort = Completer<SendPort>();

    Isolate.spawn(
      _spawnIsolate,
      _receivePort.sendPort,
      onError: _errorPort.sendPort,
    );
    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort.complete(message);
      } else if (message is List<Computer>) {
        _supportedComputers?.complete(message);
      } else if (message is List<Dive>) {
        _downloadedDives?.complete(message);
      } else if (message is List<BleDevice>) {
        _bleDevices?.complete(message);
      } else if (message is Error || message is Exception) {
        if (_supportedComputers?.isCompleted == false) {
          _supportedComputers?.completeError(message);
        }
        if (_downloadedDives?.isCompleted == false) {
          _downloadedDives?.completeError(message);
        }
      } else {
        throw UnimplementedError('Message not implemented: $message');
      }
    });
  }

  Future<void> _send(IsolateMessage message) async {
    final sendPort = await _sendPort.future;
    sendPort.send(message);
  }

  @override
  void openConnection() {
    _send((DiveComputerMethod.openConnection, []));
  }

  @override
  void closeConnection() {
    _send((DiveComputerMethod.closeConnection, []));
  }

  @override
  void enableDebugLogging() async {
    _send((DiveComputerMethod.enableDebugLogging, []));
  }

  @override
  Future<List<Computer>> get supportedComputers async {
    await _send((DiveComputerMethod.supportedComputers, []));
    return (_supportedComputers = Completer()).future;
  }

  @override
  Future<List<Dive>> download(
    Computer computer,
    ComputerTransport transport, [
    String? lastFingerprint,
  ]) async {
    await _send((
      DiveComputerMethod.download,
      [computer, transport, lastFingerprint],
    ));
    return (_downloadedDives = Completer()).future;
  }

  @override
  Future<List<BleDevice>> fetchBleDevices() async {
    await _send((DiveComputerMethod.fetchBleDevices, []));
    return (_bleDevices = Completer()).future;
  }
}

_spawnIsolate(SendPort sendPort) {
  developer.log(
    'Spawning DiveComputerFfi and BleInterface in an Isolate',
    name: 'DiveComputerIsolate',
  );

  Object? initializationError;
  try {
    DiveComputerFfi.initialize();

    if (Platform.isAndroid || Platform.isIOS) {
      BleInterface.initialize();
    }
  } catch (e) {
    initializationError = e;
  }

  ReceivePort receivePort = ReceivePort();
  receivePort.listen((message) {
    message = message as IsolateMessage;
    try {
      switch (message.$1) {
        case DiveComputerMethod.openConnection:
          DiveComputerFfi.openConnection();
          if (kDebugMode) DiveComputerFfi.enableDebugLogging();
          break;
        case DiveComputerMethod.closeConnection:
          DiveComputerFfi.closeConnection();
          break;
        case DiveComputerMethod.enableDebugLogging:
          DiveComputerFfi.enableDebugLogging(Level.FINEST);
          BleInterface.enableDebugLogging(Level.FINEST);
          break;
        case DiveComputerMethod.supportedComputers:
          final computers = DiveComputerFfi.supportedComputers;
          sendPort.send(computers);
          break;
        case DiveComputerMethod.download:
          final computer = message.$2[0] as Computer;
          final transport = message.$2[1] as ComputerTransport;
          final lastFingerprint = message.$2[3] as String?;
          DiveComputerFfi.divesCallback = (dives) {
            sendPort.send(dives);
          };
          DiveComputerFfi.download(
            computer,
            transport,
            lastFingerprint,
          );
          break;
        case DiveComputerMethod.fetchBleDevices:
          final devices = BleInterface.fetchDevices();
          sendPort.send(devices);
          break;
        default:
          throw UnimplementedError('Message not implemented: $message');
      }
    } catch (e) {
      sendPort.send(initializationError ?? e);
    }
  });
  sendPort.send(receivePort.sendPort);
}
