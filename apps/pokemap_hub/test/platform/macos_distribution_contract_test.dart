import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS runner declares the generic Hub and .pokemapgame type', () async {
    final info = await File('macos/Runner/Info.plist').readAsString();
    final appInfo =
        await File('macos/Runner/Configs/AppInfo.xcconfig').readAsString();

    expect(appInfo, contains('PRODUCT_NAME = PokeMap Hub'));
    expect(appInfo, contains('PRODUCT_BUNDLE_IDENTIFIER = app.pokemap.hub'));
    expect(appInfo.toLowerCase(), isNot(contains('selbrume')));
    expect(info, contains('<key>CFBundleDocumentTypes</key>'));
    expect(info, contains('<key>UTExportedTypeDeclarations</key>'));
    expect(info, contains('app.pokemap.game-package'));
    expect(info, contains('<string>pokemapgame</string>'));
    expect(info, contains('<string>application/x-pokemap-game</string>'));
  });

  test('Release enables hardened runtime with least-privilege entitlements',
      () async {
    final project =
        await File('macos/Runner.xcodeproj/project.pbxproj').readAsString();
    final entitlements =
        await File('macos/Runner/Release.entitlements').readAsString();

    expect(project, contains('ENABLE_HARDENED_RUNTIME = YES;'));
    expect(project, contains('CODE_SIGN_INJECT_BASE_ENTITLEMENTS = NO;'));
    expect(project, contains('MACOSX_DEPLOYMENT_TARGET = 12.0;'));
    expect(project, isNot(contains('MACOSX_DEPLOYMENT_TARGET = 10.15;')));
    expect(entitlements, contains('com.apple.security.app-sandbox'));
    expect(
      entitlements,
      contains('com.apple.security.files.user-selected.read-only'),
    );
    expect(entitlements, isNot(contains('com.apple.security.network.client')));
    expect(entitlements, isNot(contains('com.apple.security.get-task-allow')));
    expect(project, isNot(contains('DEVELOPMENT_TEAM = ')));
  });

  test('application entry point composes PokeMap Hub, not a demo counter',
      () async {
    final main = await File('lib/main.dart').readAsString();
    final composition =
        await File('lib/src/platform/macos_hub_composition.dart')
            .readAsString();

    expect(main, contains('MacOSHubComposition'));
    expect(composition, contains('PokeMapHubApp'));
    expect(composition, contains('GamePackageInstaller'));
    expect(composition, contains('_loadInstalledProjectSmoke'));
    expect(main, isNot(contains('Flutter Demo')));
    expect(main, isNot(contains('MyHomePage')));
  });

  test('macOS open-file events are forwarded to the Dart import bridge',
      () async {
    final appDelegate =
        await File('macos/Runner/AppDelegate.swift').readAsString();
    final window =
        await File('macos/Runner/MainFlutterWindow.swift').readAsString();
    final composition = await File(
      'lib/src/platform/macos_hub_composition.dart',
    ).readAsString();

    expect(appDelegate, contains('openFiles filenames'));
    expect(appDelegate, contains('takePendingPackagePaths'));
    expect(window, contains('app.pokemap.hub/package_open'));
    expect(window, contains('flushPendingPackagePaths'));
    expect(
        composition, contains("MethodChannel('app.pokemap.hub/package_open')"));
    expect(composition, contains("call.method != 'openPackages'"));
    expect(composition, contains("invokeMethod<void>('ready')"));
  });
}
