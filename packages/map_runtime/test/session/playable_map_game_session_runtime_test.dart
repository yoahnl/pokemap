import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads a scoped save without filesystem persistence and completes once',
      () async {
    final identity = GameIdentity(
      gameId: 'org.example.runtime-fixture',
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v1,
      saveFormat: 1,
      compatibilityId: 'fixture-v1',
    );
    final descriptor = GameSessionDescriptor(
      sessionId: 'session-1',
      sessionToken: 'secret',
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      launchMode: GameSessionLaunchMode.continueGame,
      installedVersionHandle: 'verified-fixture',
      saveReadHandle: 'opaque-save',
      runtimeApiVersion: '1.0.0',
      grantedCapabilities: const <String>{'map.v1'},
      locale: 'fr-FR',
      accessibility: const GameSessionAccessibilityOptions(),
    );
    final createdAt = DateTime.utc(2026, 7, 24);
    final now = DateTime.utc(2026, 7, 25);
    final save = const GameStateSaveEnvelopeMapper().create(
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '123e4567-e89b-42d3-a456-426614174000',
      createdAt: createdAt,
      updatedAt: createdAt,
      status: SaveStatus.active,
      playTimeSeconds: 90,
      gameState: const GameState(
        saveId: '123e4567-e89b-42d3-a456-426614174000',
        currentMapId: 'p3_test_map',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sparkitten',
              natureId: 'hardy',
              abilityId: 'blaze',
              level: 7,
              currentHp: 23,
            ),
          ],
        ),
        bag: Bag(
          entries: <BagEntry>[
            BagEntry(
              itemId: 'potion',
              categoryId: 'medicine',
              quantity: 2,
            ),
          ],
        ),
      ),
    );
    PlayableMapGame? mounted;
    var unmounted = false;
    final runtime = PlayableMapGameSessionRuntime(
      descriptor: descriptor,
      projectFilePath: () async => File(
        'test/fixtures/p3_scenario_runtime_golden_path/project.json',
      ).absolute.path,
      initialSave: () async => save,
      mountGame: (game) async => mounted = game,
      unmountGame: (game) async {
        expect(game, same(mounted));
        unmounted = true;
      },
      now: () => now,
    );
    final progress = <GameSessionLoadingProgress>[];
    final events = <GameSessionAdapterEvent>[];
    final subscription = runtime.events.listen(events.add);

    await runtime.load(progress.add);
    expect(mounted, isNotNull);
    expect(progress.last.stage, 'ready');
    await runtime.pause();
    final pauseDetails = await runtime.loadPauseDetails();
    expect(
      pauseDetails[RuntimePlayerPauseSection.party]!.entries.single.title,
      'Sparkitten',
    );
    expect(
      pauseDetails[RuntimePlayerPauseSection.bag]!.entries.single.trailingLabel,
      '×2',
    );
    expect(
      pauseDetails,
      contains(RuntimePlayerPauseSection.pokedex),
    );
    expect(
      pauseDetails[RuntimePlayerPauseSection.map]!.entries.single.title,
      'P3 Test Map',
    );
    expect(
      pauseDetails[RuntimePlayerPauseSection.map]!.entries.single.trailingLabel,
      'Ici',
    );
    await runtime.resume();
    final checkpoint = await runtime.captureCheckpoint();
    expect(checkpoint?.saveId, save.saveId);
    expect(checkpoint?.playTimeSeconds, greaterThanOrEqualTo(90));

    const request = GameCompletionRequest(
      endingId: 'fixture-ending',
      outcome: GameCompletionOutcome.completed,
      result: GameResultSnapshot(title: 'Fin', summary: 'Terminé'),
      credits: GameCreditsSnapshot(
        title: 'Fixture',
        author: 'PokeMap',
        endingLabel: 'Fin',
      ),
      destination: GameCompletionDestination.hub,
      allowPostGameContinue: false,
    );
    await runtime.emitCompletion(request);
    await runtime.emitCompletion(request);
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<GameSessionCompleted>(), hasLength(1));
    expect(
      events.whereType<GameSessionCompleted>().single.completion.gameId,
      identity.gameId,
    );

    await runtime.stop(GameSessionExitReason.hub);
    await runtime.dispose();
    expect(unmounted, isTrue);
    await subscription.cancel();
  });
}
