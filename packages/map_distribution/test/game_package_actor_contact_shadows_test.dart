import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  const capability = 'map3d.actor-contact-shadows@1';

  for (final inherited in [true, false]) {
    test(
        '${inherited ? 'inherited' : 'explicit'} actor contact shadows require their capability',
        () {
      final files = _payload(
        projectDefault: inherited,
        characterOverride: inherited ? null : true,
      );
      expect(
        () => const GamePackageBuilder().build(
          manifest: spatialManifest(),
          payloadFiles: files,
        ),
        throwsA(isA<GamePackageFormatException>().having(
          (error) => error.message,
          'message',
          contains(capability),
        )),
      );
      final built = const GamePackageBuilder().build(
        manifest: spatialManifest(capabilities: ['map3d@1', capability]),
        payloadFiles: files,
      );
      expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .compatibility
            .requiredCapabilities,
        contains(capability),
      );
      for (final supported in [false, true]) {
        final host = GamePackageHostCompatibility(
          hubVersion: Version.parse('1.2.0'),
          runtimeApiVersion: Version.parse('1.4.0'),
          capabilities: {
            'map3d@1',
            'catalog.partitioned@2',
            if (supported) capability,
          },
          supportedProjectFormats: {'v9'},
          currentProjectFormat: 'v9',
          supportedSaveFormats: {1},
        );
        GamePackageInspectionResult inspect() =>
            GamePackageInspector(hostCompatibility: host)
                .inspect(built.packageBytes);
        if (supported) {
          expect(inspect().compatibility?.decision,
              GamePackageCompatibilityDecision.accept);
        } else {
          expect(
            inspect,
            throwsA(isA<GamePackageFormatException>().having(
              (error) => error.code,
              'code',
              'capabilityUnsupported',
            )),
          );
        }
      }
    });
  }

  test('all explicit disabled characters suppress the enabled project default',
      () {
    final built = const GamePackageBuilder().build(
      manifest: spatialManifest(),
      payloadFiles: _payload(projectDefault: true, characterOverride: false),
    );
    expect(built.manifest.compatibility.requiredCapabilities,
        isNot(contains(capability)));
  });

  test(
      'default disabled character shadows retain existing package requirements',
      () {
    final built = const GamePackageBuilder().build(
      manifest: spatialManifest(),
      payloadFiles: _payload(projectDefault: false),
    );
    expect(built.manifest.compatibility.requiredCapabilities,
        isNot(contains(capability)));
  });
}

Map<String, List<int>> _payload({
  required bool projectDefault,
  bool? characterOverride,
}) {
  final files = spatialPayload();
  final project = ProjectManifest.fromJson(
    jsonDecode(utf8.decode(files['project/project.json']!)),
  );
  files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(
    settings:
        project.settings.copyWith(actorContactShadowsByDefault: projectDefault),
    characters: [
      for (final character in project.characters)
        character.copyWith(contactShadow: characterOverride)
    ],
  ).toJson()));
  return files;
}
