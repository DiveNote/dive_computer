# dive_computer

A Flutter plugin for communication with dive computers using the library [libdivecomputer](http://www.libdivecomputer.org/).

[![pub.dev release][release]][release]
[![License][license]](LICENSE)


## Installation

### Android, Windows, Linux

The required library is automatically bundled with the plugin.
No further installation steps are required.

### iOS, MacOS

The required library needs to be linked with with your Runner.
Please follow the instructions for linking a [compiled (dynamic) library](https://docs.flutter.dev/platform-integration/macos/c-interop#compiled-dynamic-library-macos).


## Usage

This plugin automatically spawns its own isolate for communication with the dive computer.

Please refer to the example app for a minimalistic example usage.



[license]: https://img.shields.io/github/license/DiveNote/dive_computer.svg?style=for-the-badge
[release]: https://img.shields.io/pub/v/dive_computer?style=for-the-badge

