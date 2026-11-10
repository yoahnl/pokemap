import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  test(
    'manual binding persists through real catalog without foreign map reads',
    () async {
      final qa = Directory(
        '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109/t01-map-retirement',
      );
      await qa.create(recursive: true);
      final root = await qa.createTemp('binding-');
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final map = _manualMap(true);
      final project = spatialEnvironmentProject().copyWith(
        maps: [
          const ProjectMapEntry(
            id: 'a',
            name: 'A',
            relativePath: 'maps/a.json',
          ),
          for (var i = 0; i < 80; i++)
            ProjectMapEntry(
              id: 'foreign-$i',
              name: 'Foreign',
              relativePath: 'maps/foreign-$i.json',
            ),
        ],
      );
      final session = ProjectSession(
        sessionId: root.path,
        name: project.name,
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      );
      final reader = _BindingReader();
      final controller = MapWorkspaceController(
        session,
        LocalMapWorkspaceAdapter(reader: reader),
      );
      addTearDown(controller.dispose);
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      await WorkingProjectCatalog.create(
        store: store,
        projectId: 'manual-binding',
        project: project,
      );
      await Directory('${root.path}/maps').create();
      await File('${root.path}/maps/a.json')
          .writeAsString(jsonEncode(map.toJson()));
      for (var i = 0; i < 80; i++) {
        await File('${root.path}/maps/foreign-$i.json')
            .writeAsString('foreign map must remain unread');
      }
      final history = File('${root.path}/.pokemap/authoring/history.jsonl');
      await history.parent.create(recursive: true);
      await history.writeAsString('foreign history must remain unread\n' * 81);
      await controller.initialize();
      expect(controller.error, isNull);
      final document = controller.active!;
      reader.paths.clear();
      expect(
        SpatialModelEditingCommands(
          document,
          controller.project!,
        ).bindEntity('manual-tree', 'object'),
        isTrue,
      );
      expect(document.current.entities.single.pos, const GridPos(x: 2, y: 3));
      expect(document.undoCount, 1);
      expect(await controller.save(document), isTrue, reason: document.error);
      expect(
        reader.paths.where(
          (path) =>
              path.startsWith('maps/') && path != 'maps/a.json' ||
              path.endsWith('.glb') ||
              path.endsWith('history.jsonl'),
        ),
        isEmpty,
      );
      final saved = MapData.fromJson(
        jsonDecode(await File('${root.path}/maps/a.json').readAsString()),
      );
      expect(saved.spatialScene!.instances.single.entityId, 'object');
      expect(saved.entities.single.pos, const GridPos(x: 2, y: 3));
      final reopened = MapWorkspaceController(
        session,
        LocalMapWorkspaceAdapter(reader: reader),
      );
      try {
        await reopened.initialize();
        expect(reopened.active!.saved, saved);
      } finally {
        reopened.dispose();
      }
    },
  );

  for (final manual in [false, true]) {
    test('binding respects stable manual ownership manual=$manual', () {
      final map = _manualMap(manual);
      final document = _document(map);
      final commands = SpatialModelEditingCommands(
        document,
        spatialEnvironmentProject(),
      );
      expect(SpatialEntityModelOwnership(map).canBind('manual-tree'), manual);
      expect(commands.bindEntity('manual-tree', 'object'), manual);
      if (!manual) {
        expect(document.current, same(map));
        expect(document.canUndo, isFalse);
        return;
      }
      expect(
        document.current.spatialScene!.instances.single.entityId,
        'object',
      );
      expect(document.current.entities.single.pos, const GridPos(x: 2, y: 3));
      expect(document.undoCount, 1);
      document.restore(redo: false);
      expect(document.current, map);
      document.restore(redo: true);
      expect(MapData.fromJson(document.current.toJson()), document.current);
    });
  }

  for (final kind in const [
    FieldObstacleKind.cutTree,
    FieldObstacleKind.strengthBoulder,
    FieldObstacleKind.rockSmashRock,
  ]) {
    test(
      '$kind creates a bound entity with reset policy and one undo',
      () async {
        final original = spatialEnvironmentMap();
        final instance = SpatialModelInstance(
          id: 'oak-1',
          modelId: 'oak',
          position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
          blocksMovement: true,
        );
        final map = original.copyWith(
          spatialScene: original.spatialScene!.copyWith(instances: [instance]),
        );
        final document = _document(map);
        final commands = SpatialModelEditingCommands(
          document,
          spatialEnvironmentProject(),
        );
        expect(commands.canConfigureFieldObstacle(instance.id), isTrue);
        expect(
          await commands.configureFieldObstacle(
            instance.id,
            MapEntityFieldObstacleData(kind: kind),
          ),
          isTrue,
        );
        expect(document.current.entities.single.fieldObstacle!.kind, kind);
        expect(
          isValidSpatialFieldObstacle(
            document.current,
            document.current.entities.single,
          ),
          isTrue,
        );
        expect(document.undoCount, 1);
        expect(
          await commands.configureFieldObstacle(
            instance.id,
            MapEntityFieldObstacleData(
              kind: kind,
              resetPolicy: FieldObstacleResetPolicy.persistent,
            ),
          ),
          isTrue,
        );
        expect(
          document.current.entities.single.fieldObstacle!.resetPolicy,
          FieldObstacleResetPolicy.persistent,
        );
        document.restore(redo: false);
        document.restore(redo: false);
        expect(document.current, map);
      },
    );
  }

  test('ice block is refused in 3D without changing map or history', () async {
    final original = spatialEnvironmentMap();
    final map = original.copyWith(
      spatialScene: original.spatialScene!.copyWith(
        instances: [
          SpatialModelInstance(
            id: 'oak-1',
            modelId: 'oak',
            position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
            blocksMovement: true,
          ),
        ],
      ),
    );
    final document = _document(map);
    final commands = SpatialModelEditingCommands(
      document,
      spatialEnvironmentProject(),
    );
    expect(
      await commands.configureFieldObstacle(
        'oak-1',
        const MapEntityFieldObstacleData(kind: FieldObstacleKind.iceBlock),
      ),
      isFalse,
    );
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
    expect(document.error, isNotNull);
  });

  test(
    'binding choices exclude NPC and repeating pickups and support undo',
    () {
      final instance = SpatialModelInstance(
        id: 'orb',
        modelId: 'oak',
        position: Model3dVector3(x: 4.5, y: 0, z: 3.5),
      );
      final original = spatialEnvironmentMap();
      final map = original.copyWith(
        spatialScene: original.spatialScene!.copyWith(instances: [instance]),
        entities: [
          MapEntity(
            id: 'item',
            name: 'Objet',
            kind: MapEntityKind.item,
            pos: const GridPos(x: 1, y: 1),
            item: const MapEntityItemData(gameItemId: 'resource'),
          ),
          MapEntity(
            id: 'repeat',
            name: 'Objet répétable',
            kind: MapEntityKind.item,
            pos: const GridPos(x: 2, y: 1),
            item: const MapEntityItemData(
              gameItemId: 'resource',
              pickupMode: ItemPickupMode.always,
            ),
          ),
          MapEntity(
            id: 'npc',
            name: 'Habitant',
            kind: MapEntityKind.npc,
            pos: const GridPos(x: 3, y: 1),
          ),
        ],
      );
      final document = _document(map);
      final commands = SpatialModelEditingCommands(
        document,
        spatialEnvironmentProject(),
      );
      expect(commands.bindableEntities(instance.id).map((entry) => entry.id), [
        'item',
      ]);
      expect(commands.bindEntity('orb', 'repeat'), isFalse);
      expect(commands.bindEntity('orb', 'npc'), isFalse);
      expect(commands.bindEntity('orb', 'missing'), isFalse);
      expect(document.current, same(map));
      expect(document.canUndo, isFalse);
      expect(commands.bindEntity('orb', 'item'), isTrue);
      expect(document.current.spatialScene!.instances.single.entityId, 'item');
      expect(document.current.entities.first.pos, const GridPos(x: 4, y: 3));
      expect(document.undoCount, 1);
      document.restore(redo: false);
      expect(document.current, map);
    },
  );

  test(
    'obstacle delegates to targeted publisher and saving refuses local writes',
    () async {
      final map = spatialEnvironmentMap();
      final document = _document(map);
      final calls = <(String, MapEntityFieldObstacleData?)>[];
      document.configureSpatialFieldObstacle = (id, value) async {
        calls.add((id, value));
        return false;
      };
      final commands = SpatialModelEditingCommands(
        document,
        spatialEnvironmentProject(),
      );
      const value = MapEntityFieldObstacleData(kind: FieldObstacleKind.cutTree);
      expect(await commands.configureFieldObstacle('oak-1', value), isFalse);
      expect(calls, [('oak-1', value)]);
      document.saving = true;
      expect(await commands.configureFieldObstacle('oak-1', value), isFalse);
      expect(commands.bindEntity('oak-1', 'entity'), isFalse);
      expect(calls, hasLength(1));
      expect(document.current, same(map));
      expect(document.canUndo, isFalse);
    },
  );
}

