import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'battle_start_request.dart';
import 'runtime_battle_combatant_seed_builder.dart';
import 'runtime_battle_setup_mapper.dart';
import 'runtime_map_bundle.dart';
import 'runtime_item_catalog_loader.dart';
import 'runtime_move_catalog_loader.dart';

/// Mapper runtime vers le setup de combat PSDK.
///
/// Il réutilise la même sélection de lineup et les mêmes loaders que le mapper
/// legacy, mais assemble un `PsdkBattleSetup` pour que les moves portés PSDK ne
/// soient plus bloqués par le petit bridge `BattleMoveData`.
final class RuntimePsdkBattleSetupMapper {
  RuntimePsdkBattleSetupMapper({
    RuntimeMoveCatalogLoader? moveCatalogLoader,
    RuntimeItemCatalogLoader? itemCatalogLoader,
    RuntimeBattleCombatantSeedBuilder? combatantSeedBuilder,
  })  : moveCatalogLoader = moveCatalogLoader ?? RuntimeMoveCatalogLoader(),
        itemCatalogLoader =
            itemCatalogLoader ?? const RuntimeItemCatalogLoader(),
        combatantSeedBuilder =
            combatantSeedBuilder ?? RuntimeBattleCombatantSeedBuilder();

  final RuntimeMoveCatalogLoader moveCatalogLoader;
  final RuntimeItemCatalogLoader itemCatalogLoader;
  final RuntimeBattleCombatantSeedBuilder combatantSeedBuilder;

  bool requiresDoubles(ProjectManifest manifest, BattleStartRequest request) {
    final trainerId = switch (request) {
      TrainerBattleStartRequest(:final trainerId) => trainerId,
      StaticBattleStartRequest(:final opponentProfileId) => opponentProfileId,
      WildBattleStartRequest() => null,
    };
    return trainerId != null &&
        _findTrainer(manifest, trainerId).battleFormat == BattleFormat.doubles;
  }

  Future<PsdkBattleSetup> map({
    required RuntimeMapBundle bundle,
    required GameState gameState,
    required BattleStartRequest request,
    int? playerPartyIndex,
    ItemCatalogSnapshot? itemCatalog,
  }) async {
    final doubles = requiresDoubles(bundle.manifest, request);
    if (doubles && request is! TrainerBattleStartRequest) {
      throw RuntimeBattleSetupException(
        'Le format duo est réservé aux combats de dresseurs.',
      );
    }
    if (doubles &&
        bundle.manifest.pokemon.ruleset.mechanics.disabledFeatures
            .contains(PokemonDisabledFeature.doubleBattles)) {
      throw RuntimeBattleSetupException(
        'Le profil de règles du projet ne permet pas les combats duo.',
      );
    }
    final resolvedItemCatalog = itemCatalog ??
        await itemCatalogLoader.loadSnapshot(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
        );
    final movesCatalog = await moveCatalogLoader.load(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
    );
    final playerSelection = RuntimeBattleSetupMapper().selectPlayerBattleLineup(
      gameState.party,
      playerPartyIndex: playerPartyIndex,
      activeCount: doubles ? 2 : 1,
    );
    final playerPokemon = gameState.party.members[playerSelection.activeIndex];

    final playerSeed = await combatantSeedBuilder.buildPlayerPsdkCombatantSeed(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
      movesCatalog: movesCatalog,
      itemCatalog: resolvedItemCatalog,
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
          itemCatalog: resolvedItemCatalog,
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
          if (doubles && trainer.team.length < 2) {
            throw RuntimeBattleSetupException(
              'Un combat duo exige deux Pokémon dans l’équipe du dresseur.',
              debugDetails: 'trainerId=${trainer.id}',
            );
          }

          final activeSeed =
              await combatantSeedBuilder.buildTrainerPsdkCombatantSeed(
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: bundle.manifest.pokemon,
            movesCatalog: movesCatalog,
            itemCatalog: resolvedItemCatalog,
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
                itemCatalog: resolvedItemCatalog,
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
      StaticBattleStartRequest() => () async {
          final opponent =
              _findTrainer(bundle.manifest, request.opponentProfileId);
          if (opponent.team.isEmpty) {
            throw RuntimeBattleSetupException(
              'Le boss statique "${opponent.name}" n’a aucun Pokémon authoré.',
              debugDetails: 'opponentProfileId=${opponent.id}',
            );
          }

          final activeSeed =
              await combatantSeedBuilder.buildTrainerPsdkCombatantSeed(
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: bundle.manifest.pokemon,
            movesCatalog: movesCatalog,
            itemCatalog: resolvedItemCatalog,
            teamMember: opponent.team.first,
            trainerName: opponent.name,
          );
          final reserveSeeds = <RuntimePsdkBattleCombatantSeed>[];
          for (final teamMember in opponent.team.skip(1)) {
            reserveSeeds.add(
              await combatantSeedBuilder.buildTrainerPsdkCombatantSeed(
                projectRootDirectory: bundle.projectRootDirectory,
                pokemonConfig: bundle.manifest.pokemon,
                movesCatalog: movesCatalog,
                itemCatalog: resolvedItemCatalog,
                teamMember: teamMember,
                trainerName: opponent.name,
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

    const rngSeeds = PsdkBattleRngSeeds(
      moveDamage: 17,
      moveCritical: 23,
      moveAccuracy: 31,
      generic: 47,
    );
    if (doubles) {
      final player = [playerSeed, ...playerReserveSeeds];
      final opponent = [enemyLineup.active, ...enemyLineup.reserve];
      PsdkBattleCombatantSetup project(
        RuntimePsdkBattleCombatantSeed seed,
        int index,
        String prefix,
      ) => seed.toPsdkBattleCombatantSetup(
        lineupIndex: index,
        idPrefix: prefix,
      );
      return PsdkBattleSetup.doubles(
        ruleset: bundle.manifest.pokemon.ruleset,
        player: [
          for (var index = 0; index < 2; index++)
            project(player[index], index, 'player'),
        ],
        playerReserves: [
          for (var index = 2; index < player.length; index++)
            project(player[index], index, 'player'),
        ],
        opponent: [
          for (var index = 0; index < 2; index++)
            project(opponent[index], index, 'opponent'),
        ],
        opponentReserves: [
          for (var index = 2; index < opponent.length; index++)
            project(opponent[index], index, 'opponent'),
        ],
        rngSeeds: rngSeeds,
      );
    }
    return PsdkBattleSetup.singles(
      ruleset: bundle.manifest.pokemon.ruleset,
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
      rngSeeds: rngSeeds,
      canFlee: request.allowsPlayerFlee,
      canCapture: request is WildBattleStartRequest &&
          playerHasAtLeastOneRuntimeCaptureItem(
            gameState.bag,
            ItemCapabilityResolver(resolvedItemCatalog),
            encounterKind: request.encounterKind,
          ),
      isTrainerBattle: request is TrainerBattleStartRequest,
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
