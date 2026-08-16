import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('Windows and Linux runners are committed as release targets', () {
    expect(File('windows/runner/main.cpp').existsSync(), isTrue);
    expect(File('windows/runner/Runner.rc').existsSync(), isTrue);
    expect(File('linux/runner/main.cc').existsSync(), isTrue);
    expect(File('linux/CMakeLists.txt').existsSync(), isTrue);
  });

  test('release manifest projects the canonical capability matrix', () async {
    final support =
        jsonDecode(
              await File('tool/release/platform_support.json').readAsString(),
            )
            as Map<String, Object?>;
    final platforms = support['platforms'] as Map<String, Object?>;

    expect(support['schemaVersion'], 2);
    expect(platforms.keys.toSet(), {
      for (final platform in PresentationMediaTargetPlatform.values)
        platform.name,
    });
    for (final platform in PresentationMediaTargetPlatform.values) {
      final projection = platforms[platform.name] as Map<String, Object?>;
      expect(
        projection['capabilities'],
        presentationMediaPlatformCapabilities(platform).toJson(),
        reason: platform.name,
      );
    }
  });

  test('desktop support claims preserve the intro-video limitation', () async {
    final support =
        jsonDecode(
              await File('tool/release/platform_support.json').readAsString(),
            )
            as Map<String, Object?>;
    final platforms = support['platforms'] as Map<String, Object?>;

    for (final platformName in <String>['windows', 'linux']) {
      final platform = platforms[platformName] as Map<String, Object?>;
      expect(platform['status'], 'build-and-launch-target');
      expect(platform['releaseGate'], 'release-build-and-launch');
      expect(
        platform['capabilities'],
        presentationMediaPlatformCapabilities(
          PresentationMediaTargetPlatform.values.byName(platformName),
        ).toJson(),
      );
      expect((platform['capabilities'] as Map)['video'], 'fallback-only');
    }
  });

  test('Web is explicit, uncertified and fail-closed', () async {
    final support =
        jsonDecode(
              await File('tool/release/platform_support.json').readAsString(),
            )
            as Map<String, Object?>;
    final platforms = support['platforms'] as Map<String, Object?>;
    final web = platforms['web'] as Map<String, Object?>;

    expect(web['status'], 'unsupported');
    expect(web['releaseGate'], 'fail-closed-no-runner');
    expect(
      web['capabilities'],
      presentationMediaPlatformCapabilities(
        PresentationMediaTargetPlatform.web,
      ).toJson(),
    );
    expect(web['reason'], contains('No committed Web runner'));
    expect(Directory('web').existsSync(), isFalse);
  });

  test(
    'release workflow builds and launches Windows and Linux artifacts',
    () async {
      final workflow =
          await File(
            '../../.github/workflows/pokemap_hub_product_certification.yml',
          ).readAsString();

      expect(workflow, contains('windows-desktop-certification:'));
      expect(workflow, contains('runs-on: windows-2025'));
      expect(workflow, contains('flutter build windows --release'));
      expect(workflow, contains('Start-Process'));
      expect(workflow, contains('linux-desktop-certification:'));
      expect(workflow, contains('runs-on: ubuntu-24.04'));
      expect(workflow, contains('libgstreamer1.0-dev'));
      expect(workflow, contains('libgstreamer-plugins-base1.0-dev'));
      expect(workflow, contains('flutter build linux --release'));
      expect(workflow, contains('xvfb-run'));
    },
  );

  test('Hub CI keeps visual snapshots opt-in', () async {
    final workflow =
        await File(
          '../../.github/workflows/pokemap_hub_product_certification.yml',
        ).readAsString();

    expect(
      workflow,
      contains('flutter test --timeout 2m --exclude-tags visual'),
    );
  });
}
