import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile support claims are explicit and match committed runners',
      () async {
    final support = jsonDecode(
      await File('tool/release/platform_support.json').readAsString(),
    ) as Map<String, Object?>;
    final platforms = support['platforms'] as Map<String, Object?>;
    final ios = platforms['ios'] as Map<String, Object?>;
    final android = platforms['android'] as Map<String, Object?>;

    expect(ios['status'], 'xcode-cloud-target');
    expect(ios['releaseGate'], 'xcode-cloud');
    expect(ios['deviceDistribution'], 'xcode-cloud');
    expect(android['status'], 'build-target');
    expect(android['releaseGate'], 'release-apk-build');
    expect(android['deviceDistribution'], 'github-release');
    expect(Directory('ios').existsSync(), isTrue);
    expect(Directory('android').existsSync(), isTrue);
  });

  test('iOS identity and public product branding belong to Avelune', () async {
    final project = await File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsString();
    final info = await File('ios/Runner/Info.plist').readAsString();

    expect(
      project,
      contains(
        'PRODUCT_BUNDLE_IDENTIFIER = com.yoahnl.avelune.player;',
      ),
    );
    expect(project, contains('INFOPLIST_KEY_CFBundleDisplayName = Avelune;'));
    expect(project, isNot(contains('PRODUCT_BUNDLE_IDENTIFIER = app.pokemap')));
    expect(info, contains('<string>Avelune</string>'));
    expect(info, contains('<string>Avelune Game Package</string>'));
    expect(info, isNot(contains('PokeMap Hub')));
    expect(info, isNot(contains('PokeMap Game Package')));
  });

  test('Android identity, branding, and signing belong to Avelune', () async {
    final settings = await File('android/settings.gradle.kts').readAsString();
    final gradle = await File('android/app/build.gradle.kts').readAsString();
    final manifest =
        await File('android/app/src/main/AndroidManifest.xml').readAsString();
    final activity = await File(
      'android/app/src/main/kotlin/com/yoahnl/avelune/player/MainActivity.kt',
    ).readAsString();
    final productIdentity = await File(
      'lib/src/platform/public_product_identity.dart',
    ).readAsString();

    expect(gradle, contains('namespace = "com.yoahnl.avelune.player"'));
    expect(gradle, contains('applicationId = "com.yoahnl.avelune.player"'));
    expect(
      settings,
      contains('id("com.android.application") version "8.11.1"'),
    );
    expect(
      settings,
      contains('id("org.jetbrains.kotlin.android") version "2.2.20"'),
    );
    expect(gradle, contains('AVELUNE_KEYSTORE_PATH'));
    expect(gradle, contains('AVELUNE_KEYSTORE_PASSWORD'));
    expect(gradle, contains('AVELUNE_KEY_ALIAS'));
    expect(gradle, contains('AVELUNE_KEY_PASSWORD'));
    expect(manifest, contains('android:label="Avelune"'));
    expect(manifest, isNot(contains('PokeMap')));
    expect(activity, contains('package com.yoahnl.avelune.player'));
    expect(activity, isNot(contains('pokemap')));
    expect(productIdentity, contains("'android' || 'ios' => 'Avelune'"));
  });

  test('Android streams selected packages into the application cache',
      () async {
    final activity = await File(
      'android/app/src/main/kotlin/com/yoahnl/avelune/player/MainActivity.kt',
    ).readAsString();
    final adapter = await File(
      'lib/src/platform/android_hub_platform_adapter.dart',
    ).readAsString();

    expect(activity, contains('Intent.ACTION_OPEN_DOCUMENT'));
    expect(
      activity,
      contains('input.copyTo(output, bufferSize = 64 * 1024)'),
    );
    expect(activity, isNot(contains('readBytes')));
    expect(adapter, contains("invokeMethod<String>('pickPackage')"));
    expect(adapter, isNot(contains('openFile(')));
  });

  test('GitHub delegates iOS to Xcode Cloud and releases Android', () async {
    final hubWorkflow = await File(
      '../../.github/workflows/pokemap_hub_product_certification.yml',
    ).readAsString();
    final androidWorkflow = await File(
      '../../.github/workflows/avelune_android_release.yml',
    ).readAsString();

    expect(hubWorkflow, isNot(contains('ios-simulator-certification:')));
    expect(hubWorkflow, isNot(contains('flutter build ios')));
    expect(hubWorkflow, isNot(contains('xcrun simctl')));
    expect(androidWorkflow, contains('tags: ["avelune-v*"]'));
    expect(androidWorkflow, contains('flutter build apk --debug'));
    expect(androidWorkflow, contains('flutter build apk --release'));
    expect(androidWorkflow, contains('AVELUNE_ANDROID_KEYSTORE_BASE64'));
    expect(
        androidWorkflow, contains('AVELUNE_REQUIRE_RELEASE_SIGNING: "true"'));
    expect(androidWorkflow, contains('Validate Avelune release version'));
    expect(
      androidWorkflow,
      contains(r'test "$GITHUB_REF_NAME" = "avelune-v$VERSION"'),
    );
    expect(androidWorkflow, contains('Avelune-android-'));
    expect(
      androidWorkflow,
      contains(r'gh release create "$GITHUB_REF_NAME"'),
    );
    expect(androidWorkflow, isNot(contains('PokeMap-android')));
  });
}
