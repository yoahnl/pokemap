import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS Help menu emits a Dart manual-check request', () {
    final menu =
        File('macos/Runner/Base.lproj/MainMenu.xib').readAsStringSync();
    final appDelegate =
        File('macos/Runner/AppDelegate.swift').readAsStringSync();
    final window =
        File('macos/Runner/MainFlutterWindow.swift').readAsStringSync();

    expect(menu, contains('title="Check for Updates…"'));
    expect(menu, contains('selector="checkForUpdates:"'));
    expect(appDelegate, contains('EditorUpdateBridge.requestManualCheck()'));
    expect(window, contains('name: "map_editor/editor_updates"'));
    expect(window, contains('"manualCheckRequested"'));
  });

  test('both desktop runners open trusted update links natively', () {
    final macos =
        File('macos/Runner/MainFlutterWindow.swift').readAsStringSync();
    final windows =
        File('windows/runner/flutter_window.cpp').readAsStringSync();

    expect(macos, contains('case "openExternalUri"'));
    expect(macos, contains('NSWorkspace.shared.open'));
    expect(windows, contains('"map_editor/editor_updates"'));
    expect(windows, contains('openExternalUri'));
    expect(windows, contains('ShellExecuteW'));
  });
}
