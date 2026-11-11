import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_connection_actions.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_connection_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flame/components.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import 'support/technical_map_journey_host.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the technical 2D viewport saves two maps crossed by the simulated runtime',
    (tester) async {
      expect(Platform.isMacOS, isTrue);
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final host = await TechnicalMapJourneyHost.open(tester);
      try {
        final originalMaps = await host.savedMapBytes();
        await host.selectDecor('arbre');
        final mouse = TestPointer(82, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(
          mouse.hover(host.viewport.cellAt(10, 4)),
        );
        await host.viewport.pump();
        final preview = find.byKey(const ValueKey('decor-placement-preview'));
        expect(preview, findsOneWidget);
        expect(tester.widget<Opacity>(preview).opacity, lessThan(1));
        expect(await host.savedMapBytes(), originalMaps);
        await host.viewport.tapCell(10, 4);
        expect(host.document.dirty, isTrue);
        expect(await host.savedMapBytes(), originalMaps);
        await host.save();
        final authoredTree = (await host.readSavedMap('jardin')).placedElements
            .where(
              (element) =>
                  element.elementId == 'arbre' &&
                  element.pos == const GridPos(x: 10, y: 4),
            );
        expect(authoredTree, hasLength(1));
        expect(authoredTree.single.layerId, 'decor');

        await _freeEdge(host, 23, 9);
        await host.save();
        await host.activate('clairiere');
        await _freeEdge(host, 0, 9);
        await host.save();
        await host.activate('jardin');
        final connection = MapWorkspaceConnectionActions(
          controller: host.maps,
          port: LocalMapConnectionAdapter(host.adapter),
          isActive: () => !host.maps.isDisposed,
          changed: host.maps.notify,
        );
        await tester.runAsync(
          () => connection.link(MapConnectionDirection.east, 'clairiere', 0),
        );
        await host.viewport.pump();
        expect(connection.error, isNull);
        expect(connection.busy, isFalse);

        final savedGarden = await host.readSavedMap('jardin');
        final savedClearing = await host.readSavedMap('clairiere');
        expect(savedGarden.connections.single.targetMapId, 'clairiere');
        expect(
          savedGarden.connections.single.direction,
          MapConnectionDirection.east,
        );
        expect(savedGarden.connections.single.offset, 0);
        expect(savedClearing.connections.single.targetMapId, 'jardin');
        expect(
          savedClearing.connections.single.direction,
          MapConnectionDirection.west,
        );
        expect(savedClearing.connections.single.offset, 0);
        expect(
          savedGarden.layers
              .whereType<CollisionLayer>()
              .single
              .collisions[9 * 24 + 23],
          isFalse,
        );
        expect(
          savedClearing.layers.whereType<CollisionLayer>().single.collisions[9 *
              24],
          isFalse,
        );

        final reopening = LocalProjectSessionAdapter();
        final reopenedSession = (await tester.runAsync(
          () => reopening.open(host.root),
        ))!;
        final reopened = MapWorkspaceController(
          reopenedSession,
          LocalMapWorkspaceAdapter(),
        );
        try {
          await tester.runAsync(reopened.initialize);
          await tester.runAsync(
            () => reopened.activate(
              reopened.project!.maps.singleWhere(
                (entry) => entry.id == 'jardin',
              ),
            ),
          );
          expect(reopened.error, isNull);
          expect(reopened.active!.current, savedGarden);
          expect(
            reopened.active!.current.placedElements.where(
              (element) =>
                  element.elementId == 'arbre' &&
                  element.pos == const GridPos(x: 10, y: 4),
            ),
            hasLength(1),
          );
          await tester.runAsync(
            () => reopened.activate(
              reopened.project!.maps.singleWhere(
                (entry) => entry.id == 'clairiere',
              ),
            ),
          );
          expect(reopened.error, isNull);
          expect(reopened.active!.current, savedClearing);
        } finally {
          reopened.dispose();
          await tester.runAsync(() => reopening.close(reopenedSession));
        }

        final sourceBeforeRuntime = await host.savedMapBytes();
        final descriptor = File(p.join(host.root, 'project.json'));
        final head = File(p.join(host.root, 'catalog', 'HEAD.json'));
        final descriptorBefore = descriptor.readAsBytesSync();
        final project =
            jsonDecode(utf8.decode(descriptorBefore)) as Map<String, dynamic>;
        final expectsHead = project['format'] == 'avelune.working-catalog';
        expect(head.existsSync(), expectsHead);
        final headBefore = expectsHead ? head.readAsBytesSync() : null;
        final journey = await tester.runAsync(
          () => _simulateSavedProjectRuntime(host.root),
        );
        expect(journey?.arrival, 'clairiere');
        expect(journey?.arrivalPos, const GridPos(x: 0, y: 9));
        expect(journey?.returned, 'jardin');
        expect(await host.savedMapBytes(), sourceBeforeRuntime);
        expect(descriptor.readAsBytesSync(), orderedEquals(descriptorBefore));
        expect(head.existsSync(), expectsHead);
        if (headBefore != null) {
          expect(head.readAsBytesSync(), orderedEquals(headBefore));
        }
        expect(tester.takeException(), isNull);
      } finally {
        await host.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _freeEdge(TechnicalMapJourneyHost host, int x, int y) async {
  final before = await host.savedMapBytes();
  await host.tool('Effacer les collisions');
  await host.viewport.tapCell(x, y);
  expect(host.document.dirty, isTrue);
  expect(await host.savedMapBytes(), before);
}

Future<({String? arrival, GridPos? arrivalPos, String? returned})>
_simulateSavedProjectRuntime(String root) async {
  final projectFile = p.join(root, 'project.json');
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile,
    mapId: 'jardin',
  );
  final game = _SimulatedLoadedGame(
    bundle: bundle,
    projectFilePath: projectFile,
    saveRepository: _MemorySaveRepository(),
  );
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  for (var frame = 0; frame < 240; frame++) {
    if (game.debugCompletedMapActivationDispatchCount > 0) break;
    game.update(1 / 60);
    await Future<void>.delayed(Duration.zero);
  }
  if (game.debugCompletedMapActivationDispatchCount == 0) {
    throw TestFailure('The Player did not finish its initial map activation');
  }
  if (!game.handleRuntimeInputEvent(
    RuntimeInputEvent.press(RuntimeInputControl.right),
  )) {
    throw TestFailure('The Player refused movement input');
  }
  for (var frame = 0; frame < 1800; frame++) {
    game.update(1 / 60);
    await Future<void>.delayed(Duration.zero);
    if (game.debugLastCompletedMapActivation?.mapId == 'clairiere') break;
  }
  game.handleRuntimeInputEvent(
    RuntimeInputEvent.release(RuntimeInputControl.right),
  );
  final arrival = game.debugLastCompletedMapActivation?.mapId;
  final arrivalPos = game.debugPlayerGridPosition;
  for (var frame = 0; frame < 20; frame++) {
    game.update(1 / 60);
    await Future<void>.delayed(Duration.zero);
  }
  if (!game.handleRuntimeInputEvent(
    RuntimeInputEvent.press(RuntimeInputControl.left),
  )) {
    throw TestFailure('The Player refused the return movement input');
  }
  for (var frame = 0; frame < 1800; frame++) {
    game.update(1 / 60);
    await Future<void>.delayed(Duration.zero);
    if (game.debugLastCompletedMapActivation?.mapId == 'jardin') break;
  }
  game.handleRuntimeInputEvent(
    RuntimeInputEvent.release(RuntimeInputControl.left),
  );
  return (
    arrival: arrival,
    arrivalPos: arrivalPos,
    returned: game.debugLastCompletedMapActivation?.mapId,
  );
}

class _SimulatedLoadedGame extends PlayableMapGame {
  _SimulatedLoadedGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
  });

  @override
  bool get isLoaded => true;
}

class _MemorySaveRepository implements GameSaveRepository {
  GameState? state;

  @override
  Future<void> save(GameState value) async => state = value;
  @override
  Future<GameState?> load() async => state;
  @override
  Future<bool> exists() async => state != null;
  @override
  Future<void> delete() async => state = null;
}
