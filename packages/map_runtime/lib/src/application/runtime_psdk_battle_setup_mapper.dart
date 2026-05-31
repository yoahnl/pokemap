import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_combatant_seed_builder.dart';
import 'runtime_battle_setup_mapper.dart';
import 'runtime_map_bundle.dart';
import 'runtime_move_catalog_loader.dart';

/// Mapper runtime vers le setup de combat PSDK.
///
/// Il réutilise la même sélection de lineup et les mêmes loaders que le mapper
/// legacy, mais assemble un `PsdkBattleSetup` pour que les moves portés PSDK ne
/// soient plus bloqués par le petit bridge `BattleMoveData`.
final class RuntimePsdkBattleSetupMapper {
  RuntimePsdkBattleSetupMapper({
    RuntimeMoveCatalogLoader? moveCatalogLoader,
    RuntimeBattleCombatantSeedBuilder? combatantSeedBuilder,
  })  : moveCatalogLoader = moveCatalogLoader ?? RuntimeMoveCatalogLoader(),
        combatantSeedBuilder =
            combatantSeedBuilder ?? RuntimeBattleCombatantSeedBuilder();

  final RuntimeMoveCatalogLoader moveCatalogLoader;
  final RuntimeBattleCombatantSeedBuilder combatantSeedBuilder;

  Future<PsdkBattleSetup> map({
    required RuntimeMapBundle bundle,
    required GameState gameState,
    required BattleStartRequest request,
    int? playerPartyIndex,
  }) async {
    final movesCatalog = await moveCatalogLoader.load(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
    );
    final playerSelection = RuntimeBattleSetupMapper().selectPlayerBattleLineup(
      gameState.party,
      playerPartyIndex: playerPartyIndex,
    );
    final playerPokemon = gameState.party.members[playerSelection.activeIndex];

    final playerSeed = await combatantSeedBuilder.buildPlayerPsdkCombatantSeed(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
      movesCatalog: movesCatalog,
      playerPokemon: playerPokemon,
      combatantLabel: 'Le Pokémon actif du joueur',
    );
    final playerReserveSeeds = <RuntimePsdkBattleCombatantSeed>[];
    for (final reserveIndex in playerSelection.reserveIndices) {
      final reservePokemon = gameState.party.members[reserveIndex];
      playerReserveSeeds.add(
        await combatantSeedBuilder.buildPlayerPsdkCombatantSeed(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          movesCatalog: movesCatalog,
          playerPokemon: reservePokemon,
          combatantLabel:
              'Le Pokémon de réserve du joueur (${reservePokemon.speciesId})',
        ),
      );
    }

    final enemyLineup = await switch (request) {
      WildBattleStartRequest() => combatantSeedBuilder
          .buildWildPsdkCombatantSeed(
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: bundle.manifest.pokemon,
            movesCatalog: movesCatalog,
            request: request,
          )
          .then(
            (seed) => _RuntimePsdkBattleEnemyLineup(
              active: seed,
              reserve: const <RuntimePsdkBattleCombatantSeed>[],
            ),
          ),
      TrainerBattleStartRequest() => () async {
          final trainer = _findTrainer(bundle.manifest, request.trainerId);
          if (trainer.team.isEmpty) {
            throw RuntimeBattleSetupException(
              'Le dresseur "${trainer.name}" n’a aucun Pokémon dans son équipe.',
              debugDetails: 'trainerId=${trainer.id}',
            );
          }

          final activeSeed =
              await combatantSeedBuilder.buildTrainerPsdkCombatantSeed(
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: bundle.manifest.pokemon,
            movesCatalog: movesCatalog,
            teamMember: trainer.team.first,
            trainerName: trainer.name,
          );
          final reserveSeeds = <RuntimePsdkBattleCombatantSeed>[];
          for (final teamMember in trainer.team.skip(1)) {
            reserveSeeds.add(
              await combatantSeedBuilder.buildTrainerPsdkCombatantSeed(
                projectRootDirectory: bundle.projectRootDirectory,
                pokemonConfig: bundle.manifest.pokemon,
                movesCatalog: movesCatalog,
                teamMember: teamMember,
                trainerName: trainer.name,
              ),
            );
          }
          return _RuntimePsdkBattleEnemyLineup(
            active: activeSeed,
            reserve: List<RuntimePsdkBattleCombatantSeed>.unmodifiable(
              reserveSeeds,
            ),
          );
        }(),
    };

    return PsdkBattleSetup.singles(
      player: playerSeed.toPsdkBattleCombatantSetup(
        lineupIndex: 0,
        idPrefix: 'player',
      ),
      playerReserves: List<PsdkBattleCombatantSetup>.unmodifiable(
        playerReserveSeeds.asMap().entries.map(
              (entry) => entry.value.toPsdkBattleCombatantSetup(
                lineupIndex: entry.key + 1,
                idPrefix: 'player',
              ),
            ),
      ),
      opponent: enemyLineup.active.toPsdkBattleCombatantSetup(
        lineupIndex: 0,
        idPrefix: 'opponent',
      ),
      opponentReserves: List<PsdkBattleCombatantSetup>.unmodifiable(
        enemyLineup.reserve.asMap().entries.map(
              (entry) => entry.value.toPsdkBattleCombatantSetup(
                lineupIndex: entry.key + 1,
                idPrefix: 'opponent',
              ),
            ),
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 17,
        moveCritical: 23,
        moveAccuracy: 31,
        generic: 47,
      ),
      canFlee: request is WildBattleStartRequest,
    );
  }

  ProjectTrainerEntry _findTrainer(ProjectManifest manifest, String trainerId) {
    final normalizedTrainerId = trainerId.trim();
    for (final trainer in manifest.trainers) {
      if (trainer.id == normalizedTrainerId) {
        return trainer;
      }
    }

    throw RuntimeBattleSetupException(
      'Dresseur introuvable pour démarrer le combat.',
      debugDetails: 'trainerId=$trainerId',
    );
  }
}

final class _RuntimePsdkBattleEnemyLineup {
  const _RuntimePsdkBattleEnemyLineup({
    required this.active,
    required this.reserve,
  });

  final RuntimePsdkBattleCombatantSeed active;
  final List<RuntimePsdkBattleCombatantSeed> reserve;
}
