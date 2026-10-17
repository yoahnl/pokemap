import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'playable_map_game_flash_test.dart' show MemorySave;
import 'surface/surface_runtime_test_support.dart' show runtimeTilesetImage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final afterBattleService in ['expiration', 'bicycle']) {
    testWidgets(
      'standalone Headbutt victory preserves progression through Repel $afterBattleService',
      (tester) async {
        await tester.runAsync(() async {
          final repository = MemorySave();
          final fixture = await mountInteractive(
            tester,
            repelSteps: afterBattleService == 'expiration' ? 1 : 0,
            withRepelCatalog: true,
            repository: repository,
          );
          final game = fixture.game;
          final initial = game.gameStateSnapshot;
          final victory = await finishInteractiveVictory(game);
          expect(consumed(game), isTrue);
          expect(
            victory.state.completedBattleRequestIds,
            contains(victory.request.requestId),
          );
          expect(
            victory.state.party.members.first.experience,
            greaterThan(initial.party.members.first.experience ?? 0),
          );
          expect(
            victory.state.party.members.first.currentPpByMoveId![victory
                .ppMoveId],
            initial.party.members.first.currentPpByMoveId![victory.ppMoveId]! -
                1,
          );
          if (afterBattleService == 'expiration') {
            await press(game, RuntimeInputControl.down);
            expect(game.lastCommittedMovement, isNotNull);
            expect(game.gameStateSnapshot.repelState.expirationPending, isTrue);
            for (var index = 0; index < 10; index++) {
              final dialogue = game.dialoguePresentationListenable.value;
              if (dialogue?.mode == DialoguePresentationMode.choices) break;
              await press(game, RuntimeInputControl.primary);
            }
            final dialogue = game.dialoguePresentationListenable.value!;
            expect(dialogue.nodeTitle, 'repel_expired');
            expect(dialogue.mode, DialoguePresentationMode.choices);
            expect(
              game.dispatchDialoguePresentationCommand(
                DialogueSelectChoiceCommand(
                  snapshotRevision: dialogue.revision,
                  choiceIndex: 1,
                ),
              ),
              isTrue,
            );
            await settle(game, rounds: 50);
            expect(
              game.gameStateSnapshot.repelState.expirationPending,
              isFalse,
            );
            expect(game.gameStateSnapshot.repelState.remainingSteps, 0);
          } else {
            expect(game.lastCommittedMovement, isNull);
            expect(game.gameStateSnapshot.repelState.isActive, isFalse);
            final controller = PlayerServiceRuntimeController.contextual(
              currentGameState: () => game.playerServiceGameStateSnapshot,
              commitAndSave: game.commitAndSavePlayerServiceState,
              setInputLocked: (locked) => game.setExternalInputLock(
                RuntimeExternalInputLock.playerService,
                locked: locked,
              ),
              loadRecoveryCaps: (_) async =>
                  const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
              itemCatalog: ItemCatalogSnapshot.fromCatalog(
                const ProjectItemCatalog(
                  schemaVersion: 1,
                  entries: [postBattleRepel, postBattleBike],
                ),
              ),
            );
            addTearDown(controller.dispose);
            game.setPlayerServiceRuntimeController(controller);
            final result = await controller.useBagItemOutsideBattle(
              const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'bike'),
            );
            expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
            expect(
              game.gameStateSnapshot.playerMovementMode,
              MovementMode.bicycle,
            );
            expect(game.lastCommittedMovement, isNull);
          }
          final current = game.gameStateSnapshot;
          final saved = GameState.fromJson(repository.data!);
          for (final state in [current, saved]) {
            expect(state.party, victory.state.party);
            expect(
              state.completedBattleRequestIds,
              victory.state.completedBattleRequestIds,
            );
            expect(
              state.mapInstanceWorldState,
              victory.state.mapInstanceWorldState,
            );
          }
        });
      },
    );
  }

  for (final answer in ['confirm', 'cancel', 'no', 'stale']) {
    testWidgets(
      'native Headbutt $answer validates and consumes no state before preparation',
      (tester) async {
        await tester.runAsync(() async {
          final fixture = await mountInteractive(tester, chance: 0);
          final game = fixture.game;
          final request =
              game.overworldInteractionSnapshot.primaryAction!.request;
          expect(game.dispatchOverworldInteraction(request), isTrue);
          await settle(game);
          await press(game, RuntimeInputControl.primary);
          if (answer == 'no') await press(game, RuntimeInputControl.down);
          if (answer == 'stale') game.setPlayerMovementMode(MovementMode.surf);
          await press(
            game,
            answer == 'cancel'
                ? RuntimeInputControl.secondary
                : RuntimeInputControl.primary,
          );
          expect(game.debugPendingBattleRequest, isNull);
          expect(fixture.random.calls, answer == 'confirm' ? 1 : 0);
          final state = game.gameStateSnapshot;
          expect(
            state.mapInstanceWorldState.isInteractiveEncounterConsumed(
              state.mapInstanceWorldState.instanceRef('route')!,
              'tree',
            ),
            isFalse,
          );
          expect(game.canCapturePlayerCheckpoint, isTrue);
        });
      },
    );
  }
  testWidgets('declared disabled narrative owner prevents intrinsic Headbutt', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final fixture = await mountInteractive(tester, declaredOwner: true);
      expect(fixture.game.overworldInteractionSnapshot.primaryAction, isNull);
      await press(fixture.game, RuntimeInputControl.primary);
      expect(fixture.random.calls, 0);
      expect(fixture.game.debugPendingBattleRequest, isNull);
    });
  });
  for (final failure in ['throw', 'lifecycle']) {
    testWidgets(
      'native interactive $failure during preparation releases reservation without consuming',
      (tester) async {
        await tester.runAsync(() async {
          final entered = Completer<void>(), release = Completer<void>();
          addTearDown(() {
            if (!release.isCompleted) release.complete();
          });
          final fixture = await mountInteractive(
            tester,
            beforeBattle: () async {
              entered.complete();
              await release.future;
              if (failure == 'throw') throw StateError('preparation failure');
            },
          );
          final game = fixture.game;
          await confirm(game);
          await entered.future.timeout(const Duration(seconds: 5));
          expect(await game.saveGame(), isFalse);
          expect(await game.loadGame(), isFalse);
          expect(game.canCapturePlayerCheckpoint, isFalse);
          final before = game.gameStateSnapshot;
          expect(
            before.mapInstanceWorldState.isInteractiveEncounterConsumed(
              before.mapInstanceWorldState.instanceRef('route')!,
              'tree',
            ),
            isFalse,
          );
          if (failure == 'lifecycle')
            game.setExternalInputLock(
              RuntimeExternalInputLock.lifecycle,
              locked: true,
            );
          release.complete();
          await settle(game, rounds: 50);
          expect(game.debugFlowPhaseName, 'overworld');
          expect(
            game.gameStateSnapshot.mapInstanceWorldState,
            before.mapInstanceWorldState,
          );
          expect(
            game.debugInputLockSnapshot.activeTokens.where(
              (token) =>
                  token.owner == RuntimeInputLockOwner.blockingInteraction,
            ),
            isEmpty,
          );
          if (failure == 'lifecycle')
            game.setExternalInputLock(
              RuntimeExternalInputLock.lifecycle,
              locked: false,
            );
          expect(game.canCapturePlayerCheckpoint, isTrue);
        });
      },
    );
  }
  testWidgets(
    'failed native wild hydration releases the object without consuming it',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = await mountInteractive(
          tester,
          opponentSpecies: 'absent_species',
        );
        await confirm(fixture.game);
        await settle(fixture.game, rounds: 100);
        expect(fixture.game.debugFlowPhaseName, 'overworld');
        expect(consumed(fixture.game), isFalse);
        expect(fixture.random.calls, 1);
        expect(
          fixture.game.debugInputLockSnapshot.activeTokens.where(
            (token) => token.owner == RuntimeInputLockOwner.blockingInteraction,
          ),
          isEmpty,
        );
        expect(fixture.game.canCapturePlayerCheckpoint, isTrue);
      });
    },
  );
  testWidgets(
    'ready native battle commits once and cold restore blocks the same tree',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = await mountInteractive(tester);
        final game = fixture.game;
        await confirm(game);
        for (var i = 0; i < 1500 && !consumed(game); i++) {
          game.update(.02);
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
        expect(consumed(game), isTrue);
        expect(game.debugFlowPhaseName, 'battle');
        final request = game.debugActiveBattleRequest as WildBattleStartRequest;
        expect(request.generatedPokemon, isNotNull);
        expect(
          request.encounterSourceSnapshot?.encounterKind,
          EncounterKind.headbutt,
        );
        expect(fixture.random.calls, 1);
        game.debugResetBattleForTest();
        expect(consumed(game), isTrue);
        final saved = GameState.fromJson(game.gameStateSnapshot.toJson());
        final restored = await mountInteractive(tester, restored: saved);
        expect(consumed(restored.game), isTrue);
        await confirm(restored.game, dialog: false);
        expect(restored.random.calls, 0);
        expect(restored.game.debugPendingBattleRequest, isNull);
      });
    },
  );
  testWidgets(
    'successful Smash preserves removal when its optional combat fails',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = await mountInteractive(
          tester,
          smash: true,
          beforeBattle: () async => throw StateError('failed launch'),
        );
        await confirm(fixture.game);
        await settle(fixture.game, rounds: 50);
        expect(fixture.game.debugMapEntityPosition('tree'), isNull);
        final state = fixture.game.gameStateSnapshot,
            scope = fixture.game.gameStateSnapshot.mapInstanceWorldState
                .instanceRef('route')!;
        expect(
          state.mapInstanceWorldState.isFieldObstacleCleared(scope, 'tree'),
          isTrue,
        );
        expect(
          state.mapInstanceWorldState.isInteractiveEncounterConsumed(
            scope,
            'tree',
          ),
          isFalse,
        );
        expect(fixture.random.calls, 1);
      });
    },
  );
}

