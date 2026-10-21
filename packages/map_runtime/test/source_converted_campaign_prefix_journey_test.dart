import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
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
  testWidgets(
    'genuine new game walks from Intro to its source laboratory starter',
    (tester) async {
      await tester.runAsync(() async {
        final projectFile = path.join(root!, 'project.json');
        final manifest = await loadProjectManifestFromFile(projectFile);
        expect(manifest.maps, hasLength(383));
        final intro = manifest.maps.singleWhere((m) => m.name == 'Intro');
        final home = manifest.maps.singleWhere(
          (m) => m.name.endsWith("PN's House"),
        );
        final pallet = manifest.maps.singleWhere(
          (m) => m.name == 'Pallet Town',
        );
        final lab = manifest.maps.singleWhere((m) => m.name == "Oak's Lab");
        final initial = await createConvertedSourceFreshGame(
          projectFile,
          'preset',
        );
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
        final maps = <String, MapData>{};
        var handledModal = '', currentStage = 'intro';
        final blockedEdges = <(GridPos, GridPos)>{};
        final watch = Stopwatch()..start();
        try {
          mounted = await mountConvertedSourceIntroGame(
            tester,
            projectFile,
            manifest,
            repository,
            initial,
          );
          final game = mounted.game, controller = mounted.controller;
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
              'elapsedMs': watch.elapsedMilliseconds,
            };
            checkpoints.add(row);
            stdout.writeln(
              jsonEncode({'kind': 'campaignPrefixProgress', ...row}),
            );
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
              game.debugCinematicDialogueLine == null &&
              game.dialoguePresentationListenable.value == null &&
              controller.worldServiceSnapshot == null;
          Future<void> tick() async {
            game.update(.025);
            await game.ready();
            await Future<void>.delayed(const Duration(milliseconds: 1));
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

          Future<List<GridPos>> routeTo(
            GridPos goal,
            Set<GridPos> avoid,
          ) async {
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
            final queue = Queue<GridPos>()..add(start),
                previous = <GridPos, GridPos?>{start: null};
            while (queue.isNotEmpty) {
              final cell = queue.removeFirst();
              if (cell == goal) break;
              for (final delta in [(0, -1), (-1, 0), (1, 0), (0, 1)]) {
                final next = GridPos(
                  x: cell.x + delta.$1,
                  y: cell.y + delta.$2,
                );
                if (previous.containsKey(next) ||
                    avoid.contains(next) ||
                    blockedEdges.contains((cell, next)) ||
                    world.isBlocked(next.x, next.y)) {
                  continue;
                }
                previous[next] = cell;
                queue.add(next);
              }
            }
            if (!previous.containsKey(goal)) {
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
          }

          Future<void> walkTo(
            GridPos goal, {
            Set<GridPos> avoid = const {},
          }) async {
            for (var attempt = 0; attempt < 250; attempt++) {
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
              if (game.debugPlayerGridPosition == before) {
                blockedEdges.add((before, next));
              }
            }
            fail(
              'Keyboard walk did not reach $goal from ${game.debugPlayerGridPosition}',
            );
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
          String? retainedSavePath, retainedSaveSha256;
          if (output != null) {
            final bytes = await File(repository.filePath).readAsBytes();
            retainedSavePath = '$output.starter.save.json';
            retainedSaveSha256 = crypto.sha256.convert(bytes).toString();
            await File(retainedSavePath).writeAsBytes(bytes, flush: true);
            expect(await File(retainedSavePath).readAsBytes(), bytes);
            final retained = await ConvertedSourceIntroDiskSave(retainedSavePath).load();
            expect(retained!.toJson(), saved.toJson());
            stdout.writeln(jsonEncode({'kind': 'campaignPrefixStarterSave',
              'path': retainedSavePath, 'sha256': retainedSaveSha256}));
          }
          await mounted.close(tester);
          mounted = null;
          mounted = await mountConvertedSourceIntroGame(
            tester,
            projectFile,
            manifest,
            repository,
            saved,
            restored: saveDataFromGameState(saved),
          );
          for (var frame = 0; frame < 50; frame++) {
            mounted.game.update(.025);
            await mounted.game.ready();
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          final restored = mounted.game.gameStateSnapshot;
          expect(restored.party, saved.party);
          expect(restored.currentMapId, lab.id);
          expect(restored.playerPosition, saved.playerPosition);
          expect(
            restored.narrativeFactRuntimeState,
            saved.narrativeFactRuntimeState,
          );
          expect(restored.mapInstanceWorldState, saved.mapInstanceWorldState);
          if (output != null) {
            await File(output).writeAsString(
              jsonEncode({
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
                'starterSavePath': retainedSavePath,
                'starterSaveSha256': retainedSaveSha256,
                'coldReloadReason': 'saveRestore',
                'scriptsExecuted': 0,
                'aiCalls': 0,
                'defeatRecoveryQualified': false,
                'audibleOutputQualified': false,
                'studioVisualJourneyQualified': false,
              }),
              flush: true,
            );
          }
        } finally {
          await mounted?.close(tester);
          await directory.delete(recursive: true);
        }
      });
    },
    skip: root == null,
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
