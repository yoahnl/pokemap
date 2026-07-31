import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('BattleProgressionAuthoringService', () {
    test('previews rewards and progression on a detached player state', () {
      final source = _state();

      final preview = const BattleProgressionAuthoringService().preview(
        state: source,
        context: _context(),
        reward: BattleReward(
          sourceKind: BattleRewardSourceKind.wild,
          money: 120,
        ),
      );

      expect(source.party.members.single.level, 5);
      expect(source.trainerProfile.money, 0);
      expect(preview.result.state.party.members.single.level, 6);
      expect(preview.result.state.trainerProfile.money, 120);
      expect(preview.policy.requiresRuntimeBattleWriteBack, isTrue);
      expect(preview.policy.requiresCaptureDestination, isFalse);
      expect(preview.isDecisionComplete, isTrue);
    });

    test('records typed move-learning decisions in deterministic order', () {
      final preview = const BattleProgressionAuthoringService().preview(
        state: _state(
          knownMoveIds: const <String>['one', 'two', 'three', 'four'],
        ),
        context: _context(
          candidates: const <PokemonMoveLearningCandidate>[
            PokemonMoveLearningCandidate(
              opportunityId: 'hero:growl:6',
              moveId: 'growl',
              learnedAtLevel: 6,
              maxPp: 40,
            ),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
        decisions: const <BattleProgressionAuthoringDecision>[
          BattleProgressionAuthoringDecision.moveLearning(
            BattleMoveLearningDecision.decline(
              opportunityId: 'hero:growl:6',
              partySlot: 0,
              moveId: 'growl',
            ),
          ),
        ],
      );

      expect(preview.isDecisionComplete, isTrue);
      expect(preview.decisionTrace, hasLength(1));
      expect(
        preview.decisionTrace.single.kind,
        BattleProgressionAuthoringDecisionKind.moveLearning,
      );
      expect(
        preview.result.moveLearningChanges.single.kind,
        BattleMoveLearningChangeKind.declined,
      );
    });

    test('resolves an exact evolution decision through the production queue',
        () {
      final preview = const BattleProgressionAuthoringService().preview(
        state: _state(),
        context: _context(
          evolutionCandidates: <PokemonEvolutionCandidate>[
            PokemonEvolutionCandidate(
              opportunityId: 'hero:0:6:hero2',
              sourceSpeciesId: 'hero',
              targetSpeciesId: 'hero2',
              minLevel: 6,
              targetBaseStats: PokemonBaseStats(
                hp: 60,
                attack: 65,
                defense: 60,
                specialAttack: 80,
                specialDefense: 70,
                speed: 60,
              ),
              targetPrimaryAbilityId: 'overgrow',
              targetAbilityIds: <String>['overgrow'],
            ),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
        decisions: const <BattleProgressionAuthoringDecision>[
          BattleProgressionAuthoringDecision.evolution(
            BattleEvolutionDecision.accept(
              opportunityId: 'hero:0:6:hero2',
              occurrenceId: 'hero:0:6:hero2:slot:0:levels:5->6',
              partySlot: 0,
              sourceSpeciesId: 'hero',
              targetSpeciesId: 'hero2',
            ),
          ),
        ],
      );

      expect(preview.isDecisionComplete, isTrue);
      expect(preview.result.state.party.members.single.speciesId, 'hero2');
      expect(
        preview.decisionTrace.single.kind,
        BattleProgressionAuthoringDecisionKind.evolution,
      );
    });

    test('surfaces captured outcomes as runtime-owned capture write-back', () {
      final source = _state();
      final preview = const BattleProgressionAuthoringService().preview(
        state: source,
        context: _context(
          outcome: BattleProgressionOutcomeKind.captured,
          participants: const <int>{},
          opponents: const <BattleProgressionDefeatedOpponent>[],
          metadata: const <BattleProgressionPartySlotMetadata>[],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(preview.result.state.toJson(), source.toJson());
      expect(preview.result.appliedReward.isEmpty, isTrue);
      expect(preview.policy.requiresCaptureDestination, isTrue);
      expect(preview.policy.appliesVictoryRewards, isFalse);
      expect(
        preview.captureDestination?.kind,
        BattleAuthoringCaptureDestinationKind.party,
      );
      expect(preview.captureDestination?.partyIndex, 1);
    });

    test('previews the first real box slot when the party is full', () {
      final fullParty = _state().copyWith(
        party: PlayerParty(
          members: List<PlayerPokemon>.generate(
            maxPlayerPartySize,
            (index) => PlayerPokemon(
              speciesId: 'hero_$index',
              natureId: 'hardy',
              abilityId: 'overgrow',
              level: 5,
              currentHp: 19,
            ),
          ),
        ),
      );

      final destination = const BattleProgressionAuthoringService()
          .previewCaptureDestination(fullParty);

      expect(
        destination.kind,
        BattleAuthoringCaptureDestinationKind.storageBox,
      );
      expect(destination.boxId, 'box-01');
      expect(destination.boxIndex, 0);
    });
  });
}

BattleProgressionContext _context({
  BattleProgressionOutcomeKind outcome = BattleProgressionOutcomeKind.victory,
  Set<int> participants = const <int>{0},
  List<BattleProgressionDefeatedOpponent> opponents =
      const <BattleProgressionDefeatedOpponent>[
    BattleProgressionDefeatedOpponent(level: 14, baseExperience: 70),
  ],
  List<BattleProgressionPartySlotMetadata>? metadata,
  List<PokemonMoveLearningCandidate> candidates =
      const <PokemonMoveLearningCandidate>[],
  List<PokemonEvolutionCandidate> evolutionCandidates =
      const <PokemonEvolutionCandidate>[],
}) {
  return BattleProgressionContext(
    outcome: outcome,
    playerParticipantPartySlots: participants,
    defeatedOpponents: opponents,
    partySlotMetadata: metadata ??
        const <BattleProgressionPartySlotMetadata>[
          BattleProgressionPartySlotMetadata(
            partySlot: 0,
            growthRateId: 'medium',
            oldMaxHp: 19,
            baseStats: PokemonBaseStats(
              hp: 45,
              attack: 49,
              defense: 49,
              specialAttack: 65,
              specialDefense: 65,
              speed: 45,
            ),
          ),
        ],
    moveLearningCandidatesByPartySlot: <int,
        List<PokemonMoveLearningCandidate>>{0: candidates},
    evolutionCandidatesByPartySlot: <int, List<PokemonEvolutionCandidate>>{
      0: evolutionCandidates,
    },
  );
}

GameState _state({
  List<String> knownMoveIds = const <String>[],
}) {
  return GameState(
    saveId: 'authoring-progression',
    trainerProfile: const TrainerProfile(name: 'Player'),
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'hero',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 5,
          experience: 125,
          knownMoveIds: knownMoveIds,
          currentPpByMoveId: const <String, int>{},
          currentHp: 19,
        ),
      ],
    ),
  );
}
