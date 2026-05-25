import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/runtime_launch_save.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P5 runtime project disk smoke', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp(
        'p5_runtime_project_disk_smoke_',
      );
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test(
        'writes editor-shaped project files, loads a RuntimeMapBundle, and boots PlayableMapGame',
        () async {
      final projectFilePath = p.join(root.path, 'project.json');
      final mapFilePath =
          p.join(root.path, 'maps', 'p5_runtime_smoke_map.json');
      final launchSaveFilePath =
          p.join(root.path, kRuntimeHostLaunchSaveFileName);

      final manifest = _p5SmokeManifest();
      final map = _p5SmokeMap();
      final launchSave = _p5LaunchSave();

      await _writeProjectUsingEditorRepositoryShape(
        manifest: manifest,
        projectFilePath: projectFilePath,
      );
      await _writeMapUsingEditorRepositoryShape(
        map: map,
        manifest: manifest,
        mapFilePath: mapFilePath,
      );
      await _writeLaunchSave(
        saveData: launchSave,
        launchSaveFilePath: launchSaveFilePath,
      );

      expect(await File(projectFilePath).exists(), isTrue);
      expect(await File(mapFilePath).exists(), isTrue);
      expect(await File(launchSaveFilePath).exists(), isTrue);

      final persistedProjectJson =
          jsonDecode(await File(projectFilePath).readAsString())
              as Map<String, dynamic>;
      expect(persistedProjectJson['name'], _projectName);
      expect(persistedProjectJson['maps'], isA<List<dynamic>>());
      expect(
        (persistedProjectJson['maps'] as List<dynamic>).single,
        containsPair('relativePath', 'maps/p5_runtime_smoke_map.json'),
      );

      final persistedMapJson =
          jsonDecode(await File(mapFilePath).readAsString())
              as Map<String, dynamic>;
      expect(persistedMapJson['id'], _mapId);
      expect(persistedMapJson['mapMetadata'],
          containsPair('defaultSpawnId', _spawnId));

      final hostLaunchSave = await loadRuntimeHostLaunchSaveData(
        projectFilePath: projectFilePath,
      );
      expect(hostLaunchSave, isNotNull);
      expect(hostLaunchSave!.currentMapId, _mapId);
      expect(hostLaunchSave.playerPosition, const GridPos(x: 1, y: 1));

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _mapId,
      );

      expect(bundle.manifest.name, _projectName);
      expect(bundle.map.id, _mapId);
      expect(
          bundle.map.entities.map((entity) => entity.id), contains(_spawnId));
      expect(bundle.projectRootDirectory, p.normalize(root.path));
      expect(bundle.tilesetAbsolutePathsById, isEmpty);
      expect(bundle.cellWidth, 32);
      expect(bundle.cellHeight, 32);

      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: hostLaunchSave,
      );

      expect(game.saveLoadInfo.mapId, _mapId);
      expect(game.saveLoadInfo.playerX, 1);
      expect(game.saveLoadInfo.playerY, 1);

      game.onGameResize(Vector2(320, 240));
      await game.onLoad();
      game.update(0);

      expect(game.saveLoadInfo.mapId, _mapId);
      expect(game.gameStateSnapshot.currentMapId, _mapId);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));

      await _expectNoForbiddenProjectContent(root);
    });
  });
}

const _projectName = 'P5 Runtime Project Disk Smoke';
const _mapId = 'p5_runtime_smoke_map';
const _spawnId = 'p5_runtime_smoke_spawn';
const _saveId = 'p5_runtime_smoke_launch_save';

ProjectManifest _p5SmokeManifest() {
  return const ProjectManifest(
    name: _projectName,
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'P5 Runtime Smoke Field',
        relativePath: 'maps/p5_runtime_smoke_map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    settings: ProjectSettings(
      tileWidth: 16,
      tileHeight: 16,
      displayScale: 2,
      defaultMapWidth: 4,
      defaultMapHeight: 4,
    ),
  );
}

MapData _p5SmokeMap() {
  return const MapData(
    id: _mapId,
    name: 'P5 Runtime Smoke Field',
    size: GridSize(width: 4, height: 4),
    layers: <MapLayer>[
      MapLayer.object(id: 'p5_runtime_smoke_objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: _spawnId,
        name: 'P5 Runtime Smoke Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          spawnKey: _spawnId,
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.south,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: _spawnId),
  );
}

SaveData _p5LaunchSave() {
  return const SaveData(
    saveId: _saveId,
    currentMapId: _mapId,
    playerPosition: GridPos(x: 1, y: 1),
    playerFacing: EntityFacing.south,
    trainerProfile: TrainerProfile(name: 'P5 Runtime Tester'),
  );
}

Future<void> _writeProjectUsingEditorRepositoryShape({
  required ProjectManifest manifest,
  required String projectFilePath,
}) async {
  ProjectValidator.validate(manifest);
  final file = File(projectFilePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
}

Future<void> _writeMapUsingEditorRepositoryShape({
  required MapData map,
  required ProjectManifest manifest,
  required String mapFilePath,
}) async {
  MapValidator.validate(map, projectDialogueContext: manifest);
  final file = File(mapFilePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
  );
}

Future<void> _writeLaunchSave({
  required SaveData saveData,
  required String launchSaveFilePath,
}) async {
  final file = File(launchSaveFilePath);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(saveData.toJson()),
  );
}

Future<void> _expectNoForbiddenProjectContent(Directory root) async {
  const forbiddenFragments = <String>{
    'selbrume',
    'lysa',
    'mado',
    'port des brisants',
    'phare',
    'brume',
    'rival',
  };

  await for (final entity in root.list(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final normalizedContent = (await entity.readAsString()).toLowerCase();
    for (final fragment in forbiddenFragments) {
      expect(
        normalizedContent,
        isNot(contains(fragment)),
        reason: '${entity.path} must remain a generic P5 technical fixture.',
      );
    }
  }
}
