import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  for (final sidecar in [false, true]) {
    test(
        'weather admission is capability gated for ${sidecar ? 'atmosphere' : 'visual'} documents',
        () {
      final files = spatialPayload();
      files[sidecar
              ? 'project/maps/map.atmosphere.json'
              : 'project/project.visual.json'] =
          utf8.encode(jsonEncode(sidecar
              ? SpatialAtmosphereDocument(
                      mapId: 'map',
                      settings: SpatialAtmosphereSettings(
                          weather: SpatialWeatherSettings(
                              enabled: true, kind: SpatialWeatherKind.snow)))
                  .toJson()
              : SpatialVisualDocument(
                  profile: SpatialVisualPatch.fromJson({
                  'weatherEnabled': true,
                  'weatherKind': 'snow',
                  'weatherIntensity': .8
                })).toJson()));
      final base = [
        'map3d@1',
        if (!sidecar) SpatialVisualDocument.capabilityId
      ];
      expect(
          () => const GamePackageBuilder().build(
              manifest: spatialManifest(capabilities: base),
              payloadFiles: files),
          throwsA(isA<GamePackageFormatException>().having(
              (e) => e.message,
              'capability',
              contains(SpatialWeatherCapabilities.capabilityId))));
      final built = const GamePackageBuilder().build(
          manifest: spatialManifest(
              capabilities: [...base, SpatialWeatherCapabilities.capabilityId]),
          payloadFiles: files);
      expect(
          const GamePackageInspector()
              .inspect(built.packageBytes)
              .manifest
              .compatibility
              .requiredCapabilities,
          contains(SpatialWeatherCapabilities.capabilityId));
      expect(AveluneRuntimeCompatibility.host().capabilities,
          contains(SpatialWeatherCapabilities.capabilityId));
    });
  }
}
