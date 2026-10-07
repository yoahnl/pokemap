import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  late Directory root;
  late SpatialExplorationBootstrap bootstrap;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('spatial-bootstrap-');
    final project = ProjectManifest(
        version: ProjectVersion.v9,
        name: 'Explore',
        maps: const [
          ProjectMapEntry(
              id: 'first', name: 'First', relativePath: 'first.json'),
          ProjectMapEntry(
              id: 'second', name: 'Second', relativePath: 'second.json')
        ],
        tilesets: const [],
        settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile()));
    final map = MapData(
        version: ProjectVersion.v9,
        id: 'first',
        name: 'First',
        size: const GridSize(width: 8, height: 8),
        layers: const [],
        spatialScene: MapSpatialScene(
            width: 8,
            depth: 8,
            navigation:
                SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 5))));
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    await File('${root.path}/first.json')
        .writeAsString(jsonEncode(map.toJson()));
    bootstrap = SpatialExplorationBootstrap(
        projectFilePath: () async => '${root.path}/project.json');
  });
  tearDown(() async {
    bootstrap.clear();
    await root.delete(recursive: true);
  });

  test(
      'prepares the first spatial map while authored new game remains disabled',
      () async {
    final preparation = await bootstrap.prepare();
    expect(preparation.project.newGame.enabled, isFalse);
    expect(preparation.startMap.id, 'first');
    expect(preparation.startMap.spatialScene!.navigation.spawn.z, 5);
    expect(preparation.preSessionRunner, isNull);
    expect(await bootstrap.readCurrentProjectRevision(),
        preparation.projectRevision);
  });

  test('rejects save continuation explicitly', () async {
    await expectLater(
        bootstrap.preloadInitialMap(
            RuntimeInitialMapPreloadRequest.continueGame(SaveSlotAddress(
                gameId: 'org.example.explore',
                profileId: 'profile',
                slotId: 'slot'))),
        throwsStateError);
  });

  test('detects changed spatial navigation in prepared revision', () async {
    final preparation = await bootstrap.prepare();
    final file = File('${root.path}/first.json');
    final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    ((map['spatialScene'] as Map)['navigation'] as Map)['spawn'] = {
      'x': 3.0,
      'z': 4.0
    };
    await file.writeAsString(jsonEncode(map));
    expect(await bootstrap.readCurrentProjectRevision(),
        isNot(preparation.projectRevision));
  });
}
