import 'dart:io';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'map_save_work_counts_fixture.dart';

void main() {
  final counts = <int, Map<String, List<int>>>{};
  final decoded = <int, Map<String, List<int>>>{};

  for (final unrelated in [0, 24, 48]) {
    test(
      'a local map edit reads only its map with $unrelated unrelated maps, media and history',
      () async {
        final fixture = await WorkCountsFixture.create(unrelated);
        addTearDown(fixture.dispose);
        final reader = CountingReader();
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
