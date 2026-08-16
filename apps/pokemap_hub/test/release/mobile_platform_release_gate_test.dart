import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/core/config/public_product_identity.dart';

void main() {
  test(
    'mobile support claims are explicit and match committed runners',
    () async {
      final support =
          jsonDecode(
                await File('tool/release/platform_support.json').readAsString(),
              )
              as Map<String, Object?>;
      final platforms = support['platforms'] as Map<String, Object?>;
      final ios = platforms['ios'] as Map<String, Object?>;
      final android = platforms['android'] as Map<String, Object?>;

      expect(ios['status'], 'xcode-cloud-target');
      expect(ios['releaseGate'], 'xcode-cloud');
      expect(ios['deviceDistribution'], 'xcode-cloud');
      expect(android['status'], 'build-target');
      expect(android['releaseGate'], 'release-apk-build');
      expect(android['deviceDistribution'], 'github-release');
      expect((ios['capabilities'] as Map)['video'], 'supported');
      expect((android['capabilities'] as Map)['video'], 'supported');
      expect(Directory('ios').existsSync(), isTrue);
      expect(Directory('android').existsSync(), isTrue);
    },
  );

  test(
    'iOS native plugins are linked only through Swift Package Manager',
    () async {
      final pubspec = await File('pubspec.yaml').readAsString();
      final xcodeProject =
          await File('ios/Runner.xcodeproj/project.pbxproj').readAsString();

      expect(pubspec, contains('enable-swift-package-manager: true'));
      expect(
        xcodeProject,
        contains('FlutterGeneratedPluginSwiftPackage in Frameworks'),
      );
      expect(xcodeProject, contains('isa = XCLocalSwiftPackageReference;'));
      expect(xcodeProject, contains('packageProductDependencies'));
      expect(
        xcodeProject,
        isNot(contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0')),
      );
      expect(xcodeProject, contains('IPHONEOS_DEPLOYMENT_TARGET = 15.0'));
      expect(
        await File('ios/Flutter/AppFrameworkInfo.plist').readAsString(),
        contains('<string>15.0</string>'),
      );
      expect(File('ios/Podfile').existsSync(), isFalse);
      expect(File('ios/Podfile.lock').existsSync(), isFalse);
      expect(Directory('ios/Pods').existsSync(), isFalse);

      for (final path in <String>[
        'ios/.gitignore',
        'ios/Flutter/Debug.xcconfig',
        'ios/Flutter/Release.xcconfig',
        'ios/Runner.xcodeproj/project.pbxproj',
        'ios/Runner.xcworkspace/contents.xcworkspacedata',
      ]) {
        final contents = await File(path).readAsString();
        expect(contents, isNot(contains('Pods')), reason: path);
        expect(contents, isNot(contains('CocoaPods')), reason: path);
        expect(contents, isNot(contains('.podspec')), reason: path);
      }
    },
  );

  test('native mobile codec smoke has a wireless-device driver', () {
    expect(
      File('test_driver/native_codec_playback_driver.dart').existsSync(),
      isTrue,
    );
  });

  test('iOS identity and public product branding belong to Avelune', () async {
    final project =
        await File('ios/Runner.xcodeproj/project.pbxproj').readAsString();
    final info = await File('ios/Runner/Info.plist').readAsString();

    expect(
      project,
      contains('PRODUCT_BUNDLE_IDENTIFIER = com.yoahnl.avelune.player;'),
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
    final activity =
        await File(
          'android/app/src/main/kotlin/com/yoahnl/avelune/player/MainActivity.kt',
        ).readAsString();
    final productIdentity =
        await File(
          'lib/core/config/public_product_identity.dart',
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
    // Behaviour, not source text: the mapping used to be a switch and is now
    // unconditional, since desktop renders the same console as mobile.
    expect(publicProductNameForOperatingSystem('android'), 'Avelune');
    expect(productIdentity, contains("=> 'Avelune'"));
  });

  test('Android streams selected packages into the application cache', () async {
    final activity =
        await File(
          'android/app/src/main/kotlin/com/yoahnl/avelune/player/MainActivity.kt',
        ).readAsString();
    final adapter =
        await File(
          'lib/platform/android_hub_platform_adapter.dart',
        ).readAsString();

    expect(activity, contains('Intent.ACTION_OPEN_DOCUMENT'));
    expect(activity, contains('input.copyTo(output, bufferSize = 64 * 1024)'));
    expect(activity, isNot(contains('readBytes')));
    expect(adapter, contains("invokeMethod<String>('pickPackage')"));
    expect(adapter, isNot(contains('openFile(')));
  });

  test('GitHub delegates iOS to Xcode Cloud and releases Android', () async {
    final hubWorkflow =
        await File(
          '../../.github/workflows/pokemap_hub_product_certification.yml',
        ).readAsString();
    final androidWorkflow =
        await File(
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
      androidWorkflow,
      contains('AVELUNE_REQUIRE_RELEASE_SIGNING: "true"'),
    );
    expect(androidWorkflow, contains('Validate Avelune release version'));
    expect(
      androidWorkflow,
      contains(r'test "$RELEASE_TAG" = "avelune-v$VERSION"'),
    );
    expect(
      androidWorkflow,
      contains(r'test "$REQUEST_CONFIRMATION" = RELEASE'),
    );
    expect(
      androidWorkflow,
      isNot(contains(r'test "${{ inputs.confirmation }}" = RELEASE')),
    );
    expect(androidWorkflow, contains('Avelune-android-'));
    expect(androidWorkflow, contains(r'gh release create "$RELEASE_TAG"'));
    expect(androidWorkflow, isNot(contains('PokeMap-android')));
  });

  test('GitHub publishes signed Android bundles to Play internal', () async {
    final androidWorkflow =
        await File(
          '../../.github/workflows/avelune_android_release.yml',
        ).readAsString();

    expect(androidWorkflow, contains('flutter build appbundle --release'));
    expect(androidWorkflow, contains('publish-play-internal:'));
    expect(androidWorkflow, contains('id-token: write'));
    expect(
      androidWorkflow,
      contains(
        'google-github-actions/auth@'
        '7c6bc770dae815cd3e89ee6cdf493a5fab2cc093',
      ),
    );
    expect(
      androidWorkflow,
      contains(r'${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}'),
    );
    expect(androidWorkflow, contains(r'${{ vars.GCP_SERVICE_ACCOUNT }}'));
    expect(
      androidWorkflow,
      contains('https://www.googleapis.com/auth/androidpublisher'),
    );
    expect(androidWorkflow, contains('com.yoahnl.avelune.player'));
    expect(androidWorkflow, contains('AVELUNE_PLAY_TRACK: internal'));
    expect(androidWorkflow, contains('edits/\$EDIT_ID/bundles'));
    expect(
      androidWorkflow,
      contains('edits/\$EDIT_ID/tracks/\$AVELUNE_PLAY_TRACK'),
    );
    expect(androidWorkflow, contains('edits/\$EDIT_ID:commit'));
  });
}
