import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'standalone iOS plugins use Swift Package Manager exclusively',
    () async {
      final pubspec = await File('pubspec.yaml').readAsString();
      final xcodeProject = await File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsString();

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
        'ios/Flutter/Profile.xcconfig',
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

  test('standalone commits launchable iOS and Android runners', () {
    final gradleProperties = File(
      'android/gradle.properties',
    ).readAsStringSync();

    expect(Directory('ios/Runner.xcodeproj').existsSync(), isTrue);
    expect(File('android/settings.gradle.kts').existsSync(), isTrue);
    expect(File('android/app/build.gradle.kts').existsSync(), isTrue);
    expect(
      File('android/app/src/main/AndroidManifest.xml').existsSync(),
      isTrue,
    );
    expect(gradleProperties, contains('android.builtInKotlin=false'));
    expect(gradleProperties, contains('android.newDsl=false'));
  });
}
