import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_component.dart';
import 'package:path/path.dart' as p;

import 'source_converted_gym_reward_journey_test.dart'
    show installConvertedQaHeadlessAudio;
import 'support/offline_recipe_package_fixture.dart';

class _TestGame extends PlayableMapGame {
  _TestGame({
    required super.bundle,
    required super.projectFilePath,
    required super.initialGameState,
  });

  @override
  bool get isLoaded => true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (var i = 0; i < 240 && debugIsMapActivationDispatchInFlight; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(debugIsMapActivationDispatchInFlight, isFalse);
  }
}

Future<void> _pumpUntil(_TestGame game, bool Function() done) async {
  for (var i = 0; i < 2000; i++) {
    if (done()) return;
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the battle animation');
}

Future<int> _effectWidth(
  BattleSplStaticComponent effect,
  ui.Rect target,
  int width,
  int height,
) async {
  final recorder = ui.PictureRecorder();
  effect.render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final region = target.inflate(target.width / 2);
    final left = region.left.floor().clamp(0, width);
    final right = region.right.ceil().clamp(0, width);
    final top = region.top.floor().clamp(0, height);
    final bottom = region.bottom.ceil().clamp(0, height);
    var minX = width;
    var maxX = -1;
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        if (bytes.getUint8((y * width + x) * 4 + 3) == 0) continue;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
      }
    }
    return maxX < minX ? 0 : maxX - minX + 1;
  } finally {
    image.dispose();
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final viewport in [
    const (390, 844),
    const (844, 390),
    const (320, 568),
  ]) {
    test(
      'grouped particles remain visible at ${viewport.$1}x${viewport.$2}',
      () async {
        installConvertedQaHeadlessAudio(completePlayback: true);
        await HttpOverrides.runZoned(
          () async {
            final fetched = await groupedSplRecipeFixture();
            final fixture = await offlineRecipePackageFixture(
              spatial: false,
              fetchedRecipe: fetched,
            );
            final game = _TestGame(
              bundle: fixture.bundle,
              projectFilePath: p.join(
                fixture.bundle.projectRootDirectory,
                'project.json',
              ),
              initialGameState: fixture.state,
            );
            addTearDown(() async {
              await game.debugWaitForBattlePrewarm();
              game.onRemove();
            });
            game.onGameResize(
              Vector2(viewport.$1.toDouble(), viewport.$2.toDouble()),
            );
            await game.onLoad();
            await game.debugOpenBattleForTest(
              const WildBattleStartRequest(
                requestId: 'grouped-particle-visibility',
                createdAtEpochMs: 1,
                returnContext: OverworldReturnContext(
                  mapId: 'map',
                  playerPos: GridPos(x: 1, y: 1),
                  playerFacing: Direction.east,
                ),
                mapId: 'map',
                encounterSourceId: 'grass',
                encounterSourceKind: EncounterSourceKind.gameplayZone,
                tableId: 'wild',
                encounterKind: EncounterKind.walk,
                speciesId: 'clockbird',
                level: 2,
                minLevel: 2,
                maxLevel: 2,
                weight: 1,
                playerPos: GridPos(x: 1, y: 1),
              ),
            );
            await _pumpUntil(
              game,
              () =>
                  game
                      .battleCommandOverlayListenable
                      .value
                      ?.interactionsEnabled ==
                  true,
            );
            bool choose(int index) {
              final snapshot = game.battleCommandOverlayListenable.value!;
              return game.dispatchBattlePresentationCommand(
                BattleSelectEntryCommand(
                  snapshotRevision: snapshot.revision,
                  expectedMode: snapshot.mode,
                  entryIndex: index,
                ),
              );
            }

            expect(choose(0), isTrue);
            expect(choose(0), isTrue);
            final overlay = game.debugBattleOverlayComponent!;
            await _pumpUntil(
              game,
              () => overlay.children.whereType<BattleSplStaticComponent>().any(
                (effect) => effect.playback.activeParticles > 0,
              ),
            );
            final target = overlay.currentSceneLayout.enemySpriteRect;
            var visibleWidth = 0;
            for (var tick = 0; tick < 12; tick++) {
              for (final effect
                  in overlay.children.whereType<BattleSplStaticComponent>()) {
                if (effect.playback.activeParticles == 0) continue;
                final width = await _effectWidth(
                  effect,
                  target,
                  viewport.$1,
                  viewport.$2,
                );
                if (width > visibleWidth) visibleWidth = width;
              }
              game.update(.016);
              await Future<void>.delayed(Duration.zero);
            }
            expect(
              visibleWidth,
              greaterThan(target.width * .35),
              reason:
                  'The attack should be visible relative to the target Pokémon',
            );
            expect(
              visibleWidth,
              lessThan(target.width * 1.6),
              reason: 'The attack should remain bounded around the target',
            );
          },
          createHttpClient: (_) =>
              throw StateError('Network disabled for this test'),
        );
      },
    );
  }
}
