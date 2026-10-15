import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifestPath =
      Platform.environment['AVELUNE_KANTO_CENTER_REFERENCE_MANIFEST'];
  final nativeRoot =
      Platform.environment['AVELUNE_NATIVE_TRAINER_REFERENCE_ROOT'];
  final skip = manifestPath == null || nativeRoot == null;
  late Map<String, dynamic> reference;
  late PlayerPokemon damaged;
  late RuntimePlayerServiceRecoveryCaps caps;
  late ProjectPokemonConfig nativePokemon;
  late Map<String, String> originalFiles;

  setUpAll(() async {
    if (skip) return;
    reference = Map<String, dynamic>.from(
      jsonDecode(await File(manifestPath).readAsString()) as Map,
    );
    expect(reference['nativeWriterVerified'], isTrue);
    expect(reference['strictOpenDiagnostics'], isEmpty);
    expect(
      reference['sourceSnapshotHash'],
      'fd1e6e73879d90d3dbedffcd703e5bac5b3b58c9fc8a9186ce1e5d98233dbe4e',
    );
    expect(reference['sourceScriptsExecuted'], 0);
    expect(reference['fullSourceServiceParityQualified'], isFalse);
    originalFiles = await _hashes(reference['projectPath'] as String);
    final native = jsonDecode(
      await File('$nativeRoot/trainer-seed-reference.json').readAsString(),
    ) as Map;
    final pokemon = nativePokemon = ProjectPokemonConfig.fromJson(
      Map<String, dynamic>.from(native['pokemon'] as Map),
    );
    final member = (native['trainers'] as List)
        .map(
          (raw) => ProjectTrainerEntry.fromJson(
            Map<String, dynamic>.from(raw as Map),
          ),
        )
        .expand((trainer) => trainer.team)
        .firstWhere((member) => member.speciesId == 'charmander');
    final moves = await RuntimeMoveCatalogLoader().load(
      projectRootDirectory: nativeRoot,
      pokemonConfig: pokemon,
    );
    final seed = await RuntimeBattleCombatantSeedBuilder()
        .buildTrainerPsdkCombatantSeed(
          projectRootDirectory: nativeRoot,
          pokemonConfig: pokemon,
          movesCatalog: moves,
          itemCatalog: ItemCatalogSnapshot.empty(),
          teamMember: member,
          trainerName: 'Native test party',
        );
    expect(seed.filteredMoveDiagnostics, isEmpty);
    damaged = PlayerPokemon(
      speciesId: seed.speciesId,
      natureId: 'hardy',
      abilityId: seed.abilityId,
      level: seed.level,
      currentHp: 1,
      statusId: 'psn',
      knownMoveIds: seed.moves.map((move) => move.id).toList(),
      currentPpByMoveId: {for (final move in seed.moves) move.id: 0},
    );
    final playerSeed = await RuntimeBattleCombatantSeedBuilder()
        .buildPlayerPsdkCombatantSeed(
          projectRootDirectory: nativeRoot,
          pokemonConfig: pokemon,
          movesCatalog: moves,
          itemCatalog: ItemCatalogSnapshot.empty(),
          playerPokemon: damaged,
        );
    caps = RuntimePlayerServiceRecoveryCaps(
      maxHpByPartyIndex: {0: playerSeed.maxHp},
      maxPpByPartyIndex: {
        0: {for (final move in seed.moves) move.id: move.pp},
      },
    );
  });

  tearDownAll(() async {
    if (!skip) {
      expect(await _hashes(reference['projectPath'] as String), originalFiles);
    }
  });

  for (final choice in ['yes', 'no', 'cancel']) {
    testWidgets(
      'original Center nurse $choice uses native service and preserves disk state',
      (tester) async {
        final bundle = (await tester.runAsync(
          () => loadRuntimeMapBundle(
            projectFilePath: reference['projectFilePath'] as String,
            mapId: reference['nativeMapId'] as String,
          ),
        ))!;
        final nurse = bundle.map.entities.singleWhere(
          (entity) => entity.id == reference['nativeNurseId'],
        );
        expect(nurse.pos, const GridPos(x: 9, y: 4));
        expect(nurse.npc!.counterInteractionSides, [EntityFacing.south]);
        final saveRoot = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('center-nurse-runtime-'),
        ))!;
        final repository = _DiskSave('${saveRoot.path}/save.json');
        final audio = _AudioTrace();
        final game = PlayableMapGame(
          bundle: bundle,
          projectFilePath: reference['projectFilePath'] as String,
          saveRepository: repository,
          initialGameState: GameState(
            saveId: 'center-$choice',
            currentMapId: bundle.map.id,
            playerPosition: const GridPos(x: 9, y: 6),
            playerFacing: EntityFacing.north,
            party: PlayerParty(members: [damaged]),
          ),
          dialogueFeedbackPlaybackPort: audio,
          runtimePlayerPokemonProgressionCatalogLoader:
              ({
                required gameState,
                required projectRootDirectory,
                required pokemonConfig,
              }) => loadRuntimePlayerPokemonProgressionCatalogs(
                gameState: gameState,
                projectRootDirectory: nativeRoot!,
                pokemonConfig: nativePokemon,
              ),
          musicService: RuntimeMusicService(
            driver: _SilentMusic(),
            fadeDelay: (_) async {},
          ),
        );
        var capLoads = 0;
        final locks = <bool>[];
        final service = PlayerServiceRuntimeController.contextual(
          currentGameState: () => game.playerServiceGameStateSnapshot,
          commitAndSave: game.commitAndSavePlayerServiceState,
          setInputLocked: (locked) {
            locks.add(locked);
            game.setExternalInputLock(
              RuntimeExternalInputLock.playerService,
              locked: locked,
            );
          },
          loadRecoveryCaps: (state) async {
            capLoads++;
            return loadRuntimePlayerServiceRecoveryCaps(
              gameState: state,
              projectRootDirectory: nativeRoot!,
              pokemonConfig: nativePokemon,
            );
          },
        );
        game.setPlayerServiceRuntimeController(service);
        try {
          game.onGameResize(Vector2(640, 480));
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: GameWidget<PlayableMapGame>(game: game),
            ),
          );
          await _until(tester, game, () => game.isLoaded);
          await tester.runAsync(() async => await game.toBeLoaded());
          await _until(tester, game, () => _ready(game));
          expect(
            game.gameStateSnapshot.playerPosition,
            const GridPos(x: 9, y: 6),
          );
          final before = game.gameStateSnapshot.party;
          expect(PlayerRecoveryPoint.tryRead(game.gameStateSnapshot), isNull);
          _press(game, RuntimeInputControl.primary);
          final greetings = <String>{};
          await _until(tester, game, () {
            final current = game.dialoguePresentationListenable.value;
            if (current?.mode == DialoguePresentationMode.choices) return true;
            if (current?.mode == DialoguePresentationMode.line) {
              greetings.add(current!.fullText);
              _advance(game);
            }
            return false;
          });
          expect(
            greetings,
            contains('Hello, and welcome to the Pokémon Center.'),
          );
          expect(
            game.dialoguePresentationListenable.value!.choices.map(
              (entry) => entry.label,
            ),
            ['Yes', 'No'],
          );
          expect(capLoads, 0);
          expect(game.gameStateSnapshot.party, before);
          expect(PlayerRecoveryPoint.tryRead(game.gameStateSnapshot), isNull);
          if (choice == 'no') _press(game, RuntimeInputControl.down);
          _press(
            game,
            choice == 'cancel'
                ? RuntimeInputControl.secondary
                : RuntimeInputControl.primary,
          );
          final completion = <String>{};
          await _until(tester, game, () {
            if (_ready(game)) return true;
            final current = game.dialoguePresentationListenable.value;
            if (current?.mode == DialoguePresentationMode.line) {
              completion.add(current!.fullText);
              _advance(game);
            }
            return false;
          });
          final state = game.gameStateSnapshot;
          expect(state.playerPosition, const GridPos(x: 9, y: 6));
          if (choice == 'yes') {
            expect(capLoads, 1);
            expect(locks, [true, false]);
            expect(
              state.party.members.single.currentHp,
              caps.maxHpByPartyIndex[0],
            );
            expect(
              state.party.members.single.currentPpByMoveId,
              caps.maxPpByPartyIndex[0],
            );
            expect(state.party.members.single.statusId, isEmpty);
            expect(
              completion,
              contains("We've restored your Pokémon to full health."),
            );
            final expectedCues = [
              for (final scene in bundle.manifest.scenes)
                if (scene.id == reference['nativeSceneId'])
                  for (final node in scene.graph.nodes)
                    if (node.payload
                        case final SceneYarnDialoguePayload payload)
                      for (final policy in payload.linePolicies)
                        ?policy.feedback.audioCue,
            ];
            expect(expectedCues, hasLength(1));
            expect(audio.cues, expectedCues);
            expect(PlayerRecoveryPoint.tryRead(state)?.mapId, bundle.map.id);
            expect(
              PlayerRecoveryPoint.tryRead(state)?.position,
              const GridPos(x: 9, y: 6),
            );
          } else {
            expect(capLoads, 0);
            expect(locks, isEmpty);
            expect(state.party, before);
            expect(PlayerRecoveryPoint.tryRead(state), isNull);
            expect(audio.cues, isEmpty);
            expect(completion, contains('We hope to see you again!'));
          }
          expect(await tester.runAsync(game.saveGame), isTrue);
          final saved = (await tester.runAsync(repository.load))!;
          expect(saved.party, state.party);
          expect(
            PlayerRecoveryPoint.tryRead(saved),
            PlayerRecoveryPoint.tryRead(state),
          );
          expect(
            game.handleRuntimeInputEvent(
              RuntimeInputEvent.press(RuntimeInputControl.left),
            ),
            isTrue,
          );
          await _pump(tester);
          game.handleRuntimeInputEvent(
            RuntimeInputEvent.release(RuntimeInputControl.left),
          );
          await _until(tester, game, () => !game.debugIsPlayerStepping);
          expect(
            game.gameStateSnapshot.playerPosition,
            const GridPos(x: 8, y: 6),
          );
          bool? loaded;
          Object? loadError;
          await tester.runAsync(() async {
            game.loadGame().then<void>(
              (value) {
                loaded = value;
              },
              onError: (Object error, StackTrace stack) {
                loadError = error;
              },
            );
          });
          await _until(tester, game, () => loaded != null || loadError != null);
          expect(loadError, isNull);
          expect(loaded, isTrue);
          await _until(tester, game, () => _ready(game));
          expect(game.gameStateSnapshot.party, state.party);
          expect(
            game.gameStateSnapshot.playerPosition,
            const GridPos(x: 9, y: 6),
          );
          expect(
            PlayerRecoveryPoint.tryRead(game.gameStateSnapshot),
            PlayerRecoveryPoint.tryRead(state),
          );
          expect(capLoads, choice == 'yes' ? 1 : 0);
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          service.dispose();
          await tester.runAsync(() => saveRoot.delete(recursive: true));
        }
      },
      skip: skip,
    );
  }
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 16));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 1)),
  );
}

