import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const service = BattleProgressionService();
  final itemCatalog = ItemCatalogSnapshot.fromCatalog(
    const ProjectItemCatalog(
      schemaVersion: 1,
      entries: <ProjectItemDefinition>[
        ProjectItemDefinition(
          id: 'potion',
          displayName: 'Potion',
          pocketId: 'medicine',
        ),
      ],
    ),
  );

  group('BattleProgressionService', () {
    test('awards canonical wild XP only to an actual participant', () {
      final state = _state(<PlayerPokemon>[
        _pokemon(id: 'participant', level: 5, experience: 125, currentHp: 15),
        _pokemon(id: 'unused', level: 5, experience: 125, currentHp: 19),
      ]);

      final result = service.apply(
        state: state,
        context: _context(
          participants: const <int>{0},
          metadata: <BattleProgressionPartySlotMetadata>[
            _metadata(slot: 0, oldMaxHp: 19),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(
          result.appliedReward.experienceGrants, const <BattleExperienceGrant>[
        BattleExperienceGrant(partySlot: 0, experience: 140),
      ]);
      expect(result.state.party.members[0].experience, 265);
      expect(result.state.party.members[0].level, 6);
      expect(result.state.party.members[0].currentHp, 17);
      expect(result.state.party.members[1], state.party.members[1]);
      expect(result.changes.single.calculatedStats.attack, 10);
    });

    test('uses a 1.5 trainer multiplier and equal participant split', () {
      final state = _state(<PlayerPokemon>[
        _pokemon(id: 'fainted_participant', experience: 125, currentHp: 0),
        _pokemon(id: 'unused', experience: 125, currentHp: 19),
        _pokemon(id: 'switched_participant', experience: 125, currentHp: 18),
      ]);
      final reward = BattleReward(
        sourceKind: BattleRewardSourceKind.trainer,
        trainerId: 'trainer_iris',
        money: 200,
        itemGrants: const <BattleRewardItemGrant>[
          BattleRewardItemGrant(itemId: 'potion', quantity: 1),
        ],
        flagIds: const <String>['trainer_defeated:trainer_iris'],
      );

      final result = service.apply(
        state: state,
        context: _context(
          participants: const <int>{0, 2},
          metadata: <BattleProgressionPartySlotMetadata>[
            _metadata(slot: 0, oldMaxHp: 19),
            _metadata(slot: 2, oldMaxHp: 19),
          ],
        ),
        reward: reward,
        itemCatalog: itemCatalog,
      );

      expect(
        result.appliedReward.experienceGrants,
        const <BattleExperienceGrant>[
          BattleExperienceGrant(partySlot: 0, experience: 105),
          BattleExperienceGrant(partySlot: 2, experience: 105),
        ],
      );
      expect(result.state.party.members[0].experience, 230);
      expect(result.state.party.members[0].level, 6);
      expect(result.state.party.members[0].currentHp, 0);
      expect(result.state.party.members[1], state.party.members[1]);
      expect(result.state.party.members[2].experience, 230);
      expect(result.state.trainerProfile.money, 200);
      expect(result.state.bag.entries.single.itemId, 'potion');
      expect(
        result.state.storyFlags.activeFlags,
        contains('trainer_defeated:trainer_iris'),
      );
    });

    test('can defer authored rewards while still applying XP and level-up', () {
      final state = _state(<PlayerPokemon>[
        _pokemon(id: 'participant', experience: 125, currentHp: 19),
      ]);
      final reward = BattleReward(
        sourceKind: BattleRewardSourceKind.trainer,
        trainerId: 'trainer_iris',
        money: 200,
        itemGrants: const <BattleRewardItemGrant>[
          BattleRewardItemGrant(itemId: 'potion', quantity: 1),
        ],
        flagIds: const <String>['victory:iris'],
      );

      final result = service.apply(
        state: state,
        context: _context(),
        reward: reward,
        applyAuthoredRewards: false,
      );

      expect(result.state.party.members.single.experience, 335);
      expect(result.state.trainerProfile.money, 0);
      expect(result.state.bag.entries, isEmpty);
      expect(result.state.storyFlags.activeFlags, isEmpty);
      expect(result.appliedReward.money, 200);
      expect(result.appliedReward.itemGrants, reward.itemGrants);
      expect(result.appliedReward.flagIds, reward.flagIds);
    });

    for (final outcome in <BattleProgressionOutcomeKind>[
      BattleProgressionOutcomeKind.defeat,
      BattleProgressionOutcomeKind.fled,
      BattleProgressionOutcomeKind.captured,
    ]) {
      test('${outcome.name} grants neither XP nor authored rewards', () {
        final state = _state(<PlayerPokemon>[
          _pokemon(id: 'participant', experience: 125, currentHp: 19),
        ]);

        final result = service.apply(
          state: state,
          context: _context(
            outcome: outcome,
            participants: const <int>{},
            opponents: const <BattleProgressionDefeatedOpponent>[],
            metadata: const <BattleProgressionPartySlotMetadata>[],
          ),
          reward: BattleReward(
            sourceKind: BattleRewardSourceKind.wild,
            money: 500,
            itemGrants: const <BattleRewardItemGrant>[
              BattleRewardItemGrant(itemId: 'potion', quantity: 2),
            ],
          ),
        );

        expect(result.state, same(state));
        expect(result.appliedReward.isEmpty, isTrue);
        expect(result.changes, isEmpty);
      });
    }

    test('refuses a victory without an actual participant', () {
      final state = _state(<PlayerPokemon>[
        _pokemon(id: 'unused', experience: 125, currentHp: 19),
      ]);

      expect(
        () => service.apply(
          state: state,
          context: _context(participants: const <int>{}),
          reward: BattleReward(
            sourceKind: BattleRewardSourceKind.wild,
            money: 500,
          ),
        ),
        throwsStateError,
      );
      expect(state.trainerProfile.money, 0);
    });

    test('refuses a victory without a defeated opponent', () {
      final state = _state(<PlayerPokemon>[
        _pokemon(id: 'participant', experience: 125, currentHp: 19),
      ]);

      expect(
        () => service.apply(
          state: state,
          context: _context(
            opponents: const <BattleProgressionDefeatedOpponent>[],
          ),
          reward: BattleReward(
            sourceKind: BattleRewardSourceKind.wild,
            money: 500,
          ),
        ),
        throwsStateError,
      );
      expect(state.trainerProfile.money, 0);
    });

    test('applies multiple levels deterministically', () {
      final state = _state(<PlayerPokemon>[
        _pokemon(id: 'multi', level: 5, experience: 125, currentHp: 19),
      ]);

      final result = service.apply(
        state: state,
        context: _context(
          opponents: const <BattleProgressionDefeatedOpponent>[
            BattleProgressionDefeatedOpponent(level: 50, baseExperience: 200),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(result.state.party.members.single.experience, 1553);
      expect(result.state.party.members.single.level, 11);
      expect(result.changes.single.levelsGained, 6);
    });

    test('caps level and normalizes cumulative experience at level 100', () {
      final state = _state(<PlayerPokemon>[
        _pokemon(
          id: 'cap',
          level: 99,
          experience: 970299,
          currentHp: 199,
        ),
      ]);

      final result = service.apply(
        state: state,
        context: _context(
          metadata: <BattleProgressionPartySlotMetadata>[
            _metadata(slot: 0, oldMaxHp: 199),
          ],
          opponents: const <BattleProgressionDefeatedOpponent>[
            BattleProgressionDefeatedOpponent(
              level: 100,
              baseExperience: 10000,
            ),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(result.state.party.members.single.level, 100);
      expect(result.state.party.members.single.experience, 1000000);
      expect(
        result.appliedReward.experienceGrants,
        const <BattleExperienceGrant>[
          BattleExperienceGrant(partySlot: 0, experience: 29701),
        ],
      );
      expect(result.changes.single.experienceAwarded, 29701);
    });

    test('reports zero persisted XP when a participant is already level 100',
        () {
      final state = _state(<PlayerPokemon>[
        _pokemon(
          id: 'already_capped',
          level: 100,
          experience: 1000000,
          currentHp: 200,
        ),
      ]);

      final result = service.apply(
        state: state,
        context: _context(
          metadata: <BattleProgressionPartySlotMetadata>[
            _metadata(slot: 0, oldMaxHp: 200),
          ],
          opponents: const <BattleProgressionDefeatedOpponent>[
            BattleProgressionDefeatedOpponent(level: 100, baseExperience: 600),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(result.state.party.members.single.level, 100);
      expect(result.state.party.members.single.experience, 1000000);
      expect(
        result.appliedReward.experienceGrants,
        const <BattleExperienceGrant>[
          BattleExperienceGrant(partySlot: 0, experience: 0),
        ],
      );
      expect(result.changes.single.experienceAwarded, 0);
    });

    test('defensively copies progression changes and exposes them read-only',
        () {
      final applied = service.apply(
        state: _state(<PlayerPokemon>[
          _pokemon(id: 'participant', experience: 125, currentHp: 19),
        ]),
        context: _context(),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );
      final sourceChanges = <BattlePokemonProgressionChange>[
        applied.changes.single,
      ];

      final result = BattleProgressionResult(
        state: applied.state,
        appliedReward: applied.appliedReward,
        changes: sourceChanges,
      );
      sourceChanges.clear();

      expect(result.changes, hasLength(1));
      expect(result.changes.single.partySlot, 0);
      expect(result.changes.clear, throwsUnsupportedError);
    });

    test('persists awarded XP level and HP through save JSON round-trip', () {
      final state = _state(<PlayerPokemon>[
        _pokemon(id: 'roundtrip', experience: 125, currentHp: 15),
      ]);
      final progressed = service
          .apply(
            state: state,
            context: _context(),
            reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
          )
          .state;

      final json = saveDataFromGameState(progressed).toJson();
      final reloaded = normalizeLoadedGameState(
        gameStateFromSaveData(SaveData.fromJson(json)),
      );

      expect(reloaded.party.members.single.experience, 265);
      expect(reloaded.party.members.single.level, 6);
      expect(reloaded.party.members.single.currentHp, 17);
    });
  });
}

BattleProgressionContext _context({
  BattleProgressionOutcomeKind outcome = BattleProgressionOutcomeKind.victory,
  Set<int> participants = const <int>{0},
  List<BattleProgressionPartySlotMetadata>? metadata,
  List<BattleProgressionDefeatedOpponent> opponents =
      const <BattleProgressionDefeatedOpponent>[
    BattleProgressionDefeatedOpponent(level: 14, baseExperience: 70),
  ],
}) {
  return BattleProgressionContext(
    outcome: outcome,
    playerParticipantPartySlots: participants,
    defeatedOpponents: opponents,
    partySlotMetadata: metadata ??
        <BattleProgressionPartySlotMetadata>[
          _metadata(slot: 0, oldMaxHp: 19),
        ],
  );
}

BattleProgressionPartySlotMetadata _metadata({
  required int slot,
  required int oldMaxHp,
}) {
  return BattleProgressionPartySlotMetadata(
    partySlot: slot,
    growthRateId: 'medium',
    oldMaxHp: oldMaxHp,
    baseStats: const PokemonBaseStats(
      hp: 45,
      attack: 49,
      defense: 49,
      specialAttack: 65,
      specialDefense: 65,
      speed: 45,
    ),
  );
}

PlayerPokemon _pokemon({
  required String id,
  int level = 5,
  required int experience,
  required int currentHp,
}) {
  return PlayerPokemon(
    speciesId: id,
    natureId: 'hardy',
    abilityId: 'overgrow',
    level: level,
    experience: experience,
    currentPpByMoveId: const <String, int>{},
    currentHp: currentHp,
  );
}

GameState _state(List<PlayerPokemon> party) {
  return GameState(
    saveId: 'progression',
    trainerProfile: const TrainerProfile(name: 'Player'),
    party: PlayerParty(members: party),
  );
}
