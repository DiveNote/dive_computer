# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "dive_computer")
project(${PROJECT_NAME} LANGUAGES CXX)

# List of absolute paths to libraries that should be bundled with the plugin. 
# This list could contain prebuilt libraries, or libraries created by an 
# external build triggered from this build file. 
set(dive_computer_bundled_libraries 
  ${CMAKE_CURRENT_SOURCE_DIR}/../native/lib/windows_x64/libdivecomputer-0.dll;${CMAKE_CURRENT_SOURCE_DIR}/../native/lib/windows_x64/libusb-1.0.dll;${CMAKE_CURRENT_SOURCE_DIR}/../native/lib/windows_x64/libhidapi-0.dll
  PARENT_SCOPE 
) 
