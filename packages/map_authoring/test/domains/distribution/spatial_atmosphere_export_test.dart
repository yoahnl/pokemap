import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test(
      'export preserves atmosphere sidecar and source bytes independently of map JSON',
      () async {
    final root = await Directory.systemTemp.createTemp('atmosphere-export-');
    addTearDown(() => root.delete(recursive: true));
    final files = spatialPayload();
    final sidecar = SpatialAtmosphereDocument.relativePathForMap('map');
    final settings = SpatialAtmosphereSettings(
        waterAnimated: true,
        windowsLit: true,
        fireflies: true,
        waterStrength: .6);
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
    final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
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
