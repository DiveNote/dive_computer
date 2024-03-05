import 'dart:developer' as developer;
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logging/logging.dart' as logging;

import './interfaces/dive_computer_interfaces.dart';
import './dive_computer_ffi_bindings_generated.dart';
import './utils/transports_bitmask.dart';
import './utils/utils.dart';
import '../types/computer.dart';
import '../types/dive.dart';

final log = logging.Logger('DiveComputerFfi');

/// Foreign function interface for libdivecomputer.
///
/// Warning: This class performs blocking operations and should only be used in
/// an isolate.
class DiveComputerFfi {
  static void initialize() {
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

    const String libName = 'dive_computer';
    String fileName;
    if (Platform.isWindows) {
      fileName = 'lib$libName.dll';
    } else if (Platform.isAndroid) {
      fileName = 'lib$libName.so';
    } else if (Platform.isMacOS || Platform.isIOS) {
      fileName = '$libName.framework/$libName';
    } else {
      throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
    }

    log.config('Loading native library');
    _library = ffi.DynamicLibrary.open(fileName);
    _bindings = DiveComputerFfiBindings(_library);
    log.fine('Loading complete');
  }

  void dispose() {
    _interfaces.dispose();
  }

  static final context = calloc<ffi.Pointer<dc_context_t>>();

  static late final ffi.DynamicLibrary _library;
  static late DiveComputerFfiBindings _bindings;

  static final _computerDescriptorCache =
      <Computer, ffi.Pointer<dc_descriptor_t>>{};
  static final _divesCache = <Dive>[];

  static Function(List<Dive>)? divesCallback;

  static final _interfaces =
      Interfaces(bindings: _bindings, context: context, log: log);

  static void enableDebugLogging([logging.Level level = logging.Level.INFO]) {
    log.level = level;
  }

  static void openConnection() {
    handleResult(
      _bindings.dc_context_new(context),
      'context creation',
    );

    handleResult(
      _bindings.dc_context_set_loglevel(
        context.value,
        dc_loglevel_t.DC_LOGLEVEL_ALL,
      ),
      'log level setting',
    );

    handleResult(
      _bindings.dc_context_set_logfunc(
        context.value,
        ffi.Pointer.fromFunction(_log),
        ffi.nullptr,
      ),
      'log function setting',
    );
  }

  static void closeConnection() {
    handleResult(
      _bindings.dc_context_free(context.value),
      'context freeing',
    );
    _computerDescriptorCache.values.forEach(_bindings.dc_descriptor_free);
    _computerDescriptorCache.clear();
  }

  static List<Computer> get supportedComputers {
    if (_computerDescriptorCache.isNotEmpty) {
      return _computerDescriptorCache.keys.toList();
    }

    final iterator = calloc<ffi.Pointer<dc_iterator_t>>();

    handleResult(
      _bindings.dc_descriptor_iterator(iterator),
      'iterator creation',
    );

    final computers = <Computer>[];

    int result;
    final desc = calloc<ffi.Pointer<dc_descriptor_t>>();
    while ((result = _bindings.dc_iterator_next(iterator.value, desc.cast())) ==
        dc_status_t.DC_STATUS_SUCCESS) {
      final ffi.Pointer<Utf8> vendor =
          _bindings.dc_descriptor_get_vendor(desc.value).cast();
      final ffi.Pointer<Utf8> product =
          _bindings.dc_descriptor_get_product(desc.value).cast();
      final transports = parseTransportsBitmask(
          _bindings.dc_descriptor_get_transports(desc.value));

      final computer = Computer(
        vendor.toDartString(),
        product.toDartString(),
        transports: transports,
      );
      computers.add(computer);
      _computerDescriptorCache.addEntries([MapEntry(computer, desc.value)]);
    }
    handleResult(result, 'iterator next');

    handleResult(
      _bindings.dc_iterator_free(iterator.value),
      'iterator freeing',
    );

    return computers;
  }

  static void download(
    Computer computer,
    ComputerTransport transport,
    BluetoothDevice? bluetoothDevice, [
    String? lastFingerprint,
  ]) {
    final computerDescriptor = _computerDescriptorCache[computer]!;

    final ffi.Pointer<dc_iostream_t> iostream = _interfaces.connect(
        computer, transport, computerDescriptor, bluetoothDevice, context);

    final device = calloc<ffi.Pointer<dc_device_t>>();
    try {
      handleResult(
        _bindings.dc_device_open(
          device,
          context.value,
          computerDescriptor,
          iostream,
        ),
        'device open',
      );

      final customdata = calloc<_DiveCallbackUserdata>();
      customdata.ref.device = device.value;
      customdata.ref.lastFingerprint =
          lastFingerprint?.toNativeUtf8() ?? ffi.nullptr;

      _divesCache.clear();
      handleResult(
        _bindings.dc_device_foreach(
          device.value,
          ffi.Pointer.fromFunction(_dive_callback, 0),
          customdata.cast(),
        ),
        'device foreach',
      );

      if (lastFingerprint != null) {
        _divesCache.removeWhere((e) => e.hash == lastFingerprint);
      }
      divesCallback?.call(_divesCache);

      handleResult(
        _bindings.dc_device_close(device.value),
        'device close',
      );
    } finally {
      handleResult(
        _bindings.dc_iostream_close(iostream),
        'iostream close',
      );
    }
  }

