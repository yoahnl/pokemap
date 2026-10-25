import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  test(
      'optional presentation sidecar round trips without adding gameplay requirements',
      () {
    final files = spatialPayload();
    files['project/maps/map.atmosphere.json'] = utf8.encode(jsonEncode(
        SpatialAtmosphereDocument(
                mapId: 'map',
                settings: SpatialAtmosphereSettings(fireflies: true))
            .toJson()));
    final result = const GamePackageBuilder()
        .build(manifest: spatialManifest(), payloadFiles: files);
    expect(
        const GamePackageInspector()
            .inspect(result.packageBytes)
            .manifest
            .compatibility
            .requiredCapabilities,
        result.manifest.compatibility.requiredCapabilities);
  });
  for (final bad in [
    {'schemaVersion': 2, 'mapId': 'map', 'settings': {}},
    {'schemaVersion': 1, 'mapId': 'other', 'settings': {}}
  ]) {
    test(
        'malformed or future atmosphere is rejected without mutating its bytes: $bad',
        () {
      final files = spatialPayload();
      final bytes = utf8.encode(jsonEncode(bad));
      files['project/maps/map.atmosphere.json'] = bytes;
      expect(
          () => const GamePackageBuilder()
              .build(manifest: spatialManifest(), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>()));
      expect(files['project/maps/map.atmosphere.json'], bytes);
    });
  }
}
