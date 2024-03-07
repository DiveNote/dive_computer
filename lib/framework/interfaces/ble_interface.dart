import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logging/logging.dart' as logging;

final log = logging.Logger('DiveComputerFfi');

class BleInterface {
  static void initialize() async {
    logging.hierarchicalLoggingEnabled = true;
    log.onRecord.listen((e) {
      developer.log(
        e.message,
        time: e.time,
        sequenceNumber: e.sequenceNumber,
        level: e.level.value,
        name: e.loggerName,
        zone: e.zone,
        error: e.error,
        stackTrace: e.stackTrace,
      );
    });

    FlutterBluePlus.setLogLevel(LogLevel.debug, color: false);

    _adapterState = BluetoothAdapterState.unknown;

    // if (await FlutterBluePlus.isSupported == false) {
    //   log.fine('Bluetooth not supported by this device');
    //   return;
    // }

    _adapterStateStateSubscription = _subscribeToBleAdapterState();
    _scanResultsSubscription = _subscribeToScanResults();
  }

  void dispose() {
    _scanResultsSubscription.cancel();
    _adapterStateStateSubscription.cancel();
    //_isScanningSubscription.cancel();
  }

  static late BluetoothAdapterState _adapterState;
  static late final StreamSubscription<BluetoothAdapterState>
      _adapterStateStateSubscription;
  static late final StreamSubscription<List<ScanResult>>
      _scanResultsSubscription;
  //static late StreamSubscription<bool> _isScanningSubscription;
  static List<BleDevice> _bleDevices = [];

  static void enableDebugLogging([logging.Level level = logging.Level.INFO]) {
    log.level = level;
  }

  static StreamSubscription<BluetoothAdapterState>
      _subscribeToBleAdapterState() {
    return FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      log.fine('Current BLE adapter state: $state');

      if (state == BluetoothAdapterState.on) {
        _adapterState = state;
      } else {
        log.warning("Can't connect to BLE devices, adapter is $state");
      }
    });
  }

  static StreamSubscription<List<ScanResult>> _subscribeToScanResults() {
    return FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          _bleDevices = results.map((result) => BleDevice(result)).toList();
        }
      },
      onError: (e) => log.severe('Error while listening to scan results: $e'),
    );
  }

  static List<BleDevice> fetchDevices() {
    if (_adapterState == BluetoothAdapterState.on) {
      log.fine('Scan for BLE devices');
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }

    return _bleDevices;
  }

  // BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  // late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;
  // late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  // late StreamSubscription<bool> _isScanningSubscription;
  // List<BluetoothDevice> _systemDevices = [];
  // List<ScanResult> _scanResults = [];
  // bool _isScanning = false;
}

class BleDevice {
  late String _advertisementName;

  BleDevice(ScanResult result) {
    _advertisementName = result.advertisementData.advName;
  }

  String get advertisementName => _advertisementName;
}
