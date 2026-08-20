import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('contextual PC deposits and withdraws through runtime transactions',
      () async {
    var state = _state();
    final commits = <GameState>[];
    final locks = <bool>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits.add(next);
        state = next;
      },
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );
    addTearDown(controller.dispose);

    final open = controller.openPc(
      request: const OpenPcService(
        interactionId: 'terminal.harbor',
        storageId: 'box-a',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final initial = controller.worldServiceSnapshot!;
    final initialContent = initial.content! as RuntimePcServiceContent;
    expect(initialContent.selectedBoxId, 'box-a');
    expect(initialContent.party.map((entry) => entry.label),
        <String>['Lead', 'Reserve']);
    expect(initialContent.stored.single.label, 'Coffre');
    expect(initialContent.stored.single.speciesId, 'stored');
    expect(initialContent.stored.single.formId, 'stored-form');
    expect(initialContent.party.last.targetId, 'pokemon.pkm_reserve');
    expect(initialContent.stored.single.targetId, 'pokemon.pkm_stored');
    expect(initialContent.stored.single.natureId, 'hardy');
    expect(initialContent.stored.single.abilityId, 'steadfast');
    expect(initialContent.stored.single.nickname, 'Coffre');
    expect(initialContent.stored.single.friendship, 75);
    expect(initialContent.stored.single.originKind, 'captured');
    expect(initialContent.stored.single.metMapId, 'route-1');
    expect(initialContent.stored.single.metSourceId, 'grass');
    expect(initialContent.stored.single.ballItemId, 'poke-ball');
    expect(initialContent.stored.single.metLevel, 4);

    final reserve = initialContent.party.last;
    final deposited = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.deposit,
        snapshotRevision: initial.revision,
        targetId: reserve.targetId,
      ),
    );
    expect(deposited.status, RuntimeWorldServiceCommandStatus.accepted);
    expect(commits, hasLength(1));
    expect(state.party.members.map((pokemon) => pokemon.speciesId), ['lead']);
    expect(
      state.pokemonStorage.boxes.single.pokemon
          .map((pokemon) => pokemon.speciesId),
      ['stored', 'reserve'],
    );

    final afterDeposit = controller.worldServiceSnapshot!;
    final stored =
        (afterDeposit.content! as RuntimePcServiceContent).stored.first;
    final withdrawn = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.withdraw,
        snapshotRevision: afterDeposit.revision,
        targetId: stored.targetId,
      ),
    );
    expect(withdrawn.status, RuntimeWorldServiceCommandStatus.accepted);
    expect(commits, hasLength(2));
    expect(
      state.party.members.map((pokemon) => pokemon.speciesId),
      ['lead', 'stored'],
    );
    expect(state.party.members.last.nickname, 'Coffre');
    expect(state.party.members.last.friendship, 75);
    expect(
      state.party.members.last.provenance?.kind,
      PlayerPokemonOriginKind.captured,
    );

    final beforeSwap = controller.worldServiceSnapshot!;
    final beforeSwapContent = beforeSwap.content! as RuntimePcServiceContent;
    final partyLead = beforeSwapContent.party.first;
    final boxedReserve = beforeSwapContent.stored.first;
    final swapped = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.swap,
        snapshotRevision: beforeSwap.revision,
        targetId: boxedReserve.targetId,
        secondaryTargetId: partyLead.targetId,
      ),
    );
    expect(swapped.status, RuntimeWorldServiceCommandStatus.accepted);
    expect(commits, hasLength(3));
    expect(
      state.party.members.map((pokemon) => pokemon.speciesId),
      ['reserve', 'stored'],
    );
    expect(
      state.pokemonStorage.boxes.single.pokemon
          .map((pokemon) => pokemon.speciesId),
      ['lead'],
    );
    expect(
      controller.worldServiceSnapshot?.safeMessage,
      'Échange effectué.',
    );

    final beforeClose = controller.worldServiceSnapshot!;
    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: beforeClose.revision,
      ),
    );
    expect((await open).status, PlayerServiceRuntimeStatus.completed);
    expect(locks, <bool>[true, false]);
    expect(controller.worldServiceSnapshot, isNull);
  });

  test('PC explains an unavailable deposit without mutating or locking forever',
      () async {
    const onlyPokemon = PlayerPokemon(
      speciesId: 'only',
      natureId: 'hardy',
      abilityId: 'steadfast',
      currentHp: 10,
    );
    const state = GameState(
      saveId: 'pc-last-usable',
      party: PlayerParty(members: <PlayerPokemon>[onlyPokemon]),
      pokemonStorage: PokemonStorage(
        boxes: <PokemonBox>[
          PokemonBox(id: 'box-a', label: 'Box A'),
        ],
      ),
    );
    final locks = <bool>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (_) async => fail('No mutation should be committed.'),
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );
    addTearDown(controller.dispose);

    final open = controller.openPc();
    await Future<void>.delayed(Duration.zero);
    final snapshot = controller.worldServiceSnapshot!;
    final entry = (snapshot.content! as RuntimePcServiceContent).party.single;
    expect(entry.canTransfer, isFalse);
    expect(entry.unavailableReason, contains('dernier Pokémon'));
    expect(
        snapshot.isActionEnabled(RuntimeWorldServiceAction.deposit), isFalse);

    final refused = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.deposit,
        snapshotRevision: snapshot.revision,
        targetId: entry.targetId,
      ),
    );
    expect(refused.status, RuntimeWorldServiceCommandStatus.unavailable);

    final current = controller.worldServiceSnapshot!;
    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: current.revision,
      ),
    );
    expect((await open).status, PlayerServiceRuntimeStatus.completed);
    expect(locks, <bool>[true, false]);
  });

  test('failed PC write keeps the previous runtime state and shows an error',
      () async {
    final state = _state();
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (_) async => throw StateError('disk full'),
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );
    addTearDown(controller.dispose);

    final open = controller.openPc();
    await Future<void>.delayed(Duration.zero);
    final snapshot = controller.worldServiceSnapshot!;
    final reserve = (snapshot.content! as RuntimePcServiceContent).party.last;
    final failed = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.deposit,
        snapshotRevision: snapshot.revision,
        targetId: reserve.targetId,
      ),
    );

    expect(failed.status, RuntimeWorldServiceCommandStatus.failed);
    expect(controller.worldServiceSnapshot?.safeMessage,
        'La modification du PC n’a pas pu être enregistrée.');
    expect(state.party.members, hasLength(2));

    final current = controller.worldServiceSnapshot!;
    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: current.revision,
      ),
    );
    expect((await open).status, PlayerServiceRuntimeStatus.completed);
  });
  test('moves a stored Pokemon to another box and survives a reload',
      () async {
    // BETA-PTY-003. moveWithinBox et moveBetweenBoxes existaient, testés
    // unitairement, SANS AUCUN APPELANT — le motif PTY-002 exactement : le
    // joueur ne pouvait pas ranger ses boxes. Ce cas certifie le déplacement
    // depuis le service réel, jusqu'à l'aller-retour d'enveloppe de sauvegarde.
    var state = _stateWithTwoBoxes();
    final commits = <GameState>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits.add(next);
        state = next;
      },
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );
    addTearDown(controller.dispose);

    final open = controller.openPc(
      request: const OpenPcService(
        interactionId: 'terminal.harbor',
        storageId: 'box-a',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final snapshot = controller.worldServiceSnapshot!;
    expect(
      snapshot.actions.any(
        (action) =>
            action.action == RuntimeWorldServiceAction.move && action.isEnabled,
      ),
      isTrue,
      reason: 'two boxes and one stored Pokemon make the move available',
    );

    final moved = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.move,
        snapshotRevision: snapshot.revision,
        targetId: 'pokemon.pkm_stored',
        secondaryTargetId: 'box-b',
      ),
    );

    expect(moved.status, RuntimeWorldServiceCommandStatus.accepted);
    expect(commits, hasLength(1));
    expect(
      state.pokemonStorage.boxes.first.pokemon,
      isEmpty,
      reason: 'the source box no longer holds the Pokemon',
    );
    expect(
      state.pokemonStorage.boxes.last.pokemon.single.individualId,
      'pkm_stored',
    );

    final reloaded = gameStateFromSaveData(saveDataFromGameState(state));
    expect(
      reloaded.pokemonStorage.boxes.last.pokemon.single.individualId,
      'pkm_stored',
      reason: 'the move survives the save envelope round trip',
    );

    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: controller.worldServiceSnapshot!.revision,
      ),
    );
    await open;
  });

  test('a stale target is refused cleanly, then found again by identity',
      () async {
    // Les critères « stable selection » ensemble : après un déplacement vers
    // une autre box, l'ancien targetId ne résout plus dans la box affichée —
    // refus propre SANS mutation (stale). Puis, une fois la bonne box
    // sélectionnée, LE MÊME targetId retrouve l'individu : la clé est
    // l'identité, pas la position (stable).
    var state = _stateWithTwoBoxes();
    final commits = <GameState>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits.add(next);
        state = next;
      },
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );
    addTearDown(controller.dispose);

    final open = controller.openPc(
      request: const OpenPcService(
        interactionId: 'terminal.harbor',
        storageId: 'box-a',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final before = controller.worldServiceSnapshot!;
    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.move,
        snapshotRevision: before.revision,
        targetId: 'pokemon.pkm_stored',
        secondaryTargetId: 'box-b',
      ),
    );
    expect(commits, hasLength(1));

    final stale = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.withdraw,
        snapshotRevision: controller.worldServiceSnapshot!.revision,
        targetId: 'pokemon.pkm_stored',
      ),
    );
    expect(stale.status, RuntimeWorldServiceCommandStatus.unavailable);
    expect(commits, hasLength(1), reason: 'a stale target must not mutate');

    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.select,
        snapshotRevision: controller.worldServiceSnapshot!.revision,
        targetId: 'box-b',
      ),
    );
    final found = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.withdraw,
        snapshotRevision: controller.worldServiceSnapshot!.revision,
        targetId: 'pokemon.pkm_stored',
      ),
    );
    expect(found.status, RuntimeWorldServiceCommandStatus.accepted);
    expect(
      state.party.members.last.individualId,
      'pkm_stored',
      reason: 'the same identity-keyed target resolves in its new box',
    );

    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: controller.worldServiceSnapshot!.revision,
      ),
    );
    await open;
  });

  test('refuses to move into a full box without mutating anything', () async {
    // Le critère « box full » au niveau SERVICE : l'opération pure était déjà
    // typée, mais le joueur doit recevoir le refus en message stable, sans
    // commit fantôme.
    var state = _stateWithTwoBoxes(secondBoxCapacity: 1, fillSecondBox: true);
    final commits = <GameState>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits.add(next);
        state = next;
      },
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );
    addTearDown(controller.dispose);

    final open = controller.openPc(
      request: const OpenPcService(
        interactionId: 'terminal.harbor',
        storageId: 'box-a',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final snapshot = controller.worldServiceSnapshot!;

    final refused = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.move,
        snapshotRevision: snapshot.revision,
        targetId: 'pokemon.pkm_stored',
        secondaryTargetId: 'box-b',
      ),
    );

    expect(refused.status, RuntimeWorldServiceCommandStatus.unavailable);
    expect(commits, isEmpty);
    expect(state.pokemonStorage.boxes.first.pokemon, hasLength(1));

    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: controller.worldServiceSnapshot!.revision,
      ),
    );
    await open;
  });

  test('refuses to deposit the last usable Pokemon at the service level',
      () async {
    // Le critère « last usable » traversé depuis le service : la garde vit dans
    // l'opération pure, ce cas prouve qu'elle atteint le joueur avec un refus
    // typé — et qu'aucun commit ne part.
    var state = _stateWithFaintedReserve();
    final commits = <GameState>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits.add(next);
        state = next;
      },
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );
    addTearDown(controller.dispose);

    final open = controller.openPc(
      request: const OpenPcService(
        interactionId: 'terminal.harbor',
        storageId: 'box-a',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final snapshot = controller.worldServiceSnapshot!;
    final content = snapshot.content! as RuntimePcServiceContent;
    final lead = content.party.first;

    expect(
      lead.canTransfer,
      isFalse,
      reason: 'depositing the only usable Pokemon must be pre-announced',
    );

    final refused = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.deposit,
        snapshotRevision: snapshot.revision,
        targetId: lead.targetId,
      ),
    );

    expect(refused.status, RuntimeWorldServiceCommandStatus.unavailable);
    expect(commits, isEmpty);
    expect(state.party.members, hasLength(2));

    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: controller.worldServiceSnapshot!.revision,
      ),
    );
    await open;
  });
}


