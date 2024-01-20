# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(dive_computer_library VERSION 0.0.1 LANGUAGES C)

add_library(dive_computer SHARED
  "dive_computer.c"
)

set_target_properties(dive_computer PROPERTIES
  PUBLIC_HEADER dive_computer.h
  OUTPUT_NAME "dive_computer"
)

target_compile_definitions(dive_computer PUBLIC DART_SHARED_LIB)
