import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Studio can rename its bundle if installed as PokeMap.app', () {
    final config = File('macos/Runner/Configs/AppInfo.xcconfig')
        .readAsStringSync();
    final plist = File('macos/Runner/Info.plist').readAsStringSync();
    final entitlements = File('macos/Runner/Release.entitlements')
        .readAsStringSync();
    final bridge = File('macos/Runner/StudioUpdaterBridge.swift')
        .readAsStringSync();
    final appDelegate = File('macos/Runner/AppDelegate.swift')
        .readAsStringSync();
    final xcodeProject = File('macos/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync();
    final projectAccess = File('macos/Runner/StudioProjectAccessBridge.swift')
        .readAsStringSync();

    expect(config, contains('PRODUCT_NAME = Avelune Studio'));
    expect(config, contains('PRODUCT_MODULE_NAME = Runner'));
    expect(xcodeProject, contains('path = "Avelune Studio.app"'));
    expect(appDelegate, contains('migrateInstalledBundleNameIfNeeded()'));
    expect(
      appDelegate,
      contains('installedBundle.lastPathComponent == "PokeMap.app"'),
    );
    expect(
      appDelegate,
      contains('Bundle.main.bundleIdentifier == "com.yoahnl.avelune.studio"'),
    );
    expect(
      appDelegate,
      contains('configuration.createsNewApplicationInstance = true'),
    );
    expect(
      config,
      contains('PRODUCT_BUNDLE_IDENTIFIER = com.yoahnl.avelune.studio'),
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
    expect(
      entitlements,
      contains('com.apple.security.files.user-selected.read-write'),
    );
    expect(appDelegate, contains('let panel = NSOpenPanel()'));
    expect(
      appDelegate,
      contains('authorizedDirectory.startAccessingSecurityScopedResource()'),
    );
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
    final workflow = File('../../.github/workflows/pokemap_desktop_release.yml')
        .readAsStringSync();
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
    expect(workflow, isNot(contains('packages/map_editor')));
    expect(workflow, contains('apps/avelune_studio/build/release/'));
    expect(workflow, contains('SPARKLE_PRIVATE_ED_KEY_BASE64'));
    expect(workflow, contains('POKEMAP_SPARKLE_PUBLIC_ED_KEY'));
    expect(
      workflow,
      contains('STUDIO_MACOS_BUNDLE_ID: com.yoahnl.avelune.studio'),
    );
    expect(
      workflow,
      contains(
        'STUDIO_MACOS_APPCAST_URL: https://github.com/yoahnl/pokemap/releases/'
        'download/pokemap-editor-update-stable/appcast-macos.xml',
      ),
    );
    const bundleIdCheck =
        r'test "$(plutil -extract CFBundleIdentifier raw "$APP_PATH/Contents/Info.plist")"'
        r' = "$STUDIO_MACOS_BUNDLE_ID"';
    const appcastCheck =
        r'test "$(plutil -extract SUFeedURL raw "$APP_PATH/Contents/Info.plist")"'
        r' = "$STUDIO_MACOS_APPCAST_URL"';
    expect(bundleIdCheck.allMatches(workflow), hasLength(3));
    expect(appcastCheck.allMatches(workflow), hasLength(3));
    for (final tool in [
      'package_macos_preview.sh',
      'package_macos_update.sh',
      'validate_release_version.dart',
      'generate_update_index.dart',
      'validate_update_assets.dart',
    ]) {
      final path = 'tool/release/$tool';
      expect(workflow, contains(path));
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    expect(
      workflow,
      contains('build/macos/Build/Products/Release/Avelune Studio.app'),
    );
    expect(
      workflow,
      isNot(contains('build/macos/Build/Products/Release/PokeMap.app')),
    );
  });
}
