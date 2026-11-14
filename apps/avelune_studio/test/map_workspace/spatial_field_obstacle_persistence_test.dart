import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';
import 'spatial_field_obstacle_persistence_support.dart';

void main() {
  final workCounts = <List<int>>[];
  for (final storage in [
    ProjectSessionStorage.workingCatalog,
    ProjectSessionStorage.manifest,
  ]) {
    for (final unrelated in [
      0,
      if (storage == ProjectSessionStorage.workingCatalog &&
          Platform.environment['AVELUNE_FIELD_OBSTACLE_LARGE_FIXTURE'] == '1')
        2000,
    ]) {
      testWidgets(
        '3D obstacle commands persist first repeat and reopens with $unrelated foreign maps ${storage.name}',
        (tester) async {
          final parent = Directory(
            '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109/t01-map-retirement',
          )..createSync(recursive: true);
          final root = parent.createTempSync('spatial-obstacle-');
          addTearDown(() async {
            if (await root.exists()) await root.delete(recursive: true);
          });
          final map = spatialEnvironmentMap();
          final source = map.copyWith(
            spatialScene: map.spatialScene!.copyWith(
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
          final project = spatialEnvironmentProject().copyWith(
            maps: [
              const ProjectMapEntry(
                id: 'a',
                name: 'A',
                relativePath: 'maps/a.json',
              ),
              for (var i = 0; i < unrelated; i++)
                ProjectMapEntry(
                  id: 'foreign-$i',
                  name: 'Foreign',
                  relativePath: 'maps/foreign-$i.json',
                ),
            ],
            environmentPresets: const [],
          );
          final reader = ObstacleReader();
          final adapter = LocalMapWorkspaceAdapter(reader: reader);
          final session = ProjectSession(
            sessionId: root.path,
            name: project.name,
            directoryPath: root.path,
            storage: storage,
          );
          late EditableMapDocument document;
          late ProjectManifest selectedProject;
          final controller = MapWorkspaceController(session, adapter);
          addTearDown(controller.dispose);
          await tester.runAsync(() async {
            await root.create(recursive: true);
            if (storage == ProjectSessionStorage.workingCatalog) {
              final store = await CatalogStorageStore.open(
                projectRoot: root.path,
              );
              await WorkingProjectCatalog.create(
                store: store,
                projectId: 'obstacles',
                project: project,
              );
            } else {
              await File('${root.path}/project.json')
                  .writeAsString(jsonEncode(project.toJson()));
            }
            await File('${root.path}/maps/a.json').parent
                .create(recursive: true);
            await File('${root.path}/maps/a.json')
                .writeAsString(jsonEncode(source.toJson()));
            final history = File(
              '${root.path}/.pokemap/authoring/history.jsonl',
            );
            await history.parent.create(recursive: true);
            await history.writeAsString(
              'unrelated history must remain unread\n' * (unrelated + 1),
            );
            await controller.initialize();
            expect(controller.error, isNull);
            document = controller.active!;
            selectedProject = controller.project!;
          });
          var feedbackUs = 0;
          late Future<bool> publication;
          final publish = document.configureSpatialFieldObstacle!;
          document.configureSpatialFieldObstacle = (id, value) =>
              publication = publish(id, value);
          final commands = SpatialModelEditingCommands(
            document,
            selectedProject,
          );
          expect(commands.canConfigureFieldObstacle('oak-1'), isTrue);
          final counts = <int>[];
          for (var repeat = 0; repeat < 2; repeat++) {
            reader.paths.clear();
            await tester.runAsync(() async {
              final persistence = Stopwatch()..start();
              final feedback = Stopwatch()..start();
              unawaited(
                commands.configureFieldObstacle(
                  'oak-1',
                  MapEntityFieldObstacleData(
                    kind: repeat == 0
                        ? FieldObstacleKind.strengthBoulder
                        : FieldObstacleKind.rockSmashRock,
                  ),
                ),
              );
              feedbackUs = feedback.elapsedMicroseconds;
              expect(document.undoCount, repeat + 1);
              expect(
                isValidSpatialFieldObstacle(
                  document.current,
                  document.current.entities.single,
                ),
                isTrue,
              );
              expect(await publication, isTrue, reason: document.error);
              persistence.stop();
              debugPrint(
                'studio-field-obstacle storage=${storage.name} foreign=$unrelated repeat=$repeat feedbackUs=$feedbackUs durableUs=${persistence.elapsedMicroseconds} reads=${reader.paths.length}',
              );
            });
            await tester.pump();
            counts.add(reader.paths.length);
            expect(
              reader.paths.where(
                (path) => path.startsWith('maps/') && path != 'maps/a.json',
              ),
              isEmpty,
            );
            expect(
              reader.paths.where(
                (path) =>
                    path.endsWith('.glb') || path.endsWith('history.jsonl'),
              ),
              isEmpty,
            );
          }
          workCounts.add(counts);
          expect(
            counts.every((count) => count < 130),
            isTrue,
            reason: '$counts',
          );
          if (workCounts.length == 2) {
            expect(
              workCounts.last.map((count) => count > 0),
              workCounts.first.map((count) => count > 0),
            );
          }
          await tester.runAsync(() async {
            controller.restore(redo: false);
            while (document.saving) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
            expect(document.error, isNull);
            expect(
              document.saved.entities.single.fieldObstacle!.kind,
              FieldObstacleKind.strengthBoulder,
            );
            controller.restore(redo: false);
            while (document.saving) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
            expect(document.error, isNull);
            expect(document.saved.entities, isEmpty);
            controller.restore(redo: true);
            while (document.saving) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
            expect(document.error, isNull);
            expect(
              document.saved.entities.single.fieldObstacle!.kind,
              FieldObstacleKind.strengthBoulder,
            );
            controller.restore(redo: true);
            while (document.saving) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
            expect(document.error, isNull);
            expect(
              document.saved.entities.single.fieldObstacle!.kind,
              FieldObstacleKind.rockSmashRock,
            );
            final unsaved = document.current.copyWith(
              properties: {'unrelatedDraft': 'keep'},
            );
            document.commit(unsaved);
            expect(
              await controller.configureFieldObstacle(document, 'oak-1', null),
              isTrue,
              reason: document.error,
            );
            expect(document.current.properties, {'unrelatedDraft': 'keep'});
            expect(document.saved.properties, source.properties);
            final persisted = File('${root.path}/maps/a.json');
            expect(
              MapData.fromJson(
                jsonDecode(await persisted.readAsString())
                    as Map<String, dynamic>,
              ).properties,
              source.properties,
            );
            controller.restore(redo: false);
            while (document.saving) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
            expect(document.error, isNull);
            expect(document.current.properties, {'unrelatedDraft': 'keep'});
            expect(
              document.saved.entities.single.fieldObstacle!.kind,
              FieldObstacleKind.rockSmashRock,
            );
            final beforeConflict = await persisted.readAsBytes();
            final external = utf8.encode(
              jsonEncode(
                document.saved
                    .copyWith(properties: {'external': 'preserved'})
                    .toJson(),
              ),
            );
            await persisted.writeAsBytes(external);
            final draftBeforeConflict = document.current;
            expect(
              await controller.configureFieldObstacle(document, 'oak-1', null),
              isFalse,
            );
            expect(document.current, draftBeforeConflict);
            expect(await persisted.readAsBytes(), external);
            await persisted.writeAsBytes(beforeConflict);
            final cold = LocalMapWorkspaceAdapter();
            late final MapWorkspaceDocument reopened;
            if (storage == ProjectSessionStorage.workingCatalog) {
              await cold.loadCatalog(session);
              reopened = (await cold.loadMapSelection(
                session,
                project.maps.first,
              )).document;
            } else {
              final reopenedProject = await cold.loadProject(session);
              reopened = await cold.loadMap(
                session,
                reopenedProject.maps.first,
              );
            }
            expect(reopened.map, document.saved);
            expect(
              reopened.map.entities.single.fieldObstacle!.kind,
              FieldObstacleKind.rockSmashRock,
            );
          });
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