bool consumed(PlayableMapGame game) {
  final state = game.gameStateSnapshot;
  return state.mapInstanceWorldState.isInteractiveEncounterConsumed(
    state.mapInstanceWorldState.instanceRef('route')!,
    'tree',
  );
}

Future<void> settle(PlayableMapGame game, {int rounds = 12}) async {
  for (var i = 0; i < rounds; i++) {
    game.update(.04);
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

Future<void> press(PlayableMapGame game, RuntimeInputControl control) async {
  game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
  game.update(.016);
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  await settle(game);
}

Future<void> confirm(PlayableMapGame game, {bool dialog = true}) async {
  final request = game.overworldInteractionSnapshot.primaryAction?.request;
  expect(request, isNotNull);
  expect(game.dispatchOverworldInteraction(request!), isTrue);
  await settle(game);
  if (dialog) {
    await press(game, RuntimeInputControl.primary);
    await press(game, RuntimeInputControl.primary);
  }
}

Future<({PlayableMapGame game, EncounterRandom random})> mountInteractive(
  WidgetTester tester, {
  double chance = 1,
  bool smash = false,
  bool declaredOwner = false,
  String opponentSpecies = 'sparkitten',
  Future<void> Function()? beforeBattle,
  GameState? restored,
  int repelSteps = 0,
  bool withRepelCatalog = false,
  MemorySave? repository,
}) async {
  final root = await Directory.systemTemp.createTemp('runtime-interactive-');
  addTearDown(() => root.delete(recursive: true));
  final reference = Directory(
    '../../examples/playable_runtime_host/golden_battle_slice',
  ).absolute;
  final project = ProjectManifest.fromJson(
    jsonDecode(await File('${reference.path}/project.json').readAsString())
        as Map<String, dynamic>,
  );
  await Directory('${root.path}/data/pokemon/catalogs').create(recursive: true);
  for (final entry in Directory('${reference.path}/data/pokemon').listSync()) {
    if (entry.path.endsWith('/catalogs')) continue;
    await Link(
      '${root.path}/data/pokemon/${entry.uri.pathSegments.where((part) => part.isNotEmpty).last}',
    ).create(entry.path);
  }
  for (final file in Directory(
    '${reference.path}/data/pokemon/catalogs',
  ).listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (name != 'moves.json') {
      await Link('${root.path}/data/pokemon/catalogs/$name').create(file.path);
      continue;
    }
    final catalog =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final entries = catalog['entries'] as List;
    final template = entries.first as Map;
    entries.add({
      ...template,
      'id': 'headbutt',
      'name': 'Headbutt',
      'names': {'en': 'Headbutt'},
    });
    entries.add({
      ...template,
      'id': 'rock_smash',
      'name': 'Rock Smash',
      'names': {'en': 'Rock Smash'},
    });
    await File('${root.path}/data/pokemon/catalogs/moves.json')
        .writeAsString(jsonEncode(catalog));
  }
  await Link('${root.path}/assets').create('${reference.path}/assets');
  if (withRepelCatalog) {
    await File('${root.path}/items.json').writeAsString(
      jsonEncode(
        const ProjectItemCatalog(
          schemaVersion: 1,
          entries: [postBattleRepel, postBattleBike],
        ).toJson(),
      ),
    );
  }
  final kind = smash ? EncounterKind.special : EncounterKind.headbutt;
  final payload = MapEntityInteractiveEncounterData(
    trigger: smash
        ? InteractiveEncounterTrigger.afterRockSmash
        : InteractiveEncounterTrigger.headbutt,
    encounterTableId: 'objects',
    reusePolicy: InteractiveEncounterReusePolicy.oncePerMapInstance,
  );
  final map = MapData(
    id: 'route',
    name: 'Route',
    size: const GridSize(width: 8, height: 6),
    entities: [
      const MapEntity(
        id: 'start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 2, y: 2),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'tree',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 3, y: 2),
        editorVisual: const MapEntityEditorVisual(elementId: 'object-visual'),
        interactiveEncounter: payload,
        fieldObstacle: smash
            ? const MapEntityFieldObstacleData(
                kind: FieldObstacleKind.rockSmashRock,
              )
            : null,
      ),
    ],
  );
  final manifest = project.copyWith(
    settings: withRepelCatalog
        ? project.settings.copyWith(defaultPlayerCharacterId: 'service-hero')
        : project.settings,
    characters: withRepelCatalog
        ? [
            ProjectCharacterEntry(
              id: 'service-hero',
              name: 'Hero',
              tilesetId: 'props',
              animations: [
                for (final state in [
                  CharacterAnimationState.bicycleIdle,
                  CharacterAnimationState.bicycle,
                ])
                  for (final direction in EntityFacing.values)
                    CharacterAnimation(
                      state: state,
                      direction: direction,
                      sourceAssetId: 'cycle',
                      frames: const [
                        CharacterAnimationFrame(
                          source: TilesetSourceRect(
                            x: 0,
                            y: 0,
                            width: 1,
                            height: 1,
                          ),
                          durationMs: 100,
                        ),
                      ],
                    ),
              ],
            ),
          ]
        : project.characters,
    pokemon: withRepelCatalog
        ? project.pokemon.copyWith(
            catalogFiles: {
              ...project.pokemon.catalogFiles,
              'items': 'items.json',
            },
          )
        : project.pokemon,
    eventRegistry: declaredOwner
        ? NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            legacyClaims: const [],
            records: [
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
        : [],
    maps: const [
      ProjectMapEntry(id: 'route', name: 'Route', relativePath: 'route.json'),
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
        id: 'object-visual',
        name: 'Object',
        tilesetId: 'props',
        categoryId: 'props',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
          ),
        ],
      ),
    ],
    encounterTables: [
      ProjectEncounterTable(
        id: 'objects',
        name: 'Objects',
        encounterKind: kind,
        chancePerStep: chance,
        entries: [
          ProjectEncounterEntry(
            speciesId: opponentSpecies,
            minLevel: 5,
            maxLevel: 5,
          ),
        ],
      ),
    ],
  );
  final launch = gameStateFromSaveData(
    SaveData.fromJson(
      jsonDecode(
        await File('${reference.path}/runtime_host_launch_save.json')
            .readAsString(),
      ) as Map<String, dynamic>,
    ),
  );
  final party = launch.party.copyWith(
    members: [
      for (final pokemon in launch.party.members)
        pokemon.copyWith(
          knownMoveIds: [
            ...pokemon.knownMoveIds.take(2),
            'headbutt',
            'rock_smash',
          ],
          currentPpByMoveId: {
            for (final move in pokemon.knownMoveIds.take(2))
              move: pokemon.currentPpByMoveId?[move] ?? 10,
            'headbutt': 15,
            'rock_smash': 15,
          },
        ),
    ],
  );
  final state =
      restored ??
      launch.copyWith(
        currentMapId: 'route',
        playerPosition: const GridPos(x: 2, y: 2),
        playerFacing: EntityFacing.east,
        party: party,
        repelState: repelSteps == 0
            ? const RepelState.empty()
            : RepelState.active(itemId: 'repel', steps: repelSteps),
        bag: withRepelCatalog
            ? const Bag(
                entries: [
                  BagEntry(itemId: 'repel', quantity: 2),
                  BagEntry(itemId: 'bike', quantity: 1),
                ],
              )
            : launch.bag,
        progression: launch.progression.copyWith(
          unlockedFieldAbilities: [FieldAbility.rockSmash],
        ),
        mapInstanceWorldState: const MapInstanceWorldState.empty(),
      );
  final bundle = RuntimeMapBundle(
    manifest: manifest,
    map: map,
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: {'props': '${root.path}/props.png'},
    characterAnimationAbsolutePathsByAssetId: withRepelCatalog
        ? {'cycle': '${root.path}/cycle.png'}
        : {},
  );
  await File('${root.path}/project.json')
      .writeAsString(jsonEncode(manifest.toJson()));
  await File('${root.path}/route.json').writeAsString(jsonEncode(map.toJson()));
  final random = EncounterRandom();
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: '${root.path}/project.json',
    saveData: saveDataFromGameState(state),
    saveRepository: repository ?? MemorySave(),
    initialMapActivationReason: restored == null
        ? MapActivationReason.initialBoot
        : MapActivationReason.saveRestore,
    encounterRandom: random,
    beforeBattleHandoffPreparation: beforeBattle,
    runtimeTilesetImageLoader:
        (paths, {transparentColorByTilesetId = const {}}) async => {
          'props': await runtimeTilesetImage(const [ui.Color(0xFF22AA44)]),
          if (withRepelCatalog)
            'character-animation:cycle': await runtimeTilesetImage(const [
              ui.Color(0xFF22AA44),
            ]),
        },
  );
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  await game.loaded;
  await tester.pump();
  addTearDown(game.onRemove);
  await settle(game, rounds: 30);
  expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
  expect(
    game.gameStateSnapshot.mapInstanceWorldState.instanceRef('route'),
    isNotNull,
  );
  return (game: game, random: random);
}

