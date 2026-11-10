import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

void main() {
  late StudioPlaytestControls controls;
  setUp(() => controls = StudioPlaytestControls());
  test('reset resumes paused exploration without Studio controls', () {
    final movement = SpatialMovementController(
      scene: MapSpatialScene(
        width: 8,
        depth: 8,
        navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4)),
      ),
      models: [],
    );
    final commands = StudioSpatialExplorationCommands(movement: movement);
    movement.setInput(x: 1, z: 0);
    movement.update(.05);
    expect(movement.x, greaterThan(4));
    commands.togglePause();
    expect(movement.paused, isTrue);
    commands.resetPosition();
    expect(movement.paused, isFalse);
    expect(movement.x, 4);
    movement.update(.05);
    expect(movement.x, 4);
    final diagonal = movement.allowDiagonalMovement;
    commands.toggleDiagonal();
    expect(movement.allowDiagonalMovement, !diagonal);
  });

  testWidgets(
    'saved spatial map enters the 3D loader and reports missing hero before GPU',
    (tester) async {
      final port = LocalMapWorkspaceAdapter();
      late Directory root;
      late ProjectSession session;
      late ProjectManifest project;
      late String revision;
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp(
          'studio-spatial-playtest-',
        );
        final receipt = await const LocalProjectCreationService().create(
          ProjectCreationRequest(
            name: '3D test',
            folderName: 'game',
            parentPath: root.path,
            template: ProjectCreationTemplate.empty,
            dimension: ProjectDimension.threeD,
            mapWidth: 8,
            mapHeight: 8,
          ),
        );
        session = ProjectSession(
          sessionId: 'spatial',
          name: '3D test',
          directoryPath: receipt.projectPath,
        );
        project = await port.loadProject(session);
        revision = (await port.loadMap(session, project.maps.single)).revision;
      });
      addTearDown(() => root.delete(recursive: true));
      var returned = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudioPlaytestView(
              controls: controls,
              session: session,
              entry: project.maps.single,
              expectedRevision: revision,
              port: port,
              onClose: () => returned = true,
              prepareProjectAssets: (_) async =>
                  throw StateError('2D preparation must not run'),
            ),
          ),
        ),
      );
      for (var attempt = 0; attempt < 100; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
        if (find
            .textContaining('Choisissez un héros animé')
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
      expect(find.textContaining('Choisissez un héros animé'), findsOneWidget);
      expect(find.textContaining('2D preparation must not run'), findsNothing);
      controls.requestClose();
      expect(returned, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