Future<void> _until(
  WidgetTester tester,
  PlayableMapGame game,
  bool Function() done,
) async {
  for (var tick = 0; tick < 1800; tick++) {
    if (done()) return;
    await _pump(tester);
  }
  fail(
    'Nurse did not settle: ${game.debugFlowPhaseName}, ${game.dialoguePresentationListenable.value?.fullText}',
  );
}

bool _ready(PlayableMapGame game) =>
    game.debugFlowPhaseName == 'overworld' &&
    !game.debugIsMapActivationDispatchInFlight &&
    !game.debugIsNarrativeSpatialDispatchInFlight &&
    !game.debugIsNarrativeOutcomeWorkInFlight &&
    !game.debugIsLoadActivationWorkInFlight &&
    !game.debugHasPendingDialogueLoad &&
    !game.debugHasPendingMapTransition &&
    game.dialoguePresentationListenable.value == null &&
    game.inputAuthoritySnapshot.acceptsOverworldInput;

void _advance(PlayableMapGame game) {
  _press(game, RuntimeInputControl.primary);
}

void _press(PlayableMapGame game, RuntimeInputControl control) {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
}

Future<Map<String, String>> _hashes(String root) async => {
  await for (final file in Directory(
    root,
  ).list(recursive: true, followLinks: false))
    if (file is File)
      file.path.substring(root.length + 1):
          (await sha256.bind(file.openRead()).first).toString(),
};

final class _DiskSave extends FileGameSaveRepository {
  _DiskSave(this.filePath);
  final String filePath;
  @override
  Future<String> getSaveFilePath() async => filePath;
}

final class _AudioTrace implements DialogueFeedbackPlaybackPort {
  final cues = <DialogueAudioCue>[];
  @override
  Future<void> playCue(
    DialogueAudioCue cue, {
    required String playbackId,
  }) async {
    cues.add(cue);
  }
}

final class _SilentMusic implements FlameCinematicAudioDriver {
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async => Object();
  @override
  Future<void> setVolume(Object handle, double volume) async {}
  @override
  Future<void> stop(Object handle) async {}
}
