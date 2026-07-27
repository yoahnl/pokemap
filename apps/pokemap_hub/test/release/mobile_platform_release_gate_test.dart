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

    expect(ios['status'], 'build-and-simulator-target');
    expect(ios['releaseGate'], 'device-build-and-simulator-launch');
    expect(ios['deviceDistribution'], 'not-certified');
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

  test('release workflow builds iOS and launches it on a simulator', () async {
    final workflow = await File(
      '../../.github/workflows/pokemap_hub_product_certification.yml',
    ).readAsString();

    expect(workflow, contains('ios-simulator-certification:'));
    expect(workflow, contains('flutter build ios --release --no-codesign'));
    expect(workflow, contains('flutter build ios --simulator --debug'));
    expect(
      workflow,
      contains(
        'xcrun simctl launch "\$SIMULATOR_ID" '
        'com.yoahnl.avelune.player',
      ),
    );
    expect(
      workflow,
      contains(
        'xcrun simctl terminate "\$SIMULATOR_ID" '
        'com.yoahnl.avelune.player',
      ),
    );
    expect(
      workflow,
      isNot(contains('xcrun simctl launch "\$SIMULATOR_ID" app.pokemap')),
    );
  });
}
