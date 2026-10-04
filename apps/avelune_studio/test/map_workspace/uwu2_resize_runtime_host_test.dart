import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_session.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_start.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import '../support/map_catalogue_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets(
    'workspace growth persists and the reloaded runtime walks beyond old bounds',
    (tester) async {
      final fixture = await MapCatalogueHostFixture.open(tester);
      final entry = await fixture.createMap('Promenade agrandie');
      final workspace = fixture.host.maps;
      final document = workspace.active!;
      final originalSize = document.current.size;
      final spawn = GridPos(x: originalSize.width - 2, y: 1);
      final entities = MapEntityEditingCommands(document, workspace.project!);
      entities.place(MapEntityKind.spawn, spawn);
      await fixture.tapKey('Enregistrer');
      expect(document.dirty, isFalse, reason: workspace.error);
      final saved = await fixture.reopen();
      final source = saved.maps[entry.id]!;
      final targetSize = GridSize(
        width: originalSize.width + 4,
        height: originalSize.height + 3,
      );

      await fixture.mapAction(entry.id, 'Redimensionner…');
      await fixture.field('resize-map-width', '${targetSize.width}');
      await fixture.field('resize-map-height', '${targetSize.height}');
      await tester.tap(find.text('Analyser les conséquences'));
      await pumpIo(tester, frames: 20);
      expect((await fixture.reopen()).maps[entry.id], source);
      await tester.tap(find.text('Appliquer le redimensionnement'));
      await pumpIo(tester, frames: 30);
      expect(workspace.active!.current.size, targetSize);
      expect(workspace.active!.dirty, isFalse, reason: workspace.error);
      final sourcePath = fixture.host.session.state.project!.directoryPath;
      await fixture.host.dispose();
      expect(fixture.host.session.state.project, isNull);

      final sessionAdapter = LocalProjectSessionAdapter();
      final reopened = (await tester.runAsync(
        () => sessionAdapter.open(sourcePath),
      ))!;
      addTearDown(() => tester.runAsync(() => sessionAdapter.close(reopened)));
      final adapter = LocalMapWorkspaceAdapter();
      final reread = (await tester.runAsync(() async {
        final project = await adapter.loadProject(reopened);
        final selected = project.maps.singleWhere((map) => map.id == entry.id);
        return (
          project: project,
          map: (await adapter.loadMap(reopened, selected)).map,
        );
      }))!;
      expect(reread.map.size, targetSize);
      expect(reread.map.entities, source.entities);
      expect(reread.project.settings, saved.project.settings);
      expect(reread.project.newGame, saved.project.newGame);
      expect(reread.project.settings.tileWidth, 32);
      expect(reread.project.settings.tileHeight, 32);

      final game = (await tester.runAsync(() async {
        final projectPath = p.join(sourcePath, 'project.json');
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: projectPath,
          mapId: entry.id,
        );
        expect(bundle.map, reread.map);
        return PlayableMapGame(
          bundle: bundle,
          projectFilePath: projectPath,
          initialGameState: await prepareStudioPlaytestStart(
            bundle,
            projectPath,
          ),
          saveRepository: StudioPlaytestSession(),
        );
      }))!;
      await tester.pumpWidget(
        MaterialApp(home: GameWidget<PlayableMapGame>(game: game)),
      );
      addTearDown(() async {
        game.pauseEngine();
        await tester.pumpWidget(const SizedBox());
      });
      await pumpIo(tester, frames: 40);
      await tester.runAsync(() async => await game.toBeLoaded());
      await _until(tester, game, () {
        return !game.debugIsMapActivationDispatchInFlight &&
            !game.inputAuthoritySnapshot.isGameplayLocked;
      });
      expect(game.debugPlayerGridPosition, spawn);
      expect(game.gameStateSnapshot.currentMapId, entry.id);
      final extendedCell = GridPos(x: originalSize.width + 2, y: spawn.y);
      final startWorld = game.debugPlayerWorldTopLeft;
      expect(
        game.handleRuntimeInputEvent(
          RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      await _until(
        tester,
        game,
        () => game.debugPlayerGridPosition == extendedCell,
      );
      expect(
        game.handleRuntimeInputEvent(
          RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );
      await _until(
        tester,
        game,
        () =>
            game.debugPlayerWorldTopLeft ==
            game.debugExpectedPlayerWorldTopLeft,
      );
      expect(game.debugPlayerGridPosition.x, greaterThan(originalSize.width));
      expect(
        game.debugPlayerWorldTopLeft.x - startWorld.x,
        closeTo(
          (extendedCell.x - spawn.x) *
              reread.project.settings.tileWidth *
              reread.project.settings.displayScale,
          .001,
        ),
      );
      expect(
        game.debugPlayerWorldTopLeft,
        game.debugExpectedPlayerWorldTopLeft,
      );
      final lastCell = GridPos(x: targetSize.width - 1, y: spawn.y);
      game.handleRuntimeInputEvent(
        RuntimeInputEvent.press(RuntimeInputControl.right),
      );
      await _until(
        tester,
        game,
        () => game.debugPlayerGridPosition == lastCell,
      );
      for (var frame = 0; frame < 60; frame++) {
        game.update(1 / 60);
      }
      game.handleRuntimeInputEvent(
        RuntimeInputEvent.release(RuntimeInputControl.right),
      );
      expect(game.debugPlayerGridPosition, lastCell);
      expect(reread.map.size.width, lastCell.x + 1);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _until(
  WidgetTester tester,
  PlayableMapGame game,
  bool Function() ready,
) async {
  for (var frame = 0; frame < 600 && !ready(); frame++) {
    game.update(1 / 60);
    await pumpIo(tester, frames: 1);
  }
  expect(ready(), isTrue, reason: 'The runtime reached the expected state.');
}
