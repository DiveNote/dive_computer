import 'package:dive_computer/types/computer.dart';
import 'package:dive_computer/types/dive.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class DiveComputerInterface {
  void openConnection() {
    throw UnimplementedError();
  }

  void closeConnection() {
    throw UnimplementedError();
  }

  void enableDebugLogging() {
    throw UnimplementedError();
  }

  Future<List<Computer>> get supportedComputers => throw UnimplementedError();

  Future<List<Dive>> download(
    Computer computer,
    ComputerTransport transport,
    BluetoothDevice? device, [
    String? lastFingerprint,
  ]) {
    throw UnimplementedError();
  }
}
