import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

Future<GameState> hydrateTestBattlePokemonProgression({
  required GameState state,
  required RuntimeMapBundle bundle,
}) async {
  final catalogs = await loadRuntimePlayerPokemonProgressionCatalogs(
    gameState: state,
    projectRootDirectory: bundle.projectRootDirectory,
    pokemonConfig: bundle.manifest.pokemon,
  );
  return hydrateRuntimePlayerPokemonProgression(
    gameState: state,
    catalogs: catalogs,
  );
}

/// Runs the production progression service with a compact deterministic
/// species fixture used by runtime integration tests.
GameState applyTestBattleVictoryProgression({
  required GameState state,
  required int partySlot,
  required int oldMaxHp,
  required int levelsGained,
  required BattleReward reward,
}) {
  final members = List<PlayerPokemon>.of(state.party.members);
  final member = members[partySlot];
  final curve = PokemonExperienceCurve.fromId('medium');
  final oldExperience = curve.totalExperienceForLevel(member.level);
  final targetLevel = (member.level + levelsGained).clamp(1, 100).toInt();
  final requiredExperience =
      curve.totalExperienceForLevel(targetLevel) - oldExperience;
  if (requiredExperience <= 0) {
    throw ArgumentError.value(
      levelsGained,
      'levelsGained',
      'must advance the test fixture by at least one level',
    );
  }

  members[partySlot] = member.copyWith(experience: oldExperience);
  final hydratedState = state.copyWith(
    party: state.party.copyWith(members: members),
  );
  final opponent = switch (reward.sourceKind) {
    BattleRewardSourceKind.wild => BattleProgressionDefeatedOpponent(
        level: 7,
        baseExperience: requiredExperience,
      ),
    BattleRewardSourceKind.trainer => BattleProgressionDefeatedOpponent(
        level: 14,
        baseExperience: (requiredExperience + 2) ~/ 3,
      ),
  };

  return const BattleProgressionService()
      .apply(
        state: hydratedState,
        context: BattleProgressionContext(
          outcome: BattleProgressionOutcomeKind.victory,
          playerParticipantPartySlots: <int>{partySlot},
          defeatedOpponents: <BattleProgressionDefeatedOpponent>[opponent],
          partySlotMetadata: <BattleProgressionPartySlotMetadata>[
            BattleProgressionPartySlotMetadata(
              partySlot: partySlot,
              growthRateId: 'medium',
              oldMaxHp: oldMaxHp,
              baseStats: PokemonBaseStats(
                hp: _baseHpForProjectedMaximum(
                  level: targetLevel,
                  maxHp: oldMaxHp,
                ),
                attack: 1,
                defense: 1,
                specialAttack: 1,
                specialDefense: 1,
                speed: 1,
              ),
            ),
          ],
        ),
        reward: reward,
      )
      .state;
}

int _baseHpForProjectedMaximum({required int level, required int maxHp}) {
  const calculator = PokemonStatCalculator();
  for (var baseHp = 1; baseHp <= 255; baseHp++) {
    final stats = calculator.calculate(
      baseStats: PokemonBaseStats(
        hp: baseHp,
        attack: 1,
        defense: 1,
        specialAttack: 1,
        specialDefense: 1,
        speed: 1,
      ),
      ivs: const PokemonStatSpread(),
      evs: const PokemonStatSpread(),
      level: level,
    );
    if (stats.maxHp == maxHp) return baseHp;
  }
  throw StateError(
    'Cannot project max HP $maxHp at level $level for the test fixture.',
  );
}
