import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

import 'source_converted_gym_reward_journey_test.dart'
    show installConvertedQaHeadlessAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(_installHeadlessAudio);
  final root = Platform.environment['AVELUNE_INTRO_PROJECT'];
  final output = Platform.environment['AVELUNE_INTRO_RECEIPT'];
  final genuineNewGame =
      Platform.environment['AVELUNE_INTRO_GENUINE_NEW_GAME'] == '1';
  for (final variant in ['preset', 'custom', 'cancel']) {
    testWidgets(
      'converted Intro $variant uses empty party and transactional native name input',
      (tester) async {
        await tester.runAsync(() async {
          final projectFile = path.join(root!, 'project.json');
          final manifest = await loadProjectManifestFromFile(projectFile);
          expect(manifest.maps, hasLength(3));
          final scene = manifest.scenes.singleWhere(
            (scene) => scene.graph.nodes.any(
              (node) =>
                  node.payload is SceneActionPayload &&
                  (node.payload as SceneActionPayload).interactiveCommand
                      is SceneInputTextToFactInteractiveCommand,
            ),
          );
          final command = scene.graph.nodes
              .map((node) => node.payload)
              .whereType<SceneActionPayload>()
              .map((payload) => payload.interactiveCommand)
              .whereType<SceneInputTextToFactInteractiveCommand>()
              .single;
          expect(command.presetValues, ['Blue', 'Gary', 'Michael']);
          expect(command.constraints.minGraphemes, 1);
          expect(command.constraints.maxGraphemes, 7);
          final fresh = manifest.facts.singleWhere(
            (fact) => fact.description.contains(':nativeFreshEntry:') == true,
          );
          final completed = manifest.facts.singleWhere(
            (fact) => fact.description.endsWith(':switch:99') == true,
          );
          final rival = manifest.facts.singleWhere(
            (fact) => fact.id == command.factId,
          );
          expect(fresh.initialValue, NarrativeValue.boolean(false));
          expect(rival.initialValue, NarrativeValue.string(''));
          final intro = manifest.maps.singleWhere((map) => map.name == 'Intro');
          final home = manifest.maps.singleWhere(
            (map) => map.name.endsWith("PN's House"),
          );
          final initial = genuineNewGame
              ? await createConvertedSourceFreshGame(projectFile, variant)
              : GameState(
                  saveId: 'isolated-converted-intro-$variant',
                  currentMapId: intro.id,
                  playerPosition: const GridPos(x: 0, y: 0),
                  trainerProfile: const TrainerProfile(
                    name: 'Isolated Intro QA',
                  ),
                  narrativeFactRuntimeState: NarrativeFactRuntimeState(
                    overridesByFactId: {fresh.id: true},
                  ),
                );
          expect(initial.party.members, isEmpty);
          expect(initial.pokemonStorage, const PokemonStorage());
          final hashes = await _hashProject(root);
          final directory = await Directory.systemTemp.createTemp(
            'converted-intro-save-',
          );
          final repository = ConvertedSourceIntroDiskSave(
            path.join(directory.path, 'game.json'),
          );
          ConvertedSourceIntroMounted? mounted;
          final opening = <String>[];
          final closing = <String>[];
          final requests = <Map<String, dynamic>>[];
          var rejectedCandidate = false;
          var nameConfirmed = false;
          try {
            mounted = await mountConvertedSourceIntroGame(
              tester,
              projectFile,
              manifest,
              repository,
              initial,
            );
            final game = mounted.game;
            final controller = mounted.controller;
            var handled = '';
            var done = false;
            for (var tick = 0; tick < 15000; tick++) {
              final movie = game.debugCinematicDialogueLine;
              if (movie != null) {
                if (opening.isEmpty || opening.last != movie) {
                  opening.add(movie);
                }
                _primary(game);
              }
              final dialogue = game.dialoguePresentationListenable.value;
              if (dialogue != null) {
                if (closing.isEmpty || closing.last != dialogue.fullText) {
                  closing.add(dialogue.fullText);
                }
                _primary(game);
              }
              final modal = controller.worldServiceSnapshot;
              if (modal?.content case final SceneInteractionRequest request) {
                final key = '${request.requestId}:${request.revision}';
                if (handled != key) {
                  handled = key;
                  requests.add(request.toJson());
                  expect(_value(game, rival), NarrativeValue.string(''));
                  expect(await game.saveGame(), isFalse);
                  expect(await File(repository.filePath).exists(), isFalse);
                  if (variant == 'cancel' &&
                      rejectedCandidate &&
                      request is SceneChoiceInteractionRequest) {
                    expect(
                      _value(game, completed),
                      NarrativeValue.boolean(false),
                    );
                    expect(_value(game, fresh), NarrativeValue.boolean(true));
                    done = true;
                    break;
                  }
                  final SceneInteractionResult answer;
                  if (request is SceneChoiceInteractionRequest) {
                    expect(request.options.map((option) => option.id), [
                      'custom',
                      'preset:0',
                      'preset:1',
                      'preset:2',
                    ]);
                    answer = SceneInteractionResult.choiceSelected(
                      requestId: request.requestId,
                      revision: request.revision,
                      selectedOptionId: variant == 'preset'
                          ? 'preset:1'
                          : 'custom',
                    );
                  } else if (request is SceneTextInteractionRequest) {
                    for (final invalid in ['', '12345678']) {
                      final invalidResult = await controller
                          .dispatchWorldService(
                            RuntimeWorldServiceCommand(
                              action: RuntimeWorldServiceAction.confirm,
                              snapshotRevision: modal!.revision,
                              interactionResult:
                                  SceneInteractionResult.textSubmitted(
                                    requestId: request.requestId,
                                    revision: request.revision,
                                    value: invalid,
                                  ),
                            ),
                          );
                      expect(
                        invalidResult.status,
                        RuntimeWorldServiceCommandStatus.unavailable,
                      );
                    }
                    answer = SceneInteractionResult.textSubmitted(
                      requestId: request.requestId,
                      revision: request.revision,
                      value: variant == 'cancel' ? 'Shadow' : 'Éli🌟',
                    );
                  } else if (request is SceneConfirmationInteractionRequest) {
                    final accept =
                        variant == 'preset' ||
                        (variant == 'custom' && rejectedCandidate);
                    if (accept) nameConfirmed = true;
                    if (variant == 'cancel') {
                      answer = SceneInteractionResult.cancelled(
                        requestId: request.requestId,
                        revision: request.revision,
                        reason: SceneInteractionCancellationReason.user,
                      );
                    } else {
                      answer = SceneInteractionResult.confirmed(
                        requestId: request.requestId,
                        revision: request.revision,
                        value: accept,
                      );
                    }
                    if (!accept) rejectedCandidate = true;
                  } else {
                    fail('Unexpected Intro modal ${request.kind}');
                  }
                  final result = await controller.dispatchWorldService(
                    RuntimeWorldServiceCommand(
                      action: answer is SceneCancelledInteractionResult
                          ? RuntimeWorldServiceAction.cancel
                          : RuntimeWorldServiceAction.confirm,
                      snapshotRevision: modal!.revision,
                      interactionResult: answer,
                    ),
                  );
                  expect(
                    result.status,
                    anyOf(
                      RuntimeWorldServiceCommandStatus.accepted,
                      RuntimeWorldServiceCommandStatus.cancelled,
                    ),
                  );
                }
              }
              if (variant != 'cancel' &&
                  _idle(game) &&
                  game.gameStateSnapshot.currentMapId == home.id) {
                done = true;
                break;
              }
              if (tick % 1500 == 0) {
                stdout.writeln(
                  jsonEncode({
                    'kind': 'introProgress',
                    'variant': variant,
                    'tick': tick,
                    'phase': game.debugFlowPhaseName,
                    'map': game.gameStateSnapshot.currentMapId,
                    'opening': opening.length,
                    'closing': closing.length,
                    'modal': controller.worldServiceSnapshot?.content
                        .toString(),
                  }),
                );
              }
              await _tick(game);
            }
            expect(
              done,
              isTrue,
              reason: 'Intro did not reach its expected frontier',
            );
            expect(opening, hasLength(8));
            expect(game.gameStateSnapshot.party.members, isEmpty);
            expect(
              game.gameStateSnapshot.pokemonStorage,
              initial.pokemonStorage,
            );
            expect(game.gameStateSnapshot.bag, initial.bag);
            expect(
              game.gameStateSnapshot.trainerProfile,
              initial.trainerProfile,
            );
            var coldReloaded = false;
            if (variant != 'cancel') {
              expect(nameConfirmed, isTrue);
              final expectedName = variant == 'preset' ? 'Gary' : 'Éli🌟';
              expect(_value(game, rival), NarrativeValue.string(expectedName));
              expect(_value(game, completed), NarrativeValue.boolean(true));
              expect(_value(game, fresh), NarrativeValue.boolean(false));
              expect(game.debugPlayerGridPosition, const GridPos(x: 27, y: 8));
              expect(closing.join(' '), contains(expectedName));
              expect(closing.length, 4);
              expect(await game.saveGame(), isTrue);
              final saved = (await ConvertedSourceIntroDiskSave(
                repository.filePath,
              ).load())!;
              final state = game.gameStateSnapshot;
              await mounted.close(tester);
              mounted = null;
              mounted = await mountConvertedSourceIntroGame(
                tester,
                projectFile,
                manifest,
                ConvertedSourceIntroDiskSave(repository.filePath),
                state,
                restored: saveDataFromGameState(saved),
              );
              for (var tick = 0; tick < 100; tick++) {
                await _tick(mounted.game);
              }
              expect(_idle(mounted.game), isTrue);
              expect(mounted.game.debugCinematicDialogueLine, isNull);
              expect(mounted.game.dialoguePresentationListenable.value, isNull);
              expect(mounted.controller.worldServiceSnapshot, isNull);
              expect(mounted.game.gameStateSnapshot.currentMapId, home.id);
              expect(
                mounted.game.debugPlayerGridPosition,
                const GridPos(x: 27, y: 8),
              );
              expect(
                _value(mounted.game, rival),
                NarrativeValue.string(expectedName),
              );
              expect(
                _value(mounted.game, completed),
                NarrativeValue.boolean(true),
              );
              expect(
                _value(mounted.game, fresh),
                NarrativeValue.boolean(false),
              );
              expect(mounted.game.gameStateSnapshot.party.members, isEmpty);
              expect(
                mounted.game.gameStateSnapshot.pokemonStorage,
                initial.pokemonStorage,
              );
              coldReloaded = true;
            } else {
              expect(nameConfirmed, isFalse);
              expect(_value(game, rival), NarrativeValue.string(''));
              expect(await File(repository.filePath).exists(), isFalse);
            }
            expect(await _hashProject(root), hashes);
            final receipt = {
              'kind': 'convertedSourceIntroJourney',
              'variant': variant,
              'projectPath': root,
              'sourceMapId': 1,
              'sourceEventId': 1,
              'rivalName': _value(mounted.game, rival).stringValue,
              'introCompletedSwitch99': _value(
                mounted.game,
                completed,
              ).boolValue,
              'freshAuthorization': _value(mounted.game, fresh).boolValue,
              'mapId': mounted.game.gameStateSnapshot.currentMapId,
              'position': mounted.game.debugPlayerGridPosition.toJson(),
              'openingDialogues': opening,
              'closingDialogues': closing,
              'requests': requests,
              'candidateRejectedBeforeConfirmation': rejectedCandidate,
              'actualNativeModalController': true,
              'partyInjected': false,
              'freshAuthorizationFactSeededForIsolatedQa': !genuineNewGame,
              'nativeNewGameFlowWithIdentityScene': genuineNewGame,
              'campaignNewGameFactoryQualified': false,
              'sourceScriptsExecuted': false,
              'aiCalls': 0,
              'coldDiskReload': coldReloaded,
              'unconfirmedNamePersisted': false,
              'projectFilesUnchanged': true,
              'sourceMusicAbsentOmitted': true,
              'audibleOutputQualified': false,
              'sourcePictureChoreographyQualified': false,
            };
            if (output != null) {
              await File('$output.$variant.json')
                  .writeAsString(jsonEncode(receipt), flush: true);
            }
            stdout.writeln(jsonEncode(receipt));
          } finally {
            await mounted?.close(tester);
            await directory.delete(recursive: true);
          }
        });
      },
      skip: root == null,
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }
}

