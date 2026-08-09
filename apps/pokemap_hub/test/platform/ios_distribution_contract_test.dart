import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('application bootstrap uses a platform-neutral Hub composition',
      () async {
    final main = await File('lib/main.dart').readAsString();
    final bootstrap =
        await File('lib/app/app_root.dart').readAsString();
    final composition =
        await File('lib/app/di/hub_composition.dart').readAsString();

    expect(main, contains('PokeMapHubBootstrap'));
    expect(main, isNot(contains('MacOSHubComposition')));
    expect(composition, contains('HubPlatformAdapter'));
    expect(composition, contains('PokeMapHubApp'));
    expect(bootstrap, contains('publicProductName'));
    expect(composition, contains('publicProductName'));
    expect(
      bootstrap,
      contains('package:pokemap_hub/core/config/public_product_identity.dart'),
    );
    expect(
      composition,
      contains('package:pokemap_hub/core/config/public_product_identity.dart'),
    );
  });

  test('iOS adapter uses the native Hub channel for picker and disk space',
      () async {
    final adapter = await File(
      'lib/platform/ios_hub_platform_adapter.dart',
    ).readAsString();

    expect(
      adapter,
      contains("MethodChannel('com.yoahnl.avelune.player/ios')"),
    );
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
    expect(appDelegate, contains('com.yoahnl.avelune.player/ios'));
    expect(appDelegate, isNot(contains('PokeMap Hub')));
    expect(appDelegate, contains('UIDocumentPickerViewController'));
    expect(appDelegate, contains('UIDocumentPickerDelegate'));
    expect(appDelegate, contains('"avelunegame", "pokemapgame"'));
    expect(appDelegate, contains('case "pickPackage"'));
    expect(appDelegate, contains('case "availableDiskBytes"'));
    expect(
      appDelegate,
      contains('volumeAvailableCapacityForImportantUsage'),
    );
    expect(info, contains('com.yoahnl.avelune.game-package'));
    expect(info, isNot(contains('app.pokemap.game-package')));
    expect(info, contains('<string>avelunegame</string>'));
    expect(info, contains('<string>pokemapgame</string>'));
    expect(info, contains('<key>NSPhotoLibraryUsageDescription</key>'));
    expect(
      info,
      contains(
        '<string>Avelune utilise votre photothèque uniquement pour choisir un fond personnalisé.</string>',
      ),
    );
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
    expect(info, isNot(contains('PokeMap Hub')));
    expect(info, isNot(contains('PokeMap Game Package')));
  });
}