class EncounterRandom implements Random {
  int calls = 0;
  @override
  double nextDouble() {
    calls++;
    return 0;
  }

  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

const postBattleRepel = ProjectItemDefinition(
  id: 'repel',
  displayName: 'Repousse',
  pocketId: 'items',
  uses: [
    ProjectItemUseDefinition(
      contexts: {ProjectItemUseContext.overworld},
      target: ProjectItemTargetKind.world,
      consumption: ProjectItemConsumptionPolicy.onApplied,
      effect: ProjectItemEffectDefinition.repel(steps: 3),
    ),
  ],
);

Future<({GameState state, BattleStartRequest request, String ppMoveId})>
finishInteractiveVictory(PlayableMapGame game) async {
  await confirm(game);
  for (var index = 0; index < 1500 && !consumed(game); index++) {
    game.update(.02);
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  expect(consumed(game), isTrue);
  expect(game.debugFlowPhaseName, 'battle');
  final request = game.debugActiveBattleRequest!;
  final battle = game.debugBattleSessionSnapshot!.state;
  final move = battle.player.moves.first;
  final player = battle.player.withUpdatedMoveAt(
    0,
    move.withPpState(pp: move.pp, currentPp: move.currentPp - 1),
  );
  final outcome = BattleOutcome(
    type: BattleOutcomeType.victory,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: player,
      playerReserve: battle.playerReserve,
      enemy: battle.enemy.withDamage(battle.enemy.maxHp),
      enemyReserve: battle.enemyReserve,
      playerParticipantLineupIndexes: {0},
    ),
  );
  final state = game.gameStateSnapshot;
  final context = RuntimeActiveBattleContext.withLineupMapping(
    request: request,
    playerPartyIndex: 0,
    playerPartySlotIndicesByLineupIndex: [
      for (var index = 0; index < state.party.members.length; index++) index,
    ],
    playerIndividualId: state.party.members.first.individualId,
    playerIndividualIdsByLineupIndex: [
      for (final pokemon in state.party.members) pokemon.individualId,
    ],
  );
  game.debugResetBattleForTest();
  await game.debugStartPostBattleForTest(context: context, outcome: outcome);
  for (
    var index = 0;
    index < 100 && game.debugFlowPhaseName != 'overworld';
    index++
  ) {
    if (game.debugPostBattleOverlayMounted) {
      expect(game.debugValidatePostBattleChoice(), isTrue);
    }
    game.update(.04);
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  await game.debugWaitForPostBattleCompletion().timeout(
    const Duration(seconds: 5),
  );
  await settle(game);
  expect(game.debugFlowPhaseName, 'overworld');
  expect(game.canCapturePlayerCheckpoint, isTrue);
  return (state: game.gameStateSnapshot, request: request, ppMoveId: move.id);
}

const postBattleBike = ProjectItemDefinition(
  id: 'bike',
  displayName: 'Vélo',
  pocketId: 'key-items',
  tags: {'key-item'},
  uses: [
    ProjectItemUseDefinition(
      contexts: {ProjectItemUseContext.overworld},
      target: ProjectItemTargetKind.world,
      consumption: ProjectItemConsumptionPolicy.never,
      effect: ProjectItemEffectDefinition.bicycle(),
    ),
  ],
);
