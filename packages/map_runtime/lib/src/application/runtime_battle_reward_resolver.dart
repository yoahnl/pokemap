import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'runtime_battle_outcome_apply.dart';
import 'runtime_battle_progression_context_mapper.dart';
import 'runtime_map_bundle.dart';
import 'battle_start_request.dart';
import 'runtime_pokemon_evolution_loader.dart';
import 'runtime_pokemon_learnset_loader.dart';
import 'runtime_pokemon_species_loader.dart';

typedef RuntimePostBattleSpeciesLoader = Future<RuntimePokemonSpecies>
    Function({
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
  required String speciesId,
});

typedef RuntimePostBattleMoveLearningLoader
    = Future<List<PokemonMoveLearningCandidate>> Function({
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
  required String speciesRef,
  required String fallbackSpeciesId,
  required int oldLevel,
  required int newLevel,
});

typedef RuntimePostBattleEvolutionLoader
    = Future<List<PokemonEvolutionCandidate>> Function({
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
  required String sourceSpeciesId,
});

enum RuntimePostBattleResolutionErrorCode {
  missingTrainer,
  invalidBattleData,
  missingCatalogueData,
}

/// Typed fail-closed boundary for runtime post-battle catalogue resolution.
final class RuntimePostBattleResolutionException implements Exception {
  const RuntimePostBattleResolutionException({
    required this.code,
    required this.message,
    this.debugDetails,
  });

  final RuntimePostBattleResolutionErrorCode code;
  final String message;
  final String? debugDetails;

  @override
  String toString() => 'RuntimePostBattleResolutionException('
      'code: ${code.name}, message: $message, details: $debugDetails)';
}

/// Complete, catalogue-backed projection used by the post-battle transaction.
final class RuntimeBattleRewardResolution {
  const RuntimeBattleRewardResolution({
    required this.baseState,
    required this.reward,
    required this.progressionContext,
    required this.progression,
  });

  /// The exact post-writeback state from which preview and final replay ran.
  final GameState baseState;
  final BattleReward reward;
  final BattleProgressionContext progressionContext;
  final BattleProgressionResult progression;
}

/// Resolves authored rewards and Pokémon progression without publishing state.
///
/// XP is first previewed without learn/evolution candidates. Runtime then loads
/// only the catalogue entries crossed by the resulting level interval and
/// replays the pure service from the same [GameState]. No preview mutation can
/// therefore be applied twice.
final class RuntimeBattleRewardResolver {
  RuntimeBattleRewardResolver({
    RuntimePostBattleSpeciesLoader? loadSpecies,
    RuntimePostBattleMoveLearningLoader? loadMoveLearningCandidates,
    RuntimePostBattleEvolutionLoader? loadEvolutionCandidates,
    RuntimeBattleProgressionContextMapper contextMapper =
        const RuntimeBattleProgressionContextMapper(),
    BattleProgressionService progressionService =
        const BattleProgressionService(),
  })  : _loadSpecies = loadSpecies ?? RuntimePokemonSpeciesLoader().loadById,
        _loadMoveLearningCandidates = loadMoveLearningCandidates ??
            RuntimePokemonLearnsetLoader().loadLevelUpCandidates,
        _loadEvolutionCandidates = loadEvolutionCandidates ??
            RuntimePokemonEvolutionLoader().loadLevelUpCandidates,
        _contextMapper = contextMapper,
        _progressionService = progressionService;

  final RuntimePostBattleSpeciesLoader _loadSpecies;
  final RuntimePostBattleMoveLearningLoader _loadMoveLearningCandidates;
  final RuntimePostBattleEvolutionLoader _loadEvolutionCandidates;
  final RuntimeBattleProgressionContextMapper _contextMapper;
  final BattleProgressionService _progressionService;

