import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_menu_model.dart'
    show BattleCommandRootAction;
import 'package:path/path.dart' as path;

import 'source_converted_gym_reward_journey_test.dart'
    show installConvertedQaHeadlessAudio;
import 'source_converted_intro_journey_test.dart'
    show
        createConvertedSourceFreshGame,
        mountConvertedSourceIntroGame,
        ConvertedSourceIntroMounted,
        ConvertedSourceIntroDiskSave;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => installConvertedQaHeadlessAudio(completePlayback: true));
  final root = Platform.environment['AVELUNE_CAMPAIGN_PREFIX_PROJECT'];
  final output = Platform.environment['AVELUNE_CAMPAIGN_PREFIX_RECEIPT'];
  final continueToParcel =
      Platform.environment['AVELUNE_CAMPAIGN_PREFIX_CONTINUE_PARCEL'] == '1';
  testWidgets(
    continueToParcel
        ? 'genuine new game completes the source rival and parcel journey with cold saves'
        : 'genuine new game walks from Intro to its source laboratory starter',
    (tester) async {
      await tester.runAsync(() async {
        final projectFile = path.join(root!, 'project.json');
        final manifest = await loadProjectManifestFromFile(projectFile);
        expect(manifest.maps, hasLength(383));
        Future<Map<String, String>> protectedProjectHashes() async => {
          for (final relative in [
            'project.json',
            for (final map in manifest.maps) map.relativePath,
          ])
            relative: crypto.sha256
                .convert(await File(path.join(root, relative)).readAsBytes())
                .toString(),
        };
        final beforeProjectHashes = await protectedProjectHashes();
        final intro = manifest.maps.singleWhere((m) => m.name == 'Intro');
        final home = manifest.maps.singleWhere(
          (m) => m.name.endsWith("PN's House"),
        );
        final pallet = manifest.maps.singleWhere(
          (m) => m.name == 'Pallet Town',
        );
        final lab = manifest.maps.singleWhere((m) => m.name == "Oak's Lab");
        final routeOne = manifest.maps.singleWhere(
          (map) => map.name == 'Route 1',
        );
        final initial = await createConvertedSourceFreshGame(
          projectFile,
          'preset',
        );
        final expectedRecovery = PlayerRecoveryPoint(
          mapId: home.id,
          position: const GridPos(x: 9, y: 7),
          facing: EntityFacing.north,
        );
        final recoveredFact = manifest.facts.singleWhere(
          (fact) => fact.id == manifest.defeatRecovery!.recoveredFactId,
        );
        NarrativeValue recoveryMarker(GameState state) =>
            state.narrativeFactRuntimeState.valueFor(recoveredFact.id) ??
            recoveredFact.initialValue;
        expect(PlayerRecoveryPoint.tryRead(initial), expectedRecovery);
        expect(recoveryMarker(initial), const NarrativeValue.boolean(false));
        expect(initial.currentMapId, intro.id);
        expect(initial.party.members, isEmpty);
        expect(manifest.newGame.initialParty, isEmpty);
        expect(manifest.newGame.starterOptions, isEmpty);
        final directory = await Directory.systemTemp.createTemp(
          'campaign-prefix-save-',
        );
        final repository = ConvertedSourceIntroDiskSave(
          path.join(directory.path, 'game.json'),
        );
        ConvertedSourceIntroMounted? mounted;
        final checkpoints = <Map<String, Object?>>[];
        final dialogues = <String>[];
        final movies = <String>[];
        final modalities = <String>[];
        final battleOutcomes = <Map<String, Object?>>[];
        final retainedSaves = <String, Map<String, String>>{};
        final serviceCommands = <Future<void>>[];
        Object? observedBattleSetup;
        var battleCommandCount = 0;
        final maps = <String, MapData>{};
        var handledModal = '', currentStage = 'intro';
        final blockedEdges = <(String, GridPos, GridPos)>{};
        final terrainCosts = <String, Map<GridPos, int>>{};
        var trainingIterations = 0,
            trainingMovements = 0,
            trainingRecoveries = 0;
        int? trainingExperienceBefore, trainingExperienceAfter;
        const trainingStage = 'train_before_first_parcel';
        Map<String, Object?>? successfulResult;
        final watch = Stopwatch()..start();
        try {
          mounted = await mountConvertedSourceIntroGame(
            tester,
            projectFile,
            manifest,
            repository,
            initial,
            loadActualPlayerServiceCaps: true,
          );
          var game = mounted.game;
          var controller = mounted.controller;
          NarrativeValue value(String suffix) {
            final fact = manifest.facts.singleWhere(
              (f) => f.description.endsWith(suffix),
            );
            return game.gameStateSnapshot.narrativeFactRuntimeState.valueFor(
                  fact.id,
                ) ??
                fact.initialValue;
          }

          void checkpoint(String name) {
            final row = <String, Object?>{
              'stage': name,
              'mapId': game.gameStateSnapshot.currentMapId,
              'position': game.debugPlayerGridPosition.toJson(),
              'partyCount': game.gameStateSnapshot.party.members.length,
              'party': [
                for (final member in game.gameStateSnapshot.party.members)
                  {
                    'individualId': member.individualId,
                    'speciesId': member.speciesId,
                    'level': member.level,
                    'hp': member.currentHp,
                  },
              ],
              'badges': game.gameStateSnapshot.trainerProfile.badgeIds,
              'elapsedMs': watch.elapsedMilliseconds,
            };
            checkpoints.add(row);
            stdout.writeln(
              jsonEncode({'kind': 'campaignPrefixProgress', ...row}),
            );
            if (output != null) {
              File('$output.progress.json').writeAsStringSync(
                jsonEncode({
                  'kind': 'genuineSourceCampaignProgress',
                  'projectPath': root,
                  'checkpoints': checkpoints,
                  'battleOutcomes': battleOutcomes,
                  'qaFlagsSeeded': false,
                  'qaPartySeeded': false,
                  'qaPositionSeeded': false,
                  'journeyComplete': false,
                }),
                flush: true,
              );
            }
          }

          void press(RuntimeInputControl control) {
            game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
            game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
          }

          bool idle() =>
              game.debugFlowPhaseName == 'overworld' &&
              game.debugCompletedMapActivationDispatchCount > 0 &&
              !game.debugIsEntityAutorunInFlight &&
              !game.debugIsMapActivationDispatchInFlight &&
              !game.debugIsNarrativeSpatialDispatchInFlight &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsLoadActivationWorkInFlight &&
              !game.debugHasPendingDialogueLoad &&
              !game.debugHasPendingMapTransition &&
              !game.debugIsPlayerStepping &&
              !game.debugPostBattleOverlayMounted &&
              game.debugCinematicDialogueLine == null &&
              game.dialoguePresentationListenable.value == null &&
              controller.worldServiceSnapshot == null;
          Future<void> tick() async {
            game.update(.025);
            await game.ready();
            await Future<void>.delayed(const Duration(milliseconds: 1));
            if (game.debugBattleSessionSnapshot case final battle?) {
              if (battle.state.outcome != null &&
                  !identical(observedBattleSetup, battle.setup)) {
                observedBattleSetup = battle.setup;
                battleOutcomes.add({
                  'stage': currentStage,
                  'mapId': game.gameStateSnapshot.currentMapId,
                  'trainerId': battle.setup.trainerId,
                  'isTrainerBattle': battle.setup.isTrainerBattle,
                  'enemy': battle.state.enemy.speciesId,
                  'sourceRoster': [
                    for (final member in [
                      battle.setup.enemyPokemon,
                      ...battle.setup.enemyReservePokemon,
                    ])
                      {'speciesId': member.speciesId, 'level': member.level},
                  ],
                  'enemyLevel': battle.state.enemy.level,
                  'outcome': battle.state.outcome!.type.name,
                  'victory': battle.state.outcome!.isVictory,
                  'defeat': battle.state.outcome!.isDefeat,
                });
              }
            }
            if (game.battleCommandOverlayListenable.value case final overlay?
                when overlay.interactionsEnabled &&
                    overlay.mode != BattleCommandOverlayMode.decision) {
              final enabled = overlay.entries.where((entry) => entry.enabled);
              final nativeBattle = game.debugBattleSessionSnapshot;
              final retreatWild =
                  nativeBattle != null &&
                  !nativeBattle.setup.isTrainerBattle &&
                  (nativeBattle.state.player.currentHp * 2 <
                          nativeBattle.state.player.maxHp ||
                      (nativeBattle.state.player.level <= 5 &&
                          nativeBattle.state.enemy.level >= 4));
              final preferGrass =
                  nativeBattle != null &&
                  {
                    'geodude',
                    'onix',
                    'rattata',
                    'sandshrew',
                  }.contains(nativeBattle.state.enemy.speciesId);
              final entry = overlay.mode == BattleCommandOverlayMode.fight
                  ? enabled.firstWhere(
                      (entry) =>
                          preferGrass &&
                          entry.index >= 0 &&
                          entry.index <
                              nativeBattle.state.player.moves.length &&
                          nativeBattle.state.player.moves[entry.index].id ==
                              'vine_whip',
                      orElse: () => enabled.firstWhere(
                        (entry) =>
                            entry.tone ==
                                BattleCommandOverlayEntryTone.attack ||
                            entry.tone == BattleCommandOverlayEntryTone.special,
                        orElse: () => enabled.first,
                      ),
                    )
                  : enabled.first;
              final index = switch (overlay.mode) {
                BattleCommandOverlayMode.root =>
                  retreatWild &&
                          enabled.any(
                            (entry) =>
                                entry.index ==
                                BattleCommandRootAction.run.index,
                          )
                      ? BattleCommandRootAction.run.index
                      : BattleCommandRootAction.fight.index,
                BattleCommandOverlayMode.fight ||
                BattleCommandOverlayMode.continueOnly ||
                BattleCommandOverlayMode.pokemon => entry.index,
                _ => throw StateError(
                  'Unexpected campaign battle menu ${overlay.mode}: ${overlay.prompt}',
                ),
              };
              if (game.dispatchBattlePresentationCommand(
                BattleSelectEntryCommand(
                  snapshotRevision: overlay.revision,
                  expectedMode: overlay.mode,
                  entryIndex: index,
                ),
              )) {
                battleCommandCount++;
              }
            }
            if (game.postBattlePresentationListenable.value
                case final presentation? when !presentation.completed) {
              expect(presentation.hasFailure, isFalse);
              final command = presentation.choices.isEmpty
                  ? PostBattleAdvanceCommand(
                      snapshotRevision: presentation.revision,
                    )
                  : PostBattleSelectDecisionCommand(
                      snapshotRevision: presentation.revision,
                      decisionIndex: presentation.choices.first.index,
                    );
              game.dispatchPostBattlePresentationCommand(command);
            }
            if (game.debugCinematicDialogueLine case final line?) {
              if (movies.isEmpty || movies.last != line) movies.add(line);
              press(RuntimeInputControl.primary);
            }
            final dialogue = game.dialoguePresentationListenable.value;
            if (dialogue != null) {
              if (dialogues.isEmpty || dialogues.last != dialogue.fullText) {
                dialogues.add(dialogue.fullText);
              }
              press(RuntimeInputControl.primary);
            }
            final modal = controller.worldServiceSnapshot;
            if (modal != null &&
                modal.request.kind == RuntimeWorldServiceKind.heal) {
              expect(
                modal.stage,
                isNot(RuntimeWorldServiceStage.failed),
                reason: modal.safeMessage,
              );
              final key =
                  '${modal.request.interactionId}:${modal.revision}:${modal.stage.name}';
              final action = modal.stage == RuntimeWorldServiceStage.completed
                  ? RuntimeWorldServiceAction.close
                  : RuntimeWorldServiceAction.confirm;
              if (handledModal != key && modal.isActionEnabled(action)) {
                handledModal = key;
                serviceCommands.add(
                  controller
                      .dispatchWorldService(
                        RuntimeWorldServiceCommand(
                          action: action,
                          snapshotRevision: modal.revision,
                        ),
                      )
                      .then((result) {
                        expect(
                          result.status,
                          RuntimeWorldServiceCommandStatus.accepted,
                        );
                      }),
                );
                modalities.add('nativeHeal:${action.name}');
              }
            }
            if (modal?.content case final SceneInteractionRequest request) {
              final key = '${request.requestId}:${request.revision}';
              if (key == handledModal) return;
              handledModal = key;
              modalities.add(request.runtimeType.toString());
              final SceneInteractionResult result;
              if (request is SceneChoiceInteractionRequest &&
                  currentStage == 'intro') {
                expect(
                  request.options.map((option) => option.id),
                  contains('preset:1'),
                );
                result = SceneInteractionResult.choiceSelected(
                  requestId: request.requestId,
                  revision: request.revision,
                  selectedOptionId: 'preset:1',
                );
              } else if (request is SceneConfirmationInteractionRequest) {
                result = SceneInteractionResult.confirmed(
                  requestId: request.requestId,
                  revision: request.revision,
                  value: currentStage == 'intro',
                );
              } else if (request is SceneMessageInteractionRequest) {
                result = SceneInteractionResult.acknowledged(
                  requestId: request.requestId,
                  revision: request.revision,
                );
              } else {
                fail('Unexpected $currentStage modal: ${request.toJson()}');
              }
              final outcome = await controller.dispatchWorldService(
                RuntimeWorldServiceCommand(
                  action: RuntimeWorldServiceAction.confirm,
                  snapshotRevision: modal!.revision,
                  interactionResult: result,
                ),
              );
              expect(outcome.status, RuntimeWorldServiceCommandStatus.accepted);
            }
          }

          Future<void> until(
            bool Function() condition,
            String frontier, {
            int limit = 18000,
          }) async {
            var stable = 0;
            for (var step = 0; step < limit; step++) {
              await tick();
              stable = condition() ? stable + 1 : 0;
              if (stable >= 8) return;
            }
            fail(
              '$frontier blocked: stage=$currentStage map=${game.gameStateSnapshot.currentMapId} '
              'position=${game.debugPlayerGridPosition} phase=${game.debugFlowPhaseName} '
              'dialogue=${game.dialoguePresentationListenable.value?.fullText} '
              'modal=${controller.worldServiceSnapshot?.content} '
              'pending=${game.debugPendingSceneWaitCount}',
            );
          }

          Future<MapData> authoredMap(String id) async {
            if (maps[id] case final cached?) return cached;
            final entry = manifest.maps.singleWhere((m) => m.id == id);
            final map = MapData.fromJson(
              Map<String, dynamic>.from(
                jsonDecode(
                  await File(path.join(root, entry.relativePath))
                      .readAsString(),
                ) as Map,
              ),
            );
            maps[id] = map;
            return map;
          }

          int traversalCost(MapData map, GridPos position) =>
              (terrainCosts[map.id] ??= {}).putIfAbsent(
                position,
                () =>
                    map.gameplayZones.any(
                      (zone) =>
                          zone.kind == GameplayZoneKind.encounter &&
                          gameplayZoneContainsPosition(zone, position),
                    )
                    ? 101
                    : 1,
              );

          int routeCost(MapData map, Iterable<GridPos> route) =>
              route.fold(0, (sum, cell) => sum + traversalCost(map, cell));

          Future<List<GridPos>> routeTo(
            GridPos goal,
            Set<GridPos> avoid, {
            bool required = true,
          }) async {
            final authored = await authoredMap(
              game.gameStateSnapshot.currentMapId,
            );
            final active = projectMapEntityPresentations(
              project: manifest,
              map: authored,
              gameState: game.gameStateSnapshot,
            );
            final located = active.copyWith(
              entities: [
                for (final entity in active.entities)
                  if (game.debugMapEntityPosition(entity.id)
                      case final position?)
                    entity.copyWith(pos: position)
                  else
                    entity,
              ],
            );
            final start = game.debugPlayerGridPosition;
            final world = GameplayWorldState.initial(
              map: located,
              project: manifest,
              playerPos: start,
              gameState: game.gameStateSnapshot,
              tileWidth: manifest.settings.tileWidth,
              tileHeight: manifest.settings.tileHeight,
            );
            final pending = SplayTreeMap<int, Queue<GridPos>>()
              ..[0] = (Queue<GridPos>()..add(start));
            final distances = <GridPos, int>{start: 0};
            final previous = <GridPos, GridPos?>{start: null};
            while (pending.isNotEmpty) {
              final cost = pending.firstKey()!;
              final bucket = pending[cost]!;
              final cell = bucket.removeFirst();
              if (bucket.isEmpty) pending.remove(cost);
              if (distances[cell] != cost) continue;
              if (cell == goal) break;
              for (final delta in [(0, -1), (-1, 0), (1, 0), (0, 1)]) {
                final next = GridPos(
                  x: cell.x + delta.$1,
                  y: cell.y + delta.$2,
                );
                if (avoid.contains(next) ||
                    blockedEdges.contains((authored.id, cell, next)) ||
                    world.isBlocked(next.x, next.y)) {
                  continue;
                }
                final nextCost = cost + traversalCost(located, next);
                if (nextCost >= (distances[next] ?? 1 << 62)) continue;
                distances[next] = nextCost;
                previous[next] = cell;
                (pending[nextCost] ??= Queue<GridPos>()).add(next);
              }
            }
            if (!previous.containsKey(goal)) {
              if (!required) return const [];
              fail(
                'No native collision route in ${authored.name}: $start -> $goal',
              );
            }
            final reversed = <GridPos>[];
            for (GridPos? cell = goal; cell != null; cell = previous[cell]) {
              reversed.add(cell);
            }
            return reversed.reversed.toList();
          }

          Future<void> step(RuntimeInputControl control) async {
            final startMap = game.gameStateSnapshot.currentMapId,
                start = game.debugPlayerGridPosition;
            final startBattleCount = battleOutcomes.length;
            final startDefeats =
                int.tryParse(
                  game.gameStateSnapshot.metadata['player.defeat.count'] ?? '0',
                ) ??
                0;
            game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
            try {
              for (var frame = 0; frame < 60; frame++) {
                await tick();
                if (game.gameStateSnapshot.currentMapId != startMap ||
                    game.debugPlayerGridPosition != start ||
                    game.debugIsCinematicPlaying ||
                    game.dialoguePresentationListenable.value != null) {
                  break;
                }
              }
            } finally {
              game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
            }
            await until(idle, 'finish keyboard step', limit: 6000);
            if (currentStage == trainingStage &&
                battleOutcomes
                    .skip(startBattleCount)
                    .any(
                      (outcome) =>
                          outcome['isTrainerBattle'] == false &&
                          outcome['defeat'] == true,
                    )) {
              expect(game.gameStateSnapshot.currentMapId, home.id);
              expect(game.debugPlayerGridPosition, expectedRecovery.position);
              expect(
                PlayerRecoveryPoint.tryRead(game.gameStateSnapshot),
                expectedRecovery,
              );
              expect(
                int.parse(
                  game.gameStateSnapshot.metadata['player.defeat.count']!,
                ),
                startDefeats + 1,
              );
              checkpoint('native_wild_defeat_returned_home');
              throw const _NativeWildDefeatRecovered();
            }

            if (currentStage == trainingStage &&
                (game.gameStateSnapshot.currentMapId != startMap ||
                    game.debugPlayerGridPosition != start)) {
              trainingMovements++;
            }
          }

          Future<void> walkTo(
            GridPos goal, {
            Set<GridPos> avoid = const {},
          }) async {
            final expectedMapId = game.gameStateSnapshot.currentMapId;
            for (var attempt = 0; attempt < 250; attempt++) {
              expect(game.gameStateSnapshot.currentMapId, expectedMapId);
              final beforeMapId = game.gameStateSnapshot.currentMapId;
              final before = game.debugPlayerGridPosition;
              if (before == goal) return;
              final route = await routeTo(goal, avoid);
              final next = route[1];
              final control = next.x < before.x
                  ? RuntimeInputControl.left
                  : next.x > before.x
                  ? RuntimeInputControl.right
                  : next.y < before.y
                  ? RuntimeInputControl.up
                  : RuntimeInputControl.down;
              await step(control);
              expect(
                game.gameStateSnapshot.currentMapId,
                expectedMapId,
                reason: 'Unexpected map transition while walking to $goal',
              );
              if (game.gameStateSnapshot.currentMapId == beforeMapId &&
                  game.debugPlayerGridPosition == before) {
                blockedEdges.add((beforeMapId, before, next));
              }
            }
            fail(
              'Keyboard walk did not reach $goal from ${game.debugPlayerGridPosition}',
            );
          }

          Future<void> crossConnection(
            MapConnectionDirection direction,
            String targetMapId,
          ) async {
            final source = await authoredMap(
              game.gameStateSnapshot.currentMapId,
            );
            final target = await authoredMap(targetMapId);
            final connection = source.connections.singleWhere(
              (connection) =>
                  connection.direction == direction &&
                  connection.targetMapId == targetMapId,
            );
            final targetWorld = GameplayWorldState.initial(
              map: projectMapEntityPresentations(
                project: manifest,
                map: target,
                gameState: game.gameStateSnapshot,
              ),
              project: manifest,
              playerPos: const GridPos(x: 0, y: 0),
              gameState: game.gameStateSnapshot,
              tileWidth: manifest.settings.tileWidth,
              tileHeight: manifest.settings.tileHeight,
            );
            final candidates = <(GridPos, int)>[];
            final count =
                direction == MapConnectionDirection.north ||
                    direction == MapConnectionDirection.south
                ? source.size.width
                : source.size.height;
            for (var index = 0; index < count; index++) {
              final border = switch (direction) {
                MapConnectionDirection.north => GridPos(x: index, y: 0),
                MapConnectionDirection.south => GridPos(
                  x: index,
                  y: source.size.height - 1,
                ),
                MapConnectionDirection.west => GridPos(x: 0, y: index),
                MapConnectionDirection.east => GridPos(
                  x: source.size.width - 1,
                  y: index,
                ),
              };
              final arrival = resolveConnectedMapTargetPos(
                sourcePos: border,
                sourceSize: source.size,
                targetSize: target.size,
                direction: direction,
                offset: connection.offset,
              );
              if (arrival == null ||
                  targetWorld.isBlocked(arrival.x, arrival.y)) {
                continue;
              }
              final route = await routeTo(border, const {}, required: false);
              if (route.isNotEmpty) {
                candidates.add((
                  border,
                  routeCost(source, route.skip(1)) +
                      traversalCost(target, arrival),
                ));
              }
            }
            candidates.sort((a, b) => a.$2.compareTo(b.$2));
            expect(
              candidates,
              isNotEmpty,
              reason: 'No walkable ${source.name} -> ${target.name} boundary',
            );
            await walkTo(candidates.first.$1);
            await step(switch (direction) {
              MapConnectionDirection.north => RuntimeInputControl.up,
              MapConnectionDirection.south => RuntimeInputControl.down,
              MapConnectionDirection.west => RuntimeInputControl.left,
              MapConnectionDirection.east => RuntimeInputControl.right,
            });
            expect(game.gameStateSnapshot.currentMapId, targetMapId);
            checkpoint('connection_${source.name}_${target.name}');
          }

          await until(
            () => game.gameStateSnapshot.currentMapId == home.id && idle(),
            'source intro',
          );
          expect(game.debugPlayerGridPosition, const GridPos(x: 27, y: 8));
          expect(value(':variable:28').stringValue, 'Gary');
          expect(value(':switch:99').boolValue, isTrue);
          expect(game.gameStateSnapshot.party.members, isEmpty);
          expect(value(':variable:29').intValue, 0);
          if (continueToParcel) {
            expect(
              game
                  .gameStateSnapshot
                  .pauseMenuState
                  .visibilityOverrides[ProjectPauseActionId.pokedex],
              isFalse,
            );
          }
          checkpoint('source_intro_completed');
          currentStage = 'home';
          await walkTo(
            const GridPos(x: 31, y: 4),
            avoid: {const GridPos(x: 30, y: 4)},
          );
          await step(RuntimeInputControl.left);
          expect(game.gameStateSnapshot.currentMapId, home.id);
          expect(game.debugPlayerGridPosition.x, lessThan(20));
          checkpoint('stairs_down');
          await walkTo(const GridPos(x: 5, y: 10));
          await step(RuntimeInputControl.down);
          expect(game.gameStateSnapshot.currentMapId, pallet.id);
          expect(game.debugPlayerGridPosition, const GridPos(x: 12, y: 8));
          checkpoint('home_exit');
          currentStage = 'escort';
          await walkTo(const GridPos(x: 18, y: 2));
          await step(RuntimeInputControl.up);
          await until(
            () =>
                game.gameStateSnapshot.currentMapId == lab.id &&
                idle() &&
                value(':switch:75').boolValue == true,
            'Oak escort and source laboratory preparation',
          );
          expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 6));
          expect(value(':switch:74').boolValue, isFalse);
          expect(value(':variable:29').intValue, 0);
          expect(game.gameStateSnapshot.party.members, isEmpty);
          checkpoint('laboratory_offer_enabled');
          currentStage = 'starter';
          final offer = manifest.scenes.singleWhere(
            (s) =>
                s.metadata['sourcePageIndex'] == '1' &&
                s.graph.nodes
                    .map((n) => n.payload)
                    .whereType<SceneActionPayload>()
                    .any(
                      (a) =>
                          a.interactiveCommand
                              is SceneReceivePokemonFromCatalogInteractiveCommand &&
                          (a.interactiveCommand
                                      as SceneReceivePokemonFromCatalogInteractiveCommand)
                                  .speciesId ==
                              'bulbasaur',
                    ),
          );
          final ball = (await authoredMap(lab.id)).entities.singleWhere(
            (e) =>
                e.properties['sourceEventIdentity'] ==
                offer.metadata['sourceEventIdentity'],
          );
          await walkTo(
            GridPos(x: ball.pos.x, y: ball.pos.y + ball.size.height),
          );
          await step(RuntimeInputControl.up);
          expect(
            game.overworldInteractionSnapshot.primaryAction?.request.targetId,
            ball.id,
          );
          press(RuntimeInputControl.primary);
          await until(
            () => idle() && game.gameStateSnapshot.party.members.length == 1,
            'source Bulbasaur choice',
          );
          final pokemon = game.gameStateSnapshot.party.members.single;
          expect(pokemon.speciesId, 'bulbasaur');
          expect(pokemon.level, 5);
          expect(pokemon.provenance!.kind, PlayerPokemonOriginKind.gift);
          expect(value(':variable:29').intValue, 1);
          expect(value(':switch:75').boolValue, isFalse);
          expect(value(':map:9:event:4:self:A').boolValue, isTrue);
          checkpoint('bulbasaur_received');
          expect(await game.saveGame(), isTrue);
          final saved = (await repository.load())!;
          expect(PlayerRecoveryPoint.tryRead(saved), expectedRecovery);
          expect(recoveryMarker(saved), const NarrativeValue.boolean(false));
          String? retainedSavePath, retainedSaveSha256;
          if (output != null) {
            final bytes = await File(repository.filePath).readAsBytes();
            retainedSavePath = '$output.starter.save.json';
            retainedSaveSha256 = crypto.sha256.convert(bytes).toString();
            await File(retainedSavePath).writeAsBytes(bytes, flush: true);
            expect(await File(retainedSavePath).readAsBytes(), bytes);
            final retained = await ConvertedSourceIntroDiskSave(
              retainedSavePath,
            ).load();
            expect(retained!.toJson(), saved.toJson());
            stdout.writeln(
              jsonEncode({
                'kind': 'campaignPrefixStarterSave',
                'path': retainedSavePath,
                'sha256': retainedSaveSha256,
              }),
            );
          }
          await mounted.close(tester);
          mounted = null;
          mounted = await mountConvertedSourceIntroGame(
            tester,
            projectFile,
            manifest,
            repository,
            saved,
            loadActualPlayerServiceCaps: true,
            restored: saveDataFromGameState(saved),
          );
          for (var frame = 0; frame < 50; frame++) {
            mounted.game.update(.025);
            await mounted.game.ready();
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          final restored = mounted.game.gameStateSnapshot;
          expect(PlayerRecoveryPoint.tryRead(restored), expectedRecovery);
          expect(recoveryMarker(restored), const NarrativeValue.boolean(false));
          expect(restored.party, saved.party);
          expect(restored.currentMapId, lab.id);
          expect(restored.playerPosition, saved.playerPosition);
          expect(
            restored.narrativeFactRuntimeState,
            saved.narrativeFactRuntimeState,
          );
          expect(restored.mapInstanceWorldState, saved.mapInstanceWorldState);
          Future<void> expectFullyHealed() async {
            final state = game.gameStateSnapshot;
            final caps = await loadRuntimePlayerServiceRecoveryCaps(
              gameState: state,
              projectRootDirectory: root,
              pokemonConfig: manifest.pokemon,
            );
            for (var index = 0; index < state.party.members.length; index++) {
              final member = state.party.members[index];
              expect(member.currentHp, caps.maxHpByPartyIndex[index]);
              expect(member.statusId, isEmpty);
              for (final move in member.knownMoveIds) {
                expect(
                  member.currentPpByMoveId![move],
                  caps.maxPpByPartyIndex[index]![move],
                );
              }
            }
          }

          Future<void> healAtHome() async {
            expect(game.gameStateSnapshot.currentMapId, pallet.id);
            await walkTo(const GridPos(x: 12, y: 8));
            await step(RuntimeInputControl.up);
            expect(game.gameStateSnapshot.currentMapId, home.id);
            await walkTo(const GridPos(x: 9, y: 7));
            await step(RuntimeInputControl.up);
            expect(
              game.overworldInteractionSnapshot.primaryAction?.request.targetId,
              'ac13_f53fde4243ea4d68dbcba221',
            );
            press(RuntimeInputControl.primary);
            await until(idle, 'voluntary source Mom healing');
            await expectFullyHealed();
            checkpoint('source_mom_healed');
            await walkTo(const GridPos(x: 5, y: 10));
            await step(RuntimeInputControl.down);
            expect(game.gameStateSnapshot.currentMapId, pallet.id);
          }

          Future<void> trainStarterBeforeParcel() async {
            expect(game.gameStateSnapshot.currentMapId, pallet.id);
            currentStage = trainingStage;
            await healAtHome();
            final trainingBattlesStart = battleOutcomes.length;
            trainingExperienceBefore =
                game.gameStateSnapshot.party.members.single.experience;
            while (true) {
              expect(trainingIterations, lessThan(6000));
              expect(trainingMovements, lessThan(6000));
              expect(
                battleOutcomes.length - trainingBattlesStart,
                lessThan(80),
              );
              trainingIterations++;
              try {
                final member = game.gameStateSnapshot.party.members.single;
                if (member.level >= 9 &&
                    member.knownMoveIds.contains('vine_whip')) {
                  if (game.gameStateSnapshot.currentMapId == routeOne.id) {
                    await crossConnection(
                      MapConnectionDirection.south,
                      pallet.id,
                    );
                  }
                  expect(game.gameStateSnapshot.currentMapId, pallet.id);
                  await healAtHome();
                  break;
                }
                if (game.gameStateSnapshot.currentMapId == pallet.id) {
                  await crossConnection(
                    MapConnectionDirection.north,
                    routeOne.id,
                  );
                }
                expect(game.gameStateSnapshot.currentMapId, routeOne.id);
                expect(member.individualId, pokemon.individualId);
                final caps = await loadRuntimePlayerServiceRecoveryCaps(
                  gameState: game.gameStateSnapshot,
                  projectRootDirectory: root,
                  pokemonConfig: manifest.pokemon,
                );
                if (member.currentHp < caps.maxHpByPartyIndex[0]! ||
                    (member.currentPpByMoveId?['tackle'] ?? 0) < 4) {
                  await crossConnection(
                    MapConnectionDirection.south,
                    pallet.id,
                  );
                  await healAtHome();
                  continue;
                }
                final target =
                    game.debugPlayerGridPosition == const GridPos(x: 18, y: 39)
                    ? const GridPos(x: 19, y: 39)
                    : const GridPos(x: 18, y: 39);
                final count = battleOutcomes.length;
                await walkTo(target);
                if (battleOutcomes.length > count) {
                  checkpoint('native_wild_training_battle');
                }
              } on _NativeWildDefeatRecovered {
                trainingRecoveries++;
                expect(trainingRecoveries, lessThanOrEqualTo(20));
                await expectFullyHealed();
                expect(
                  recoveryMarker(game.gameStateSnapshot),
                  const NarrativeValue.boolean(false),
                );
                checkpoint('native_mom_recovery_completed');
                await walkTo(const GridPos(x: 5, y: 10));
                await step(RuntimeInputControl.down);
                expect(game.gameStateSnapshot.currentMapId, pallet.id);
              }
            }
            final victories = battleOutcomes
                .skip(trainingBattlesStart)
                .where(
                  (outcome) =>
                      outcome['isTrainerBattle'] == false &&
                      outcome['victory'] == true,
                );
            expect(victories, isNotEmpty);
            trainingExperienceAfter =
                game.gameStateSnapshot.party.members.single.experience;
            expect(
              trainingExperienceAfter,
              greaterThan(trainingExperienceBefore!),
            );
            expect(
              game.gameStateSnapshot.party.members.single.individualId,
              pokemon.individualId,
            );
            expect(
              game.gameStateSnapshot.party.members.single.provenance,
              pokemon.provenance,
            );
            expect(game.gameStateSnapshot.trainerProfile.badgeIds, isEmpty);
            checkpoint('bulbasaur_learned_vine_whip_without_seeds');
            expect(game.gameStateSnapshot.currentMapId, pallet.id);
          }

          if (continueToParcel) {
            game = mounted.game;
            controller = mounted.controller;
            void expectRecoveryUnchanged() {
              expect(
                PlayerRecoveryPoint.tryRead(game.gameStateSnapshot),
                expectedRecovery,
              );
              expect(
                recoveryMarker(game.gameStateSnapshot),
                const NarrativeValue.boolean(false),
              );
            }

            void expectRivalCompleted() {
              for (final event in [2, 3, 9, 14, 17, 18, 19]) {
                expect(value(':map:9:event:$event:self:A').boolValue, isTrue);
              }
            }

            void expectPokedexVisible(bool visible) {
              expect(
                game
                    .gameStateSnapshot
                    .pauseMenuState
                    .visibilityOverrides[ProjectPauseActionId.pokedex],
                visible,
              );
            }

            Future<void> retainSave(String milestone, GameState state) async {
              if (output == null) return;
              final bytes = await File(repository.filePath).readAsBytes();
              final destination = '$output.$milestone.save.json';
              await File(destination).writeAsBytes(bytes, flush: true);
              expect(await File(destination).readAsBytes(), bytes);
              expect(
                (await ConvertedSourceIntroDiskSave(
                  destination,
                ).load())!.toJson(),
                state.toJson(),
              );
              retainedSaves[milestone] = {
                'path': destination,
                'sha256': crypto.sha256.convert(bytes).toString(),
              };
            }

            expectPokedexVisible(false);
            checkpoint('starter_cold_continued');
            currentStage = 'first_rival_and_laboratory_exit';
            await walkTo(const GridPos(x: 8, y: 9));
            await step(RuntimeInputControl.down);
            await walkTo(const GridPos(x: 8, y: 14));
            await step(RuntimeInputControl.down);
            expect(game.gameStateSnapshot.currentMapId, pallet.id);
            expect(battleCommandCount, greaterThan(0));
            expect(battleOutcomes, hasLength(1));
            expect(
              battleOutcomes.every(
                (outcome) =>
                    outcome['stage'] == 'first_rival_and_laboratory_exit' &&
                    outcome['mapId'] == lab.id &&
                    outcome['trainerId'] ==
                        'source-pbs-7437064774f78b0a09d0ff4a' &&
                    outcome['isTrainerBattle'] == true &&
                    ((outcome['victory'] == true) !=
                        (outcome['defeat'] == true)),
              ),
              isTrue,
            );
            expect(
              game.gameStateSnapshot.party.members.single.individualId,
              pokemon.individualId,
            );
            expect(battleOutcomes.single['sourceRoster'], [
              {'speciesId': 'bulbasaur', 'level': 5},
            ]);
            expectRivalCompleted();
            expectRecoveryUnchanged();
            expectPokedexVisible(false);
            checkpoint('source_first_rival_completed');
            await trainStarterBeforeParcel();

            final viridian = manifest.maps.singleWhere(
              (map) => map.name == 'Viridian City',
            );
            final mart = manifest.maps.singleWhere(
              (map) => map.name == 'Viridian City Poké Mart',
            );
            const parcelId = 'source-item-632264d97a2bdc7d42791d64';
            const ballId = 'source-item-2ecd28fd9e7563a50a9e3f8c';
            int quantity(String itemId) => const BagOperations().quantityOf(
              game.gameStateSnapshot.bag,
              itemId,
            );
            expect(quantity(parcelId), 0);
            final ballsBefore = quantity(ballId);
            currentStage = 'walk_to_viridian';
            await crossConnection(MapConnectionDirection.north, routeOne.id);
            await crossConnection(MapConnectionDirection.north, viridian.id);
            await walkTo(const GridPos(x: 36, y: 20));
            await step(RuntimeInputControl.up);
            await until(
              () =>
                  game.gameStateSnapshot.currentMapId == mart.id &&
                  quantity(parcelId) == 1 &&
                  idle(),
              'source Mart parcel autorun',
            );
            checkpoint('source_parcel_obtained');
            expect(await game.saveGame(), isTrue);
            final parcelSave = (await repository.load())!;
            await retainSave('parcel', parcelSave);
            await mounted.close(tester);
            mounted = null;
            mounted = await mountConvertedSourceIntroGame(
              tester,
              projectFile,
              manifest,
              repository,
              parcelSave,
              loadActualPlayerServiceCaps: true,
              restored: saveDataFromGameState(parcelSave),
            );
            game = mounted.game;
            controller = mounted.controller;
            await until(idle, 'cold continue with source parcel');
            expect(quantity(parcelId), 1);
            expect(game.gameStateSnapshot.currentMapId, mart.id);
            expect(value(':map:12:event:22:self:A').boolValue, isTrue);
            expectRecoveryUnchanged();
            expectPokedexVisible(false);
            currentStage = 'return_parcel_to_oak';
            await walkTo(const GridPos(x: 6, y: 9));
            await step(RuntimeInputControl.down);
            expect(game.gameStateSnapshot.currentMapId, viridian.id);
            await crossConnection(MapConnectionDirection.south, routeOne.id);
            await crossConnection(MapConnectionDirection.south, pallet.id);
            await walkTo(const GridPos(x: 22, y: 14));
            await step(RuntimeInputControl.up);
            expect(game.gameStateSnapshot.currentMapId, lab.id);
            expectRivalCompleted();
            expect(
              battleOutcomes.where(
                (battle) => battle['isTrainerBattle'] == true,
              ),
              hasLength(1),
            );
            await walkTo(const GridPos(x: 8, y: 6));
            await step(RuntimeInputControl.up);
            expect(
              game.overworldInteractionSnapshot.primaryAction?.request.targetId,
              'ac13_3fae306e4da429e5dfaf7bbf',
            );
            press(RuntimeInputControl.primary);
            await until(
              () =>
                  quantity(parcelId) == 0 &&
                  value(':switch:60').boolValue == true &&
                  idle(),
              'source Oak parcel delivery and Pokedex',
            );
            expect(quantity(ballId), ballsBefore + 5);
            expect(value(':player:has_pokedex').boolValue, isTrue);
            expect(value(':player:pokedex:unlocked:1').boolValue, isTrue);
            expect(game.gameStateSnapshot.trainerProfile.badgeIds, isEmpty);
            expectPokedexVisible(true);
            expectRivalCompleted();
            expectRecoveryUnchanged();
            expect(
              battleOutcomes.where(
                (battle) => battle['isTrainerBattle'] == true,
              ),
              hasLength(1),
            );
            checkpoint('source_parcel_delivered_pokedex_obtained');
            expect(await game.saveGame(), isTrue);
            final delivered = (await repository.load())!;
            await retainSave('parcel-delivered', delivered);
            await mounted.close(tester);
            mounted = null;
            mounted = await mountConvertedSourceIntroGame(
              tester,
              projectFile,
              manifest,
              repository,
              delivered,
              loadActualPlayerServiceCaps: true,
              restored: saveDataFromGameState(delivered),
            );
            game = mounted.game;
            controller = mounted.controller;
            final lineCount = dialogues.length;
            await until(idle, 'cold continue after source parcel delivery');
            expect(dialogues, hasLength(lineCount));
            expect(quantity(parcelId), 0);
            expect(quantity(ballId), ballsBefore + 5);
            expect(game.gameStateSnapshot.party, delivered.party);
            expect(
              game.gameStateSnapshot.narrativeFactRuntimeState,
              delivered.narrativeFactRuntimeState,
            );
            expectPokedexVisible(true);
            expectRivalCompleted();
            expectRecoveryUnchanged();
            expect(
              battleOutcomes.where(
                (battle) => battle['isTrainerBattle'] == true,
              ),
              hasLength(1),
            );
            checkpoint('parcel_delivery_cold_continued');
          }
          await Future.wait(serviceCommands);
          expect(await protectedProjectHashes(), beforeProjectHashes);
          if (output != null) {
            successfulResult = {
              'kind': 'genuineSourceCampaignPrefixJourney',
              'projectPath': root,
              'checkpoints': checkpoints,
              'movies': movies,
              'dialogues': dialogues,
              'modals': modalities,
              'nativeNewGameFlow': true,
              'identitySceneExecuted': true,
              'qaFlagsSeeded': false,
              'qaPartySeeded': false,
              'qaPositionSeeded': false,
              'movements': 'nativeKeyboardOnly',
              'savedAndColdContinued': true,
              'savedRecoveryPoint': {
                'mapId': PlayerRecoveryPoint.tryRead(saved)!.mapId,
                'position': PlayerRecoveryPoint.tryRead(saved)!.position
                    .toJson(),
                'facing': PlayerRecoveryPoint.tryRead(saved)!.facing.name,
              },
              'recoveryMarkerOutsideDefeat': recoveryMarker(saved).boolValue,
              'retainedSaves': retainedSaves,
              'starterSavePath': retainedSavePath,
              'starterSaveSha256': retainedSaveSha256,
              'coldReloadReason': 'saveRestore',
              'parcelJourneyRequested': continueToParcel,
              'parcelJourneyQualified': continueToParcel,
              'firstBadgeJourneyQualified': false,
              'battleCommands': battleCommandCount,
              'starterTrainedBeforeParcel': continueToParcel,
              'trainingRecoveries': trainingRecoveries,
              'trainingExperienceBefore': trainingExperienceBefore,
              'trainingExperienceAfter': trainingExperienceAfter,
              'trainingIterations': trainingIterations,
              'trainingMovementCommands': trainingMovements,
              'routePolicy': 'dijkstraNonEncounter1Encounter101',
              'battleOutcomes': battleOutcomes,
              'projectManifestAnd383MapsUnchanged': true,
              'scriptsExecuted': 0,
              'aiCalls': 0,
              'defeatRecoveryQualified': false,
              'audibleOutputQualified': false,
              'studioVisualJourneyQualified': false,
            };
          }
        } catch (error, stack) {
          if (output != null) {
            try {
              await File('$output.failure.json').writeAsString(
                jsonEncode({
                  'kind': 'genuineSourceCampaignJourneyFailure',
                  'projectPath': root,
                  'stage': currentStage,
                  'elapsedMs': watch.elapsedMilliseconds,
                  'error': error.toString(),
                  'stackTrace': stack.toString(),
                  'state': mounted?.game.gameStateSnapshot.toJson(),
                  'checkpoints': checkpoints,
                  'battleCommands': battleCommandCount,
                  'battleOutcomes': battleOutcomes,
                  'trainingRecoveries': trainingRecoveries,
                  'trainingExperienceBefore': trainingExperienceBefore,
                  'trainingExperienceAfter': trainingExperienceAfter,
                  'trainingIterations': trainingIterations,
                  'trainingMovementCommands': trainingMovements,
                  'qaFlagsSeeded': false,
                  'qaPartySeeded': false,
                  'qaPositionSeeded': false,
                  'journeyComplete': false,
                  'firstBadgeJourneyQualified': false,
                }),
                flush: true,
              );
            } catch (diagnosticError) {
              stdout.writeln(
                jsonEncode({
                  'kind': 'campaignFailureReceiptWriteFailed',
                  'error': diagnosticError.toString(),
                  'originalFailure': error.toString(),
                }),
              );
            }
          }
          rethrow;
        } finally {
          await mounted?.close(tester);
          await directory.delete(recursive: true);
          expect(await protectedProjectHashes(), beforeProjectHashes);
        }
        if (output != null) {
          expect(successfulResult, isNotNull);
          successfulResult!['playerClosed'] = true;
          await File(output)
              .writeAsString(jsonEncode(successfulResult), flush: true);
        }
      });
    },
    skip: root == null,
    timeout: Timeout(Duration(minutes: continueToParcel ? 40 : 6)),
  );
}

final class _NativeWildDefeatRecovered implements Exception {
  const _NativeWildDefeatRecovered();
}
