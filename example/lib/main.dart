import 'dart:io';

import 'package:dive_computer/framework/interfaces/ble_interface.dart';
import 'package:flutter/material.dart';
import 'package:dive_computer/dive_computer.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
//import 'package:provider/provider.dart';

//import './bluetooth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (await FlutterBluePlus.isSupported == false) {
    log.fine('Bluetooth not supported by this device');
    return;
  }

  runApp(
    //ChangeNotifierProvider(
    //  create: (context) => BluetoothProvider(),
    //  child: const MyApp(),
    //),
    const MyApp(),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final dc = DiveComputer.instance;

  late final Future<List<BleDevice>> _bleDevices;
  late final Future<List<Computer>> supportedComputers;

  @override
  void initState() {
    _bleDevices = dc.fetchBleDevices();

    dc.enableDebugLogging();
    dc.openConnection();

    supportedComputers = dc.supportedComputers;

    super.initState();
  }

  @override
  void dispose() {
    dc.closeConnection();
    super.dispose();
  }

  _example() {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return _desktop();
    } else {
      return _mobile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('libdivecomputer ffi example'),
        ),
        body: _example(),
      ),
    );
  }

  _desktop() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Supported dive computers:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder(
              future: supportedComputers,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.hasData) {
                  final computers = snapshot.data as List<Computer>;
                  return ListView.builder(
                    itemCount: computers.length,
                    itemBuilder: (context, index) {
                      final computer = computers[index];
                      return GestureDetector(
                        onTap: () async {
                          final dives = await dc.download(
                            computer,
                            computer.transports.first,
                            "exampleFingerprint",
                          );
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Downloaded ${dives.length} dives'),
                            ),
                          );
                        },
                        child: Text(computer.toString()),
                      );
                    },
                  );
                }

                return const Text('Loading...');
              },
            ),
          ),
        ],
      ),
    );
  }

  _mobile() {
    return FutureBuilder<List<BleDevice>>(
      future: _bleDevices,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          if (snapshot.error != null) {
            return const Center(
              child: Text(
                'Something went wrong!',
              ),
            );
          } else {
            final bleDevices = snapshot.data![0] as List<BleDevice>;
            return ListView.builder(
              itemCount: bleDevices.length,
              itemBuilder: (context, index) {
                final device = bleDevices[index];
                return ListTile(
                  title: Text(device.advertisementName),
                  onTap: () async {
                    // final dives = await dc.download(
                    //   snapshot.data![1][0] as Computer,
                    //   ComputerTransport.ble,
                    //   device,
                    //   "exampleFingerprint",
                    // );
                    // ignore: use_build_context_synchronously
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(
                    //     content: Text('Downloaded ${dives.length} dives'),
                    //   ),
                    // );
                  },
                );
              },
            );

            // return Consumer<BluetoothProvider>(
            //   builder: (context, bluetoothProvider, child) {
            //     return RefreshIndicator(
            //       onRefresh: bluetoothProvider.scanForDevices,
            //       child: ListView(
            //         children: [
            //           ...bluetoothProvider.systemDevices.map(
            //             (device) => DiveComputerTile(
            //               diveComputerName: device.platformName,
            //               isNewDC: false,
            //               onPressed: () async {
            //                 // First, check if connection to device has been established
            //                 if (!FlutterBluePlus.connectedDevices
            //                     .contains(device)) {
            //                   device.connectionState
            //                       .listen((BluetoothConnectionState state) {
            //                     print('Connection state: $state');
            //                   });

            //                   await device.connect();
            //                 }

            //                 // Check if device is supported by dive_computer and device supports ble
            //                 final computers =
            //                     snapshot.data![1] as List<Computer>;
            //                 Computer? computer;
            //                 for (var c in computers) {
            //                   if (device.platformName.contains(c.product)) {
            //                     computer = c;
            //                     break;
            //                   }
            //                 }

            //                 if (computer == null) {
            //                   print('${device.platformName} not supported');
            //                   return;
            //                 }

            //                 ComputerTransport? transport;
            //                 if (computer.transports
            //                     .contains(ComputerTransport.ble)) {
            //                   // flutter_blue_plus supports only BLE, not Bluetooth
            //                   transport = ComputerTransport.ble;
            //                 }

            //                 if (transport == null) {
            //                   print(
            //                       'No BLE or Bluetooth support for ${device.platformName}');
            //                   return;
            //                 }

            //                 // subsurface BLE/Bluetooth import process
            //                 // run, downloadfromdcthread.cpp line 87
            //                 //    1. get dc_descriptor_t for device <- downloadfromdcthread.cpp line 90 <- LIBDIVECOMPUTER
            //                 //    2. do_libdivecomputer_import <- downloadfromdcthread.cpp line 117
            //                 //        a. dc_context_new, libdivecompute.c line 1512 <- LIBDIVECOMPUTER
            //                 //        b. divecomputer_device_open, libdivecompute.c line 1525
            //                 //            BT: (most likely not supported with iOS and definitly not supported by flutter_blue_plus)
            //                 //              I. rfcomm_stream_open, libdivecompute.c line 1420
            //                 //            BLE:
            //                 //              I. ble_packet_open, libdivecompute.c line 1432
            //                 //                a. qt_ble_open, qtserialbluetooth.cpp line 303
            //                 //                    1. connectToDevice, qt-ble.cpp line 585
            //                 //                    2. discoverServices, qt-ble.cpp line 630
            //                 //                    3. select_preferred_service, qt-ble.cpp line 638 <- The service which is providing read and write access
            //                 //                    4. get ClientCharacteristicConfiguration descriptor and write 0x0100 to enable notifications, qt-ble.cpp line 658-677
            //                 //                    5. assign BLEObject to iostream, qt-ble.cpp line 689
            //                 //                b. dc_custom_open, qtserialbluetooth.cpp line 308  <- LIBDIVECOMPUTER
            //                 //                    1. dc_iostream_allocate, custom.c line 84 <- LIBDIVECOMPUTER

            //                 // From here the process is the same as for other transports
            //                 //        c. dc_device_open, libdivecompute.c line 1531 <- LIBDIVECOMPUTER
            //                 //        d. do_device_import, libdivecomputer.c line 1541
            //                 //            I. dc_device_set_events, libdivecomputer.c line 1178 <- LIBDIVECOMPUTER
            //                 //            II. dc_device_set_cancel, libdivecomputer.c line 1183 <- LIBDIVECOMPUTER
            //                 //            III. in case no dump dc_device_foreach, libdivecomputer.c line 1210 <- LIBDIVECOMPUTER

            //                 // Download dives from device
            //                 final dives = await dc.download(
            //                   computer,
            //                   transport,
            //                   device,
            //                   "exampleFingerprint",
            //                 );

            //                 // ignore: use_build_context_synchronously
            //                 ScaffoldMessenger.of(context).showSnackBar(
            //                   SnackBar(
            //                     content:
            //                         Text('Downloaded ${dives.length} dives'),
            //                   ),
            //                 );
            //               },
            //             ),
            //           ),
            //           ...bluetoothProvider.scanResults.map(
            //             (result) => DiveComputerTile(
            //               diveComputerName: result.device.platformName,
            //               isNewDC: true,
            //               onPressed: () => result.device.connect(),
            //             ),
            //           ),
            //         ],
            //       ),
            //     );
            //   },
            // );
          }
        }
      },
    );
  }
}

class DiveComputerTile extends StatelessWidget {
  final String diveComputerName;
  final bool isNewDC;
  final Function onPressed;

  const DiveComputerTile({
    super.key,
    required this.diveComputerName,
    required this.isNewDC,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  child: Text(diveComputerName),
                ),
              ),
              TextButton(
                onPressed: () => onPressed(),
                child: Text(
                  isNewDC ? 'Connect' : 'Import',
                  style: TextStyle(
                    color: isNewDC ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
