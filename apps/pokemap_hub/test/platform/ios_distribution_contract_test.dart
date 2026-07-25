import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('application bootstrap uses a platform-neutral Hub composition',
      () async {
    final main = await File('lib/main.dart').readAsString();
    final composition =
        await File('lib/src/platform/hub_composition.dart').readAsString();

    expect(main, contains('PokeMapHubBootstrap'));
    expect(main, isNot(contains('MacOSHubComposition')));
    expect(composition, contains('HubPlatformAdapter'));
    expect(composition, contains('PokeMapHubApp'));
  });

  test('iOS adapter uses the native Hub channel for picker and disk space',
      () async {
    final adapter = await File(
      'lib/src/platform/ios_hub_platform_adapter.dart',
    ).readAsString();

    expect(adapter, contains("MethodChannel('app.pokemap.hub/ios')"));
    expect(adapter, contains("invokeMethod<String>('pickPackage')"));
    expect(adapter, contains("invokeMethod<num>('availableDiskBytes')"));
    expect(adapter, isNot(contains('/bin/df')));
    expect(adapter, isNot(contains('app.pokemap.hub/package_open')));
  });

  test('iOS runner exposes a native .pokemapgame document picker', () async {
    final appDelegate =
        await File('ios/Runner/AppDelegate.swift').readAsString();
    final info = await File('ios/Runner/Info.plist').readAsString();
    final project =
        await File('ios/Runner.xcodeproj/project.pbxproj').readAsString();

    expect(appDelegate, contains('import UniformTypeIdentifiers'));
    expect(appDelegate, contains('app.pokemap.hub/ios'));
    expect(appDelegate, contains('UIDocumentPickerViewController'));
    expect(appDelegate, contains('UIDocumentPickerDelegate'));
    expect(appDelegate, contains('case "pickPackage"'));
    expect(appDelegate, contains('case "availableDiskBytes"'));
    expect(
      appDelegate,
      contains('volumeAvailableCapacityForImportantUsage'),
    );
    expect(info, contains('app.pokemap.game-package'));
    expect(info, contains('<string>pokemapgame</string>'));
    expect(
      RegExp(
        r'PRODUCT_BUNDLE_IDENTIFIER = com\.yoahnl\.avelune\.player;',
      ).allMatches(project),
      hasLength(3),
    );
    expect(
      RegExp(
        r'INFOPLIST_KEY_CFBundleDisplayName = Avelune;',
      ).allMatches(project),
      hasLength(3),
    );
    expect(info, contains('<string>Avelune</string>'));
  });
}
