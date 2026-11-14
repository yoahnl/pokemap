import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_start.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:path/path.dart' as p;

import '../../tool/create_example_project.dart';

void main() {
  late StudioPlaytestControls controls;
  setUp(() => controls = StudioPlaytestControls());
  test('playtest saves are isolated per launch and discarded', () async {
    final first = StudioPlaytestSaveRepository();
    final second = StudioPlaytestSaveRepository();
    await first.save(const GameState(saveId: 'test-only'));
    expect(await first.exists(), isTrue);
    expect((await first.load())!.saveId, 'test-only');
    expect(await second.exists(), isFalse);
    await first.delete();
    expect(await first.load(), isNull);
  });

  test('a broken authored spawn is not replaced by a test fallback', () async {
    final project = ProjectManifest(
      name: 'Broken spawn',
      maps: const [
        ProjectMapEntry(id: 'start', name: 'Start', relativePath: 'start.json'),
        ProjectMapEntry(id: 'other', name: 'Other', relativePath: 'other.json'),
      ],
      tilesets: const [],
      newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'start'),
    );
    final bundle = RuntimeMapBundle(
      manifest: project,
      map: const MapData(
        id: 'other',
        name: 'Other',
        size: GridSize(width: 4, height: 4),
        mapMetadata: MapMetadata(defaultSpawnId: 'missing'),
      ),
      projectRootDirectory: '/unused',
      tilesetAbsolutePathsById: const {},
    );
    await expectLater(
      prepareStudioPlaytestStart(bundle, '/unused/project.json'),
      throwsA(isA<GameplaySpawnResolutionException>()),
    );
  });

  testWidgets('revision conflict refuses runtime before file bundle load', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudioPlaytestView(
            controls: controls,
            session: const ProjectSession(
              sessionId: 'session',
              name: 'Test',
              directoryPath: '/does-not-exist',
            ),
            entry: const ProjectMapEntry(
              id: 'map',
              name: 'Carte',
              relativePath: 'map.json',
            ),
            expectedRevision: 'expected-revision',
            port: _ChangedPort(),
            onClose: () => closed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('La carte a changé sur disque'), findsOneWidget);
    expect(find.text('Retour à la carte'), findsNothing);
    expect(find.byKey(const ValueKey('playtest-fps')), findsNothing);
    controls.requestClose();
    expect(closed, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('selected map without a spawn starts an isolated test game', (
    tester,
  ) async {
    late Directory directory;
    late ProjectSession session;
    late ProjectMapEntry entry;
    late MapWorkspaceDocument document;
    late String projectBefore;
    late String mapBefore;
    var port = LocalMapWorkspaceAdapter();
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('studio_other_map_');
      await writeExampleProject(directory);
      session = ProjectSession(
        sessionId: 'other-map-test',
        name: 'Two maps',
        directoryPath: await directory.resolveSymbolicLinks(),
      );
      final project = await port.loadProject(session);
      final configured = project.copyWith(
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'jardin',
          startSpawnId: 'depart',
          startingMoney: 75,
        ),
      );
      await File(p.join(directory.path, 'project.json'))
          .writeAsString(jsonEncode(configured.toJson()));
      final otherMap = exampleMap(
        'clairiere',
        'Clairière',
        alternate: true,
      ).copyWith(entities: const []);
      await File(p.join(directory.path, 'maps', 'clairiere.json'))
          .writeAsString(jsonEncode(otherMap.toJson()));
      projectBefore = await File(p.join(directory.path, 'project.json'))
          .readAsString();
      mapBefore = await File(p.join(directory.path, 'maps', 'clairiere.json'))
          .readAsString();
      port = LocalMapWorkspaceAdapter();
      await port.loadProject(session);
      entry = configured.maps.firstWhere((map) => map.id == 'clairiere');
      document = await port.loadMap(session, entry);
    });
    addTearDown(() => directory.delete(recursive: true));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudioPlaytestView(
            controls: controls,
            session: session,
            entry: entry,
            expectedRevision: document.revision,
            port: port,
            onClose: () {},
          ),
        ),
      ),
    );
    PlayableMapGame? game;
    for (var attempt = 0; attempt < 300; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final finder = find.byType(GameWidget<PlayableMapGame>);
      if (finder.evaluate().isNotEmpty) {
        game = tester.widget<GameWidget<PlayableMapGame>>(finder).game;
        if (game!.isLoaded && !game.debugIsMapActivationDispatchInFlight) break;
      }
    }
    expect(find.textContaining('Expected authored start map'), findsNothing);
    expect(game, isNotNull);
    expect(game!.isLoaded, isTrue);
    expect(game.gameStateSnapshot.currentMapId, 'clairiere');
    expect(game.gameStateSnapshot.trainerProfile.money, 75);
    final position = game.debugPlayerGridPosition;
    expect(position, isNotNull);
    expect(position.x, inInclusiveRange(0, document.map.size.width - 1));
    expect(position.y, inInclusiveRange(0, document.map.size.height - 1));
    final previousGame = game;
    final pendingPc = game.debugOpenPlayerServicePc();
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      if (find.byType(PlayerPcOverlay).evaluate().isNotEmpty) break;
    }
    expect(find.byType(PlayerPcOverlay), findsOneWidget);
    await controls.newGame();
    await tester.pump();
    await tester.runAsync(
      () async => expect(
        (await pendingPc).status,
        PlayerServiceRuntimeStatus.cancelled,
      ),
    );
    for (var attempt = 0; attempt < 300; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final finder = find.byType(GameWidget<PlayableMapGame>);
      if (finder.evaluate().isNotEmpty) {
        game = tester.widget<GameWidget<PlayableMapGame>>(finder).game;
        if (game!.isLoaded && !game.debugIsMapActivationDispatchInFlight) break;
      }
    }
    expect(game, isNot(same(previousGame)));
    expect(previousGame.isPaused, isTrue);
    expect(find.byType(PlayerPcOverlay), findsNothing);
    expect(game!.gameStateSnapshot.currentMapId, 'clairiere');
    expect(game.gameStateSnapshot.trainerProfile.money, 75);
    await tester.runAsync(() async {
      expect(
        await File(p.join(directory.path, 'project.json')).readAsString(),
        projectBefore,
      );
      expect(
        await File(p.join(directory.path, 'maps', 'clairiere.json'))
            .readAsString(),
        mapBefore,
      );
    });
    await tester.pumpWidget(const SizedBox());
  });
}

class _ChangedPort implements MapWorkspacePort {
  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async => const MapWorkspaceDocument(
    map: MapData(id: 'map', name: 'Carte', size: GridSize(width: 1, height: 1)),
    revision: 'changed-revision',
    mapId: 'map',
  );

  @override
  Future<ProjectManifest> loadProject(ProjectSession session) =>
      throw UnimplementedError();

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) => throw UnimplementedError();
}
