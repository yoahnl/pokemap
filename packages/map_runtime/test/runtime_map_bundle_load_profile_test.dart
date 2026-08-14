import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';

import '../../../tools/performance/smart_tiles_rich_map_fixture.dart';

void main() {
  test('profiles every rich runtime bundle loading phase', () async {
    final fixture = generateSmartTilesRichMapFixture(extent: 128);
    final root = await Directory.systemTemp.createTemp('runtime-load-profile-');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/maps').create(recursive: true);
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(fixture.manifest.toJson()),
    );
    await File('${root.path}/maps/${fixture.map.id}.json').writeAsString(
      jsonEncode(fixture.map.toJson()),
    );
    RuntimeMapBundleLoadProfile? profile;

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: '${root.path}/project.json',
      mapId: fixture.map.id,
      profileSink: (value) => profile = value,
    );

    expect(bundle.map.id, fixture.map.id);
    expect(profile, isNotNull);
    expect(profile!.usedPreloadedManifest, isFalse);
    expect(profile!.mapCellCount, 128 * 128);
    expect(profile!.mapLayerCount, fixture.map.layers.length);
    expect(profile!.resolvedTilesetPathCount, greaterThan(0));
    expect(profile!.manifestLoadMicroseconds, isNonNegative);
    expect(profile!.mapLoadMicroseconds, isNonNegative);
    expect(profile!.assetCatalogLoadMicroseconds, isNonNegative);
    expect(profile!.tilesetResolutionMicroseconds, isNonNegative);
    expect(profile!.borderPreparationMicroseconds, isNonNegative);
    expect(profile!.totalMicroseconds, isNonNegative);

    RuntimeMapBundleLoadProfile? preloadedProfile;
    await loadRuntimeMapBundle(
      projectFilePath: '${root.path}/project.json',
      mapId: fixture.map.id,
      preloadedManifest: fixture.manifest,
      profileSink: (value) => preloadedProfile = value,
    );
    expect(preloadedProfile!.usedPreloadedManifest, isTrue);
    expect(preloadedProfile!.manifestLoadMicroseconds, 0);
  });
}