Future<GameState> createConvertedSourceFreshGame(
  String projectFile,
  String variant,
) async {
  final flow = RuntimeProjectNewGameFlowPort(
    projectFilePath: () async => projectFile,
    initialMapPreloader: RuntimeInitialMapPreloader(
      projectFilePath: () async => projectFile,
      loadSave: (_) async => null,
      tilesetImageLoader: (
        paths, {
        transparentColorByTilesetId = const {},
        onProgress,
      }) async => {},
    ),
  );
  final port = HeadlessSceneInteractionPort();
  final identities = <SceneInteractionRequest>[];
  final subscription = port.requests.listen((request) {
    identities.add(request);
    final SceneInteractionResult result;
    if (request is SceneTextInteractionRequest) {
      result = SceneInteractionResult.textSubmitted(
        requestId: request.requestId,
        revision: request.revision,
        value: 'Yoahn',
      );
    } else if (request is SceneSelectionInteractionRequest) {
      result = SceneInteractionResult.selectionSubmitted(
        requestId: request.requestId,
        revision: request.revision,
        selectedOptionIds: [
          variant == 'custom'
              ? request.options.last.id
              : request.options.first.id,
        ],
      );
    } else {
      throw StateError(
        'The source identity Scene requested an unexpected interaction.',
      );
    }
    expect(port.resolve(result).isAccepted, isTrue);
  });
  try {
    final preparation = await flow.prepare();
    expect(preparation.project.newGame.enabled, isTrue);
    expect(preparation.project.newGame.initialParty, isEmpty);
    expect(preparation.project.newGame.starterOptions, isEmpty);
    final runner = preparation.preSessionRunner;
    expect(runner, isNotNull);
    final draft = await runner!.run(
      runId: 'source-fresh-$variant',
      draft: NewGameDraft.start(
        draftId: 'source-fresh-$variant',
        projectRevision: preparation.projectRevision,
        slotId: 'slot1',
        config: preparation.project.newGame,
      ),
      interactions: port,
    );
    expect(identities.whereType<SceneTextInteractionRequest>(), hasLength(1));
    expect(
      identities.whereType<SceneSelectionInteractionRequest>(),
      hasLength(1),
    );
    expect(identities, hasLength(2));
    final revision = await flow.readCurrentProjectRevision();
    final committed = commitNewGameDraft(
      journal: NewGameSeedCommitJournal.empty(),
      operationId: 'source-fresh-$variant',
      currentProjectRevision: revision,
      expectedDraftRevision: draft.revision,
      draft: draft,
    );
    expect(committed.status, NewGameSeedCommitStatus.committed);
    final state = createNewGameStateFromSeed(
      project: preparation.project,
      startMap: preparation.startMap,
      initialRecoveryMap: preparation.initialRecoveryMap,
      seed: committed.seed!,
      currentProjectRevision: revision,
      tileWidthPx: preparation.project.settings.tileWidth,
      tileHeightPx: preparation.project.settings.tileHeight,
    );
    expect(state.trainerProfile.name, 'Yoahn');
    expect(state.party.members, isEmpty);
    expect(
      PlayerRecoveryPoint.tryRead(state)?.mapId,
      preparation.initialRecoveryMap!.id,
    );
    return state;
  } finally {
    await subscription.cancel();
    port.close();
    flow.clear();
  }
}

