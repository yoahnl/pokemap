import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/presentation/flame/dialogue_overlay_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final speed in PlaytestSpeed.values) {
    testWidgets(
      '×${speed.multiplier} preserves collision, waits, choices and save reload',
      (tester) async {
        await tester.runAsync(() async {
          final game = await _mount(tester);
          expect(game.testSpeed.value, PlaytestSpeed.normal);
          game.setTestSpeed(speed);
          final probe = _TimeProbe();
          game.world.add(probe);
          await game.ready();
          for (var i = 0; i < 60; i++) {
            game.update(1 / 60);
          }
          expect(probe.elapsed, closeTo(speed.multiplier, 1e-8));
          expect(probe.largestStep, lessThanOrEqualTo(1 / 60));

          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.right),
          );
          for (var i = 0; i < 120; i++) {
            game.update(1 / 60);
            await Future<void>.delayed(Duration.zero);
          }
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.right),
          );
          expect(game.debugPlayerGridPosition.x, lessThan(3));
          expect(game.debugPlayerGridPosition.x, greaterThan(1));

          var waited = false;
          final wait = game
              .debugExecuteSceneInteractiveCommand(
                SceneInteractiveCommand.wait(durationMs: 1000),
              )
              .then((result) {
                expect(result, 'completed');
                waited = true;
              });
          await Future<void>.delayed(Duration.zero);
          for (var i = 0; i < (30 / speed.multiplier).floor(); i++) {
            game.update(1 / 60);
            await Future<void>.delayed(Duration.zero);
          }
          expect(waited, isFalse);
          await game.advanceTestSimulation(const Duration(seconds: 1));
          await wait;
          expect(waited, isTrue);
          var chainedWaitsCompleted = false;
          final chain = () async {
            await game.debugExecuteSceneInteractiveCommand(
              SceneInteractiveCommand.wait(durationMs: 100),
            );
            await game.debugExecuteSceneInteractiveCommand(
              SceneInteractiveCommand.wait(durationMs: 100),
            );
            chainedWaitsCompleted = true;
          }();
          await Future<void>.delayed(Duration.zero);
          game.update(.25 / speed.multiplier);
          expect(
            chainedWaitsCompleted,
            isTrue,
            reason: 'Event continuations must resume between simulation steps.',
          );
          await chain;

          String? outcome;
          final overlay = DialogueOverlayComponent(
            session: DialogueSession.start([
              YarnNode(
                title: 'Start',
                steps: [
                  YarnStepLine('Choisis ta destination.'),
                  YarnStepChoiceBlock([
                    YarnChoice(
                      text: 'Rester',
                      outcomeId: 'stay',
                      steps: const [],
                    ),
                    YarnChoice(
                      text: 'Partir',
                      outcomeId: 'leave',
                      steps: const [],
                    ),
                  ]),
                ],
              ),
            ], 'Start')!,
            onFinished: (value) => outcome = value,
            viewportSize: Vector2(320, 240),
          );
          game.camera.viewport.add(overlay);
          await game.ready();
          await game.advanceTestSimulation(const Duration(seconds: 2));
          expect(overlay.isCurrentLineFullyRevealed, isTrue);
          expect(overlay.isShowingChoices, isFalse);
          expect(outcome, isNull);
          overlay.advance();
          await game.advanceTestSimulation(const Duration(seconds: 2));
          expect(overlay.isShowingChoices, isTrue);
          expect(outcome, isNull);
          overlay.confirmChoice();
          await game.ready();
          expect(outcome, 'stay');

          expect(await game.saveGame(), isTrue);
          final saved = game.gameStateSnapshot.toJson();
          expect(jsonEncode(saved), isNot(contains('testSpeed')));
          expect(await game.loadGame(), isTrue);
          final restored = game.gameStateSnapshot.toJson();
          for (final key in [
            'currentMapId',
            'playerPosition',
            'playerPixelPosition',
            'playerFacing',
            'party',
            'bag',
            'money',
            'storyFlags',
            'narrativeFactRuntimeState',
            'mapInstanceWorldState',
          ]) {
            expect(restored[key], saved[key], reason: key);
          }
          expect(game.testSpeed.value, speed);
        });
      },
    );
  }
}

final class _TimeProbe extends Component {
  double elapsed = 0;
  double largestStep = 0;

  @override
  void update(double dt) {
    elapsed += dt;
    largestStep = max(largestStep, dt);
  }
}

Future<PlayableMapGame> _mount(WidgetTester tester) async {
  final dir = await Directory.systemTemp.createTemp('avelune-test-speed-');
  addTearDown(() => dir.delete(recursive: true));
  final map = MapData(
    id: 'room',
    name: 'Room',
    size: GridSize(width: 6, height: 4),
    layers: [
      CollisionLayer(
        id: 'walls',
        name: 'Walls',
        collisions: [for (var i = 0; i < 24; i++) i == 9],
      ),
    ],
  );
  const manifest = ProjectManifest(
    name: 'Speed fixture',
    maps: [
      ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'room.json'),
    ],
    tilesets: [],
  );
  await File('${dir.path}/project.json')
      .writeAsString(jsonEncode(manifest.toJson()));
  await File('${dir.path}/room.json').writeAsString(jsonEncode(map.toJson()));
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: '${dir.path}/project.json',
    mapId: 'room',
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: '${dir.path}/project.json',
    initialGameState: const GameState(
      saveId: 'speed',
      currentMapId: 'room',
      playerPosition: GridPos(x: 1, y: 1),
    ),
    saveRepository: _SerializedSaves(),
    encounterRandom: Random(42),
    npcRouteRandom: Random(42),
  );
  game.onGameResize(Vector2(640, 480));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget<PlayableMapGame>(game: game),
    ),
  );
  await game.toBeLoaded();
  await game.ready();
  game.pauseEngine();
  for (var i = 0; i < 30; i++) {
    game.update(.025);
    await Future<void>.delayed(Duration.zero);
  }
  addTearDown(() async {
    game.onRemove();
    await tester.pumpWidget(const SizedBox.shrink());
  });
  return game;
}

final class _SerializedSaves implements GameSaveRepository {
  String? value;

  @override
  Future<void> save(GameState state) async =>
      value = jsonEncode(strictGameStateSaveJson(state));
  @override
  Future<GameState?> load() async => value == null
      ? null
      : gameStateFromStrictSaveJson(jsonDecode(value!) as Map<String, dynamic>);
  @override
  Future<bool> exists() async => value != null;
  @override
  Future<void> delete() async => value = null;
}
