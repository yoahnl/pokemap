import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  final counts = <int, Map<String, List<int>>>{};
  final decoded = <int, Map<String, List<int>>>{};

  for (final unrelated in [0, 24, 48]) {
    test(
      'a local map edit reads only its map with $unrelated unrelated maps, media and history',
      () async {
        final fixture = await _Fixture.create(unrelated);
        addTearDown(fixture.dispose);
        final reader = _CountingReader();
        final controller = MapWorkspaceController(
          fixture.session,
          LocalMapWorkspaceAdapter(reader: reader),
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        expect(controller.error, isNull);
        final document = controller.active!;
        expect(document.base.mapId, 'a');
        expect(controller.project!.characters.map((entry) => entry.id),
            contains('trainer-look'));
        expect(controller.project!.elements.map((entry) => entry.id),
            contains('trainer-portrait'));

        final gestures = <String, void Function(EditableMapDocument, int)>{
          'presence': _presence,
          'camera': _camera,
          'move': _move,
        };
        final observed = <String, List<int>>{};
        final definitions = <String, List<int>>{};
        for (final gesture in gestures.entries) {
          for (var repeat = 0; repeat < 2; repeat++) {
            reader.reset();
            gesture.value(document, repeat);
            expect(
              await controller.save(document),
              isTrue,
              reason: document.error,
            );
            expect(
              reader.paths.where(
                (path) =>
                    path.startsWith('maps/') && !path.startsWith('maps/a.'),
              ),
              isEmpty,
              reason: '${gesture.key} read another map',
            );
            expect(
              reader.paths.where(
                (path) =>
                    path.endsWith('.glb') ||
                    path.endsWith('.png') ||
                    path.endsWith('history.jsonl'),
              ),
              isEmpty,
              reason: '${gesture.key} read unrelated media or history',
            );
            expect(
              reader.definitions.where((unit) => unit.contains('foreign')),
              isEmpty,
              reason: '${gesture.key} decoded an unrelated definition',
            );
            observed
                .putIfAbsent(gesture.key, () => [])
                .add(reader.paths.length);
            definitions
                .putIfAbsent(gesture.key, () => [])
                .add(reader.definitions.length);
          }
        }
        counts[unrelated] = observed;
        decoded[unrelated] = definitions;
        if (unrelated > 0) {
          expect(
            decoded[unrelated],
            decoded[0],
            reason: 'unrelated content changed the definitions a local edit decodes',
          );
        }
        if (counts.containsKey(24) && counts.containsKey(48)) {
          for (final gesture in gestures.keys) {
            for (var repeat = 0; repeat < 2; repeat++) {
              expect(
                counts[48]![gesture]![repeat] - counts[24]![gesture]![repeat],
                lessThanOrEqualTo(8),
                reason: 'doubling unrelated content may only add index pages',
              );
            }
          }
        }

        final scene = document.current.spatialScene!;
        document.commit(
          document.current.copyWith(
            spatialScene: scene.copyWith(
              instances: [
                SpatialModelInstance(
                  id: 'oak-1',
                  modelId: 'pine',
                  position: scene.instances.single.position,
                ),
              ],
            ),
          ),
        );
        expect(await controller.save(document), isTrue, reason: document.error);
        expect(
          controller.project!.models3d.map((model) => model.id),
          contains('pine'),
          reason: 'a new dependency is read with the saved map',
        );

        final saved = document.saved;
        final cold = LocalMapWorkspaceAdapter();
        final catalog = await cold.loadCatalog(fixture.session);
        final reopened = await cold.loadMapSelection(
          fixture.session,
          catalog.metadata.maps.singleWhere((entry) => entry.id == 'a'),
        );
        expect(reopened.document.map, saved);
        expect(reopened.definitions.characters.map((entry) => entry.id),
            contains('trainer-look'));
        expect(reopened.document.map.entities.single.npc!.trainerId,
            'guide-trainer');
        final store = await CatalogStorageStore.open(projectRoot: fixture.root.path);
        final root = (await store.openRoot((await store.readHead())!)).snapshot;
        final preserved = await PortableProjectCatalog.fromSnapshot(root,
            metadataFields: {'trainers'});
        expect(preserved.projectMetadata.trainers.map((trainer) => trainer.id), [
          'guide-trainer',
          for (var i = 0; i < unrelated; i++) 'foreign-trainer-$i',
        ]);
        expect(
          reopened.document.map.spatialScene!.camera.distance,
          _distance(1),
        );
        expect(
          reopened.document.map.spatialScene!.instances.single.position.x,
          2.5,
        );
        expect(
          reopened.document.map.spatialScene!.instances.single.modelId,
          'pine',
        );
        expect(
          reopened
              .document
              .map
              .entities
              .single
              .npc!
              .visibilityRule!
              .predicate!
              .timeWindow!
              .startMinute,
          _startMinute(1),
        );
        final storedMap = File('${fixture.root.path}/maps/a.json');
        final storedHead = File('${fixture.root.path}/catalog/HEAD.json');
        final mapBytes = await storedMap.readAsBytes();
        final headBytes = await storedHead.readAsBytes();
        final entity = document.current.entities.single;
        document.commit(document.current.copyWith(entities: [
          entity.copyWith(npc: entity.npc!.copyWith(trainerId: 'missing-trainer')),
        ]));
        expect(await controller.save(document), isFalse);
        expect(document.error, isNotNull);
        expect(await storedMap.readAsBytes(), mapBytes);
        expect(await storedHead.readAsBytes(), headBytes);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}

double _distance(int repeat) => 12 + repeat.toDouble();

int _startMinute(int repeat) => 360 + 60 * repeat;

void _presence(EditableMapDocument document, int repeat) => document.commit(
  const EntityActions().setVisibilityRule(
    document.current,
    entityId: 'guide',
    visibilityRule: MapEntityNpcVisibilityRule(
      mode: MapEntityNpcVisibilityMode.visibleWhen,
      predicate: MapEntityRuntimePredicate(
        kind: MapEntityRuntimePredicateKind.localTimeWindow,
        timeWindow: LocalTimeWindow(
          startMinute: _startMinute(repeat),
          endMinute: 1200,
        ),
      ),
    ),
  ),
);

void _camera(EditableMapDocument document, int repeat) {
  final camera = document.current.spatialScene!.camera;
  document.commit(
    const SpatialMapOperations().configureCamera(
      document.current,
      camera.copyWith(distance: _distance(repeat)),
    ),
  );
}

void _move(EditableMapDocument document, int repeat) {
  final scene = document.current.spatialScene!;
  final instance = scene.instances.single;
  document.commit(
    document.current.copyWith(
      spatialScene: scene.copyWith(
        instances: [
          instance.copyWith(
            position: Model3dVector3(
              x: repeat.isEven ? 3.5 : 2.5,
              y: instance.position.y,
              z: instance.position.z,
            ),
          ),
        ],
      ),
    ),
  );
}

final class _Fixture {
  _Fixture(this.root, this.session);

  final Directory root;
  final ProjectSession session;

  static Future<_Fixture> create(int unrelated) async {
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
            id: 'guide-trainer', name: 'Guide', trainerClass: 'Trainer',
            characterId: 'trainer-look', portraitElementId: 'trainer-portrait'),
        for (var i = 0; i < unrelated; i++)
          ProjectTrainerEntry(
              id: 'foreign-trainer-$i', name: 'Foreign $i',
              trainerClass: 'Trainer'),
      ],
      characters: const [ProjectCharacterEntry(
          id: 'trainer-look', name: 'Trainer', tilesetId: 'atlas')],
      elements: const [ProjectElementEntry(
          id: 'trainer-portrait', name: 'Trainer portrait', tilesetId: 'atlas',
          categoryId: 'trainer-art', frames: [TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))])],
      elementCategories: const [ProjectElementCategory(
          id: 'trainer-art', name: 'Trainer art')],
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
              displayName: 'Guide', trainerId: 'guide-trainer'),
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
    return _Fixture(
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

final class _CountingReader
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
