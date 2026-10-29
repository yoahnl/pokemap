import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_zone_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  for (final storage in [
    ProjectSessionStorage.manifest,
    ProjectSessionStorage.workingCatalog,
  ]) {
    for (final foreign in [
      0,
      if (Platform.environment['AVELUNE_FIELD_OBSTACLE_LARGE_FIXTURE'] == '1')
        2000,
    ]) {
      testWidgets(
        'spatial route UI first repeat durable undo reopen $foreign ${storage.name}',
        (tester) async {
          final root = Directory(
            '/Users/karim/Library/Caches/AveluneQA/field-actions-3d/studio-route',
          );
          addTearDown(() async {
            if (await root.exists()) await root.delete(recursive: true);
          });
          final project = spatialEnvironmentProject().copyWith(
            environmentPresets: const [],
            maps: [
              const ProjectMapEntry(
                id: 'a',
                name: 'A',
                relativePath: 'maps/a.json',
              ),
              for (var i = 0; i < foreign; i++)
                ProjectMapEntry(
                  id: 'foreign-$i',
                  name: 'Foreign',
                  relativePath: 'maps/foreign-$i.json',
                ),
            ],
          );
          final reader = _Reader();
          final local = LocalMapWorkspaceAdapter(reader: reader);
          final session = ProjectSession(
            sessionId: root.path,
            name: project.name,
            directoryPath: root.path,
            storage: storage,
          );
          final controller = MapWorkspaceController(session, local);
          addTearDown(controller.dispose);
          late EditableMapDocument document;
          await tester.runAsync(() async {
            await root.create(recursive: true);
            if (storage == ProjectSessionStorage.workingCatalog) {
              final store = await CatalogStorageStore.open(
                projectRoot: root.path,
              );
              await WorkingProjectCatalog.create(
                store: store,
                projectId: 'routes',
                project: project,
              );
            } else {
              await File('${root.path}/project.json')
                  .writeAsString(jsonEncode(project.toJson()));
            }
            final file = File('${root.path}/maps/a.json');
            await file.parent.create(recursive: true);
            await file.writeAsString(
              jsonEncode(spatialEnvironmentMap().toJson()),
            );
            final history = File(
              '${root.path}/.pokemap/authoring/history.jsonl',
            );
            await history.parent.create(recursive: true);
            await history.writeAsString(
              'foreign history must not be read\n' * (foreign + 1),
            );
            await controller.initialize();
            expect(controller.error, isNull);
            document = controller.active!;
          });
          final commands = GameplayZoneEditingCommands(
            document,
            controller.project!,
          );
          expect(
            commands.availableKinds,
            contains(GameplayZoneKind.fieldAction),
          );
          late Future<bool> pending;
          final publish = document.configureFieldTraversal!;
          document.configureFieldTraversal = (next) => pending = publish(next);
          final view = MapWorkspaceViewState()
            ..tool = StudioMapTool.gameplayZone
            ..zoneKind = GameplayZoneKind.fieldAction;
          addTearDown(view.dispose);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, refresh) => SpatialMapEditor(
                    document: document,
                    controller: controller,
                    project: controller.project!,
                    visuals: _SpatialVisuals(),
                    view: view,
                    onChanged: () => refresh(() {}),
                  ),
                ),
              ),
            ),
          );
          final canvas = tester.widget<SpatialSceneView>(
            find.byType(SpatialSceneView),
          );
          late MapGameplayZone zone;
          await tester.runAsync(() async {
            reader.paths.clear();
            final timer = Stopwatch()..start();
            expect(
              canvas.onDragStart!(2, 2, null),
              isTrue,
              reason: document.error,
            );
            canvas.onDragUpdate!((5, 2));
            canvas.onDragEnd!();
            zone = document.current.gameplayZones.single;
            final feedback = timer.elapsedMicroseconds;
            expect(
              document.current.gameplayZones.single.fieldAction!.waterfall,
              isNotNull,
            );
            expect(await pending, isTrue, reason: document.error);
            timer.stop();
            debugPrint(
              'studio-route storage=${storage.name} foreign=$foreign first feedbackUs=$feedback durableUs=${timer.elapsedMicroseconds} reads=${reader.paths.length}',
            );
          });
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: SizedBox(
                    width: 500,
                    child: MapZoneInspector(
                      document: document,
                      project: controller.project!,
                      zone: document.current.gameplayZones.single,
                      onChanged: () {},
                      onDeleted: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(find.text('Cascade · 3D'), findsOneWidget);
          expect(find.text('Sens de traversée'), findsOneWidget);
          final surf = tester.widget<DropdownButtonFormField<String>>(
            find.descendant(
              of: find.byKey(ValueKey('waterfall-${zone.id}-Surf requis-true')),
              matching: find.byType(DropdownButtonFormField<String>),
            ),
          );
          await tester.runAsync(() async {
            reader.paths.clear();
            final timer = Stopwatch()..start();
            surf.onChanged!('false');
            final feedback = timer.elapsedMicroseconds;
            expect(
              document
                  .current
                  .gameplayZones
                  .single
                  .fieldAction!
                  .waterfall!
                  .requiresSurf,
              isFalse,
            );
            expect(await pending, isTrue, reason: document.error);
            timer.stop();
            debugPrint(
              'studio-route storage=${storage.name} foreign=$foreign repeat feedbackUs=$feedback durableUs=${timer.elapsedMicroseconds} reads=${reader.paths.length}',
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
            expect(reader.paths.length, lessThan(130));
            controller.restore(redo: false);
            while (document.saving) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
            expect(document.error, isNull);
            expect(
              document
                  .saved
                  .gameplayZones
                  .single
                  .fieldAction!
                  .waterfall!
                  .requiresSurf,
              isTrue,
            );
            controller.restore(redo: true);
            while (document.saving) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
            expect(document.error, isNull);
            expect(
              document
                  .saved
                  .gameplayZones
                  .single
                  .fieldAction!
                  .waterfall!
                  .requiresSurf,
              isFalse,
            );
            document.commit(
              document.current.copyWith(
                properties: {'foreignDraft': 'preserved'},
              ),
            );
            commands.configureWaterfall(zone.id, requiresSurf: true);
            expect(await pending, isTrue, reason: document.error);
            expect(document.current.properties, {'foreignDraft': 'preserved'});
            expect(
              document.saved.properties,
              spatialEnvironmentMap().properties,
            );
            reader.paths.clear();
            commands.delete(zone.id);
            expect(await pending, isTrue, reason: document.error);
            expect(
              reader.paths.where(
                (path) =>
                    path.startsWith('maps/') && path != 'maps/a.json' ||
                    path.endsWith('.glb') ||
                    path.endsWith('history.jsonl'),
              ),
              isEmpty,
            );
            expect(document.saved.gameplayZones, isEmpty);
            controller.restore(redo: false);
            while (document.saving) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
            expect(document.error, isNull);
            expect(
              document
                  .saved
                  .gameplayZones
                  .single
                  .fieldAction!
                  .waterfall!
                  .requiresSurf,
              isTrue,
            );
            expect(document.current.properties, {'foreignDraft': 'preserved'});
            final file = File('${root.path}/maps/a.json');
            final originalBytes = await file.readAsBytes();
            final externalBytes = utf8.encode(
              jsonEncode(
                document.saved
                    .copyWith(properties: {'external': 'preserved'})
                    .toJson(),
              ),
            );
            await file.writeAsBytes(externalBytes);
            final originalDraft = document.current;
            commands.configureWaterfall(zone.id, requiresSurf: false);
            expect(await pending, isFalse);
            expect(document.current, originalDraft);
            expect(await file.readAsBytes(), externalBytes);
            await file.writeAsBytes(originalBytes);
            final cold = MapWorkspaceController(
              session,
              LocalMapWorkspaceAdapter(),
            );
            addTearDown(cold.dispose);
            await cold.initialize();
            expect(cold.error, isNull);
            expect(cold.active!.saved, document.saved);
          });
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

final class _Reader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
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
  }) {
    paths.add(relativePath);
    return delegate.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

class _SpatialVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
