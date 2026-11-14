import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'map_save_cost_bench_support.dart';

void main() {
  final root = Platform.environment['AVELUNE_MAP_SAVE_BENCH_ROOT'];
  final mapId =
      Platform.environment['AVELUNE_MAP_SAVE_BENCH_MAP'] ?? 'first-map';
  final profile = Platform.environment['AVELUNE_MAP_SAVE_BENCH_PROFILE'] == '1';
  final repeats = int.parse(
    Platform.environment['AVELUNE_MAP_SAVE_BENCH_REPEATS'] ?? '3',
  );

  test(
    'map save cost on a real working catalog',
    () async {
      final reader = SaveCostCountingReader();
      final adapter = LocalMapWorkspaceAdapter(reader: reader);
      final profiler = profile ? await SaveCostProfiler.connect() : null;
      final sessionWatch = Stopwatch()..start();
      final session = await LocalProjectSessionAdapter().open(root!);
      stdout.writeln(
        'bench session ms=${sessionWatch.elapsedMilliseconds} storage=${session.storage.name}',
      );
      expect(session.storage, ProjectSessionStorage.workingCatalog);
      final controller = MapWorkspaceController(session, adapter);

      Future<void> measure(String label, Future<void> Function() body) async {
        reader.reset();
        final started = DateTime.now();
        await profiler?.start();
        final watch = Stopwatch()..start();
        await body();
        watch.stop();
        final report = await profiler?.stop();
        final written = await writtenSince(root, started);
        stdout.writeln(
          'bench $label ms=${watch.elapsedMilliseconds} ${reader.summary()} writes=${written.length} ${summarizeWrites(written)}',
        );
        if (report != null) stdout.writeln(report);
      }

      await measure('open', () async {
        await controller.initialize();
        expect(controller.error, isNull);
        final entry = controller.project!.maps.singleWhere(
          (map) => map.id == mapId,
        );
        await controller.activate(entry);
        expect(controller.error, isNull);
      });
      final document = controller.documents[mapId]!;
      final npc = document.current.entities.firstWhere(
        (entity) => entity.npc != null,
      );
      final instance = document.current.spatialScene!.instances.first;

      for (var repeat = 0; repeat < repeats; repeat++) {
        await measure('presence#$repeat', () async {
          final previous =
              document.current.entities
                  .firstWhere((entity) => entity.id == npc.id)
                  .npc
                  ?.visibilityRule
                  ?.predicate
                  ?.timeWindow
                  ?.startMinute ??
              0;
          document.commit(
            const EntityActions().setVisibilityRule(
              document.current,
              entityId: npc.id,
              visibilityRule: MapEntityNpcVisibilityRule(
                mode: MapEntityNpcVisibilityMode.visibleWhen,
                predicate: MapEntityRuntimePredicate(
                  kind: MapEntityRuntimePredicateKind.localTimeWindow,
                  timeWindow: LocalTimeWindow(
                    startMinute: (previous + 30) % 600 + 60,
                    endMinute: 60 * 20,
                  ),
                ),
              ),
            ),
          );
          expect(
            await controller.save(document),
            isTrue,
            reason: document.error,
          );
        });
        await measure('camera#$repeat', () async {
          final camera = document.current.spatialScene!.camera;
          document.commit(
            const SpatialMapOperations().configureCamera(
              document.current,
              camera.copyWith(distance: camera.distance + 1),
            ),
          );
          expect(
            await controller.save(document),
            isTrue,
            reason: document.error,
          );
        });
        await measure('move#$repeat', () async {
          final scene = document.current.spatialScene!;
          final current = scene.instances.firstWhere(
            (value) => value.id == instance.id,
          );
          document.commit(
            document.current.copyWith(
              spatialScene: scene.copyWith(
                instances: [
                  for (final value in scene.instances)
                    value.id == current.id
                        ? value.copyWith(
                            position: Model3dVector3(
                              x: current.position.x + (repeat.isEven ? 1 : -1),
                              y: current.position.y,
                              z: current.position.z,
                            ),
                          )
                        : value,
                ],
              ),
            ),
          );
          expect(
            await controller.save(document),
            isTrue,
            reason: document.error,
          );
        });
      }
      final saved = document.saved;
      final cold = LocalMapWorkspaceAdapter();
      await cold.loadCatalog(session);
      final entry = (await cold.loadCatalog(session)).metadata.maps
          .singleWhere((map) => map.id == mapId);
      final reopened = (await cold.loadMapSelection(session, entry)).document;
      expect(reopened.map, saved);
      controller.dispose();
      await profiler?.close();
    },
    skip: root == null
        ? 'Set AVELUNE_MAP_SAVE_BENCH_ROOT to a QA copy.'
        : false,
    timeout: const Timeout(Duration(minutes: 60)),
  );
}
