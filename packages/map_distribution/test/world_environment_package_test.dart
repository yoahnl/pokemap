import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  test(
      'world environment exports require explicit support while legacy exports remain admitted',
      () {
    final files = spatialPayload();
    final base = [
      'map3d@1',
      SpatialVisualDocument.capabilityId,
      SpatialWeatherCapabilities.capabilityId
    ];
    files['project/project.visual.json'] =
        utf8.encode(jsonEncode(SpatialVisualDocument(
            profile: SpatialVisualPatch.fromJson({
      'timeMode': 'real',
      'weatherMode': 'real',
      'weatherSequence': ['clear', 'rain'],
    })).toJson()));
    expect(
        () => const GamePackageBuilder().build(
            manifest: spatialManifest(capabilities: base), payloadFiles: files),
        throwsA(isA<GamePackageFormatException>().having(
            (e) => e.message,
            'capability',
            contains(WorldEnvironmentCapabilities.capabilityId))));
    expect(() => const GamePackageBuilder().build(manifest: spatialManifest(capabilities: [...base, WorldEnvironmentCapabilities.capabilityId, WorldEnvironmentCapabilities.realWeatherCapabilityId]), payloadFiles: files), throwsA(isA<GamePackageFormatException>().having((error) => error.message, 'capability', contains(WorldEnvironmentCapabilities.realWeatherCapabilityId))));
    final built = const GamePackageBuilder().build(
        manifest: spatialManifest(
            capabilities: [...base, WorldEnvironmentCapabilities.capabilityId, WorldEnvironmentCapabilities.realWeatherCapabilityId]),
        payloadFiles: files);
    expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .compatibility
            .requiredCapabilities,
        contains(WorldEnvironmentCapabilities.capabilityId));
    expect(AveluneRuntimeCompatibility.host().capabilities,
        contains(WorldEnvironmentCapabilities.capabilityId));
    files.remove('project/project.visual.json');
    expect(
        () => const GamePackageBuilder()
            .build(manifest: spatialManifest(), payloadFiles: files),
        returnsNormally);
  });
}