GameState _state() => GameState(
      saveId: 'pc-service',
      party: PlayerParty(
        members: <PlayerPokemon>[
          _pokemon('lead'),
          _pokemon('reserve'),
        ],
      ),
      pokemonStorage: PokemonStorage(
        boxes: <PokemonBox>[
          PokemonBox(
            id: 'box-a',
            label: 'Box A',
            pokemon: <PlayerPokemon>[_pokemon('stored')],
          ),
        ],
      ),
    );

PlayerPokemon _pokemon(String speciesId) => PlayerPokemon(
      individualId: 'pkm_$speciesId',
      speciesId: speciesId,
      formId: speciesId == 'stored' ? 'stored-form' : '',
      natureId: 'hardy',
      abilityId: 'steadfast',
      currentHp: 10,
      level: 5,
      nickname: speciesId == 'stored' ? 'Coffre' : '',
      friendship: speciesId == 'stored' ? 75 : 0,
      provenance: speciesId == 'stored'
          ? const PlayerPokemonProvenance(
              kind: PlayerPokemonOriginKind.captured,
              mapId: 'route-1',
              sourceId: 'grass',
              ballItemId: 'poke-ball',
              metLevel: 4,
            )
          : null,
    );

GameState _stateWithTwoBoxes({
  int secondBoxCapacity = 30,
  bool fillSecondBox = false,
}) =>
    GameState(
      saveId: 'pc-service-move',
      party: PlayerParty(
        members: <PlayerPokemon>[_pokemon('lead'), _pokemon('reserve')],
      ),
      pokemonStorage: PokemonStorage(
        boxes: <PokemonBox>[
          PokemonBox(
            id: 'box-a',
            label: 'Box A',
            pokemon: <PlayerPokemon>[_pokemon('stored')],
          ),
          PokemonBox(
            id: 'box-b',
            label: 'Box B',
            capacity: secondBoxCapacity,
            pokemon: fillSecondBox
                ? <PlayerPokemon>[_pokemon('occupant')]
                : const <PlayerPokemon>[],
          ),
        ],
      ),
    );

GameState _stateWithFaintedReserve() => GameState(
      saveId: 'pc-service-last-usable',
      party: PlayerParty(
        members: <PlayerPokemon>[
          _pokemon('lead'),
          _pokemon('reserve').copyWith(currentHp: 0),
        ],
      ),
      pokemonStorage: PokemonStorage(
        boxes: <PokemonBox>[
          PokemonBox(
            id: 'box-a',
            label: 'Box A',
            pokemon: <PlayerPokemon>[_pokemon('stored')],
          ),
        ],
      ),
    );
