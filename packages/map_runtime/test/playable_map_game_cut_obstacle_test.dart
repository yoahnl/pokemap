import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Strength activation and repeated directional pushes publish one movement each and survive fresh restore',
    (tester) async {
      await tester.runAsync(() async {
        final receipts = <RuntimeCommittedMovement>[];
        final fixture = await _mount(
          tester,
          obstacleKind: FieldObstacleKind.strengthBoulder,
          movementReceipts: receipts,
        );
        final game = fixture.game;
        final request =
            game.overworldInteractionSnapshot.primaryAction?.request;
        expect(request, isNotNull);
        expect(game.dispatchOverworldInteraction(request!), isTrue);
        for (var i = 0; i < 8; i++) {
          game.update(.016);
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        await _press(game, RuntimeInputControl.primary);
        await _press(game, RuntimeInputControl.primary);
        await _tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
        final instance = game.gameStateSnapshot.mapInstanceWorldState
            .instanceRef('route')!;
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.isStrengthActive(
            instance,
          ),
          isTrue,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        await _press(game, RuntimeInputControl.right);
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        expect(game.debugMapEntityPosition('tree'), const GridPos(x: 3, y: 1));
        expect(game.debugRenderedPlayerFootCell, const GridPos(x: 2, y: 1));
        expect(receipts, hasLength(1));
        await _press(game, RuntimeInputControl.right);
        expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 1));
        expect(game.debugMapEntityPosition('tree'), const GridPos(x: 4, y: 1));
        expect(game.debugRenderedPlayerFootCell, const GridPos(x: 3, y: 1));
        expect(receipts, hasLength(2));
        await _press(game, RuntimeInputControl.right);
        expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 1));
        expect(receipts, hasLength(2));
        expect(await game.saveGame(), isTrue);
        final saved = GameState.fromJson(game.gameStateSnapshot.toJson());
        final restored = await _mount(
          tester,
          obstacleKind: FieldObstacleKind.strengthBoulder,
          restoredState: saved,
        );
        expect(
          restored.game.debugPlayerGridPosition,
          const GridPos(x: 3, y: 1),
        );
        expect(
          restored.game.debugMapEntityPosition('tree'),
          const GridPos(x: 4, y: 1),
        );
        expect(
          restored.game.gameStateSnapshot.mapInstanceWorldState
              .isStrengthActive(instance),
          isTrue,
        );
        final authored = await game.debugLoadRuntimeMapBundleCachedForTest(
          'route',
        );
        expect(
          authored.map.entities
              .singleWhere((entity) => entity.id == 'tree')
              .pos,
          const GridPos(x: 2, y: 1),
        );
      });
    },
  );
  for (final answer in ['yes', 'no', 'cancel', 'stale']) {
    testWidgets('native Rock Smash $answer uses the Player dialogue', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final fixture = await _mount(
          tester,
          obstacleKind: FieldObstacleKind.rockSmashRock,
        );
        final game = fixture.game;
        final request =
            game.overworldInteractionSnapshot.primaryAction?.request;
        expect(request, isNotNull);
        expect(game.dispatchOverworldInteraction(request!), isTrue);
        for (var i = 0; i < 8; i++) {
          game.update(.016);
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        await _press(game, RuntimeInputControl.primary);
        if (answer == 'no') {
          await _press(game, RuntimeInputControl.down);
        }
        if (answer == 'stale') {
          game.setPlayerMovementMode(MovementMode.surf);
        }
        await _press(
          game,
          answer == 'cancel'
              ? RuntimeInputControl.secondary
              : RuntimeInputControl.primary,
        );
        await _tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
        final instance = game.gameStateSnapshot.mapInstanceWorldState
            .instanceRef('route')!;
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.isFieldObstacleCleared(
            instance,
            'tree',
          ),
          answer == 'yes',
        );
        expect(
          game.debugMapEntityPosition('tree'),
          answer == 'yes' ? isNull : const GridPos(x: 2, y: 1),
        );
      });
    });
  }

  testWidgets(
    'Cut then Rock Smash preserve the authored set and remove both collisions',
    (tester) async {
      await tester.runAsync(() async {
        final game = (await _mount(tester, mixedObstacles: true)).game;
        await _cut(game);
        await _press(game, RuntimeInputControl.right);
        await _confirmObstacle(game);
        expect(game.debugMapEntityPosition('tree'), isNull);
        expect(game.debugMapEntityPosition('smash'), isNull);
        await _press(game, RuntimeInputControl.right);
        expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 1));
        final state = game.gameStateSnapshot;
        final fresh = (await _mount(
          tester,
          mixedObstacles: true,
          restoredState: GameState.fromJson(state.toJson()),
        )).game;
        expect(fresh.debugMapEntityPosition('tree'), isNull);
        expect(fresh.debugMapEntityPosition('smash'), isNull);
        final authored = await fresh.debugLoadRuntimeMapBundleCachedForTest(
          'route',
        );
        expect(
          authored.map.entities.where((entity) => entity.fieldObstacle != null),
          hasLength(2),
        );
      });
    },
  );
  for (final foreground in [false, true]) {
    testWidgets(
      'mounted Strength keeps player and actual painted boulder aligned in pass $foreground',
      (tester) async {
        await tester.runAsync(() async {
          final game = (await _mount(
            tester,
            obstacleKind: FieldObstacleKind.strengthBoulder,
            renderInForeground: foreground,
          )).game;
          await _confirmObstacle(game);
          final layers = game.world.children
              .whereType<MapLayersComponent>()
              .singleWhere(
                (component) =>
                    component.bundle.map.id == 'route' &&
                    component.renderPass ==
                        (foreground
                            ? MapLayerRenderPass.foreground
                            : MapLayerRenderPass.background),
              );
          final before = await _renderLayers(layers);
          expect(await pixelAt(before, 80, 48), rgba(34, 170, 68, 255));
          expect(await pixelAt(before, 112, 48), rgba(0, 0, 0, 0));
          before.dispose();
          final start = game.debugPlayerWorldTopLeft;
          game.handleRuntimeInputEvent(
            RuntimeInputEvent.press(RuntimeInputControl.right),
          );
          game.update(.016);
          game.handleRuntimeInputEvent(
            RuntimeInputEvent.release(RuntimeInputControl.right),
          );
          expect(
            game.debugMapEntityPosition('tree'),
            const GridPos(x: 3, y: 1),
          );
          expect(game.debugPlayerWorldTopLeft, start);
          game.update(.125);
          expect(game.debugPlayerWorldTopLeft.x, closeTo(start.x + 16, .0001));
          final middle = await _renderLayers(layers);
          expect(await pixelAt(middle, 72, 48), rgba(0, 0, 0, 0));
          expect(await pixelAt(middle, 96, 48), rgba(34, 170, 68, 255));
          middle.dispose();
          game.update(.125);
          expect(game.debugPlayerWorldTopLeft.x, closeTo(start.x + 32, .0001));
          final after = await _renderLayers(layers);
          expect(await pixelAt(after, 80, 48), rgba(0, 0, 0, 0));
          expect(await pixelAt(after, 112, 48), rgba(34, 170, 68, 255));
          after.dispose();
          expect(
            game.debugRenderedPlayerFootCell,
            game.debugPlayerGridPosition,
          );
        });
      },
    );
  }
  testWidgets(
    'Strength map reset restores position and activation while same-map warp and save retain them',
    (tester) async {
      await tester.runAsync(() async {
        final game = (await _mount(
          tester,
          obstacleKind: FieldObstacleKind.strengthBoulder,
        )).game;
        await _confirmObstacle(game);
        await _press(game, RuntimeInputControl.right);
        final instance = game.gameStateSnapshot.mapInstanceWorldState
            .instanceRef('route')!;
        expect(await _warp(game, 'route', 'safe'), 'completed');
        expect(game.debugMapEntityPosition('tree'), const GridPos(x: 3, y: 1));
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.isStrengthActive(
            instance,
          ),
          isTrue,
        );
        expect(await game.saveGame(), isTrue);
        expect(await _warp(game, 'neighbor', 'safe'), 'completed');
        expect(await _warp(game, 'route', 'safe'), 'completed');
        final reset = game.gameStateSnapshot.mapInstanceWorldState.instanceRef(
          'route',
        )!;
        expect(reset, isNot(instance));
        expect(game.debugMapEntityPosition('tree'), const GridPos(x: 2, y: 1));
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.isStrengthActive(reset),
          isFalse,
        );
        expect(await game.loadGame(), isTrue);
        expect(game.debugMapEntityPosition('tree'), const GridPos(x: 3, y: 1));
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('route'),
          instance,
        );
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.isStrengthActive(
            instance,
          ),
          isTrue,
        );
      });
    },
  );

  for (final corruption in [
    'missingEntity',
    'wrongKind',
    'overlap',
    'bounds',
    'retainedMap',
    'retainedEntity',
    'npcMissing',
    'npcType',
    'npcBounds',
  ]) {
    testWidgets(
      'save loading refuses $corruption without changing the live game or save bytes',
      (tester) async {
        await tester.runAsync(() async {
          final repository = _MemorySave();
          final game = (await _mount(
            tester,
            obstacleKind: FieldObstacleKind.strengthBoulder,
            saveRepository: repository,
            retainInstances: corruption.startsWith('retained'),
            includeWalker: corruption.startsWith('npc'),
          )).game;
          final before = game.gameStateSnapshot;
          final current = before.mapInstanceWorldState.instancesByMapId;
          final scope = before.mapInstanceWorldState.instanceRef('route')!;
          var instances = before.mapInstanceWorldState.activateStrength(scope);
          if (corruption == 'missingEntity') {
            instances = instances.moveFieldObstacle(
              scope,
              'ghost',
              const GridPos(x: 3, y: 1),
            );
          }
          if (corruption.startsWith('npc')) {
            instances = instances.setNpcPoses(scope, _npcPoses({
              corruption == 'npcMissing'
                  ? 'ghost'
                  : corruption == 'npcType'
                  ? 'tree'
                  : 'walker': GridPos(
                x: corruption == 'npcBounds' ? 5 : 4,
                y: 2,
              ),
            }));
          }
          if (corruption == 'wrongKind') {
            instances = instances.clearFieldObstacle(scope, 'tree');
          }
          if (corruption == 'overlap') {
            instances = instances.moveFieldObstacle(
              scope,
              'tree',
              const GridPos(x: 1, y: 1),
            );
          }
          if (corruption == 'bounds') {
            instances = instances.moveFieldObstacle(
              scope,
              'tree',
              const GridPos(x: 5, y: 1),
            );
          }
          if (corruption == 'retainedMap' || corruption == 'retainedEntity') {
            instances = MapInstanceWorldState(
              instancesByMapId: {
                ...current,
                corruption == 'retainedMap'
                    ? 'unknown-map'
                    : 'neighbor': MapInstanceRuntimeState(
                  instanceId: 'invalid-retained',
                  fieldObstaclePositions: const {'ghost': GridPos(x: 3, y: 1)},
                  strengthActive: true,
                ),
              },
            );
          }
          repository.data = before
              .copyWith(mapInstanceWorldState: instances)
              .toJson();
          final bytes = jsonEncode(repository.data);
          expect(await game.loadGame(), isFalse);
          expect(game.gameStateSnapshot, before);
          expect(jsonEncode(repository.data), bytes);
          expect(
            game.debugMapEntityPosition('tree'),
            const GridPos(x: 2, y: 1),
          );
        });
      },
    );
  }

  for (final wall in [false, true]) {
    testWidgets(
      'active Strength walks through an absent boulder without pushing it wallBehind=$wall',
      (tester) async {
        await tester.runAsync(() async {
          final game = (await _mount(
            tester,
            obstacleKind: FieldObstacleKind.strengthBoulder,
            hiddenStrengthObstacle: true,
            wallBehindHiddenObstacle: wall,
          )).game;
          await _confirmObstacle(game);
          final scope = game.gameStateSnapshot.mapInstanceWorldState
              .instanceRef('route')!;
          expect(
            game.gameStateSnapshot.mapInstanceWorldState.isStrengthActive(
              scope,
            ),
            isTrue,
          );
          final layer = game.world.children
              .whereType<MapLayersComponent>()
              .singleWhere(
                (component) =>
                    component.bundle.map.id == 'route' &&
                    component.renderPass == MapLayerRenderPass.background,
              );
          final before = await _renderLayers(layer);
          expect(await pixelAt(before, 48, 80), rgba(0, 0, 0, 0));
          before.dispose();
          await _press(game, RuntimeInputControl.down);
          expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 2));
          expect(
            game.debugMapEntityPosition('hidden-rock'),
            const GridPos(x: 1, y: 2),
          );
          expect(
            game.gameStateSnapshot.mapInstanceWorldState.fieldObstaclePosition(
              scope,
              'hidden-rock',
            ),
            isNull,
          );
        });
      },
    );
  }

  testWidgets(
    'NPC leaves a boulder destination and both positions survive save and cold reload then reset',
    (tester) async {
      await tester.runAsync(() async {
        final game = (await _mount(
          tester,
          includeWalker: true,
          obstacleKind: FieldObstacleKind.strengthBoulder,
        )).game;
        await _moveWalker(game);
        expect(
          game.debugMapEntityPosition('walker'),
          const GridPos(x: 4, y: 2),
        );
        await _confirmObstacle(game);
        await _press(game, RuntimeInputControl.right);
        expect(game.debugMapEntityPosition('tree'), const GridPos(x: 3, y: 1));
        expect(
          game.debugMapEntityPosition('walker'),
          const GridPos(x: 4, y: 2),
        );
        final savedWalkerPosition = game.world.children
            .whereType<OverworldActorComponent>()
            .singleWhere((actor) => actor.character.id == 'walker-visual')
            .position
            .clone();
        expect(await game.saveGame(), isTrue);
        final saved = GameState.fromJson(game.gameStateSnapshot.toJson());
        expect(await game.loadGame(), isTrue);
        final fresh = (await _mount(
          tester,
          includeWalker: true,
          obstacleKind: FieldObstacleKind.strengthBoulder,
          restoredState: saved,
        )).game;
        expect(fresh.debugMapEntityPosition('tree'), const GridPos(x: 3, y: 1));
        expect(
          fresh.debugMapEntityPosition('walker'),
          const GridPos(x: 4, y: 2),
        );
        final actor = fresh.world.children
            .whereType<OverworldActorComponent>()
            .singleWhere((actor) => actor.character.id == 'walker-visual');
        expect(actor.gridPos, const GridPos(x: 4, y: 2));
        expect(actor.position, savedWalkerPosition);
        expect(await _warp(fresh, 'neighbor', 'safe'), 'completed');
        expect(await _warp(fresh, 'route', 'safe'), 'completed');
        expect(fresh.debugMapEntityPosition('tree'), const GridPos(x: 2, y: 1));
        expect(
          fresh.debugMapEntityPosition('walker'),
          const GridPos(x: 3, y: 1),
        );
      });
    },
  );

  for (final retain in [false, true]) {
    testWidgets(
      'connection return restores the NPC and boulder poses for the selected instance retain=$retain',
      (tester) async {
        await tester.runAsync(() async {
          final game = (await _mount(
            tester,
            includeWalker: true,
            obstacleKind: FieldObstacleKind.strengthBoulder,
            connections: true,
            retainInstances: retain,
          )).game;
          await _moveWalker(game);
          await _confirmObstacle(game);
          await _press(game, RuntimeInputControl.right);
          expect(
            game.debugMapEntityPosition('walker'),
            const GridPos(x: 4, y: 2),
          );
          expect(
            game.debugMapEntityPosition('tree'),
            const GridPos(x: 3, y: 1),
          );
          final before = game.gameStateSnapshot.mapInstanceWorldState
              .instanceRef('route');
          expect(await _warp(game, 'route', 'edge'), 'completed');
          await _press(game, RuntimeInputControl.right);
          await _tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
          expect(game.gameStateSnapshot.currentMapId, 'neighbor');
          await _press(game, RuntimeInputControl.left);
          await _tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
          expect(game.gameStateSnapshot.currentMapId, 'route');
          expect(
            game.debugMapEntityPosition('walker'),
            retain ? const GridPos(x: 4, y: 2) : const GridPos(x: 3, y: 1),
          );
          final actor = game.world.children
              .whereType<OverworldActorComponent>()
              .singleWhere((actor) => actor.character.id == 'walker-visual');
          expect(actor.gridPos, game.debugMapEntityPosition('walker'));
          expect(
            game.debugMapEntityPosition('tree'),
            retain ? const GridPos(x: 3, y: 1) : const GridPos(x: 2, y: 1),
          );
          expect(
            game.gameStateSnapshot.mapInstanceWorldState.instanceRef('route'),
            retain ? before : isNot(before),
          );
        });
      },
    );
  }

  testWidgets(
    'a fresh Cut tree allocates an instance and offers an interaction',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = await _mount(tester);
        final game = fixture.game;
        expect(game.debugMapEntityPosition('tree'), const GridPos(x: 2, y: 1));
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('route'),
          isNotNull,
        );
        expect(game.overworldInteractionSnapshot.primaryAction, isNotNull);
      });
    },
  );

  testWidgets(
    'save restore projects a cleared tree before collision validation',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = await _mount(tester, restoredCleared: true);
        final game = fixture.game;
        expect(game.debugMapEntityPosition('tree'), isNull);
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        expect(fixture.sfx.cuts, 0);
      });
    },
  );

  testWidgets('V2 without a declared owner admits intrinsic Cut', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final fixture = await _mount(tester, v2Only: true);
      await _cut(fixture.game);
      expect(fixture.sfx.cuts, 1);
    });
  });

  testWidgets('a disabled declared V2 owner still prevents intrinsic Cut', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final fixture = await _mount(tester, v2Only: true, declaredOwner: true);
      expect(fixture.game.overworldInteractionSnapshot.primaryAction, isNull);
      await _press(fixture.game, RuntimeInputControl.primary);
      expect(
        fixture.game.debugMapEntityPosition('tree'),
        const GridPos(x: 2, y: 1),
      );
      expect(fixture.sfx.cuts, 0);
    });
  });

  for (final answer in ['yes', 'no', 'cancel', 'stale']) {
    testWidgets('native Cut $answer resolves through the Player dialogue', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final fixture = await _mount(tester);
        final game = fixture.game;
        final request =
            game.overworldInteractionSnapshot.primaryAction?.request;
        expect(request, isNotNull);
        expect(game.dispatchOverworldInteraction(request!), isTrue);
        expect(
          game.inputAuthoritySnapshot.context,
          RuntimeInputContext.dialogue,
        );
        final position = game.debugPlayerGridPosition;
        await _press(game, RuntimeInputControl.right);
        expect(game.debugPlayerGridPosition, position);
        final revision = game.debugGameStateRevision;
        game.gameStateSnapshot;
        game.saveLoadInfo;
        expect(game.debugGameStateRevision, revision);
        await _press(game, RuntimeInputControl.primary);
        if (answer == 'no') {
          await _press(game, RuntimeInputControl.down);
        }
        if (answer == 'stale') {
          game.setPlayerMovementMode(MovementMode.surf);
        }
        await _press(
          game,
          answer == 'cancel'
              ? RuntimeInputControl.secondary
              : RuntimeInputControl.primary,
        );
        await _tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
        final success = answer == 'yes';
        final state = game.gameStateSnapshot;
        final instance = state.mapInstanceWorldState.instanceRef('route')!;
        expect(
          state.mapInstanceWorldState.isFieldObstacleCleared(instance, 'tree'),
          success,
        );
        expect(
          game.debugMapEntityPosition('tree'),
          success ? isNull : const GridPos(x: 2, y: 1),
        );
        expect(fixture.sfx.cuts, success ? 1 : 0);
        final authored = await game.debugLoadRuntimeMapBundleCachedForTest(
          'route',
        );
        expect(
          authored.map.entities.any((entity) => entity.id == 'tree'),
          isTrue,
        );
        if (success) {
          await _press(game, RuntimeInputControl.right);
          expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
          final reloaded = await _mount(
            tester,
            restoredState: game.gameStateSnapshot,
          );
          expect(reloaded.game.debugMapEntityPosition('tree'), isNull);
          expect(
            reloaded.game.debugPlayerGridPosition,
            const GridPos(x: 2, y: 1),
          );
          expect(reloaded.sfx.cuts, 0);
        }
      });
    });
  }

  testWidgets(
    'same-map warp preserves Cut and a different-map setup restores it',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = await _mount(tester);
        final game = fixture.game;
        await _cut(game);
        final cutInstance = game.gameStateSnapshot.mapInstanceWorldState
            .instanceRef('route');
        expect(await _warp(game, 'route', 'tree-cell'), 'completed');
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        expect(game.debugMapEntityPosition('tree'), isNull);
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('route'),
          cutInstance,
        );
        expect(await game.saveGame(), isTrue);
        expect(await _warp(game, 'neighbor', 'safe'), 'completed');
        expect(await _warp(game, 'route', 'tree-cell'), 'blocked');
        expect(game.gameStateSnapshot.currentMapId, 'neighbor');
        expect(await _warp(game, 'route', 'safe'), 'completed');
        expect(game.debugMapEntityPosition('tree'), const GridPos(x: 2, y: 1));
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('route'),
          isNot(cutInstance),
        );
        expect(await game.loadGame(), isTrue);
        expect(game.debugMapEntityPosition('tree'), isNull);
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('route'),
          cutInstance,
        );
        expect(fixture.sfx.cuts, 1);
      });
    },
  );

  for (final retain in [false, true]) {
    testWidgets(
      'connection return uses the exact Cut instance retain=$retain',
      (tester) async {
        await tester.runAsync(() async {
          final fixture = await _mount(
            tester,
            startNeighbor: true,
            connections: true,
            retainInstances: retain,
          );
          final game = fixture.game;
          await _cut(game);
          final instance = game.gameStateSnapshot.mapInstanceWorldState
              .instanceRef('neighbor');
          expect(await _warp(game, 'neighbor', 'edge'), 'completed');
          await _press(game, RuntimeInputControl.left);
          await _tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
          expect(game.gameStateSnapshot.currentMapId, 'route');
          expect(game.debugPlayerGridPosition, const GridPos(x: 4, y: 1));
          await _press(game, RuntimeInputControl.right);
          await _tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
          if (retain) {
            expect(game.gameStateSnapshot.currentMapId, 'neighbor');
            expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 1));
            expect(game.debugMapEntityPosition('tree'), isNull);
            expect(
              game.gameStateSnapshot.mapInstanceWorldState.instanceRef(
                'neighbor',
              ),
              instance,
            );
          } else {
            expect(game.gameStateSnapshot.currentMapId, 'route');
            expect(
              game.gameStateSnapshot.mapInstanceWorldState.instanceRef(
                'neighbor',
              ),
              isNull,
            );
          }
          expect(fixture.sfx.cuts, 1);
        });
      },
    );
  }
}

