import 'package:flutter/material.dart';
import 'package:dive_computer/dive_computer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final dc = DiveComputer.instance;

  late final Future<List<Computer>> supportedComputers;

  @override
  void initState() {
    super.initState();

    dc.enableDebugLogging();
    dc.openConnection();

    supportedComputers = dc.supportedComputers;
  }

  @override
  void dispose() {
    dc.closeConnection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('libdivecomputer ffi example'),
        ),
        body: Container(
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
                                  content:
                                      Text('Downloaded ${dives.length} dives'),
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
        ),
      ),
    );
  }
}
