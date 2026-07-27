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
    expect(android['status'], 'not-claimed');
    expect(android['releaseGate'], 'none');
    expect(Directory('ios').existsSync(), isTrue);
    expect(Directory('android').existsSync(), isFalse);
  });

  test('iOS identity and product branding belong to PokeMap Hub', () async {
    final project = await File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsString();
    final info = await File('ios/Runner/Info.plist').readAsString();

    expect(project, contains('PRODUCT_BUNDLE_IDENTIFIER = app.pokemap.hub;'));
    expect(project,
        contains('INFOPLIST_KEY_CFBundleDisplayName = "PokeMap Hub";'));
    expect(project, isNot(contains('com.yoahnl.avelune')));
    expect(info, contains('<string>PokeMap Hub</string>'));
    expect(info, isNot(contains('Avelune')));
  });

  test('release workflow builds iOS and launches it on a simulator', () async {
    final workflow = await File(
      '../../.github/workflows/pokemap_hub_product_certification.yml',
    ).readAsString();

    expect(workflow, contains('ios-simulator-certification:'));
    expect(workflow, contains('flutter build ios --release --no-codesign'));
    expect(workflow, contains('flutter build ios --simulator --debug'));
    expect(workflow, contains('xcrun simctl launch'));
  });
}