Future<({PlayableMapGame game, _Sfx sfx})> _mount(
  WidgetTester tester, {
  FieldObstacleKind obstacleKind = FieldObstacleKind.cutTree,
  List<RuntimeCommittedMovement>? movementReceipts,
  GameSaveRepository? saveRepository,
  bool includeWalker = false,
  bool hiddenStrengthObstacle = false,
  bool wallBehindHiddenObstacle = false,
  bool renderInForeground = false,
  bool mixedObstacles = false,
  bool restoredCleared = false,
  GameState? restoredState,
  bool startNeighbor = false,
  bool connections = false,
  bool retainInstances = false,
  bool v2Only = false,
  bool declaredOwner = false,
}) async {
  final root = await Directory.systemTemp.createTemp('native-cut-player-');
  addTearDown(() => root.delete(recursive: true));
  final sfx = _Sfx();
  var state =
      restoredState ??
      GameState(
        saveId: 'cut-player',
        currentMapId: 'route',
        playerPosition: GridPos(x: restoredCleared ? 2 : 1, y: 1),
        playerFacing: EntityFacing.east,
        party: const PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'scyther',
              natureId: 'hardy',
              abilityId: 'swarm',
              level: 20,
              currentHp: 30,
              knownMoveIds: ['cut', 'strength', 'rock_smash'],
            ),
          ],
        ),
        progression: const PlayerProgression(
          unlockedFieldAbilities: [
            FieldAbility.cut,
            FieldAbility.strength,
            FieldAbility.rockSmash,
          ],
        ),
        mapInstanceWorldState: restoredCleared
            ? MapInstanceWorldState(
                instancesByMapId: {
                  'route': MapInstanceRuntimeState(
                    instanceId: 'restored-route',
                    clearedFieldObstacleIds: {'tree'},
                  ),
                },
              )
            : MapInstanceWorldState(instancesByMapId: {}),
      );
  if (startNeighbor) {
    state = state.copyWith(
      currentMapId: 'neighbor',
      playerFacing: EntityFacing.west,
    );
  }
  if (hiddenStrengthObstacle) {
    state = state.copyWith(
      storyFlags: const StoryFlags(activeFlags: {'hide-rock'}),
    );
  }
  final manifest = ProjectManifest(
    name: 'Cut Player',
    characters: includeWalker
        ? const [
            ProjectCharacterEntry(
              id: 'walker-visual',
              name: 'Walker',
              tilesetId: 'props',
              frameHeight: 1,
            ),
          ]
        : const [],
    facts: hiddenStrengthObstacle
        ? [NarrativeFactDefinition(id: 'hide-rock', label: 'Hide rock')]
        : const [],
    worldRules: hiddenStrengthObstacle
        ? [
            WorldRuleDefinition(
              id: 'hide-rock-rule',
              label: 'Hide rock',
              source: const WorldRuleSource(
                kind: WorldRuleSourceKind.fact,
                sourceId: 'hide-rock',
                predicate: WorldRuleSourcePredicate.isTrue,
              ),
              target: const WorldRuleTarget(
                kind: WorldRuleTargetKind.mapEntity,
                mapId: 'route',
                entityId: 'hidden-rock',
              ),
              effect: const WorldRuleEffect(
                kind: WorldRuleEffectKind.entityHidden,
              ),
            ),
          ]
        : const [],
    eventRegistry: v2Only
        ? NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            legacyClaims: const [],
            records: [
              if (declaredOwner)
                NarrativeEventRecord.configuredStructurallyUnchecked(
                  NarrativeEventDefinition(
                    id: 'evt_019abcde-1400-7000-8000-000000000009',
                    name: 'Tree owner',
                    source: NarrativeEventSourceRef.entityInteract(
                      'route',
                      'tree',
                    ),
                    sceneId: 'owner-scene',
                    conditions: const [],
                    reusePolicy: NarrativeEventReusePolicy.oneShot,
                    priority: 0,
                    order: 0,
                  ),
                  enabled: false,
                ),
            ],
          )
        : null,
    scenes: declaredOwner
        ? [
            SceneAsset(
              id: 'owner-scene',
              name: 'Owner',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: [
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                  SceneNode(id: 'end', kind: SceneNodeKind.end),
                ],
                edges: [
                  SceneEdge(
                    id: 'finish',
                    fromNodeId: 'start',
                    fromPortId: 'completed',
                    toNodeId: 'end',
                    kind: SceneEdgeKind.defaultFlow,
                  ),
                ],
              ),
            ),
          ]
        : const [],
    maps: const [
      ProjectMapEntry(
        id: 'route',
        name: 'Route',
        relativePath: 'maps/route.json',
      ),
      ProjectMapEntry(
        id: 'neighbor',
        name: 'Neighbor',
        relativePath: 'maps/neighbor.json',
      ),
    ],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'props',
        name: 'Props',
        relativePath: 'props.png',
      ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'props', name: 'Props'),
    ],
    elements: const [
      ProjectElementEntry(
        id: 'obstacle',
        name: 'Obstacle',
        tilesetId: 'props',
        categoryId: 'props',
        frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
      ),
    ],
    settings: ProjectSettings(
      mapInstanceRetentionPolicy: retainInstances
          ? MapInstanceRetentionPolicy(
              viewportWidthTiles: 20,
              viewportHeightTiles: 15,
              marginTiles: 2,
            )
          : null,
    ),
  );
  final route = MapData(
    id: 'route',
    name: 'Route',
    size: const GridSize(width: 5, height: 4),
    layers: wallBehindHiddenObstacle
        ? [
            MapLayer.collision(
              id: 'wall',
              name: 'Wall',
              collisions: List.generate(20, (index) => index == 16),
            ),
          ]
        : const [],
    entities: [
      MapEntity(
        id: 'spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'tree',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 2, y: 1),
        blocksMovement: true,
        fieldObstacle: MapEntityFieldObstacleData(
          kind: mixedObstacles ? FieldObstacleKind.cutTree : obstacleKind,
        ),
        editorVisual: MapEntityEditorVisual(
          elementId: 'obstacle',
          renderInForeground: renderInForeground,
        ),
      ),
      if (includeWalker)
        const MapEntity(
          id: 'walker',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 3, y: 1),
          npc: MapEntityNpcData(
            displayName: 'Walker',
            characterId: 'walker-visual',
          ),
        ),
      if (hiddenStrengthObstacle)
        const MapEntity(
          id: 'hidden-rock',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 1, y: 2),
          fieldObstacle: MapEntityFieldObstacleData(
            kind: FieldObstacleKind.strengthBoulder,
          ),
          editorVisual: MapEntityEditorVisual(elementId: 'obstacle'),
        ),
      if (mixedObstacles)
        const MapEntity(
          id: 'smash',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 3, y: 1),
          fieldObstacle: MapEntityFieldObstacleData(
            kind: FieldObstacleKind.rockSmashRock,
          ),
          editorVisual: MapEntityEditorVisual(elementId: 'obstacle'),
        ),
    ],
    warps: [
      _arrival('route', 'tree-cell', 2),
      _arrival('route', 'safe', 1),
      _arrival('route', 'edge', 4),
    ],
    connections: connections
        ? const [
            MapConnection(
              direction: MapConnectionDirection.east,
              targetMapId: 'neighbor',
              offset: 0,
            ),
          ]
        : const [],
  );
  final neighbor = MapData(
    id: 'neighbor',
    name: 'Neighbor',
    size: const GridSize(width: 5, height: 4),
    layers: const [],
    entities: [
      MapEntity(
        id: 'spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.west,
        ),
      ),
      MapEntity(
        id: 'tree',
        kind: MapEntityKind.custom,
        pos: GridPos(x: includeWalker ? 3 : 0, y: 1),
        blocksMovement: true,
        fieldObstacle: MapEntityFieldObstacleData(kind: obstacleKind),
      ),
    ],
    warps: [_arrival('neighbor', 'safe', includeWalker ? 4 : 3), _arrival('neighbor', 'edge', 0)],
    connections: connections
        ? const [
            MapConnection(
              direction: MapConnectionDirection.west,
              targetMapId: 'route',
              offset: 0,
            ),
          ]
        : const [],
  );
  final bundle = RuntimeMapBundle(
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: {'props': '${root.path}/props.png'},
    manifest: manifest,
    map: startNeighbor ? neighbor : route,
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: '${root.path}/project.json',
    saveData: saveDataFromGameState(state),
    initialMapActivationReason: restoredCleared || restoredState != null
        ? MapActivationReason.saveRestore
        : MapActivationReason.initialBoot,
    runtimeTilesetImageLoader:
        (paths, {transparentColorByTilesetId = const {}}) async => {
          'props': await runtimeTilesetImage(const [ui.Color(0xFF22AA44)]),
        },
    overworldSfxPlayer: sfx,
    onCommittedMovement: movementReceipts?.add,
    runtimeMapBundleLoader: ({
      required projectFilePath,
      required mapId,
    }) async => bundle.copyWith(map: mapId == 'route' ? route : neighbor),
    saveRepository: saveRepository ?? _MemorySave(),
    runtimePlayerPokemonProgressionCatalogLoader:
        ({
          required gameState,
          required projectRootDirectory,
          required pokemonConfig,
        }) async => const RuntimePlayerPokemonProgressionCatalogs(
          speciesById: {
            'scyther': PlayerPokemonHydrationSpecies(
              id: 'scyther',
              baseStats: PokemonBaseStats(
                hp: 70,
                attack: 110,
                defense: 80,
                specialAttack: 55,
                specialDefense: 80,
                speed: 105,
              ),
              primaryAbilityId: 'swarm',
              abilityIds: ['swarm'],
              growthRateId: 'medium_fast',
            ),
          },
          maxPpByMoveId: {'cut': 30, 'strength': 15, 'rock_smash': 15},
        ),
  );
  game.onGameResize(Vector2(320, 240));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  await game.loaded;
  await tester.pump();
  addTearDown(game.onRemove);
  await _tickUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
  return (game: game, sfx: sfx);
}