EditableMapDocument _document(MapData map) => EditableMapDocument(
  MapWorkspaceDocument(map: map, mapId: map.id, revision: 'initial'),
);

MapData _manualMap(bool manual) {
  final base = spatialEnvironmentMap();
  final instance = SpatialModelInstance(
    id: 'manual-tree',
    modelId: 'oak',
    position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
  );
  return base.copyWith(
    entities: [
      MapEntity(
        id: 'object',
        name: 'Objet lié',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 1, y: 1),
      ),
    ],
    spatialScene: base.spatialScene!.copyWith(instances: [instance]),
    layers: [
      MapLayer.environment(
        id: 'forest',
        name: 'Forest',
        content: EnvironmentLayerContent(
          targetsSpatialTerrain: true,
          areas: [
            EnvironmentArea(
              id: 'trees',
              name: 'Trees',
              presetId: 'woodland',
              seed: 1,
              mask: EnvironmentAreaMask(
                width: 12,
                height: 10,
                cells: List.filled(120, false),
              ),
              generatedPlacementIds: [instance.id],
              manualPlacementIds: manual ? [instance.id] : [],
            ),
          ],
        ),
      ),
    ],
  );
}

final class _BindingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => delegate.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) async* {
    yield await readBytes(projectRoot: projectRoot, relativePath: relativePath);
  }
}
