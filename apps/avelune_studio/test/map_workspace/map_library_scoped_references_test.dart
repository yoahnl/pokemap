import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_catalog_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';

ProjectModel3dEntry _model(String id, List<int> bytes) => ProjectModel3dEntry(
  id: id,
  name: id,
  sourceAssetId: '$id-source',
  relativePath: 'assets/models3d/$id.glb',
  inspection: const GlbModel3dInspector().inspect(bytes),
);

MapData _map(String id, String modelId) => MapData(
  id: id,
  name: id == 'room' ? 'Chambre' : 'Jardin',
  version: ProjectVersion.v9,
  size: const GridSize(width: 8, height: 8),
  spatialScene: MapSpatialScene(
    width: 8,
    depth: 8,
    instances: [
      SpatialModelInstance(
        id: '$modelId-placed',
        modelId: modelId,
        position: Model3dVector3(x: 2, y: 0, z: 2),
      ),
    ],
  ),
);

void main() {
  late Directory root;
  late MapWorkspaceController controller;
  late MapLibraryCommands commands;

  setUp(() async {
    final temporary = await Directory.systemTemp.createTemp('maps_refs_');
    root = Directory(await temporary.resolveSymbolicLinks());
    final bytes = triangleGlb();
    final artifact = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: 'model/gltf-binary',
    );
    final models = [_model('house', bytes), _model('tree', bytes)];
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'maps-refs',
      project: ProjectManifest(
        name: 'Références ciblées',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        maps: const [
          ProjectMapEntry(
            id: 'room',
            name: 'Chambre',
            relativePath: 'maps/room.json',
          ),
          ProjectMapEntry(
            id: 'yard',
            name: 'Jardin',
            relativePath: 'maps/yard.json',
          ),
        ],
        tilesets: const [],
        models3d: models,
      ),
    );
    final assets = File('${root.path}/$assetCatalogStorageKey');
    await assets.parent.create(recursive: true);
    await assets.writeAsString(
      jsonEncode(
        AssetCatalog(
          records: [
            for (final model in models)
              AssetRecord(
                id: model.sourceAssetId,
                logicalPath: model.relativePath,
                artifact: artifact,
              ),
          ],
        ).toJson(),
      ),
    );
    for (final model in models) {
      final source = File('${root.path}/${model.relativePath}');
      await source.parent.create(recursive: true);
      await source.writeAsBytes(bytes);
    }
    final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    for (final (id, model) in [('room', 'house'), ('yard', 'tree')]) {
      final file = File('${root.path}/maps/$id.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(_map(id, model).toJson()));
    }
    final session = ProjectSession(
      sessionId: 'maps-refs',
      name: 'Références ciblées',
      directoryPath: root.path,
      storage: ProjectSessionStorage.workingCatalog,
    );
    final maps = LocalMapWorkspaceAdapter();
    controller = MapWorkspaceController(
      session,
      maps,
      catalogPort: LocalMapCatalogAdapter(maps),
    );
    await controller.initialize();
    commands = MapLibraryCommands(controller);
  });

  tearDown(() async {
    controller.dispose();
    await root.delete(recursive: true);
  });

  test('renaming a map whose models the open map does not use publishes, undoes and redoes', () async {
    expect(controller.active?.base.mapId, 'room');
    expect(controller.hasCompleteProject, isFalse);
    expect(controller.project!.models3d.map((m) => m.id), ['house']);

    final renamed = await commands.renameMap('yard', 'Grand jardin');
    expect(renamed.ok, isTrue, reason: renamed.detail);
    expect(_name(controller, 'yard'), 'Grand jardin');

    await controller.stepHistory(redo: false);
    expect(controller.error, isNull);
    expect(_name(controller, 'yard'), 'Jardin');

    await controller.stepHistory(redo: true);
    expect(controller.error, isNull);
    expect(_name(controller, 'yard'), 'Grand jardin');
  });

  test(
    'duplicating and moving a map whose models the open map does not use',
    () async {
      final folder = await commands.createFolder('Routes');
      expect(folder.ok, isTrue, reason: folder.detail);
      final moved = await commands.moveMap('yard', folder.groupId);
      expect(moved.ok, isTrue, reason: moved.detail);

      final copy = await commands.duplicateMap('yard', name: 'Jardin bis');
      expect(copy.ok, isTrue, reason: copy.detail);
      expect(controller.active?.base.mapId, copy.mapId);
      expect(
        controller.active!.current.spatialScene!.instances.single.modelId,
        'tree',
      );
    },
  );

  test('an engine refusal is reported in French and changes nothing', () async {
    final refused = await commands.renameMap('yard', 'J' * 200);
    expect(refused.ok, isFalse);
    expect(
      refused.detail,
      'Le nom d’une carte doit contenir de 1 à 160 caractères. Rien n’a été publié.',
    );
    expect(controller.error, refused.detail);
    expect(_name(controller, 'yard'), 'Jardin');
  });

  test('the open map is still renamed with its own definitions', () async {
    final renamed = await commands.renameMap('room', 'Chambre bleue');
    expect(renamed.ok, isTrue, reason: renamed.detail);
    expect(controller.active!.current.name, 'Chambre bleue');
  });
}

String _name(MapWorkspaceController controller, String id) =>
    controller.project!.maps.singleWhere((map) => map.id == id).name;