  // ignore: non_constant_identifier_names
  static int _dive_callback(
    ffi.Pointer<ffi.UnsignedChar> data,
    int size,
    ffi.Pointer<ffi.UnsignedChar> fingerprint,
    int fsize,
    ffi.Pointer<ffi.Void> userdata,
  ) {
    final _DiveCallbackUserdata customdata =
        userdata.cast<_DiveCallbackUserdata>().ref;

    _parseDive(data, size, fingerprint, fsize, customdata.device.cast());

    String? lastFingerprint;
    String currentFingerprint = _buildFingerprintHash(fingerprint, fsize);
    if (customdata.lastFingerprint.address != ffi.nullptr.address) {
      lastFingerprint = customdata.lastFingerprint.cast<Utf8>().toDartString();
    }

    // non-zero to continue
    if (currentFingerprint == lastFingerprint) return 0;
    if (kDebugMode && _divesCache.length >= 5) return 0;
    return 1;
  }

  static final _samplesCache = <int, Sample>{};
  static void _parseDive(
    ffi.Pointer<ffi.UnsignedChar> data,
    int size,
    ffi.Pointer<ffi.UnsignedChar> fingerprint,
    int fsize,
    ffi.Pointer<dc_device_t> device,
  ) {
    final fingerprintHash =
        _buildFingerprintHash(fingerprint, fsize).toNativeUtf8();
    log.fine('Parsing Dive #${fingerprintHash.toDartString()}');

    final parser = malloc<ffi.Pointer<dc_parser_t>>();

    handleResult(_bindings.dc_parser_new(
      parser,
      device,
      data,
      size,
    ));

    final diveTime =
        _parseField<int>(dc_field_type_t.DC_FIELD_DIVETIME, parser.value);
    final maxDepth =
        _parseField<double>(dc_field_type_t.DC_FIELD_MAXDEPTH, parser.value);
    final avgDepth =
        _parseField<double>(dc_field_type_t.DC_FIELD_AVGDEPTH, parser.value);
    final atmospheric =
        _parseField<double>(dc_field_type_t.DC_FIELD_ATMOSPHERIC, parser.value);
    final temperatureSurface = _parseField<double>(
        dc_field_type_t.DC_FIELD_TEMPERATURE_SURFACE, parser.value);
    final temperatureMinumum = _parseField<double>(
        dc_field_type_t.DC_FIELD_TEMPERATURE_MINIMUM, parser.value);
    final temperatureMaximum = _parseField<double>(
        dc_field_type_t.DC_FIELD_TEMPERATURE_MAXIMUM, parser.value);
    final diveMode =
        _parseField<int>(dc_field_type_t.DC_FIELD_DIVEMODE, parser.value);

    final salinity =
        _parseField<Salinity>(dc_field_type_t.DC_FIELD_SALINITY, parser.value);

    final gasmixCount =
        _parseField<int>(dc_field_type_t.DC_FIELD_GASMIX_COUNT, parser.value);
    List<Gasmix>? gasmixes;
    if (gasmixCount != null) {
      gasmixes = [];
      for (var i = 0; i < gasmixCount; i++) {
        final gasmix = _parseField<Gasmix>(
            dc_field_type_t.DC_FIELD_GASMIX, parser.value, i);
        if (gasmix == null) continue;
        gasmixes.add(gasmix);
      }
    }

    final tankCount =
        _parseField<int>(dc_field_type_t.DC_FIELD_TANK_COUNT, parser.value);
    List<Tank>? tanks;
    if (tankCount != null) {
      tanks = [];
      for (var i = 0; i < tankCount; i++) {
        final tank =
            _parseField<Tank>(dc_field_type_t.DC_FIELD_TANK, parser.value, i);
        if (tank == null) continue;
        tanks.add(tank);
      }
    }

    final dateTimePointer = malloc<dc_datetime_t>();
    handleResult(
      _bindings.dc_parser_get_datetime(parser.value, dateTimePointer),
    );
    final dateTime = DateTime(
      dateTimePointer.ref.year,
      dateTimePointer.ref.month,
      dateTimePointer.ref.day,
      dateTimePointer.ref.hour,
      dateTimePointer.ref.minute,
      dateTimePointer.ref.second,
    );

    try {
      _samplesCache.clear();
      handleResult(
        _bindings.dc_parser_samples_foreach(
          parser.value,
          ffi.Pointer.fromFunction(_sample_callback),
          fingerprintHash.cast(),
        ),
      );
    } catch (e) {
      log.warning(e);
    }

    final dive = Dive(
      fingerprintHash.toDartString(),
      samples: _samplesCache.values.toList(),
      diveTime: diveTime,
      maxDepth: maxDepth,
      avgDepth: avgDepth,
      atmospheric: atmospheric,
      temperatureSurface: temperatureSurface,
      temperatureMinimum: temperatureMinumum,
      temperatureMaximum: temperatureMaximum,
      diveMode: diveMode,
      salinity: salinity,
      dateTime: dateTime,
      gasmixes: gasmixes,
      tanks: tanks,
    );
    log.info(dive);
    _divesCache.add(dive);

    handleResult(_bindings.dc_parser_destroy(parser.value));
  }

