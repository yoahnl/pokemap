import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  test('point shadows require their own capability and reject older lighting hosts', () {
    final payload = _payload(feature: 'point-light', castsShadows: true);
    const previous = ['map3d@1', 'map3d.point-light@1', 'map3d.shadows@1'];
    expect(() => const GamePackageBuilder().build(
      manifest: spatialManifest(capabilities: previous), payloadFiles: payload),
      throwsA(isA<GamePackageFormatException>().having((error) => error.message,
        'message', contains('map3d.point-light-shadows@1'))));
    final built = const GamePackageBuilder().build(manifest: spatialManifest(
      capabilities: [...previous, 'map3d.point-light-shadows@1']), payloadFiles: payload);
    for (final supported in [false, true]) {
      final inspector = GamePackageInspector(hostCompatibility: GamePackageHostCompatibility(
        hubVersion: Version.parse('1.2.0'), runtimeApiVersion: Version.parse('1.4.0'),
        capabilities: {...previous, 'catalog.partitioned@2', if (supported) 'map3d.point-light-shadows@1'},
        supportedProjectFormats: {'v9'}, currentProjectFormat: 'v9', supportedSaveFormats: {1}));
      if (supported) {
        expect(inspector.inspect(built.packageBytes).compatibility?.decision, GamePackageCompatibilityDecision.accept);
      } else {
        expect(() => inspector.inspect(built.packageBytes), throwsA(isA<GamePackageFormatException>()
          .having((error) => error.code, 'code', 'capabilityUnsupported')));
      }
    }
  });
  for (final feature in ['day-night', 'point-light']) {
    final capability = 'map3d.$feature@1';

    test('$feature requires its declared capability and a supporting host', () {
      final payload = _payload(feature: feature);
      expect(
        () => const GamePackageBuilder().build(
          manifest: spatialManifest(),
          payloadFiles: payload,
        ),
        throwsA(isA<GamePackageFormatException>().having(
          (error) => error.message,
          'message',
          contains(capability),
        )),
      );
      final built = const GamePackageBuilder().build(
        manifest: spatialManifest(capabilities: ['map3d@1', capability]),
        payloadFiles: payload,
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

  test('an unused illuminated resource does not require point light support',
      () {
    final built = const GamePackageBuilder().build(
      manifest: spatialManifest(),
      payloadFiles: _payload(feature: 'point-light', placed: false),
    );
    expect(built.manifest.compatibility.requiredCapabilities,
        isNot(contains('map3d.point-light@1')));
  });

  test('a zero intensity resource does not require point light support', () {
    final built = const GamePackageBuilder().build(
      manifest: spatialManifest(),
      payloadFiles: _payload(feature: 'point-light', intensity: 0),
    );
    expect(built.manifest.compatibility.requiredCapabilities,
        isNot(contains('map3d.point-light@1')));
  });

  test('scenes without lighting retain their existing package requirements',
      () {
    final built = const GamePackageBuilder().build(
      manifest: spatialManifest(),
      payloadFiles: spatialPayload(),
    );
    expect(built.manifest.compatibility.requiredCapabilities,
        isNot(anyElement(startsWith('map3d.day-night@'))));
    expect(built.manifest.compatibility.requiredCapabilities,
        isNot(anyElement(startsWith('map3d.point-light@'))));
  });
}

Map<String, List<int>> _payload({
  required String feature,
  bool placed = true,
  double intensity = 1,
  bool castsShadows = false,
}) {
  final files = spatialPayload();
  final project = ProjectManifest.fromJson(
    jsonDecode(utf8.decode(files['project/project.json']!)),
  );
  final map = MapData.fromJson(
    jsonDecode(utf8.decode(files['project/maps/map.json']!)),
  );
  files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(
    models3d: [
      project.models3d.single.copyWith(
        castsShadowsByDefault: castsShadows,
        light: feature == 'point-light'
            ? Model3dPointLight(
                localPosition: Model3dVector3(x: 0, y: 2.25, z: 0),
                intensity: intensity,
              )
            : null,
      ),
    ],
  ).toJson()));
  files['project/maps/map.json'] = utf8.encode(jsonEncode(map
      .copyWith(
        spatialScene: map.spatialScene!.copyWith(
          dayNightCycle: feature == 'day-night' ? SpatialDayNightCycle() : null,
          instances: placed ? map.spatialScene!.instances : [],
        ),
      )
      .toJson()));
  return files;
}
