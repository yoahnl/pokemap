import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retired Flutter desktop hosts have no release runners', () {
    expect(
      File('macos/Runner.xcodeproj/project.pbxproj').existsSync(),
      isFalse,
    );
    expect(File('windows/runner/main.cpp').existsSync(), isFalse);
    expect(File('linux/runner/main.cc').existsSync(), isFalse);

    final workflow =
        File(
          '../../.github/workflows/pokemap_hub_product_certification.yml',
        ).readAsStringSync();
    expect(workflow, isNot(contains('flutter build macos --release')));
    expect(workflow, isNot(contains('flutter build windows --release')));
    expect(workflow, isNot(contains('flutter build linux --release')));
    expect(workflow, isNot(contains('notarized-release:')));

    final support =
        jsonDecode(
              File('tool/release/platform_support.json').readAsStringSync(),
            )
            as Map<String, Object?>;
    final platforms = support['platforms'] as Map<String, Object?>;
    for (final platform in ['macos', 'windows', 'linux']) {
      final entry = platforms[platform] as Map;
      expect(entry['distributionLifecycle'], 'retired-standalone-host');
      expect(entry['releaseGate'], 'none');
    }
  });

  test('the shared Flutter library remains available to the iOS runtime', () {
    expect(File('lib/pokemap_hub_ui.dart').existsSync(), isTrue);
    expect(
      File(
        'lib/features/installation/application/use_cases/install_game_package_use_case.dart',
      ).existsSync(),
      isTrue,
    );
    expect(File('lib/main.dart').existsSync(), isFalse);
  });
}
