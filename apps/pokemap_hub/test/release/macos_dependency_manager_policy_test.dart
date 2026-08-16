import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hub locks native plugins to Swift Package Manager', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final xcodeProject =
        File('macos/Runner.xcodeproj/project.pbxproj').readAsStringSync();

    expect(pubspec, contains('enable-swift-package-manager: true'));
    expect(
      xcodeProject,
      contains('FlutterGeneratedPluginSwiftPackage in Frameworks'),
    );
    expect(xcodeProject, contains('isa = XCLocalSwiftPackageReference;'));
    expect(xcodeProject, contains('packageProductDependencies'));
  });

  test('Hub registers the macOS media plugins used by the Player', () {
    final registrant =
        File(
          'macos/Flutter/GeneratedPluginRegistrant.swift',
        ).readAsStringSync();

    for (final plugin in <String>[
      'AudioplayersDarwinPlugin.register',
      'FilePickerPlugin.register',
      'FileSelectorPlugin.register',
      'VideoPlayerPlugin.register',
    ]) {
      expect(registrant, contains(plugin), reason: plugin);
    }
  });

  test('Hub macOS project contains no CocoaPods integration', () {
    expect(File('macos/Podfile').existsSync(), isFalse);
    expect(File('macos/Podfile.lock').existsSync(), isFalse);
    expect(Directory('macos/Pods').existsSync(), isFalse);

    for (final path in <String>[
      'macos/.gitignore',
      'macos/Flutter/Flutter-Debug.xcconfig',
      'macos/Flutter/Flutter-Release.xcconfig',
      'macos/Runner.xcodeproj/project.pbxproj',
      'macos/Runner.xcworkspace/contents.xcworkspacedata',
    ]) {
      final contents = File(path).readAsStringSync();
      expect(contents, isNot(contains('Pods')), reason: path);
      expect(contents, isNot(contains('CocoaPods')), reason: path);
    }
  });
}
