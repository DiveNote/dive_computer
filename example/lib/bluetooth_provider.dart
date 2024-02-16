import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothProvider with ChangeNotifier {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  BluetoothProvider() {
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false);
    _initBLE();
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  void _initBLE() {
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;

      if (state == BluetoothAdapterState.on) {
        FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

        try {
          FlutterBluePlus.systemDevices.then((value) {
            _systemDevices = value;
            notifyListeners();
          });
        } catch (e, s) {
          print('Error while getting system devices: $e, $s');
        }
      } else {
        print('Bluetooth adapter is ${state.toString().split('.')[1]}');
      }
    }, onError: (e, s) {
      print('Error while listening to adapter state stream: $e, $s');
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
    }, onError: (e, s) {
      print('Error while listening to scan results stream: $e, $s');
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      notifyListeners();
    }, onError: (e, s) {
      print('Error while listening to isScanning stream: $e, $s');
    });
  }

  Future<void> scanForDevices() async {
    if (_adapterState == BluetoothAdapterState.on) {
      print('Scanning for devices...');
      try {
        FlutterBluePlus.systemDevices.then((value) {
          _systemDevices = value;
          notifyListeners();
        });
      } catch (e, s) {
        print('Error while getting system devices: $e, $s');
      }

      if (_isScanning == false) {
        FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      }
    }

    return Future.delayed(const Duration(milliseconds: 500));
  }

  List<BluetoothDevice> get systemDevices =>
      _systemDevices.where((device) => device.platformName.isNotEmpty).toList();

  List<ScanResult> get scanResults => _scanResults
      .where((device) => device.device.platformName.isNotEmpty)
      .toList();
}