  static T? _parseField<T>(
    int fieldType,
    ffi.Pointer<dc_parser_t> parser, [
    int flags = 0,
  ]) {
    // ignore: prefer_typing_uninitialized_variables
    final ffi.Pointer field;
    switch (T) {
      case const (int):
        field = malloc<ffi.UnsignedInt>();
        break;
      case const (double):
        field = malloc<ffi.Double>();
        break;
      case const (Salinity):
        field = malloc<dc_salinity_t>();
        break;
      case const (Gasmix):
        field = malloc<dc_gasmix_t>();
        break;
      case const (Tank):
        field = malloc<dc_tank_t>();
        break;
      default:
        throw UnsupportedError('Unsupported type: ${T.runtimeType}');
    }

    try {
      handleResult(_bindings.dc_parser_get_field(
        parser,
        fieldType,
        flags,
        field.cast(),
      ));
    } on UnsupportedError catch (_) {
      return null;
    }

    switch (T) {
      case const (int):
        return field.cast<ffi.UnsignedInt>().value as T;
      case const (double):
        return field.cast<ffi.Double>().value as T;
      case const (Salinity):
        final salinity = field.cast<dc_salinity_t>().ref;
        return Salinity(salinity.type, salinity.density) as T;
      case const (Gasmix):
        final gasmix = field.cast<dc_gasmix_t>().ref;
        return Gasmix(
          flags,
          gasmix.usage,
          helium: gasmix.helium,
          oxygen: gasmix.oxygen,
          nitrogen: gasmix.nitrogen,
        ) as T;
      case const (Tank):
        final tank = field.cast<dc_tank_t>().ref;
        return Tank(
          tank.gasmix,
          tank.usage,
          workpressure: tank.workpressure,
          beginpressure: tank.beginpressure,
          endpressure: tank.endpressure,
        ) as T;
      default:
        throw UnsupportedError('Unsupported type: ${T.runtimeType}');
    }
  }

