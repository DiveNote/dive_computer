class Dive {
  final String hash;

  final int? diveTime, diveMode;
  final double? maxDepth,
      avgDepth,
      atmospheric,
      temperatureSurface,
      temperatureMinimum,
      temperatureMaximum;

  final DateTime? dateTime;
  final Salinity? salinity;
  final List<Gasmix>? gasmixes;
  final List<Tank>? tanks;

  final List<Sample> samples;

  Dive(
    this.hash, {
    required this.diveTime,
    required this.maxDepth,
    required this.avgDepth,
    required this.atmospheric,
    required this.temperatureSurface,
    required this.temperatureMinimum,
    required this.temperatureMaximum,
    required this.diveMode,
    required this.dateTime,
    required this.salinity,
    required this.gasmixes,
    required this.tanks,
    required this.samples,
  });

  @override
  String toString() {
    return 'Dive{hash: $hash, diveTime: $diveTime, maxDepth: $maxDepth} samples: ${samples.length}';
  }
}

enum Usage { none, oxygen, diluent, sidemount }

class Gasmix {
  final int index, usage;
  final double helium, oxygen, nitrogen;
  Gasmix(this.index, this.usage,
      {required this.helium, required this.oxygen, required this.nitrogen});
}

class Tank {
  final int gasmix, usage;
  final double workpressure, beginpressure, endpressure;
  Tank(this.gasmix, this.usage,
      {required this.workpressure,
      required this.beginpressure,
      required this.endpressure});
}

class Salinity {
  final int salinity;
  final double density;
  Salinity(this.salinity, this.density);
}

class Sample {
  final int time;
  int? rbt, heartbeat, bearing, gasmix;
  double? depth, temperature, setpoint, cns;
  PPO2? ppo2;
  Deco? deco;
  Vendor? vendor;
  List<Pressure>? pressure;
  List<Event>? events;

  Sample(this.time);

  @override
  String toString() {
    return 'Sample{time: $time, depth: $depth}';
  }
}

class Event {
  final int type, time, flags, value;
  Event(this.type, this.time, this.flags, this.value);
}

class Vendor {
  final int type, size;
  Vendor(this.type, this.size);
}

class PPO2 {
  final int sensor;
  final double value;
  PPO2(this.sensor, this.value);
}

class Deco {
  final int type, time, tts;
  final double depth;
  Deco(this.type, this.time, this.depth, this.tts);
}

class Pressure {
  final int tank;
  final double pressure;
  Pressure(this.tank, this.pressure);
}
