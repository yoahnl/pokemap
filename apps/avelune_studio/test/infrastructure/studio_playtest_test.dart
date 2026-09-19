import 'dart:io';

import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../tool/create_example_project.dart';

void main() {
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

  testWidgets('revision conflict refuses runtime before file bundle load', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudioPlaytestView(
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
    await tester.tap(find.text('Retour à la carte'));
    expect(closed, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('saved example mounts real runtime, walks, and returns', (
    tester,
  ) async {
    late Directory directory;
    late ProjectSession session;
    late ProjectManifest project;
    late MapWorkspaceDocument document;
    final port = LocalMapWorkspaceAdapter();
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('studio_playtest_');
      await writeExampleProject(directory);
      session = ProjectSession(
        sessionId: 'native-runtime',
        name: 'Example',
        directoryPath: await directory.resolveSymbolicLinks(),
      );
      project = await port.loadProject(session);
      document = await port.loadMap(session, project.maps.first);
    });
    addTearDown(() => directory.delete(recursive: true));
    var returned = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudioPlaytestView(
            session: session,
            entry: project.maps.first,
            expectedRevision: document.revision,
            port: port,
            onClose: () => returned = true,
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
    expect(game, isNotNull);
    expect(game!.isLoaded, isTrue);
    expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 9));
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.right),
    );
    game.update(.016);
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    );
    game.update(.3);
    expect(game.debugPlayerGridPosition, const GridPos(x: 9, y: 9));
    await tester.tap(find.text('Retour à la carte'));
    expect(returned, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(game.paused, isTrue);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
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
