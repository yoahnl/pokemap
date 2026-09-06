import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('localizes unavailable runtime services from the session locale',
      () async {
    Future<PlayableMapGameSessionRuntime> runtimeFor(String locale) async {
      final runtime = PlayableMapGameSessionRuntime(
        descriptor: GameSessionDescriptor(
          sessionId: 'session-$locale',
          sessionToken: 'secret',
          identity: GameIdentity(
            gameId: 'org.example.runtime-fixture',
            gameVersion: '1.0.0',
            projectFormat: ProjectFormat.v1,
            saveFormat: 1,
            compatibilityId: 'fixture-v1',
          ),
          profileId: 'player-1',
          slotId: 'slot-1',
          launchMode: GameSessionLaunchMode.newGame,
          installedVersionHandle: 'verified-fixture',
          runtimeApiVersion: '1.0.0',
          grantedCapabilities: const <String>{},
          locale: locale,
          accessibility: const GameSessionAccessibilityOptions(),
          initialGameState: const GameState(
            saveId: 'slot-1',
            currentMapId: 'map-start',
          ),
        ),
        projectFilePath: () async => '',
        initialSave: () async => null,
        mountGame: (_) async {},
        unmountGame: (_) async {},
      );
      addTearDown(runtime.dispose);
      return runtime;
    }

    final english = await runtimeFor('en-US');
    expect(
      (await english.dispatchPauseCommand(
        const RuntimePlayerPauseCommand.useBagItem(
          itemTargetId: 'bag:potion',
          partyTargetId: 'party:0',
        ),
      ))
          .safeMessage,
      'The bag is unavailable.',
    );

    final french = await runtimeFor('fr-FR');
    expect(
      (await french.dispatchWorldService(
        const RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.close,
          snapshotRevision: 1,
        ),
      ))
          .safeMessage,
      'Aucun service contextuel n’est actif.',
    );
  });

  test('routes party reorder pause commands to the party service', () async {
    // BETA-PTY-002, le maillon de ROUTAGE — mesuré manquant par sabotage :
    // renvoyer les genres équipe vers le service du sac laissait tout vert,
    // parce qu'aucun test ne traversait dispatchPauseCommand de la session
    // avec un genre équipe. Celui-ci le fait sur le vrai runtime chargé.
    final identity = GameIdentity(
      gameId: 'org.example.runtime-fixture',
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v1,
      saveFormat: 1,
      compatibilityId: 'fixture-v1',
    );
    final descriptor = GameSessionDescriptor(
      sessionId: 'session-party',
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
    final createdAt = DateTime.utc(2026, 8, 19);
    final save = const GameStateSaveEnvelopeMapper().create(
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '123e4567-e89b-42d3-a456-426614174001',
      createdAt: createdAt,
      updatedAt: createdAt,
      status: SaveStatus.active,
      playTimeSeconds: 10,
      gameState: const GameState(
        saveId: '123e4567-e89b-42d3-a456-426614174001',
        currentMapId: 'p3_test_map',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              individualId: 'pkm_first',
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              level: 7,
              currentHp: 20,
            ),
            PlayerPokemon(
              individualId: 'pkm_second',
              speciesId: 'sparkitten',
              natureId: 'hardy',
              abilityId: 'blaze',
              level: 7,
              currentHp: 20,
            ),
          ],
        ),
      ),
    );
    PlayableMapGame? mounted;
    final runtime = PlayableMapGameSessionRuntime(
      descriptor: descriptor,
      projectFilePath: () async => File(
        'test/fixtures/p3_scenario_runtime_golden_path/project.json',
      ).absolute.path,
      initialSave: () async => save,
      mountGame: (game) async {
        expect(game.dialogueTextSpeed, RuntimeDialogueTextSpeed.slow);
        mounted = game;
      },
      unmountGame: (_) async {},
      now: () => DateTime.utc(2026, 8, 20),
    );
    addTearDown(runtime.dispose);
    runtime.applyPlayerPreferences(const PlayerPreferencesSnapshot(
      locale: 'fr',
      accessibility: GameSessionAccessibilityOptions(),
      dialogueTextSpeed: RuntimeDialogueTextSpeed.slow,
    ));
    await runtime.load((_) {});
    expect(mounted, isNotNull);

    runtime.applyPlayerPreferences(const PlayerPreferencesSnapshot(
      locale: 'en',
      accessibility: GameSessionAccessibilityOptions(
        reducedMotion: true,
        textScale: 1.4,
      ),
      dialogueTextSpeed: RuntimeDialogueTextSpeed.fast,
    ));
    expect(mounted!.dialogueTextSpeed, RuntimeDialogueTextSpeed.fast);
    expect(mounted!.reducedMotion, isTrue);
    expect(mounted!.textScale, 1.4);
    expect(mounted!.runtimeLocale, 'fr-FR');
    expect((await runtime.loadPauseDetails())[RuntimePlayerPauseSection.map]!.title, 'Map');

    final result = await runtime.dispatchPauseCommand(
      const RuntimePlayerPauseCommand.setPartyLead(
        partyTargetId: 'pokemon.pkm_second',
      ),
    );

    expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
    expect(
      mounted!.gameStateSnapshot.party.members
          .map((member) => member.individualId),
      <String>['pkm_second', 'pkm_first'],
      reason: 'the session routed the party kind to the party service',
    );
  });

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
      // Valeurs NON par défaut exprès : le descripteur porte déjà ces options
      // depuis toujours, mais rien ne les transmettait au jeu. Toute
      // l'accessibilité de BETA-BAT-007 était donc injoignable en production —
      // le moteur l'honorait, personne ne la lui donnait.
      accessibility: const GameSessionAccessibilityOptions(
        reducedMotion: true,
        textScale: 1.5,
      ),
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
        trainerProfile: TrainerProfile(
          name: 'Session trainer',
          money: 1234,
          playtimeSeconds: 7,
        ),
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
    expect(mounted!.enableActorContactShadows, isFalse);
    expect(mounted!.enableStaticPlacedElementShadows, isFalse);
    expect(mounted!.reducedMotion, isTrue);
    expect(mounted!.textScale, 1.5);
    expect(progress.last.stage, 'ready');
    await runtime.pause();
    final pauseDetails = await runtime.loadPauseDetails();
    final profile = pauseDetails[RuntimePlayerPauseSection.profile]!.profile!;
    expect(profile.playerName, mounted!.gameStateSnapshot.trainerProfile.name);
    expect(profile.money, 1234);
    expect(profile.currentMapId, mounted!.gameStateSnapshot.currentMapId);
    expect(profile.locationName, 'P3 Test Map');
    expect(profile.playtimeSeconds, greaterThanOrEqualTo(90));
    final pausedCheckpoint = await runtime.captureCheckpoint();
    expect(profile.playtimeSeconds, pausedCheckpoint!.playTimeSeconds);
    expect(mounted!.gameStateSnapshot.trainerProfile.playtimeSeconds, 7);
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
    expect(
      checkpoint?.state['itemSystemSchemaVersion'],
      currentItemSystemSaveSchemaVersion,
    );

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

  test('loads an older game version when save compatibility is unchanged',
      () async {
    final identity = GameIdentity(
      gameId: 'org.example.runtime-fixture',
      gameVersion: '1.0.1',
      projectFormat: ProjectFormat.v1,
      saveFormat: 1,
      compatibilityId: 'fixture-v1',
    );
    final descriptor = GameSessionDescriptor(
      sessionId: 'session-compatible-update',
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
    final timestamp = DateTime.utc(2026, 8, 28);
    final save = const GameStateSaveEnvelopeMapper().create(
      identity: GameIdentity(
        gameId: 'org.example.runtime-fixture',
        gameVersion: '1.0.0',
        projectFormat: ProjectFormat.v1,
        saveFormat: 1,
        compatibilityId: 'fixture-v1',
      ),
      profileId: descriptor.profileId,
      slotId: descriptor.slotId,
      saveId: '123e4567-e89b-42d3-a456-426614174003',
      createdAt: timestamp,
      updatedAt: timestamp,
      status: SaveStatus.active,
      playTimeSeconds: 30,
      gameState: const GameState(
        saveId: '123e4567-e89b-42d3-a456-426614174003',
        currentMapId: 'p3_test_map',
      ),
    );
    PlayableMapGame? mounted;
    final runtime = PlayableMapGameSessionRuntime(
      descriptor: descriptor,
      projectFilePath: () async => File(
        'test/fixtures/p3_scenario_runtime_golden_path/project.json',
      ).absolute.path,
      initialSave: () async => save,
      mountGame: (game) async => mounted = game,
      unmountGame: (_) async {},
    );
    addTearDown(runtime.dispose);

    await runtime.load((_) {});

    expect(mounted, isNotNull);
  });

  test(
      'reuses a preloaded initial map bundle without reading the project again',
      () async {
    final projectFile = File(
      'test/fixtures/p3_scenario_runtime_golden_path/project.json',
    ).absolute;
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectFile.path,
      mapId: 'p3_test_map',
    );
    final identity = GameIdentity(
      gameId: 'org.example.runtime-fixture',
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v1,
      saveFormat: 1,
      compatibilityId: 'fixture-v1',
    );
    final descriptor = GameSessionDescriptor(
      sessionId: 'session-preloaded',
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
    final timestamp = DateTime.utc(2026, 8, 9);
    final save = const GameStateSaveEnvelopeMapper().create(
      identity: identity,
      profileId: descriptor.profileId,
      slotId: descriptor.slotId,
      saveId: '123e4567-e89b-42d3-a456-426614174001',
      createdAt: timestamp,
      updatedAt: timestamp,
      status: SaveStatus.active,
      playTimeSeconds: 30,
      gameState: const GameState(
        saveId: '123e4567-e89b-42d3-a456-426614174001',
        currentMapId: 'p3_test_map',
      ),
    );
    var preloadReads = 0;
    PlayableMapGame? mounted;
    final runtime = PlayableMapGameSessionRuntime(
      descriptor: descriptor,
      projectFilePath: () async => '/missing/project.json',
      initialSave: () async => save,
      preloadedInitialMap: ({
        required String projectFilePath,
        required GameSessionDescriptor descriptor,
        required SaveEnvelope? initialSave,
      }) async {
        preloadReads++;
        expect(projectFilePath, '/missing/project.json');
        expect(descriptor.sessionId, 'session-preloaded');
        expect(initialSave, same(save));
        return RuntimeInitialMapPreloadResult(bundle: bundle);
      },
      mountGame: (game) async => mounted = game,
      unmountGame: (_) async {},
    );
    addTearDown(runtime.dispose);

    await runtime.load((_) {});

    expect(preloadReads, 1);
    expect(mounted, isNotNull);
    expect(mounted!.gameStateSnapshot.currentMapId, 'p3_test_map');
  });

  test('refuses a preloaded bundle when the saved map has diverged', () async {
    final projectFile = File(
      'test/fixtures/p3_scenario_runtime_golden_path/project.json',
    ).absolute;
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectFile.path,
      mapId: 'p3_test_map',
    );
    final identity = GameIdentity(
      gameId: 'org.example.runtime-fixture',
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v1,
      saveFormat: 1,
      compatibilityId: 'fixture-v1',
    );
    final descriptor = GameSessionDescriptor(
      sessionId: 'session-diverged-preload',
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
    final timestamp = DateTime.utc(2026, 8, 9);
    final save = const GameStateSaveEnvelopeMapper().create(
      identity: identity,
      profileId: descriptor.profileId,
      slotId: descriptor.slotId,
      saveId: '123e4567-e89b-42d3-a456-426614174002',
      createdAt: timestamp,
      updatedAt: timestamp,
      status: SaveStatus.active,
      playTimeSeconds: 30,
      gameState: const GameState(
        saveId: '123e4567-e89b-42d3-a456-426614174002',
        currentMapId: 'another-map',
      ),
    );
    var mounted = false;
    final runtime = PlayableMapGameSessionRuntime(
      descriptor: descriptor,
      projectFilePath: () async => '/missing/project.json',
      initialSave: () async => save,
      preloadedInitialMap: ({
        required projectFilePath,
        required descriptor,
        required initialSave,
      }) async =>
          RuntimeInitialMapPreloadResult(bundle: bundle),
      mountGame: (_) async => mounted = true,
      unmountGame: (_) async {},
    );
    addTearDown(runtime.dispose);

    await expectLater(runtime.load((_) {}), throwsStateError);

    expect(mounted, isFalse);
  });
}
