import 'dart:async';
import 'dart:io';

import 'package:dive_computer/dive_computer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// https://doc.qt.io/qt-6/qbluetoothuuid.html#DescriptorType-enum
enum DescriptorType {
  CharacteristicExtendedProperties,
  CharacteristicUserDescription,
  ClientCharacteristicConfiguration,
  ServerCharacteristicConfiguration,
  CharacteristicPresentationFormat,
  CharacteristicAggregateFormat,
  ValidRange,
  ExternalReportReference,
  ReportReference,
  EnvironmentalSensingConfiguration,
  EnvironmentalSensingMeasurement,
  EnvironmentalSensingTriggerSetting,
  UnknownDescriptorType,
}

final Map<DescriptorType, Guid> DescriptorTypeValues = {
  // DescriptorType.CharacteristicExtendedProperties: 2900,
  // DescriptorType.CharacteristicUserDescription: 2901,
  DescriptorType.ClientCharacteristicConfiguration:
      Guid("00002902-0000-1000-8000-00805f9b34fb"),
  // DescriptorType.ServerCharacteristicConfiguration: 2903,
  // DescriptorType.CharacteristicPresentationFormat: 2904,
  // DescriptorType.CharacteristicAggregateFormat: 2905,
  // DescriptorType.ValidRange: 2906,
  // DescriptorType.ExternalReportReference: 2907,
  // DescriptorType.ReportReference: 2908,
  // DescriptorType.EnvironmentalSensingConfiguration:,
  // DescriptorType.EnvironmentalSensingMeasurement:,
  // DescriptorType.EnvironmentalSensingTriggerSetting:,
  // DescriptorType.UnknownDescriptorType:,
};

class BluetoothProvider with ChangeNotifier {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  BluetoothProvider() {
    FlutterBluePlus.setLogLevel(LogLevel.none, color: false);
    _initBLE();
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  void _initBLE() async {
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }

    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;

      if (state == BluetoothAdapterState.on) {
        FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

        try {
          FlutterBluePlus.systemDevices.then((systemDevices) {
            if (systemDevices.isNotEmpty) {
              _systemDevices = systemDevices;
              notifyListeners();
            }
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

    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (results.isNotEmpty) {
        _scanResults = results;
        notifyListeners();
      }
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
        FlutterBluePlus.systemDevices.then((systemDevices) {
          if (systemDevices.isNotEmpty) {
            _systemDevices = systemDevices;
            notifyListeners();
          }
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