MapWarp _arrival(String mapId, String id, int x) => MapWarp(
  id: id,
  pos: GridPos(x: x, y: 1),
  targetMapId: mapId,
  targetPos: GridPos(x: x, y: 1),
  triggerMode: MapWarpTriggerMode.onBump,
);

Future<void> _cut(PlayableMapGame game) async {
  final request = game.overworldInteractionSnapshot.primaryAction?.request;
  expect(request, isNotNull);
  expect(game.dispatchOverworldInteraction(request!), isTrue);
  for (var i = 0; i < 8; i++) {
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  await _press(game, RuntimeInputControl.primary);
  await _press(game, RuntimeInputControl.primary);
  await _tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
  expect(game.debugMapEntityPosition('tree'), isNull);
}

Future<String> _warp(PlayableMapGame game, String mapId, String warpId) async {
  final result = game.debugExecuteSceneInteractiveCommand(
    SceneInteractiveCommand.warp(
      destinationMapId: mapId,
      warpId: warpId,
      transition: SceneWarpTransition.none,
    ),
  );
  var finished = false;
  result.whenComplete(() => finished = true);
  await _tickUntil(game, () => finished);
  return result;
}

final class _MemorySave implements GameSaveRepository {
  Map<String, dynamic>? data;
  @override
  Future<void> save(GameState state) async {
    data = state.toJson();
  }

  @override
  Future<GameState?> load() async =>
      data == null ? null : GameState.fromJson(data!);
  @override
  Future<bool> exists() async => data != null;
  @override
  Future<void> delete() async {
    data = null;
  }
}

Future<void> _press(PlayableMapGame game, RuntimeInputControl control) async {
  game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
  game.update(.016);
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  for (var i = 0; i < 8; i++) {
    game.update(.04);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

Future<void> _tickUntil(PlayableMapGame game, bool Function() predicate) async {
  for (var i = 0; i < 200 && !predicate(); i++) {
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(predicate(), isTrue);
}

final class _Sfx implements OverworldSfxPlayer {
  var cuts = 0;
  @override
  Future<void> playCut() async {
    cuts += 1;
  }

  @override
  Future<void> playJump() async {}
  @override
  Future<void> dispose() async {}
}

Future<void> _confirmObstacle(PlayableMapGame game) async {
  final request = game.overworldInteractionSnapshot.primaryAction?.request;
  expect(request, isNotNull);
  expect(game.dispatchOverworldInteraction(request!), isTrue);
  for (var i = 0; i < 8; i++) {
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  await _press(game, RuntimeInputControl.primary);
  await _press(game, RuntimeInputControl.primary);
  await _tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
}

Future<ui.Image> _renderLayers(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  component.render(ui.Canvas(recorder));
  return recorder.endRecording().toImage(160, 128);
}

Future<void> _moveWalker(PlayableMapGame game) async {
  final movement = game.debugExecuteSceneInteractiveCommand(
    SceneInteractiveCommand.actorRoute(
      target: SceneActorTarget.entity(mapId: 'route', entityId: 'walker'),
      steps: [
        SceneActorRouteStep.move(direction: EntityFacing.east, durationMs: 30),
        SceneActorRouteStep.move(direction: EntityFacing.south, durationMs: 30),
      ],
    ),
  );
  var finished = false;
  movement.whenComplete(() => finished = true);
  await _tickUntil(game, () => finished);
  expect(await movement, 'completed');
}

Map<String, MapInstanceNpcPose> _npcPoses(Map<String, GridPos> positions) => {
  for (final entry in positions.entries)
    entry.key: MapInstanceNpcPose(position: entry.value, facing: EntityFacing.south),
};
