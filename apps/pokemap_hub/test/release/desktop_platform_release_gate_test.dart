import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows and Linux runners are committed as supported platforms', () {
    expect(File('windows/runner/main.cpp').existsSync(), isTrue);
    expect(File('windows/runner/Runner.rc').existsSync(), isTrue);
    expect(File('linux/runner/main.cc').existsSync(), isTrue);
    expect(File('linux/CMakeLists.txt').existsSync(), isTrue);
  });

  test('desktop support claims preserve the intro-video limitation', () async {
    final support = jsonDecode(
      await File('tool/release/platform_support.json').readAsString(),
    ) as Map<String, Object?>;
    final platforms = support['platforms'] as Map<String, Object?>;

    for (final platformName in <String>['windows', 'linux']) {
      final platform = platforms[platformName] as Map<String, Object?>;
      expect(platform['status'], 'build-and-launch-target');
      expect(platform['releaseGate'], 'release-build-and-launch');
      expect(platform['introVideoPlayback'], 'fallback-only');
    }
  });

  test('release workflow builds and launches Windows and Linux artifacts',
      () async {
    final workflow = await File(
      '../../.github/workflows/pokemap_hub_product_certification.yml',
    ).readAsString();

    expect(workflow, contains('windows-desktop-certification:'));
    expect(workflow, contains('runs-on: windows-2025'));
    expect(workflow, contains('flutter build windows --release'));
    expect(workflow, contains('Start-Process'));
    expect(workflow, contains('linux-desktop-certification:'));
    expect(workflow, contains('runs-on: ubuntu-24.04'));
    expect(workflow, contains('flutter build linux --release'));
    expect(workflow, contains('xvfb-run'));
  });
}
