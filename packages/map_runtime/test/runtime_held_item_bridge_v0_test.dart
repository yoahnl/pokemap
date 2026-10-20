import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/player_service_runtime_controller.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/player/runtime_player_pause_data.dart';

void main() {
  group('runtime held item bridge v0', () {
    test('authored King Rock resolves to its executable battle effect', () {
      const catalog = ProjectItemCatalog(
        schemaVersion: 1,
        entries: [
          ProjectItemDefinition(
            id: 'authored-royal-rock',
            displayName: 'Roche Royale',
            pocketId: 'held-items',
            heldEffectId: 'king_s_rock',
          ),
        ],
      );
      expect(
        validateProjectItemCatalog(
          catalog,
          capabilityTruth: itemSystemV1CapabilityTruth,
        ).hasBlockingDiagnostics,
        isFalse,
      );
      final snapshot = ItemCatalogSnapshot.fromCatalog(catalog);
      final resolution = resolveRuntimeHeldItemEffect(
        itemCatalog: snapshot,
        itemId: 'authored-royal-rock',
      );
      expect(resolution.status, RuntimeHeldItemSupportStatus.supported);
      expect(resolution.heldEffectId, 'king_s_rock');
      expect(
        PokemonEvolutionHeldItemPolicy.fromCatalog(snapshot)
            .recognizes('authored-royal-rock'),
        isTrue,
      );
      expect(
        PokemonEvolutionHeldItemPolicy.fromCatalog(snapshot)
            .preventsEvolution('authored-royal-rock'),
        isFalse,
      );
    });

    test('canonical heldEffectId has three honest support states', () {
      final catalog = ItemCatalogSnapshot.fromCatalog(
        const ProjectItemCatalog(
          schemaVersion: 1,
          entries: <ProjectItemDefinition>[
            ProjectItemDefinition(
              id: 'custom-leftovers',
              displayName: 'Custom Leftovers',
              pocketId: 'held-items',
              heldEffectId: 'leftovers',
            ),
            ProjectItemDefinition(
              id: 'pretty-ribbon',
              displayName: 'Pretty Ribbon',
              pocketId: 'treasures',
            ),
            ProjectItemDefinition(
              id: 'future-charm',
              displayName: 'Future Charm',
              pocketId: 'held-items',
              heldEffectId: 'future-effect',
            ),
          ],
        ),
      );

      final supported = resolveRuntimeHeldItemEffect(
        itemCatalog: catalog,
        itemId: 'custom-leftovers',
      );
      final passive = resolveRuntimeHeldItemEffect(
        itemCatalog: catalog,
        itemId: 'pretty-ribbon',
      );
      final unsupported = resolveRuntimeHeldItemEffect(
        itemCatalog: catalog,
        itemId: 'future-charm',
      );

      expect(supported.status, RuntimeHeldItemSupportStatus.supported);
      expect(supported.heldEffectId, 'leftovers');
      expect(passive.status, RuntimeHeldItemSupportStatus.passive);
      expect(unsupported.status, RuntimeHeldItemSupportStatus.unsupported);
    });

    test('only explicit native passive effects are neutral in battle', () {
      final catalog = ItemCatalogSnapshot.fromCatalog(
        const ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            ProjectItemDefinition(
              id: 'guard',
              displayName: 'Guard',
              pocketId: 'held-items',
              heldEffectId: 'prevent_evolution',
            ),
            ProjectItemDefinition(
              id: 'unknown',
              displayName: 'Unknown',
              pocketId: 'held-items',
              heldEffectId: 'future_effect',
            ),
            ProjectItemDefinition(
              id: 'alias',
              displayName: 'Alias',
              pocketId: 'held-items',
              heldEffectId: 'prevent-evolution',
            ),
          ],
        ),
      );
      final native = resolveRuntimeHeldItemEffect(
        itemCatalog: catalog,
        itemId: 'guard',
      );
      expect(native.isRuntimeSupported, isTrue);
      expect(native.heldEffectId, PokemonPassiveHeldEffect.preventEvolution.id);
      expect(
        ItemEffectRegistry().supportsHeldEffect(native.heldEffectId!),
        isFalse,
      );
      for (final id in ['unknown', 'alias', 'absent']) {
        expect(
          resolveRuntimeHeldItemEffect(
            itemCatalog: catalog,
            itemId: id,
          ).isRuntimeSupported,
          isFalse,
          reason: id,
        );
      }
    });

    test('native passive held items reconcile unchanged removed and received slots', () {
      final state = PsdkBattleState.fromSetup(
        PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
          player: _combatant(id: 'player_0', heldItemId: 'prevent_evolution'),
          playerReserves: [
            _combatant(id: 'player_1'),
            _combatant(id: 'player_2', heldItemId: 'prevent_evolution'),
            _combatant(id: 'player_3'),
          ],
          opponent: _combatant(id: 'opponent_0'),
          rngSeeds: _rngSeeds,
        ),
      );
      const saved = GameState(
        saveId: 'native-held-writeback',
        party: PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'a',
              natureId: 'hardy',
              abilityId: 'pressure',
              heldItemId: 'guard',
            ),
            PlayerPokemon(
              speciesId: 'b',
              natureId: 'hardy',
              abilityId: 'pressure',
              heldItemId: 'guard',
            ),
            PlayerPokemon(
              speciesId: 'c',
              natureId: 'hardy',
              abilityId: 'pressure',
            ),
            PlayerPokemon(
              speciesId: 'd',
              natureId: 'hardy',
              abilityId: 'pressure',
            ),
          ],
        ),
      );
      final catalog = ItemCatalogSnapshot.fromCatalog(
        const ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            ProjectItemDefinition(
              id: 'guard',
              displayName: 'Guard',
              pocketId: 'held-items',
              heldEffectId: 'prevent_evolution',
            ),
          ],
        ),
      );
      final result = writePlayerPsdkHeldItemsBackToPartySlots(
        gameState: saved,
        context: _context(),
        psdkState: state,
        itemCatalog: catalog,
      );
      expect(result.party.members.map((pokemon) => pokemon.heldItemId), [
        'guard',
        '',
        'guard',
        '',
      ]);
    });

    test(
      'a native evolution guard can be equipped and returned to the bag',
      () async {
        var state = const GameState(
          saveId: 'native-equip',
          party: PlayerParty(
            members: [
              PlayerPokemon(
                individualId: 'lead',
                speciesId: 'machoke',
                natureId: 'hardy',
                abilityId: 'guts',
              ),
            ],
          ),
          bag: Bag(entries: [BagEntry(itemId: 'guard', quantity: 1)]),
        );
        final saved = <GameState>[];
        final controller = PlayerServiceRuntimeController.contextual(
          currentGameState: () => state,
          commitAndSave: (next) async {
            saved.add(next);
            state = next;
          },
          setInputLocked: (_) {},
          loadRecoveryCaps: (_) async =>
              throw StateError('No healing requested'),
          itemCatalog: ItemCatalogSnapshot.fromCatalog(
            const ProjectItemCatalog(
              schemaVersion: 1,
              entries: [
                ProjectItemDefinition(
                  id: 'guard',
                  displayName: 'Evolution Guard',
                  pocketId: 'held-items',
                  heldEffectId: 'prevent_evolution',
                ),
              ],
            ),
          ),
        );
        addTearDown(controller.dispose);
        expect(
          (await controller.useBagItemOutsideBattle(
            const RuntimePlayerPauseCommand.equipHeldItem(
              itemTargetId: 'guard',
              partyTargetId: 'party.0',
            ),
          )).status,
          RuntimePlayerPauseCommandStatus.accepted,
        );
        expect(state.party.members.single.heldItemId, 'guard');
        expect(
          state.bag.entries.where(
            (entry) => entry.itemId == 'guard' && entry.quantity > 0,
          ),
          isEmpty,
        );
        expect(
          (await controller.useBagItemOutsideBattle(
            const RuntimePlayerPauseCommand.unequipHeldItem(
              partyTargetId: 'party.0',
            ),
          )).status,
          RuntimePlayerPauseCommandStatus.accepted,
        );
        expect(state.party.members.single.heldItemId, '');
        expect(
          state.bag.entries
              .singleWhere((entry) => entry.itemId == 'guard')
              .quantity,
          1,
        );
        expect(saved, hasLength(2));
    });

    test('a runtime seed hydrates and executes its held-item effect', () {
      final playerSeed = RuntimePsdkBattleCombatantSeed(
        speciesId: 'player',
        level: 20,
        maxHp: 80,
        catchRate: 45,
        stats: _stats,
        typing: const BattleTypingSnapshot(primaryType: 'normal'),
        abilityId: 'pressure',
        heldItemId: 'leftovers',
        moves: <PsdkBattleMoveData>[_move('player-wait')],
        currentHp: 40,
      );
      final session = BattleSessionFacade.fromPsdkSetup(
        setup: PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
          player: playerSeed.toPsdkBattleCombatantSetup(
            lineupIndex: 0,
            idPrefix: 'player',
          ),
          opponent: _combatant(id: 'opponent_0'),
          rngSeeds: _rngSeeds,
        ),
      );

      final player = session.state.psdkState.battlerAt(psdkPlayerSlot);
      expect(player.heldItemId, 'leftovers');
      expect(
        player.effects.effects.map((effect) => effect.id),
        contains('item:leftovers'),
      );

      session.submit(const BattleDecision.noAction());

      expect(
        session.state.psdkState.battlerAt(psdkPlayerSlot).currentHp,
        45,
      );
    });

    for (final effectId in ['lum_berry', 'sitrus_berry', 'smoke_ball']) {
      test(
        'proven held effect $effectId survives its real lifecycle write-back',
        () {
          final itemId = 'authored-$effectId';
          final catalog = ProjectItemCatalog(
            schemaVersion: 1,
            entries: [
              ProjectItemDefinition(
                id: itemId,
                displayName: 'Authored held item',
                pocketId: 'held-items',
                heldEffectId: effectId,
              ),
            ],
          );
          expect(
            validateProjectItemCatalog(
              catalog,
              capabilityTruth: itemSystemV1CapabilityTruth,
            ).hasBlockingDiagnostics,
            isFalse,
          );
          final itemCatalog = ItemCatalogSnapshot.fromCatalog(catalog);
          expect(
            resolveRuntimeHeldItemEffect(
              itemCatalog: itemCatalog,
              itemId: itemId,
            ).status,
            RuntimeHeldItemSupportStatus.supported,
          );
          final setup = PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
            player: _combatant(id: 'player_0', heldItemId: effectId),
            opponent: _combatant(id: 'opponent_0'),
            rngSeeds: _rngSeeds,
          );
          final initial = PsdkBattleState.fromSetup(setup);
          final gameState = GameState(
            saveId: 'held-lifecycle-$effectId',
            party: PlayerParty(
              members: [
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'hardy',
                  abilityId: 'overgrow',
                  heldItemId: itemId,
                ),
              ],
            ),
            bag: const Bag(
              entries: [BagEntry(itemId: 'spare-potion', quantity: 2)],
            ),
          );
          final context = _context(lineupIndices: const [0]);
          final untouched = writePlayerPsdkHeldItemsBackToPartySlots(
            gameState: gameState,
            context: context,
            psdkState: initial,
            itemCatalog: itemCatalog,
          );
          expect(untouched.party.members.single.heldItemId, itemId);
          final PsdkBattleState after;
          if (effectId == 'lum_berry') {
            after = const BattleStatusChangeHandler()
                .applyMajorStatus(
                  context: BattleHandlerContext(
                    state: initial,
                    rng: BattleRngStreams.fromPsdkSeeds(_rngSeeds),
                    turn: 1,
                    user: psdkOpponentSlot,
                  ),
                  target: psdkPlayerSlot,
                  moveId: 'poison_probe',
                  status: PsdkBattleMajorStatus.poison,
                )
                .state;
            expect(after.battlerAt(psdkPlayerSlot).majorStatus, isNull);
          } else if (effectId == 'sitrus_berry') {
            after = const BattleEndTurnHandler()
                .resolveEndTurn(
                  BattleHandlerContext(
                    state: initial.updateBattler(
                      psdkPlayerSlot,
                      (holder) => holder.copyWith(currentHp: 40),
                    ),
                    rng: BattleRngStreams.fromPsdkSeeds(_rngSeeds),
                    turn: 1,
                    user: psdkPlayerSlot,
                  ),
                )
                .state;
            expect(after.battlerAt(psdkPlayerSlot).currentHp, 60);
          } else {
            final fled = BattleEngine.fromPsdk(setup: setup)
                .submit(const BattleDecision.flee());
            expect(fled.outcome!.kind, BattleEngineOutcomeKind.fled);
            after = fled.state.psdkState;
          }
          final consumed = effectId != 'smoke_ball';
          final holder = after.battlerAt(psdkPlayerSlot);
          expect(holder.itemConsumed, consumed);
          expect(holder.consumedItemId, consumed ? effectId : null);
          final updated = writePlayerPsdkHeldItemsBackToPartySlots(
            gameState: untouched,
            context: context,
            psdkState: after,
            itemCatalog: itemCatalog,
          );
          expect(
            updated.party.members.single.heldItemId,
            consumed ? '' : itemId,
          );
          expect(updated.bag, gameState.bag);
          expect(
            writePlayerPsdkHeldItemsBackToPartySlots(
              gameState: updated,
              context: context,
              psdkState: after,
              itemCatalog: itemCatalog,
            ),
            updated,
          );
        },
      );
    }

    test('writes unchanged, consumed, removed and received items explicitly',
        () {
      final psdkState = PsdkBattleState.fromSetup(
        PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
          player: _combatant(
            id: 'player_0',
            heldItemId: 'oran_berry',
          ),
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'player_1',
              consumedItemId: 'sitrus_berry',
              itemConsumed: true,
            ),
            _combatant(id: 'player_2'),
            _combatant(
              id: 'player_3',
              heldItemId: 'leftovers',
            ),
          ],
          opponent: _combatant(id: 'opponent_0'),
          rngSeeds: _rngSeeds,
        ),
      );
      const gameState = GameState(
        saveId: 'held-item-write-back',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              heldItemId: 'custom-oran',
            ),
            PlayerPokemon(
              speciesId: 'bench-one',
              natureId: 'hardy',
              abilityId: 'pressure',
              heldItemId: 'custom-sitrus',
            ),
            PlayerPokemon(
              speciesId: 'bench-two',
              natureId: 'hardy',
              abilityId: 'pressure',
              heldItemId: 'custom-balloon',
            ),
            PlayerPokemon(
              speciesId: 'bench-three',
              natureId: 'hardy',
              abilityId: 'pressure',
              heldItemId: 'custom-oran',
            ),
          ],
        ),
      );

      final result = writePlayerPsdkHeldItemsBackToPartySlots(
        gameState: gameState,
        context: _context(),
        psdkState: psdkState,
        itemCatalog: ItemCatalogSnapshot.fromCatalog(
          const ProjectItemCatalog(
            schemaVersion: 1,
            entries: <ProjectItemDefinition>[
              ProjectItemDefinition(
                id: 'custom-oran',
                displayName: 'Custom Oran',
                pocketId: 'held-items',
                heldEffectId: 'oran_berry',
              ),
              ProjectItemDefinition(
                id: 'custom-sitrus',
                displayName: 'Custom Sitrus',
                pocketId: 'held-items',
                heldEffectId: 'sitrus_berry',
              ),
              ProjectItemDefinition(
                id: 'custom-balloon',
                displayName: 'Custom Balloon',
                pocketId: 'held-items',
                heldEffectId: 'air_balloon',
              ),
              ProjectItemDefinition(
                id: 'custom-leftovers',
                displayName: 'Custom Leftovers',
                pocketId: 'held-items',
                heldEffectId: 'leftovers',
              ),
            ],
          ),
        ),
      );

      expect(
        result.party.members.map((pokemon) => pokemon.heldItemId),
        <String>['custom-oran', '', '', 'custom-leftovers'],
      );
    });

    test('pause commands equip, swap and unequip canonical held items',
        () async {
      var state = const GameState(
        saveId: 'held-item-transfer',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              heldItemId: 'oran-charm',
            ),
          ],
        ),
        bag: Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'leftovers-charm', quantity: 1),
            BagEntry(itemId: 'pretty-ribbon', quantity: 1),
            BagEntry(itemId: 'future-charm', quantity: 1),
          ],
        ),
      );
      final commits = <GameState>[];
      final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => state,
        commitAndSave: (next) async {
          commits.add(next);
          state = next;
        },
        setInputLocked: (_) {},
        loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
          maxHpByPartyIndex: <int, int>{0: 20},
        ),
        itemCatalog: ItemCatalogSnapshot.fromCatalog(
          const ProjectItemCatalog(
            schemaVersion: 1,
            entries: <ProjectItemDefinition>[
              ProjectItemDefinition(
                id: 'leftovers-charm',
                displayName: 'Leftovers Charm',
                pocketId: 'held-items',
                heldEffectId: 'leftovers',
              ),
              ProjectItemDefinition(
                id: 'oran-charm',
                displayName: 'Oran Charm',
                pocketId: 'held-items',
                heldEffectId: 'oran_berry',
              ),
              ProjectItemDefinition(
                id: 'pretty-ribbon',
                displayName: 'Pretty Ribbon',
                pocketId: 'treasures',
              ),
              ProjectItemDefinition(
                id: 'future-charm',
                displayName: 'Future Charm',
                pocketId: 'held-items',
                heldEffectId: 'future-effect',
              ),
            ],
          ),
        ),
      );
      addTearDown(controller.dispose);

      final equipped = await controller.useBagItemOutsideBattle(
        const RuntimePlayerPauseCommand.equipHeldItem(
          itemTargetId: 'leftovers-charm',
          partyTargetId: 'party.0',
        ),
      );
      final unequipped = await controller.useBagItemOutsideBattle(
        const RuntimePlayerPauseCommand.unequipHeldItem(
          partyTargetId: 'party.0',
        ),
      );
      final passive = await controller.useBagItemOutsideBattle(
        const RuntimePlayerPauseCommand.equipHeldItem(
          itemTargetId: 'pretty-ribbon',
          partyTargetId: 'party.0',
        ),
      );
      final unsupported = await controller.useBagItemOutsideBattle(
        const RuntimePlayerPauseCommand.equipHeldItem(
          itemTargetId: 'future-charm',
          partyTargetId: 'party.0',
        ),
      );

      expect(equipped.status, RuntimePlayerPauseCommandStatus.accepted);
      expect(unequipped.status, RuntimePlayerPauseCommandStatus.accepted);
      expect(passive.status, RuntimePlayerPauseCommandStatus.unavailable);
      expect(unsupported.status, RuntimePlayerPauseCommandStatus.unavailable);
      expect(unsupported.safeMessage, contains('pas pris en charge'));
      expect(commits, hasLength(2));
      expect(state.party.members.single.heldItemId, isEmpty);
      expect(
        state.bag.entries.map((entry) => (entry.itemId, entry.quantity)),
        containsAll(<(String, int)>[
          ('leftovers-charm', 1),
          ('oran-charm', 1),
          ('pretty-ribbon', 1),
          ('future-charm', 1),
        ]),
      );
    });
  });
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  String? heldItemId,
  String? consumedItemId,
  bool itemConsumed = false,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 80,
    currentHp: 80,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    heldItemId: heldItemId,
    consumedItemId: consumedItemId,
    itemConsumed: itemConsumed,
    moves: <PsdkBattleMoveData>[_move('$id-move')],
  );
}

const _stats = BattleStatsSnapshot(
  attack: 50,
  defense: 50,
  specialAttack: 50,
  specialDefense: 50,
  speed: 50,
);

PsdkBattleMoveData _move(String id) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: 'Wait',
    type: 'normal',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.user,
  );
}

const _rngSeeds = PsdkBattleRngSeeds(
  moveDamage: 1,
  moveCritical: 2,
  moveAccuracy: 3,
  generic: 4,
);

RuntimeActiveBattleContext _context({
  List<int> lineupIndices = const [0, 1, 2, 3],
}) {
  return RuntimeActiveBattleContext.withLineupMapping(
    request: const TrainerBattleStartRequest(
      requestId: 'held-item-battle',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: 'field',
        playerPos: GridPos(x: 1, y: 1),
        playerFacing: Direction.south,
      ),
      trainerId: 'trainer',
      npcEntityId: 'npc',
      mapId: 'field',
      playerPos: GridPos(x: 1, y: 1),
    ),
    playerPartyIndex: 0,
    playerPartySlotIndicesByLineupIndex: lineupIndices,
  );
}
