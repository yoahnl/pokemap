import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS runner ships as PokeMap with a production bundle identity',
      () async {
    final appInfo = await File(
      'macos/Runner/Configs/AppInfo.xcconfig',
    ).readAsString();
    final project = await File(
      'macos/Runner.xcodeproj/project.pbxproj',
    ).readAsString();
    final scheme = await File(
      'macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
    ).readAsString();

    expect(appInfo, contains('PRODUCT_NAME = PokeMap'));
    expect(
      appInfo,
      contains('PRODUCT_BUNDLE_IDENTIFIER = com.yoahnl.pokemap.editor'),
    );
    expect(appInfo, isNot(contains('com.example')));
    expect(project, contains('PokeMap.app'));
    expect(project, isNot(contains('map_editor.app')));
    expect(project, isNot(contains('com.example')));
    expect(scheme, contains('BuildableName = "PokeMap.app"'));
  });

  test('Windows runner ships a PokeMap executable and product metadata',
      () async {
    final cmake = await File('windows/CMakeLists.txt').readAsString();
    final resources = await File('windows/runner/Runner.rc').readAsString();
    final entrypoint = await File('windows/runner/main.cpp').readAsString();

    expect(cmake, contains('set(BINARY_NAME "PokeMap")'));
    expect(resources, contains('VALUE "ProductName", "PokeMap"'));
    expect(resources, contains('VALUE "OriginalFilename", "PokeMap.exe"'));
    expect(resources, isNot(contains('com.example')));
    expect(entrypoint, contains('window.Create(L"PokeMap"'));
  });

  test('Linux runner ships a PokeMap executable and application identity',
      () async {
    final cmake = await File('linux/CMakeLists.txt').readAsString();
    final entrypoint =
        await File('linux/runner/my_application.cc').readAsString();

    expect(cmake, contains('set(BINARY_NAME "pokemap")'));
    expect(cmake, contains('set(APPLICATION_ID "com.yoahnl.pokemap.editor")'));
    expect(cmake, isNot(contains('com.example')));
    expect(entrypoint, contains('gtk_window_set_title(window, "PokeMap")'));
  });

  test('macOS preview packager creates a PokeMap DMG fail-closed', () async {
    final script = await File(
      'tool/release/package_macos_preview.sh',
    ).readAsString();

    expect(script, contains('set -euo pipefail'));
    expect(script, contains("-volname 'PokeMap'"));
    expect(script, contains(r'"$hdiutil_bin" verify "$dmg_path"'));
    expect(script, contains('--app'));
    expect(script, contains('--dmg'));
  });
}
