import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flame/components.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import '../tool/create_example_project.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Studio edits two maps and the Player crosses their saved link', (
    tester,
  ) async {
    expect(Platform.isMacOS, isTrue);
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final directory = await Directory.systemTemp.createTemp(
      'avelune-map-authoring-player-',
    );
    final root = await directory.resolveSymbolicLinks();
    final session = ProjectSessionController(LocalProjectSessionAdapter());
    try {
      await writeExampleProject(directory);
      await session.open(root);
      await tester.pumpWidget(StudioBootstrap(debugSession: session));
      await _until(
        tester,
        () => find.byKey(const ValueKey('home-tool-map')).evaluate().isNotEmpty,
      );
      await tester.tap(find.byKey(const ValueKey('home-tool-map')));
      await _until(
        tester,
        () => find.byKey(const ValueKey('map-canvas')).evaluate().isNotEmpty,
      );

      final gardenFile = File(p.join(root, 'maps', 'jardin.json'));
      final clearingFile = File(p.join(root, 'maps', 'clairiere.json'));
      final originalGarden = gardenFile.readAsBytesSync();
      await tester.tap(find.byKey(const ValueKey('decor-arbre')));
      await tester.pump();
      final mouse = TestPointer(82, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(mouse.hover(_cell(tester, 10, 4)));
      await tester.pump();
      final preview = find.byKey(const ValueKey('decor-placement-preview'));
      expect(preview, findsOneWidget);
      expect(tester.widget<Opacity>(preview).opacity, lessThan(1));
      expect(gardenFile.readAsBytesSync(), orderedEquals(originalGarden));
      await tester.tapAt(_cell(tester, 10, 4));
      await _until(
        tester,
        () => find.text('Non enregistré').evaluate().isNotEmpty,
      );
      expect(gardenFile.readAsBytesSync(), orderedEquals(originalGarden));
      await _save(tester);
      final authoredTree = _readMap(gardenFile).placedElements.where(
        (element) =>
            element.elementId == 'arbre' &&
            element.pos == const GridPos(x: 10, y: 4),
      );
      expect(authoredTree, hasLength(1));
      expect(authoredTree.single.layerId, 'decor');

      await _freeEdge(tester, 23, 9);
      await _save(tester);
      await tester.tap(find.byKey(const ValueKey('map-library-clairiere')));
      await _until(tester, () => find.text('Clairière').evaluate().length > 1);
      await _freeEdge(tester, 0, 9);
      await _save(tester);
      await tester.tap(find.byKey(const ValueKey('map-library-jardin')));
      await _until(
        tester,
        () => find.text('Jardin des essais').evaluate().length > 1,
      );
      await tester.tap(find.byTooltip('Autres outils de carte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Passages').last);
      await tester.pumpAndSettle();
      await _until(
        tester,
        () => find
            .byKey(const ValueKey('connection-create'))
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(find.byKey(const ValueKey('connection-create')));
      await _until(tester, () => _readMap(gardenFile).connections.isNotEmpty);

      final savedGarden = _readMap(gardenFile);
      final savedClearing = _readMap(clearingFile);
      expect(savedGarden.connections.single.targetMapId, 'clairiere');
      expect(savedClearing.connections.single.targetMapId, 'jardin');
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

      final reopened = MapWorkspaceController(
        ProjectSession(
          sessionId: root,
          name: 'Réouverture',
          directoryPath: root,
        ),
        LocalMapWorkspaceAdapter(),
      );
      try {
        await reopened.initialize();
        expect(
          reopened.active!.current.connections.single.targetMapId,
          'clairiere',
        );
        expect(
          reopened.active!.current.placedElements.where(
            (element) =>
                element.elementId == 'arbre' &&
                element.pos == const GridPos(x: 10, y: 4),
          ),
          hasLength(1),
        );
        await reopened.activate(
          reopened.project!.maps.firstWhere((entry) => entry.id == 'clairiere'),
        );
        expect(
          reopened.active!.current.connections.single.targetMapId,
          'jardin',
        );
      } finally {
        reopened.dispose();
      }

      final gardenBytes = gardenFile.readAsBytesSync();
      final clearingBytes = clearingFile.readAsBytesSync();
      final journey = await tester.runAsync(() => _playSavedProject(root));
      expect(journey?.arrival, 'clairiere');
      expect(journey?.arrivalPos, const GridPos(x: 0, y: 9));
      expect(journey?.returned, 'jardin');
      expect(gardenFile.readAsBytesSync(), orderedEquals(gardenBytes));
      expect(clearingFile.readAsBytesSync(), orderedEquals(clearingBytes));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await session.dispose();
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}

MapData _readMap(File file) => MapData.fromJson(
  jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
);

Offset _cell(WidgetTester tester, int x, int y) {
  final rect = tester.getRect(find.byKey(const ValueKey('map-canvas')));
  return rect.topLeft +
      Offset((x + .5) * rect.width / 24, (y + .5) * rect.height / 16);
}

Future<void> _freeEdge(WidgetTester tester, int x, int y) async {
  await tester.tap(find.text('Collisions').first);
  await tester.pump();
  await tester.tap(find.text('Libérer les cases'));
  await tester.pump();
  await tester.tapAt(_cell(tester, x, y));
  await _until(tester, () => find.text('Non enregistré').evaluate().isNotEmpty);
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('Enregistrer')));
  await _until(tester, () => find.text('Enregistré').evaluate().isNotEmpty);
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (ready()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw TestFailure('Studio did not reach the expected state');
}

Future<({String? arrival, GridPos? arrivalPos, String? returned})>
_playSavedProject(String root) async {
  final projectFile = p.join(root, 'project.json');
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile,
    mapId: 'jardin',
  );
  final game = _LoadedGame(
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

class _LoadedGame extends PlayableMapGame {
  _LoadedGame({
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