  Future<RuntimeBattleRewardResolution> resolve({
    required RuntimeMapBundle bundle,
    required GameState postWriteBackState,
    required RuntimeActiveBattleContext runtimeContext,
    required BattleOutcome outcome,
  }) async {
    try {
      final reward = _rewardFor(
        request: runtimeContext.request,
        outcome: outcome,
        manifest: bundle.manifest,
      );
      if (!outcome.isVictory) {
        final context = _contextMapper.fromLegacyOutcome(
          runtimeContext: runtimeContext,
          outcome: outcome,
          partyLength: postWriteBackState.party.members.length,
          defeatedOpponents: const <BattleProgressionDefeatedOpponent>[],
          partySlotMetadata: const <BattleProgressionPartySlotMetadata>[],
          ruleset: bundle.manifest.pokemon.ruleset,
        );
        return RuntimeBattleRewardResolution(
          baseState: postWriteBackState,
          reward: reward,
          progressionContext: context,
          progression: _progressionService.apply(
            state: postWriteBackState,
            context: context,
            reward: reward,
            applyAuthoredRewards: false,
          ),
        );
      }

      final defeatedOpponents = <BattleProgressionDefeatedOpponent>[];
      final seenEnemyLineupIndexes = <int>{};
      for (final enemy in <BattleCombatant>[
        outcome.finalState.enemySide.active,
        ...outcome.finalState.enemySide.reserve,
      ]) {
        if (!enemy.isFainted ||
            !seenEnemyLineupIndexes.add(enemy.lineupIndex)) {
          continue;
        }
        final species = await _loadSpecies(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          speciesId: enemy.writeBackSpeciesId,
        );
        defeatedOpponents.add(
          BattleProgressionDefeatedOpponent(
            level: enemy.level,
            baseExperience: species.baseExp,
          ),
        );
      }
      final mapped = _contextMapper.fromLegacyOutcome(
        runtimeContext: runtimeContext,
        outcome: outcome,
        partyLength: postWriteBackState.party.members.length,
        defeatedOpponents: defeatedOpponents,
        partySlotMetadata: const <BattleProgressionPartySlotMetadata>[],
        ruleset: bundle.manifest.pokemon.ruleset,
      );

      final metadata = <BattleProgressionPartySlotMetadata>[];
      final speciesByPartySlot = <int, RuntimePokemonSpecies>{};
      final participantSlots = mapped.playerParticipantPartySlots.toList()
        ..sort();
      for (final partySlot in participantSlots) {
        final member = postWriteBackState.party.members[partySlot];
        final species = await _loadSpecies(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          speciesId: member.speciesId,
        );
        speciesByPartySlot[partySlot] = species;
        final baseStats = _baseStats(species);
        final calculated = const PokemonStatCalculator().calculate(
          baseStats: baseStats,
          ivs: member.ivs,
          evs: member.evs,
          level: member.level,
          naturePolicy: PokemonNatureStatPolicy.canonical,
          natureId: member.natureId,
        );
        metadata.add(
          BattleProgressionPartySlotMetadata(
            partySlot: partySlot,
            growthRateId: species.growthRateId,
            oldMaxHp: calculated.maxHp,
            baseStats: baseStats,
          ),
        );
      }

      final previewContext = BattleProgressionContext(
        outcome: mapped.outcome,
        ruleset: bundle.manifest.pokemon.ruleset,
        playerParticipantPartySlots: mapped.playerParticipantPartySlots,
        defeatedOpponents: defeatedOpponents,
        partySlotMetadata: metadata,
      );
      final preview = _progressionService.apply(
        state: postWriteBackState,
        context: previewContext,
        reward: reward,
        applyAuthoredRewards: false,
      );

      final moveCandidates = <int, Iterable<PokemonMoveLearningCandidate>>{};
      final evolutionCandidates = <int, Iterable<PokemonEvolutionCandidate>>{};
      for (final change in preview.changes) {
        if (change.newLevel <= change.oldLevel) continue;
        final member = postWriteBackState.party.members[change.partySlot];
        final species = speciesByPartySlot[change.partySlot]!;
        moveCandidates[change.partySlot] = await _loadMoveLearningCandidates(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          speciesRef: species.learnsetRef,
          fallbackSpeciesId: member.speciesId,
          oldLevel: change.oldLevel,
          newLevel: change.newLevel,
        );
        evolutionCandidates[change.partySlot] = await _loadEvolutionCandidates(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          sourceSpeciesId: member.speciesId,
        );
      }

      final context = BattleProgressionContext(
        outcome: mapped.outcome,
        ruleset: bundle.manifest.pokemon.ruleset,
        playerParticipantPartySlots: mapped.playerParticipantPartySlots,
        defeatedOpponents: defeatedOpponents,
        partySlotMetadata: metadata,
        moveLearningCandidatesByPartySlot: moveCandidates,
        evolutionCandidatesByPartySlot: evolutionCandidates,
      );
      final progression = _progressionService.apply(
        state: postWriteBackState,
        context: context,
        reward: reward,
        applyAuthoredRewards: false,
      );
      return RuntimeBattleRewardResolution(
        baseState: postWriteBackState,
        reward: reward,
        progressionContext: context,
        progression: progression,
      );
    } on RuntimePostBattleResolutionException {
      rethrow;
    } catch (error) {
      throw RuntimePostBattleResolutionException(
        code: RuntimePostBattleResolutionErrorCode.missingCatalogueData,
        message: 'Les données de progression post-combat sont incomplètes.',
        debugDetails: '$error',
      );
    }
  }
}

