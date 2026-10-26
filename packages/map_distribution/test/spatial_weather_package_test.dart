import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  test('new weather states require a separately advertised capability', () {
    final files = spatialPayload();
    files['project/project.visual.json'] = utf8.encode(jsonEncode(SpatialVisualDocument(profile: SpatialVisualPatch.fromJson({'weatherKind': 'tempest'})).toJson()));
    final caps = ['map3d@1', SpatialVisualDocument.capabilityId, SpatialWeatherCapabilities.capabilityId];
    expect(() => const GamePackageBuilder().build(manifest: spatialManifest(capabilities: caps), payloadFiles: files), throwsA(isA<GamePackageFormatException>().having((error) => error.message, 'capability', contains(SpatialWeatherCapabilities.extendedCapabilityId))));
    final built = const GamePackageBuilder().build(manifest: spatialManifest(capabilities: [...caps, SpatialWeatherCapabilities.extendedCapabilityId]), payloadFiles: files);
    expect(const GamePackageInspector().inspect(built.packageBytes).manifest.compatibility.requiredCapabilities, contains(SpatialWeatherCapabilities.extendedCapabilityId));
  });
  for (final sound in [false, true]) {
  for (final sidecar in [false, true]) {
    test(
        'weather sound=$sound admission is capability gated for ${sidecar ? 'atmosphere' : 'visual'} documents',
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
                              enabled: true, kind: SpatialWeatherKind.snow, soundEnabled: sound)))
                  .toJson()
              : SpatialVisualDocument(
                  profile: SpatialVisualPatch.fromJson({
                  'weatherEnabled': true,
                  'weatherKind': 'snow',
                  'weatherIntensity': .8,
                  if (sound) 'weatherSoundEnabled': true
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
      if (sound) {
        expect(() => const GamePackageBuilder().build(manifest: spatialManifest(capabilities: [...base, SpatialWeatherCapabilities.capabilityId]), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>().having((e) => e.message, 'capability', contains(SpatialWeatherCapabilities.soundCapabilityId))));
      }
      final built = const GamePackageBuilder().build(
          manifest: spatialManifest(
              capabilities: [...base, SpatialWeatherCapabilities.capabilityId, if (sound) SpatialWeatherCapabilities.soundCapabilityId]),
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
}
