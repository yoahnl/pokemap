import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('standalone locks native plugins to Swift Package Manager', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('enable-swift-package-manager: true'));
    expect(
      pubspec,
      matches(
        RegExp(
          r'dependency_overrides:\s+gamepads_darwin:\s+path: ../../packages/gamepads_darwin',
          multiLine: true,
        ),
      ),
    );
  });

  test('standalone macOS project contains no CocoaPods integration', () {
    expect(File('macos/Podfile').existsSync(), isFalse);
    expect(File('macos/Podfile.lock').existsSync(), isFalse);

    for (final path in <String>[
      'macos/.gitignore',
      'macos/Flutter/Flutter-Debug.xcconfig',
      'macos/Flutter/Flutter-Release.xcconfig',
      'macos/Runner.xcodeproj/project.pbxproj',
      'macos/Runner.xcworkspace/contents.xcworkspacedata',
    ]) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains('Pods')),
        reason: path,
      );
    }
  });
}
