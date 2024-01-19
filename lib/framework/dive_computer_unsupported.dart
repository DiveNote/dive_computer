import 'package:dive_computer/framework/dive_computer_interface.dart';

class DiveComputer extends DiveComputerInterface {
  static DiveComputer? _instance;
  static DiveComputer get instance => _instance ??= DiveComputer._();

  DiveComputer._();
}
