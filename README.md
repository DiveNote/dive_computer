# dive_computer

A Flutter plugin for communication with dive computers using the library [libdivecomputer](http://www.libdivecomputer.org/).

[![pub.dev release][release]][release]
[![License][license]](LICENSE)


## Installation

TODO


## Usage

This plugin automatically spawns its own isolate for communication with the dive computer.

Please refer to the example app for a minimalistic example usage.

# macOS

This plugin supports USB and Serial connection on macOS. On macOS you need to make sure the app has access to the USB connection granted. To do so add the following snippet to info.plist and make sure you grant USB access in xcode via `Signing & Capabilities -> Hardware -> USB`.
```
<key>NSUSBPeripheralUsageDescription</key>
<string>Your explanation here</string>
```

---

### Acknowledgements

Parts of this project are using the library [libdivecomputer](https://www.libdivecomputer.org/).

> libdivecomputer Copyright (c) 2008 Jef Driesen

<sup>The library is licensed under the GNU Lesser General Public License version 2.1.</sup>

[license]: https://img.shields.io/github/license/DiveNote/dive_computer.svg?style=for-the-badge
[release]: https://img.shields.io/pub/v/dive_computer?style=for-the-badge