  static int _currentSampleTime = 0;
  // ignore: non_constant_identifier_names
  static void _sample_callback(
    int type /* dc_sample_type_t */,
    ffi.Pointer<dc_sample_value_t> value,
    ffi.Pointer<ffi.Void> userdata,
  ) {
    final fingerprintHash = userdata.cast<Utf8>().toDartString();

    // https://github.com/libdivecomputer/libdivecomputer/blob/08d8c3e13272bc4c33f62cfdc57a34702cff7191/include/libdivecomputer/parser.h#L237-L272
    switch (type) {
      case dc_sample_type_t.DC_SAMPLE_TIME:
        final time = value.cast<ffi.UnsignedInt>().value;
        log.finest('Time: $time @ $fingerprintHash');
        _samplesCache.putIfAbsent(time, () => Sample(time));
        _currentSampleTime = time;
        break;
      case dc_sample_type_t.DC_SAMPLE_DEPTH:
        final depth = value.cast<ffi.Double>().value;
        log.finest('Depth: $depth @ $fingerprintHash');
        _samplesCache[_currentSampleTime]!.depth = depth;
        break;
      case dc_sample_type_t.DC_SAMPLE_TEMPERATURE:
        final temperature = value.cast<ffi.Double>().value;
        log.finest('Temperature: $temperature @ $fingerprintHash');
        _samplesCache[_currentSampleTime]!.temperature = temperature;
        break;
      case dc_sample_type_t.DC_SAMPLE_RBT:
        final rbt = value.cast<ffi.UnsignedInt>().value;
        log.finest('RBT: $rbt @ $fingerprintHash');
        _samplesCache[_currentSampleTime]!.rbt = rbt;
      case dc_sample_type_t.DC_SAMPLE_HEARTBEAT:
        final heartbeat = value.cast<ffi.UnsignedInt>().value;
        log.finest('Heartbeat: $heartbeat @ $fingerprintHash');
        _samplesCache[_currentSampleTime]!.heartbeat = heartbeat;
        break;
      case dc_sample_type_t.DC_SAMPLE_BEARING:
        final bearing = value.cast<ffi.UnsignedInt>().value;
        log.finest('Bearing: $bearing @ $fingerprintHash');
        _samplesCache[_currentSampleTime]!.bearing = bearing;
        break;
      case dc_sample_type_t.DC_SAMPLE_SETPOINT:
        final setpoint = value.cast<ffi.Double>().value;
        log.finest('Setpoint: $setpoint @ $fingerprintHash');
        _samplesCache[_currentSampleTime]!.setpoint = setpoint;
        break;
      case dc_sample_type_t.DC_SAMPLE_CNS:
        final cns = value.cast<ffi.Double>().value;
        log.finest('CNS: $cns @ $fingerprintHash');
        _samplesCache[_currentSampleTime]!.cns = cns;
        break;
      case dc_sample_type_t.DC_SAMPLE_GASMIX:
        final gasmix = value.cast<ffi.UnsignedInt>().value;
        log.finest('Gasmix: $gasmix @ $fingerprintHash');
        _samplesCache[_currentSampleTime]!.gasmix = gasmix;
        break;
      case dc_sample_type_t.DC_SAMPLE_PRESSURE:
        final pressureCallback = value.cast<_SampleCallbackPressure>();
        final pressure = pressureCallback.ref.value;
        log.finest('Pressure: $pressure @ $fingerprintHash');
        _samplesCache[_currentSampleTime]!.pressure ??= [];
        _samplesCache[_currentSampleTime]!
            .pressure!
            .add(Pressure(pressureCallback.ref.tank, pressure));
        break;
      case dc_sample_type_t.DC_SAMPLE_EVENT:
        final eventCallback = value.cast<_SampleCallbackEvent>();
        _samplesCache[_currentSampleTime]!.events ??= [];
        _samplesCache[_currentSampleTime]!.events!.add(Event(
              eventCallback.ref.type,
              eventCallback.ref.time,
              eventCallback.ref.flags,
              eventCallback.ref.value,
            ));
        break;
      case dc_sample_type_t.DC_SAMPLE_VENDOR:
        final vendorCallback = value.cast<_SampleCallbackVendor>();
        _samplesCache[_currentSampleTime]!.vendor ??= Vendor(
          vendorCallback.ref.type,
          vendorCallback.ref.size,
        );
        break;
      case dc_sample_type_t.DC_SAMPLE_PPO2:
        final ppo2Callback = value.cast<_SampleCallbackPPO2>();
        _samplesCache[_currentSampleTime]!.ppo2 ??= PPO2(
          ppo2Callback.ref.sensor,
          ppo2Callback.ref.value,
        );
        break;
      case dc_sample_type_t.DC_SAMPLE_DECO:
        final decoCallback = value.cast<_SampleCallbackDeco>();
        _samplesCache[_currentSampleTime]!.deco ??= Deco(
          decoCallback.ref.type,
          decoCallback.ref.time,
          decoCallback.ref.depth,
          decoCallback.ref.tts,
        );
        break;
      default:
        log.warning('Unknown sample type: $type');
    }
  }

  static void _log(
    ffi.Pointer<dc_context_t> context,
    int loglevel,
    ffi.Pointer<ffi.Char> file,
    int line,
    ffi.Pointer<ffi.Char> function,
    ffi.Pointer<ffi.Char> message,
    ffi.Pointer<ffi.Void> userdata,
  ) {
    log.fine('[native] ${message.cast<Utf8>().toDartString()}');
  }

  static String _buildFingerprintHash(
      ffi.Pointer<ffi.UnsignedChar> fingerprint, int fsize) {
    final ascii = '0123456789ABCDEF'.codeUnits;

    var result = StringBuffer();

    for (var i = 0; i < fsize; ++i) {
      var msn = ((fingerprint + i).value >> 4) & 0x0F;
      var lsn = (fingerprint + i).value & 0x0F;

      result.writeCharCode(ascii[msn]);
      result.writeCharCode(ascii[lsn]);
    }

    return result.toString();
  }
}

final class _DiveCallbackUserdata extends ffi.Struct {
  external ffi.Pointer<dc_device_t> device;
  external ffi.Pointer<Utf8> lastFingerprint;
}

typedef _SampleCallbackPressure = UnnamedStruct2;
typedef _SampleCallbackEvent = UnnamedStruct3;
typedef _SampleCallbackVendor = UnnamedStruct4;
typedef _SampleCallbackPPO2 = UnnamedStruct5;
typedef _SampleCallbackDeco = UnnamedStruct6;
