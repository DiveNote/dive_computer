import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dive_computer/dive_computer.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import './bluetooth_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BluetoothProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<void> _future;
  final dc = DiveComputer.instance;

  late final Future<List<Computer>> supportedComputers;

  @override
  void initState() {
    _future =
        Provider.of<BluetoothProvider>(context, listen: false).scanForDevices();

    dc.enableDebugLogging();
    dc.openConnection();

    supportedComputers = dc.supportedComputers;

    super.initState();
  }

  @override
  void dispose() {
    dc.closeConnection();
    for (var device in FlutterBluePlus.connectedDevices) {
      device.disconnect();
    }

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
                            computer.transports.last,
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
    return FutureBuilder(
      future: _future,
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
            return Consumer<BluetoothProvider>(
              builder: (context, bluetoothProvider, child) {
                return RefreshIndicator(
                  onRefresh: bluetoothProvider.scanForDevices,
                  child: ListView(
                    children: [
                      ...bluetoothProvider.systemDevices.map(
                        (device) => DiveComputerTile(
                          diveComputerName: device.platformName,
                          isNewDC: false,
                          onPressed: () => _listDives(device),
                        ),
                      ),
                      ...bluetoothProvider.scanResults.map(
                        (result) => DiveComputerTile(
                          diveComputerName: result.device.platformName,
                          isNewDC: true,
                          onPressed: () => result.device.connect(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        }
      },
    );
  }

  _listDives(BluetoothDevice device) async {
    if (!FlutterBluePlus.connectedDevices.contains(device)) {
      device.connectionState.listen((BluetoothConnectionState state) {
        print('Connection state: $state');
      });

      await device.connect();
    }
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
