Pod::Spec.new do |s|
  s.name             = 'gamepads_darwin'
  s.version          = '0.1.1'
  s.summary          = 'MacOS implementation of gamepads.'
  s.description      = 'MacOS implementation of gamepads, a Flutter plugin to handle gamepad input across multiple platforms.'
  s.homepage         = 'https://flame-engine.org'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Luan' => 'luan@blue-fire.xyz' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