NarrativeValue _value(PlayableMapGame game, NarrativeFactDefinition fact) =>
    game.gameStateSnapshot.narrativeFactRuntimeState.valueFor(fact.id) ??
    fact.initialValue;

Future<void> _tick(PlayableMapGame game) async {
  game.update(.025);
  await game.ready();
  await Future<void>.delayed(const Duration(milliseconds: 1));
}

void _primary(PlayableMapGame game) {
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.primary),
  );
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.primary),
  );
}

bool _idle(PlayableMapGame game) =>
    game.debugFlowPhaseName == 'overworld' &&
    game.debugCompletedMapActivationDispatchCount > 0 &&
    !game.debugIsEntityAutorunInFlight &&
    !game.debugIsMapActivationDispatchInFlight &&
    !game.debugIsNarrativeSpatialDispatchInFlight &&
    !game.debugIsNarrativeOutcomeWorkInFlight &&
    !game.debugIsLoadActivationWorkInFlight &&
    !game.debugHasPendingDialogueLoad &&
    !game.debugHasPendingMapTransition &&
    !game.debugIsPlayerStepping;

Future<ConvertedSourceIntroMounted> mountConvertedSourceIntroGame(
  WidgetTester tester,
  String projectFile,
  ProjectManifest manifest,
  ConvertedSourceIntroDiskSave repository,
  GameState initial, {
  SaveData? restored,
}) async {
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile,
    mapId: initial.currentMapId,
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectFile,
    initialGameState: restored == null ? initial : null,
    saveData: restored,
    initialMapActivationReason: restored == null
        ? MapActivationReason.initialBoot
        : MapActivationReason.saveRestore,
    saveRepository: repository,
  );
  final controller = PlayerServiceRuntimeController.contextual(
    currentGameState: () => game.playerServiceGameStateSnapshot,
    commitAndSave: game.commitAndSavePlayerServiceState,
    setInputLocked: (locked) => game.setExternalInputLock(
      RuntimeExternalInputLock.playerService,
      locked: locked,
    ),
    loadRecoveryCaps: (_) async =>
        const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
    projectRootDirectory: path.dirname(projectFile),
    pokemonConfig: manifest.pokemon,
  );
  game.setPlayerServiceRuntimeController(controller);
  try {
    game.onGameResize(Vector2(640, 480));
    game.setDialogueFlutterOverlayPreferred(true);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GameWidget<PlayableMapGame>(game: game),
      ),
    );
    await game.toBeLoaded();
    await game.ready();
    game.pauseEngine();
    return ConvertedSourceIntroMounted(game, controller);
  } catch (_) {
    await controller.dispose();
    game.onRemove();
    rethrow;
  }
}

final class ConvertedSourceIntroMounted {
  ConvertedSourceIntroMounted(this.game, this.controller);
  final PlayableMapGame game;
  final PlayerServiceRuntimeController controller;
  Future<void> close(WidgetTester tester) async {
    await controller.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    game.onRemove();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await tester.pumpWidget(const SizedBox.shrink());
  }
}

final class ConvertedSourceIntroDiskSave extends FileGameSaveRepository {
  ConvertedSourceIntroDiskSave(this.filePath);
  final String filePath;
  @override
  Future<String> getSaveFilePath() async => filePath;
}

Future<Map<String, String>> _hashProject(String root) async {
  final hashes = <String, String>{};
  await for (final entity in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    if (entity is File) {
      hashes[path.relative(entity.path, from: root)] = crypto.sha256
          .convert(await entity.readAsBytes())
          .toString();
    }
    if (entity is Link) fail('Project symlink: ${entity.path}');
  }
  return hashes;
}

void _installHeadlessAudio({bool completePlayback = false}) =>
    installConvertedQaHeadlessAudio(completePlayback: completePlayback);
