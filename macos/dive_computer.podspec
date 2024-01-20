#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint dive_computer.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'dive_computer'
  s.version          = '0.0.1'
  s.summary          = 'DiveComputer FFI plugin for Flutter.'
  s.description      = <<-DESC
DiveComputer FFI plugin for Flutter.
                       DESC
  s.homepage         = 'https://divenote.app'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sebastian Schneider' => 'hello@divenote.app' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/../src/libdivecomputer/include"'
  }
end
