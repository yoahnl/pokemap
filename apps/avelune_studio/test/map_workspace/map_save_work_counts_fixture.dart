import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

final class WorkCountsFixture {
  WorkCountsFixture(this.root, this.session);

  final Directory root;
  final ProjectSession session;

  static Future<WorkCountsFixture> create(int unrelated) async {
    final root = await Directory.systemTemp.createTemp('map-save-counts-');
    final project = spatialEnvironmentProject().copyWith(
      maps: [
        const ProjectMapEntry(id: 'a', name: 'A', relativePath: 'maps/a.json'),
        for (var i = 0; i < unrelated; i++)
          ProjectMapEntry(
            id: 'foreign-$i',
            name: 'Foreign $i',
            relativePath: 'maps/foreign-$i.json',
          ),
      ],
      models3d: [
        ...spatialEnvironmentProject().models3d,
        ProjectModel3dEntry(
          id: 'pine',
          name: 'Pin',
          sourceAssetId: 'pine-source',
          relativePath: 'assets/models3d/pine.glb',
          inspection: spatialEnvironmentProject().models3d.single.inspection,
        ),
        for (var i = 0; i < unrelated; i++)
          ProjectModel3dEntry(
            id: 'foreign-model-$i',
            name: 'Foreign $i',
            sourceAssetId: 'foreign-source-$i',
            relativePath: 'assets/models3d/foreign-model-$i.glb',
            inspection: spatialEnvironmentProject().models3d.single.inspection,
          ),
      ],
      dialogues: [
        for (var i = 0; i < unrelated; i++)
          ProjectDialogueEntry(
            id: 'foreign-dialogue-$i',
            name: 'Foreign $i',
            relativePath: 'dialogues/foreign-$i.yarn',
          ),
      ],
      trainers: [
        const ProjectTrainerEntry(
          id: 'guide-trainer',
          name: 'Guide',
          trainerClass: 'Trainer',
          characterId: 'trainer-look',
          portraitElementId: 'trainer-portrait',
        ),
        for (var i = 0; i < unrelated; i++)
          ProjectTrainerEntry(
            id: 'foreign-trainer-$i',
            name: 'Foreign $i',
            trainerClass: 'Trainer',
          ),
      ],
      characters: const [
        ProjectCharacterEntry(
          id: 'trainer-look',
          name: 'Trainer',
          tilesetId: 'atlas',
        ),
      ],
      elements: const [
        ProjectElementEntry(
          id: 'trainer-portrait',
          name: 'Trainer portrait',
          tilesetId: 'atlas',
          categoryId: 'trainer-art',
          frames: [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
            ),
          ],
        ),
      ],
      elementCategories: const [
        ProjectElementCategory(id: 'trainer-art', name: 'Trainer art'),
      ],
      environmentPresets: const [],
    );
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'map-save-counts-$unrelated',
      project: project,
    );
    final map = spatialEnvironmentMap().copyWith(
      entities: [
        const MapEntity(
          id: 'guide',
          name: 'Guide',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 3, y: 4),
          npc: MapEntityNpcData(
            displayName: 'Guide',
            trainerId: 'guide-trainer',
          ),
        ),
      ],
      spatialScene: spatialEnvironmentMap().spatialScene!.copyWith(
        instances: [
          SpatialModelInstance(
            id: 'oak-1',
            modelId: 'oak',
            position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
          ),
        ],
      ),
    );
    await _write(root, 'maps/a.json', jsonEncode(map.toJson()));
    for (var i = 0; i < unrelated; i++) {
      await _write(
        root,
        'maps/foreign-$i.json',
        jsonEncode(
          spatialEnvironmentMap()
              .copyWith(
                id: 'foreign-$i',
                name: 'Foreign $i',
                spatialScene: spatialEnvironmentMap().spatialScene!.copyWith(
                  instances: [
                    SpatialModelInstance(
                      id: 'foreign-instance-$i',
                      modelId: 'foreign-model-$i',
                      position: Model3dVector3(x: 1.5, y: 0, z: 1.5),
                    ),
                  ],
                ),
              )
              .toJson(),
        ),
      );
      await _write(root, 'assets/models3d/foreign-model-$i.glb', 'glTF$i');
      await _write(root, 'assets/foreign-$i.png', 'png$i');
      await _write(
        root,
        'dialogues/foreign-$i.yarn',
        'title: foreign\n---\n===\n',
      );
    }
    await _write(
      root,
      '.pokemap/authoring/history.jsonl',
      'unrelated history must remain unread\n' * (unrelated + 1),
    );
    return WorkCountsFixture(
      root,
      ProjectSession(
        sessionId: root.path,
        name: project.name,
        directoryPath: await root.resolveSymbolicLinks(),
        storage: ProjectSessionStorage.workingCatalog,
      ),
    );
  }

  static Future<void> _write(Directory root, String path, String text) async {
    final file = File('${root.path}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsString(text);
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final definitions = <String>[];
  final delegate = const LocalProjectFileReader();

  void reset() {
    paths.clear();
    definitions.clear();
  }

  void _record(String projectRoot, String relativePath) {
    paths.add(relativePath);
    if (!relativePath.startsWith('catalog/objects/')) return;
    final text = File('$projectRoot/$relativePath').readAsStringSync();
    if (text.startsWith('{"key":')) definitions.add(text);
  }

  @override
  bool get supportsStreamingResources => true;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.probeResource(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    _record(projectRoot, relativePath);
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    _record(projectRoot, relativePath);
    return delegate.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
