# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(libdivecomputer VERSION 0.0.1 LANGUAGES C)

add_subdirectory(hidapi hidapi)
add_subdirectory(libusb libusb)

add_compile_definitions(ENABLE_LOGGING=1)
add_compile_definitions(HAVE_CLOCK_GETTIME=1)
add_compile_definitions(HAVE_DECL_OPTRESET=1)
add_compile_definitions(HAVE_DECL_STRERROR_R=1)
add_compile_definitions(HAVE_DLFCN_H=1)
add_compile_definitions(HAVE_GETOPT_H=1)
add_compile_definitions(HAVE_GETOPT_LONG=1)
add_compile_definitions(HAVE_GMTIME_R=1)
add_compile_definitions(HAVE_HIDAPI=1)
add_compile_definitions(HAVE_INTTYPES_H=1)
add_compile_definitions(HAVE_IOKIT_SERIAL_IOSS_H=1)
add_compile_definitions(HAVE_LIBUSB=1)
add_compile_definitions(HAVE_LOCALTIME_R=1)
add_compile_definitions(HAVE_MACH_ABSOLUTE_TIME=1)
add_compile_definitions(HAVE_MACH_MACH_TIME_H=1)
add_compile_definitions(HAVE_PTHREAD_H=1)
add_compile_definitions(HAVE_STDINT_H=1)
add_compile_definitions(HAVE_STDIO_H=1)
add_compile_definitions(HAVE_STDLIB_H=1)
add_compile_definitions(HAVE_STRERROR_R=1)
add_compile_definitions(HAVE_STRINGS_H=1)
add_compile_definitions(HAVE_STRING_H=1)
add_compile_definitions(HAVE_STRUCT_TM_TM_GMTOFF=1)
add_compile_definitions(HAVE_SYS_PARAM_H=1)
add_compile_definitions(HAVE_SYS_SOCKET_H=1)
add_compile_definitions(HAVE_SYS_STAT_H=1)
add_compile_definitions(HAVE_SYS_TYPES_H=1)
add_compile_definitions(HAVE_TIMEGM=1)
add_compile_definitions(HAVE_UNISTD_H=1)
add_compile_definitions(HAVE_VERSION_SUFFIX=1)
add_compile_definitions(LT_OBJDIR=".libs/")
add_compile_definitions(PACKAGE="libdivecomputer")
add_compile_definitions(PACKAGE_BUGREPORT="")
add_compile_definitions(PACKAGE_NAME="libdivecomputer")
add_compile_definitions(PACKAGE_STRING="libdivecomputer 0.9.0-devel")
add_compile_definitions(PACKAGE_TARNAME="libdivecomputer")
add_compile_definitions(PACKAGE_URL="")
add_compile_definitions(PACKAGE_VERSION="0.9.0-devel")
add_compile_definitions(STDC_HEADERS=1)
add_compile_definitions(VERSION="0.9.0-devel")

# add_compile_definitions(__APPLE__=1)
# add_compile_definitions(HAVE_HIDAPI=1)
# add_compile_definitions(HAVE_PTHREAD_H=1)

include_directories(
  "libdivecomputer/include"
  "hidapi/hidapi"
  "libusb/libusb"
)