BattleReward _rewardFor({
  required BattleStartRequest request,
  required BattleOutcome outcome,
  required ProjectManifest manifest,
}) {
  if (request is TrainerBattleStartRequest) {
    final matches = manifest.trainers
        .where((trainer) => trainer.id.trim() == request.trainerId)
        .toList(growable: false);
    if (outcome.isVictory && matches.length != 1) {
      throw RuntimePostBattleResolutionException(
        code: RuntimePostBattleResolutionErrorCode.missingTrainer,
        message: 'Les récompenses du dresseur sont introuvables.',
        debugDetails:
            'trainerId=${request.trainerId}, matchingEntries=${matches.length}',
      );
    }
    final trainer = matches.singleOrNull;
    return BattleReward(
      sourceKind: BattleRewardSourceKind.trainer,
      trainerId: request.trainerId,
      money: outcome.isVictory ? trainer?.moneyReward ?? 0 : 0,
      itemGrants: outcome.isVictory
          ? <BattleRewardItemGrant>[
              for (final grant in trainer?.rewardItemGrants ??
                  const <ProjectTrainerItemGrant>[])
                BattleRewardItemGrant(
                  itemId: grant.itemId,
                  quantity: grant.quantity,
                ),
            ]
          : const <BattleRewardItemGrant>[],
      flagIds: outcome.isVictory
          ? trainer?.rewardFlagIds ?? const <String>[]
          : const <String>[],
      badgeId: outcome.isVictory ? trainer?.rewardBadgeId : null,
      fieldAbilityUnlock:
          outcome.isVictory ? trainer?.rewardFieldAbilityUnlock : null,
    );
  }
  if (request is! WildBattleStartRequest &&
      request is! StaticBattleStartRequest) {
    throw RuntimePostBattleResolutionException(
      code: RuntimePostBattleResolutionErrorCode.invalidBattleData,
      message: 'Ce type de combat ne peut pas produire de récompenses.',
      debugDetails: 'requestType=${request.runtimeType}',
    );
  }
  return BattleReward(sourceKind: BattleRewardSourceKind.wild);
}

PokemonBaseStats _baseStats(RuntimePokemonSpecies species) {
  return PokemonBaseStats(
    hp: species.baseHp,
    attack: species.baseAttack,
    defense: species.baseDefense,
    specialAttack: species.baseSpecialAttack,
    specialDefense: species.baseSpecialDefense,
    speed: species.baseSpeed,
  );
}
