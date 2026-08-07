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

  test('Debug can read a package explicitly selected by the player', () async {
    final entitlements =
        await File('macos/Runner/DebugProfile.entitlements').readAsString();

    expect(entitlements, contains('com.apple.security.app-sandbox'));
    expect(
      entitlements,
      contains('com.apple.security.files.user-selected.read-only'),
    );
  });

  test('macOS reports a missing picker entitlement instead of failing silently',
      () async {
    final window =
        await File('macos/Runner/MainFlutterWindow.swift').readAsString();
    final adapter = await File(
      'lib/platform/macos_hub_platform_adapter.dart',
    ).readAsString();

    expect(window, contains('import Security'));
    expect(window, contains('canSelectPackages'));
    expect(window, contains('SecTaskCopyValueForEntitlement'));
    expect(
      window,
      contains('com.apple.security.files.user-selected.read-only'),
    );
    expect(
      adapter,
      contains("invokeMethod<bool>('canSelectPackages')"),
    );
    expect(adapter, contains('HubPackagePickerFailure'));
  });

  test('macOS package picker uses the Hub native bridge', () async {
    final window =
        await File('macos/Runner/MainFlutterWindow.swift').readAsString();
    final adapter = await File(
      'lib/platform/macos_hub_platform_adapter.dart',
    ).readAsString();

    expect(window, contains('import UniformTypeIdentifiers'));
    expect(window, contains('case "pickPackage"'));
    expect(window, contains('NSOpenPanel()'));
    expect(window, contains('allowedContentTypes'));
    expect(
      adapter,
      contains("invokeMethod<String>('pickPackage')"),
    );
    expect(adapter, isNot(contains('openFile(')));
  });

  test('application entry point composes PokeMap Hub, not a demo counter',
      () async {
    final main = await File('lib/main.dart').readAsString();
    final composition =
        await File('lib/app/di/hub_composition.dart').readAsString();
    // The installer moved out of the composition root into the DI layer when
    // the dashboard became a Notifier; the assertion follows it rather than
    // being dropped.
    final installerWiring = await File(
      'lib/app/di/installation_repository_provider.dart',
    ).readAsString();

    expect(main, contains('PokeMapHubBootstrap'));
    expect(main, contains('ProviderScope'));
    expect(main, isNot(contains('MacOSHubComposition')));
    expect(composition, contains('PokeMapHubApp'));
    expect(installerWiring, contains('GamePackageInstaller'));
    expect(installerWiring, contains('loadInstalledProjectSmoke'));
    expect(main, isNot(contains('Flutter Demo')));
    expect(main, isNot(contains('MyHomePage')));
  });

  test('macOS open-file events are forwarded to the Dart import bridge',
      () async {
    final appDelegate =
        await File('macos/Runner/AppDelegate.swift').readAsString();
    final window =
        await File('macos/Runner/MainFlutterWindow.swift').readAsString();
    final adapter = await File(
      'lib/platform/macos_hub_platform_adapter.dart',
    ).readAsString();

    expect(appDelegate, contains('openFiles filenames'));
    expect(appDelegate, contains('takePendingPackagePaths'));
    expect(window, contains('app.pokemap.hub/package_open'));
    expect(window, contains('flushPendingPackagePaths'));
    expect(adapter, contains("MethodChannel('app.pokemap.hub/package_open')"));
    expect(adapter, contains("call.method != 'openPackages'"));
    expect(adapter, contains("invokeMethod<void>('ready')"));
  });
}
