import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS Help menu emits a Dart manual-check request', () {
    final menu =
        File('macos/Runner/Base.lproj/MainMenu.xib').readAsStringSync();
    final appDelegate =
        File('macos/Runner/AppDelegate.swift').readAsStringSync();
    final bridge =
        File('macos/Runner/EditorUpdaterBridge.swift').readAsStringSync();

    expect(menu, contains('title="Check for Updates…"'));
    expect(menu, contains('selector="checkForUpdates:"'));
    expect(appDelegate, contains('EditorUpdaterBridge.requestManualCheck()'));
    expect(bridge, contains('name: "map_editor/editor_updates"'));
    expect(bridge, contains('"manualCheckRequested"'));
  });

  test('both desktop runners open trusted update links natively', () {
    final macos =
        File('macos/Runner/EditorUpdaterBridge.swift').readAsStringSync();
    final windows =
        File('windows/runner/editor_updater_bridge.cpp').readAsStringSync();

    expect(macos, contains('case "openExternalUri"'));
    expect(macos, contains('NSWorkspace.shared.open'));
    expect(windows, contains('"map_editor/editor_updates"'));
    expect(windows, contains('openExternalUri'));
    expect(windows, contains('ShellExecuteW'));
  });
}
