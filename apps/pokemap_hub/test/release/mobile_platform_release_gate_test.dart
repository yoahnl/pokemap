import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SwiftUI owns the Avelune iOS bundle and embeds the shared runtime', () {
    final project = File('../Avelune iOS/project.yml').readAsStringSync();
    final xcodeProject =
        File(
          '../Avelune iOS/AveluneiOS.xcodeproj/project.pbxproj',
        ).readAsStringSync();
    final module =
        File('../Avelune iOS/flutter_runtime/pubspec.yaml').readAsStringSync();
    final runtime =
        File('../Avelune iOS/flutter_runtime/lib/main.dart').readAsStringSync();

    expect(
      project,
      contains('PRODUCT_BUNDLE_IDENTIFIER: com.yoahnl.avelune.player'),
    );
    expect(
      project,
      contains(
        'path: flutter_runtime/build/swift-package/FlutterNativeIntegration',
      ),
    );
    expect(
      RegExp(
        r'PRODUCT_BUNDLE_IDENTIFIER = com\.yoahnl\.avelune\.player;',
      ).allMatches(xcodeProject),
      hasLength(4),
    );
    expect(module, contains('pokemap_hub:'));
    expect(module, contains('path: ../../pokemap_hub'));
    expect(runtime, contains('HubInstalledGamePlayer('));
    expect(runtime, contains('InstallGamePackageUseCase'));
  });

  test('the retired Flutter mobile hosts cannot be distributed', () {
    expect(File('ios/Runner.xcodeproj/project.pbxproj').existsSync(), isFalse);
    expect(File('android/app/build.gradle.kts').existsSync(), isFalse);
    expect(
      File('../../.github/workflows/avelune_android_release.yml').existsSync(),
      isFalse,
    );

    final support =
        jsonDecode(
              File('tool/release/platform_support.json').readAsStringSync(),
            )
            as Map<String, Object?>;
    final platforms = support['platforms'] as Map<String, Object?>;
    expect(
      (platforms['ios'] as Map)['distributionLifecycle'],
      'native-swiftui-host',
    );
    expect(
      (platforms['android'] as Map)['distributionLifecycle'],
      'planned-native-host',
    );
    expect((platforms['android'] as Map)['releaseGate'], 'none');
  });
}
