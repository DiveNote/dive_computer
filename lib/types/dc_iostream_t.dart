// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'dart:ffi';

import '../framework/dive_computer_ffi_bindings_generated.dart';

final class dc_iostream_vtable_t extends Struct {
  @Uint64()
  external int size;

  external Pointer<
          NativeFunction<
              Int32 Function(Pointer<dc_iostream_t> iostream, Int32 timeout)>>
      set_timeout;
  external Pointer<
      NativeFunction<
          dc_status_t Function(
              Pointer<dc_iostream_t> iostream, Uint32 value)>> set_break;
  external Pointer<
      NativeFunction<
          dc_status_t Function(
              Pointer<dc_iostream_t> iostream, Uint32 value)>> set_dtr;
  external Pointer<
      NativeFunction<
          dc_status_t Function(
              Pointer<dc_iostream_t> iostream, Uint32 value)>> set_rts;
  external Pointer<
          NativeFunction<
              dc_status_t Function(
                  Pointer<dc_iostream_t> iostream, Pointer<Uint32> value)>>
      get_lines;
  external Pointer<
          NativeFunction<
              dc_status_t Function(
                  Pointer<dc_iostream_t> iostream, Pointer<Uint64> value)>>
      get_available;
  external Pointer<
      NativeFunction<
          dc_status_t Function(
              Pointer<dc_iostream_t> iostream,
              Uint32 baudrate,
              Uint32 databits,
              dc_parity_t parity,
              dc_stopbits_t stopbits,
              dc_flowcontrol_t flowcontrol)>> configure;
  external Pointer<
      NativeFunction<
          Int32 Function(Pointer<dc_iostream_t> iostream, Int32 value)>> poll;
  external Pointer<
      NativeFunction<
          Int32 Function(Pointer<dc_iostream_t> iostream, Pointer<Void> data,
              Uint64 size, Pointer<Uint64> actual)>> read;
  external Pointer<
      NativeFunction<
          Int32 Function(Pointer<dc_iostream_t> iostream, Pointer<Void> data,
              Uint64 size, Pointer<Uint64> actual)>> write;
  external Pointer<
      NativeFunction<
          dc_status_t Function(Pointer<dc_iostream_t> iostream, Int32 request,
              Pointer<Void> data, Uint64 size)>> ioctl;
  external Pointer<
          NativeFunction<dc_status_t Function(Pointer<dc_iostream_t> iostream)>>
      flush;
  external Pointer<
          NativeFunction<
              dc_status_t Function(
                  Pointer<dc_iostream_t> iostream, dc_direction_t direction)>>
      purge;
  external Pointer<
      NativeFunction<
          dc_status_t Function(
              Pointer<dc_iostream_t> iostream, Uint32 milliseconds)>> sleep;
  external Pointer<
          NativeFunction<dc_status_t Function(Pointer<dc_iostream_t> iostream)>>
      close;
}

final class dc_iostream_t extends Struct {
  external Pointer<dc_iostream_vtable_t> vtable;
  external Pointer<dc_context_t> context;

  @Int32()
  external int transport;
}
