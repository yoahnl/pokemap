import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final withSound in [false, true]) {
  test(
      'export preserves atmosphere sidecar and source bytes, with sound: $withSound',
      () async {
    final root = await Directory.systemTemp.createTemp('atmosphere-export-');
    addTearDown(() => root.delete(recursive: true));
    final files = spatialPayload();
    final sidecar = SpatialAtmosphereDocument.relativePathForMap('map');
    final settings = SpatialAtmosphereSettings(
        weather: SpatialWeatherSettings(enabled: true, kind: SpatialWeatherKind.rain, soundEnabled: withSound),
        waterAnimated: true,
        windowsLit: true,
        fireflies: true, fireflyLighting: true, fireflyPinkAmount: .5,
        depthOfFieldEnabled: true, depthOfFieldStrength: .65, depthOfFieldFocusRange: 18, halosEnabled: true, depthFogEnabled: true, haloStrength: 1.4, haloSpread: 1.25,
        fogOpacity: .32, fogStart: 39, fogEnd: 49,
        halos: [SpatialAtmosphereHalo(instanceId: 'model', localPosition: Model3dVector3(x: 0, y: 2, z: 0))],
        waterStrength: .6);
    final visual = SpatialVisualDocument(profile: SpatialVisualPatch.fromJson({'pitchDegrees':34,'depthOfFieldEnabled':true,'weatherKind':'snow', 'timeMode': 'real', 'weatherMode': 'automatic', 'weatherSequence': ['clear', 'rain']}));
    files['project/project.visual.json'] = utf8.encode(jsonEncode(visual.toJson()));
    files['project/maps/map.visual.json'] = utf8.encode(jsonEncode(SpatialVisualDocument(mapId: 'map', profile: SpatialVisualPatch.fromJson({'fogOpacity': .3})).toJson()));
    files['project/$sidecar'] = utf8.encode(jsonEncode(
        SpatialAtmosphereDocument(mapId: 'map', settings: settings).toJson()));
    for (final e in files.entries) {
      final file = File('${root.path}/${e.key.substring(8)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(e.value);
    }
    final artifact = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: GamePackageExportProfile(
            gameId: 'games.example.atmosphere',
            gameVersion: '0.1.0',
            title: 'Atmosphere',
            authorName: 'Yoahn',
            defaultLocale: 'fr',
            supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest);
    expect(artifact.manifest.compatibility.requiredCapabilities, contains(SpatialVisualDocument.capabilityId));
    expect(artifact.manifest.compatibility.requiredCapabilities, contains(WorldEnvironmentCapabilities.capabilityId));
    expect(artifact.manifest.compatibility.requiredCapabilities, contains(SpatialLightWorkshopCapabilities.capabilityId));
    expect(artifact.manifest.compatibility.requiredCapabilities, contains(SpatialWeatherCapabilities.capabilityId));
    expect(artifact.manifest.compatibility.requiredCapabilities.contains(SpatialWeatherCapabilities.soundCapabilityId), withSound);
    final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
    for (final path in ['project/project.visual.json', 'project/maps/map.visual.json']) {
      expect(archive.findFile(path)?.content, files[path]);
    }
    final packed = archive.findFile('project/$sidecar');
    expect(packed, isNotNull);
    expect(
        SpatialAtmosphereDocument.fromJson(
                jsonDecode(utf8.decode(packed!.content)))
            .settings,
        settings);
    for (final e in files.entries) {
      expect(await File('${root.path}/${e.key.substring(8)}').readAsBytes(),
          e.value);
    }
  });
  }
}
