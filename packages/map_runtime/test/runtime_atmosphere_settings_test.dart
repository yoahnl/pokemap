import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';

import '../../../tools/performance/smart_tiles_rich_map_fixture.dart';

void main() {
  test('runtime loads selected map sidecar and preserves settings through bundle copy', () async {
    final fixture = generateSmartTilesRichMapFixture(extent: 128);
    final root = await Directory.systemTemp.createTemp('runtime-atmosphere-');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/maps').create();
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(fixture.manifest.toJson()));
    await File('${root.path}/maps/${fixture.map.id}.json')
        .writeAsString(jsonEncode(fixture.map.toJson()));
    final legacy = await loadRuntimeMapBundle(
      projectFilePath: '${root.path}/project.json',
      mapId: fixture.map.id,
    );
    expect(legacy.spatialAtmosphereSettings.waterAnimated, isFalse);
    final settings = SpatialAtmosphereSettings(
      waterAnimated: true,
      windowsLit: true,
      fireflies: true,
      waterStrength: .4,
    );
    final file = File(
      '${root.path}/${SpatialAtmosphereDocument.relativePathForMap(fixture.map.id)}',
    );
    await file.writeAsString(
      jsonEncode(
        SpatialAtmosphereDocument(
          mapId: fixture.map.id,
          settings: settings,
        ).toJson(),
      ),
    );
    final loaded = await loadRuntimeMapBundle(
      projectFilePath: '${root.path}/project.json',
      mapId: fixture.map.id,
    );
    expect(loaded.spatialAtmosphereSettings, settings);
    expect(loaded.copyWith().spatialAtmosphereSettings, settings);
    final before = await file.readAsBytes();
    await file.writeAsString(
      jsonEncode({'schemaVersion': 2, 'mapId': fixture.map.id, 'settings': {}}),
    );
    final unsupported = await file.readAsBytes();
    await expectLater(
      loadRuntimeMapBundle(
        projectFilePath: '${root.path}/project.json',
        mapId: fixture.map.id,
      ),
      throwsA(isA<MapLoadException>()),
    );
    expect(await file.readAsBytes(), unsupported);
    expect(before, isNot(unsupported));
  });
}
