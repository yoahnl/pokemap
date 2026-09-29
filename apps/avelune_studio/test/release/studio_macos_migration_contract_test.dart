import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Studio can replace the installed PokeMap macOS bundle', () {
    final config = File(
      'macos/Runner/Configs/AppInfo.xcconfig',
    ).readAsStringSync();
    final plist = File('macos/Runner/Info.plist').readAsStringSync();
    final entitlements = File(
      'macos/Runner/Release.entitlements',
    ).readAsStringSync();
    final bridge = File(
      'macos/Runner/StudioUpdaterBridge.swift',
    ).readAsStringSync();
    final projectAccess = File(
      'macos/Runner/StudioProjectAccessBridge.swift',
    ).readAsStringSync();

    expect(config, contains('PRODUCT_NAME = PokeMap'));
    expect(
      config,
      contains('PRODUCT_BUNDLE_IDENTIFIER = com.yoahnl.pokemap.editor'),
    );
    expect(plist, contains('<string>Avelune Studio</string>'));
    expect(plist, contains('pokemap-editor-update-stable/appcast-macos.xml'));
    expect(plist, contains(r'$(POKEMAP_SPARKLE_PUBLIC_ED_KEY)'));
    expect(plist, contains('<key>SURequireSignedFeed</key>'));
    expect(
      plist,
      matches(RegExp(r'<key>SUEnableAutomaticChecks</key>\s*<false/>')),
    );
    expect(entitlements, contains('com.apple.security.network.client'));
    expect(bridge, contains('map_editor/editor_updates'));
    expect(bridge, contains('respondToRestart'));
    expect(bridge, contains('shouldPostponeRelaunchForUpdate'));
    expect(bridge, contains('didFinishUpdateCycleFor'));
    expect(projectAccess, contains('map_editor.last_project_bookmark'));
    expect(projectAccess, contains('resolveLastProjectManifestPath'));
    expect(projectAccess, contains('activateProjectDirectory'));
    expect(projectAccess, contains('rememberProjectDirectory'));
    expect(
      File(
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png',
      ).existsSync(),
      isTrue,
    );
  });

  test('the stable workflow packages Studio under the existing update tag', () {
    final workflow = File(
      '../../.github/workflows/pokemap_desktop_release.yml',
    ).readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: (\d+)\.(\d+)\.(\d+)\+(\d+)$',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(version, isNotNull);
    expect(int.parse(version!.group(4)!), greaterThan(307));
    expect(workflow, contains('tags: ["pokemap-v*"]'));
    expect(workflow, contains('pokemap-editor-update-stable'));
    expect(workflow, contains('working-directory: apps/avelune_studio'));
    expect(workflow, contains('apps/avelune_studio/build/release/'));
    expect(workflow, contains('SPARKLE_PRIVATE_ED_KEY_BASE64'));
    expect(workflow, contains('POKEMAP_SPARKLE_PUBLIC_ED_KEY'));
    expect(workflow, contains('CFBundleIdentifier raw'));
    expect(workflow, contains('com.yoahnl.pokemap.editor'));
  });
}
