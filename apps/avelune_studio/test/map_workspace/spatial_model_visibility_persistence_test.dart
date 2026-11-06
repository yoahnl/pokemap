import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/events/event_conditions.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_model_entity_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show AuthoringPerformanceObserver, AuthoringPerformanceSpan;
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  final counts = <ProjectSessionStorage, List<int>>{};
  for (final storage in [
    ProjectSessionStorage.workingCatalog,
    ProjectSessionStorage.manifest,
  ]) {
    for (final unrelated in [0, 80]) {
      testWidgets(
        'daily visibility UI persists and preserves preview first/repeat foreign=$unrelated ${storage.name}',
        (tester) async {
          final root = Directory(
            '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/periodic-availability-authoring/fixture',
          );
          addTearDown(() async {
            if (await root.exists()) await root.delete(recursive: true);
          });
          final source = spatialEnvironmentMap().copyWith(
            spatialScene: spatialEnvironmentMap().spatialScene!.copyWith(
              instances: [
                SpatialModelInstance(
                  id: 'oak-1',
                  modelId: 'oak',
                  blocksMovement: true,
                  position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
                ),
              ],
            ),
          );
          final project = spatialEnvironmentProject().copyWith(
            environmentPresets: const [],
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
            scenes: [
              SceneAsset(
                id: 'reward',
                name: 'Récompense',
                graph: SceneGraph(
                  startNodeId: 'start',
                  nodes: [
                    SceneNode(id: 'start', kind: SceneNodeKind.start),
                    SceneNode(id: 'end', kind: SceneNodeKind.end),
                    SceneNode(
                      id: 'claim',
                      kind: SceneNodeKind.action,
                      payload: SceneActionPayload.interactive(
                        SceneInteractiveCommand.claimPeriodicReward(
                          definition: PeriodicItemRewardDefinition(
                            rewardId: 'daily',
                            label: 'Fruit',
                            itemId: 'fruit',
                            quantity: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                  edges: const [],
                ),
              ),
            ],
          );
          final reader = _Reader();
          final observer = _Observer();
          final adapter = LocalMapWorkspaceAdapter(
            reader: reader,
            performanceObserver: observer,
          );
          final session = ProjectSession(
            sessionId: root.path,
            name: project.name,
            directoryPath: root.path,
            storage: storage,
          );
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
                projectId: 'daily-visibility',
                project: project,
              );
            } else {
              await File('${root.path}/project.json')
                  .writeAsString(jsonEncode(project.toJson()));
            }
            await Directory('${root.path}/maps').create();
            await File('${root.path}/maps/a.json')
                .writeAsString(jsonEncode(source.toJson()));
            for (var i = 0; i < unrelated; i++) {
              await File('${root.path}/maps/foreign-$i.json').writeAsString(
                jsonEncode(source.copyWith(id: 'foreign-$i').toJson()),
              );
            }
            final history = File(
              '${root.path}/.pokemap/authoring/history.jsonl',
            );
            await history.parent.create(recursive: true);
            await history.writeAsString(
              'foreign history must remain unread\n' * (unrelated + 1),
            );
            await controller.initialize();
            expect(controller.error, isNull);
          });
          final document = controller.active!;
          final renderMap = document.spatialPreviewMap;
          final publish = document.configureSpatialModelVisibility!;
          late Future<bool> publication;
          document.configureSpatialModelVisibility = (id, value) =>
              publication = publish(id, value);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: StatefulBuilder(
                    builder: (context, refresh) => SpatialModelEntityControls(
                      document: document,
                      project: controller.project!,
                      instance: document.current.spatialScene!.instances.single,
                      onChanged: () => refresh(() {}),
                    ),
                  ),
                ),
              ),
            ),
          );
          final measured = <int>[];
          for (final expected in [true, false]) {
            reader.paths.clear();
            reader.dataReads = 0;
            final condition = NarrativeEventConditionExpression.leaf(
              NarrativeEventCondition.periodicRewardAvailable(
                reference: PeriodicRewardReference(
                  sceneId: 'reward',
                  nodeId: 'claim',
                  rewardId: 'daily',
                ),
                expectedValue: expected,
              ),
            );
            final controls = tester.widget<EventConditions>(
              find.byType(EventConditions),
            );
            await tester.runAsync(() async {
              controls.onChanged(condition);
              expect(
                document
                    .current
                    .spatialScene!
                    .instances
                    .single
                    .visibilityCondition,
                condition,
              );
              expect(identical(document.spatialPreviewMap, renderMap), isTrue);
              expect(await publication, isTrue, reason: document.error);
            });
            await tester.pump();
            expect(identical(document.spatialPreviewMap, renderMap), isTrue);
            expect(
              document.current.spatialScene!.instances.single.blocksMovement,
              isTrue,
            );
            expect(
              reader.paths.where(
                (path) =>
                    path.startsWith('maps/') && path != 'maps/a.json' ||
                    path.endsWith('.glb') ||
                    path.endsWith('history.jsonl'),
              ),
              isEmpty,
            );
            measured.add(reader.dataReads);
            expect(observer.events, isNotEmpty);
          }
          final baseline = counts[storage];
          if (baseline != null) expect(measured, baseline);
          counts[storage] = measured;
          await tester.runAsync(() async {
            for (final redo in [false, false, true, true]) {
              controller.restore(redo: redo);
              while (document.saving) {
                await Future<void>.delayed(const Duration(milliseconds: 5));
              }
              expect(document.error, isNull);
              expect(identical(document.spatialPreviewMap, renderMap), isTrue);
            }
            final saved = MapData.fromJson(
              jsonDecode(await File('${root.path}/maps/a.json').readAsString())
                  as Map<String, dynamic>,
            );
            expect(
              saved.spatialScene!.instances.single.visibilityCondition,
              document
                  .current
                  .spatialScene!
                  .instances
                  .single
                  .visibilityCondition,
            );
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
          });
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _Observer implements AuthoringPerformanceObserver {
  final events = <String>[];
  @override
  AuthoringPerformanceSpan? startSpan(String name) {
    events.add('start:$name');
    return null;
  }

  @override
  void incrementCounter(String name, {int by = 1}) => events.add('$name:$by');
}

final class _Reader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  int dataReads = 0;
  final delegate = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => delegate.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    paths.add(relativePath);
    final bytes = await delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    if (!relativePath.startsWith('catalog/objects/')) {
      dataReads++;
    } else {
      final value = jsonDecode(utf8.decode(bytes));
      if (value is Map && value['key'] is Map) dataReads++;
    }
    return bytes;
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) async* {
    yield await readBytes(projectRoot: projectRoot, relativePath: relativePath);
  }
}