add_library(libdivecomputer SHARED
  "libdivecomputer/src/context.c"
  "libdivecomputer/src/device.c"
  "libdivecomputer/src/iterator.c"
  "libdivecomputer/src/buffer.c"
  "libdivecomputer/src/descriptor.c"
  "libdivecomputer/src/iostream.c"
  "libdivecomputer/src/array.c"
  "libdivecomputer/src/checksum.c"
  "libdivecomputer/src/ringbuffer.c"
  "libdivecomputer/src/rbstream.c"
  "libdivecomputer/src/common.c"
  "libdivecomputer/src/datetime.c"
  "libdivecomputer/src/packet.c"
  "libdivecomputer/src/aes.c"
  "libdivecomputer/src/platform.c"
  "libdivecomputer/src/ihex.c"
  "libdivecomputer/src/timer.c"
  "libdivecomputer/src/parser.c"
  "libdivecomputer/src/serial_posix.c"
  "libdivecomputer/src/usb.c"
  "libdivecomputer/src/usbhid.c"

  "libdivecomputer/src/atomics_cobalt.c"
  "libdivecomputer/src/atomics_cobalt_parser.c"
  "libdivecomputer/src/citizen_aqualand.c"
  "libdivecomputer/src/citizen_aqualand_parser.c"
  "libdivecomputer/src/cochran_commander.c"
  "libdivecomputer/src/cochran_commander_parser.c"
  "libdivecomputer/src/cressi_edy.c"
  "libdivecomputer/src/cressi_edy_parser.c"
  "libdivecomputer/src/cressi_goa.c"
  "libdivecomputer/src/cressi_goa_parser.c"
  "libdivecomputer/src/cressi_leonardo.c"
  "libdivecomputer/src/cressi_leonardo_parser.c"
  "libdivecomputer/src/deepblu_cosmiq.c"
  "libdivecomputer/src/deepblu_cosmiq_parser.c"
  "libdivecomputer/src/deepsix_excursion.c"
  "libdivecomputer/src/deepsix_excursion_parser.c"
  "libdivecomputer/src/diverite_nitekq.c"
  "libdivecomputer/src/diverite_nitekq_parser.c"
  "libdivecomputer/src/divesoft_freedom.c"
  "libdivecomputer/src/divesoft_freedom_parser.c"
  "libdivecomputer/src/hdlc.c"
  "libdivecomputer/src/divesystem_idive.c"
  "libdivecomputer/src/divesystem_idive_parser.c"
  "libdivecomputer/src/hw_frog.c"
  "libdivecomputer/src/hw_ostc3.c"
  "libdivecomputer/src/hw_ostc.c"
  "libdivecomputer/src/hw_ostc_parser.c"
  "libdivecomputer/src/liquivision_lynx.c"
  "libdivecomputer/src/liquivision_lynx_parser.c"
  "libdivecomputer/src/mares_common.c"
  "libdivecomputer/src/mares_darwin.c"
  "libdivecomputer/src/mares_darwin_parser.c"
  "libdivecomputer/src/mares_iconhd.c"
  "libdivecomputer/src/mares_iconhd_parser.c"
  "libdivecomputer/src/mares_nemo.c"
  "libdivecomputer/src/mares_nemo_parser.c"
  "libdivecomputer/src/mares_puck.c"
  "libdivecomputer/src/mclean_extreme.c"
  "libdivecomputer/src/mclean_extreme_parser.c"
  "libdivecomputer/src/oceanic_common.c"
  "libdivecomputer/src/oceanic_atom2.c"
  "libdivecomputer/src/oceanic_atom2_parser.c"
  "libdivecomputer/src/oceanic_veo250.c"
  "libdivecomputer/src/oceanic_veo250_parser.c"
  "libdivecomputer/src/oceanic_vtpro.c"
  "libdivecomputer/src/oceanic_vtpro_parser.c"
  "libdivecomputer/src/oceans_s1_common.c"
  "libdivecomputer/src/oceans_s1.c"
  "libdivecomputer/src/oceans_s1_parser.c"
  "libdivecomputer/src/reefnet_sensus.c"
  "libdivecomputer/src/reefnet_sensus_parser.c"
  "libdivecomputer/src/reefnet_sensuspro.c"
  "libdivecomputer/src/reefnet_sensuspro_parser.c"
  "libdivecomputer/src/reefnet_sensusultra.c"
  "libdivecomputer/src/reefnet_sensusultra_parser.c"
  "libdivecomputer/src/seac_screen.c"
  "libdivecomputer/src/seac_screen_parser.c"
  "libdivecomputer/src/shearwater_common.c"
  "libdivecomputer/src/shearwater_petrel.c"
  "libdivecomputer/src/shearwater_predator.c"
  "libdivecomputer/src/shearwater_predator_parser.c"
  "libdivecomputer/src/sporasub_sp2.c"
  "libdivecomputer/src/sporasub_sp2_parser.c"
  "libdivecomputer/src/suunto_common.c"
  "libdivecomputer/src/suunto_common2.c"
  "libdivecomputer/src/suunto_d9.c"
  "libdivecomputer/src/suunto_d9_parser.c"
  "libdivecomputer/src/suunto_eon.c"
  "libdivecomputer/src/suunto_eon_parser.c"
  "libdivecomputer/src/suunto_eonsteel.c"
  "libdivecomputer/src/suunto_eonsteel_parser.c"
  "libdivecomputer/src/suunto_solution.c"
  "libdivecomputer/src/suunto_solution_parser.c"
  "libdivecomputer/src/suunto_vyper.c"
  "libdivecomputer/src/suunto_vyper_parser.c"
  "libdivecomputer/src/suunto_vyper2.c"
  "libdivecomputer/src/tecdiving_divecomputereu.c"
  "libdivecomputer/src/tecdiving_divecomputereu_parser.c"
  "libdivecomputer/src/uwatec_aladin.c"
  "libdivecomputer/src/uwatec_memomouse.c"
  "libdivecomputer/src/uwatec_memomouse_parser.c"
  "libdivecomputer/src/uwatec_smart.c"
  "libdivecomputer/src/uwatec_smart_parser.c"
  "libdivecomputer/src/zeagle_n2ition3.c"
)

target_link_libraries(libdivecomputer PRIVATE hidapi::hidapi)
target_link_libraries(libdivecomputer PRIVATE libusb)

set_target_properties(libdivecomputer PROPERTIES
  PUBLIC_HEADER dive_computer.h
  OUTPUT_NAME "libdivecomputer"
)

target_compile_definitions(libdivecomputer PUBLIC DART_SHARED_LIB)
