import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_platform_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  for (final foreign in [0, 90]) {
    testWidgets(
      'guided route platform UI persistence stays targeted with $foreign foreign maps',
      (tester) async {
        final root = Directory(
          '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7/platforms/studio',
        );
        addTearDown(() async {
          if (await root.exists()) await root.delete(recursive: true);
        });
        final project = spatialEnvironmentProject().copyWith(
          environmentPresets: const [],
          maps: [
            const ProjectMapEntry(
              id: 'a',
              name: 'Hall',
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
        final deck = SpatialModelInstance(
          id: 'deck',
          modelId: 'oak',
          blocksMovement: false,
          position: Model3dVector3(x: 2, y: 0, z: 2),
        );
        final map = spatialEnvironmentMap().copyWith(
          spatialScene: MapSpatialScene(
            width: 12,
            depth: 10,
            instances: [deck],
          ),
        );
        final reader = _Reader();
        final adapter = LocalMapWorkspaceAdapter(reader: reader);
        final session = ProjectSession(
          sessionId: root.path,
          name: project.name,
          directoryPath: root.path,
          storage: ProjectSessionStorage.workingCatalog,
        );
        final controller = MapWorkspaceController(session, adapter);
        addTearDown(controller.dispose);
        late EditableMapDocument document;
        await tester.runAsync(() async {
          if (await root.exists()) await root.delete(recursive: true);
          await root.create(recursive: true);
          final store = await CatalogStorageStore.open(projectRoot: root.path);
          await WorkingProjectCatalog.create(
            store: store,
            projectId: 'platform-ui',
            project: project,
          );
          final file = File('${root.path}/maps/a.json');
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode(map.toJson()));
          for (var i = 0; i < foreign; i++) {
            await File('${root.path}/maps/foreign-$i.json')
                .writeAsString('must not be read');
          }
          await controller.initialize();
          expect(controller.error, isNull);
          document = controller.active!;
        });
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: SpatialPlatformControls(
                  document: document,
                  project: project,
                  instance: deck,
                  onChanged: () {},
                ),
              ),
            ),
          ),
        );
        Future<void> press(String label) async {
          final button = find.text(label);
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pump();
        }

        await press('Créer le trajet');
        expect(
          document
              .current
              .spatialScene!
              .platforms
              .single
              .routes
              .single
              .waypoints
              .length,
          2,
        );
        final first = document.current;
        final counts = <int>[];
        for (var repeat = 0; repeat < 2; repeat++) {
          if (repeat == 1) {
            final field = find.byWidgetPredicate(
              (widget) =>
                  widget is StudioDraftField &&
                  widget.label == 'Durée du trajet (ms)',
            );
            await tester.ensureVisible(field);
            await tester.enterText(
              find.descendant(of: field, matching: find.byType(TextField)),
              '2000',
            );
            await press('Appliquer le trajet');
          }
          await tester.runAsync(() async {
            reader.paths.clear();
            final timer = Stopwatch()..start();
            final revision = await adapter.saveMap(
              session,
              document.base,
              document.current,
            );
            document.acceptSave(document.current, revision);
            timer.stop();
            counts.add(reader.paths.length);
            expect(
              reader.paths.where(
                (path) =>
                    path.startsWith('maps/') && path != 'maps/a.json' ||
                    path.endsWith('.glb') ||
                    path.endsWith('history.jsonl'),
              ),
              isEmpty,
            );
            debugPrint(
              'platform-studio foreign=$foreign repeat=$repeat reads=${reader.paths.length} elapsedUs=${timer.elapsedMicroseconds}',
            );
          });
        }
        expect(counts.every((value) => value < 200), isTrue, reason: '$counts');
        expect(
          document.current.spatialScene!.instances,
          first.spatialScene!.instances,
        );
        final field = find.byWidgetPredicate(
          (widget) =>
              widget is StudioDraftField &&
              widget.label == 'Durée du trajet (ms)',
        );
        await tester.ensureVisible(field);
        await tester.enterText(
          find.descendant(of: field, matching: find.byType(TextField)),
          '-1',
        );
        final before = document.current;
        await press('Appliquer le trajet');
        expect(document.current, same(before));
        await tester.runAsync(() async {
          final reopened = MapWorkspaceController(
            session,
            LocalMapWorkspaceAdapter(),
          );
          addTearDown(reopened.dispose);
          await reopened.initialize();
          expect(reopened.error, isNull);
          expect(
            reopened.active!.saved.spatialScene!.platforms.single.durationMs,
            2000,
          );
        });
        expect(tester.takeException(), isNull);
      },
    );
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
