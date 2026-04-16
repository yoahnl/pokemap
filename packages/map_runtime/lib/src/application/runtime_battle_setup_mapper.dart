import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_combatant_seed_builder.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_map_bundle.dart';
import 'runtime_move_catalog_loader.dart';

export 'runtime_battle_setup_exception.dart' show RuntimeBattleSetupException;

const _runtimeCapturePokeBallItemId = 'poke-ball';
const _runtimeCapturePokeBallCategoryId = 'items';

/// Mapper runtime unique vers [BattleSetup].
///
/// Important :
/// - cette classe reste locale à `map_runtime` ;
/// - elle ne réintroduit pas de dépendance vers `map_editor` ;
/// - elle relit uniquement le strict nécessaire des données Pokémon projet
///   pour construire le setup de combat réel.
///
/// M5 introduit un seam runtime spécialisé pour les moves parce que :
/// - le catalogue moves est maintenant canonique et beaucoup plus riche ;
/// - `runtime_battle_setup_mapper.dart` ne doit plus relire `moves.json`
///   comme un tuple pauvre `id/name/power` ;
/// - `map_battle` ne doit toujours pas lire le JSON projet brut.
///
/// M6 poursuit cette extraction pour les espèces et learnsets :
/// - le mapper ne relit plus lui-même ces JSON projet ;
/// - il délègue à de petits loaders runtime spécialisés ;
/// - il reste centré sur la composition combat, pas sur la plomberie locale.
///
/// M7 poursuit dans la même direction :
/// - le mapper ne construit plus lui-même les seeds de combattants ;
/// - il délègue cette projection à un builder spécialisé ;
/// - il garde seulement l'orchestration de haut niveau, la politique de
///   capture et les sélections exactes qui appartiennent encore au runtime.
class RuntimeBattleSetupMapper {
  const RuntimeBattleSetupMapper({
    this.moveCatalogLoader = const RuntimeMoveCatalogLoader(),
    this.combatantSeedBuilder = const RuntimeBattleCombatantSeedBuilder(),
  });

  final RuntimeMoveCatalogLoader moveCatalogLoader;
  final RuntimeBattleCombatantSeedBuilder combatantSeedBuilder;

  Future<BattleSetup> map({
    required RuntimeMapBundle bundle,
    required GameState gameState,
    required BattleStartRequest request,
    int? playerPartyIndex,
  }) async {
    final movesCatalog = await moveCatalogLoader.load(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
    );
    final playerSelection = selectPlayerBattleLineup(
      gameState.party,
      playerPartyIndex: playerPartyIndex,
    );
    final playerPokemon = gameState.party.members[playerSelection.activeIndex];

    final playerSeed = await combatantSeedBuilder.buildPlayerCombatantSeed(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
      movesCatalog: movesCatalog,
      playerPokemon: playerPokemon,
    );
    final playerReserveSeeds = <RuntimeBattleCombatantSeed>[];
    for (final reserveIndex in playerSelection.reserveIndices) {
      playerReserveSeeds.add(
        await combatantSeedBuilder.buildPlayerCombatantSeed(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          movesCatalog: movesCatalog,
          playerPokemon: gameState.party.members[reserveIndex],
        ),
      );
    }

    final enemyLineup = await switch (request) {
      WildBattleStartRequest() => combatantSeedBuilder
          .buildWildCombatantSeed(
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: bundle.manifest.pokemon,
            movesCatalog: movesCatalog,
            request: request,
          )
          .then(
            (seed) => _RuntimeBattleEnemyLineup(
              active: seed,
              reserve: const <RuntimeBattleCombatantSeed>[],
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
              await combatantSeedBuilder.buildTrainerCombatantSeed(
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: bundle.manifest.pokemon,
            movesCatalog: movesCatalog,
            teamMember: trainer.team.first,
            trainerName: trainer.name,
          );
          final reserveSeeds = <RuntimeBattleCombatantSeed>[];
          for (final teamMember in trainer.team.skip(1)) {
            reserveSeeds.add(
              await combatantSeedBuilder.buildTrainerCombatantSeed(
                projectRootDirectory: bundle.projectRootDirectory,
                pokemonConfig: bundle.manifest.pokemon,
                movesCatalog: movesCatalog,
                teamMember: teamMember,
                trainerName: trainer.name,
              ),
            );
          }
          return _RuntimeBattleEnemyLineup(
            active: activeSeed,
            reserve:
                List<RuntimeBattleCombatantSeed>.unmodifiable(reserveSeeds),
          );
        }(),
    };

    return BattleSetup(
      playerPokemon: playerSeed.toBattleCombatantData(lineupIndex: 0),
      playerReservePokemon: List<BattleCombatantData>.unmodifiable(
        playerReserveSeeds.asMap().entries.map(
              (entry) => entry.value.toBattleCombatantData(
                lineupIndex: entry.key + 1,
              ),
            ),
      ),
      enemyPokemon: enemyLineup.active.toBattleCombatantData(lineupIndex: 0),
      enemyReservePokemon: List<BattleCombatantData>.unmodifiable(
        enemyLineup.reserve.asMap().entries.map(
              (entry) => entry.value.toBattleCombatantData(
                lineupIndex: entry.key + 1,
              ),
            ),
      ),
      isTrainerBattle: request is TrainerBattleStartRequest,
      trainerId:
          request is TrainerBattleStartRequest ? request.trainerId : null,
      // Le moteur battle ne connaît ni le bag runtime, ni les limites de party.
      // On garde donc la décision de "peut-on capturer ?" ici, au point où le
      // runtime possède encore les vraies données save/projet nécessaires.
      //
      // Lot 14 reste volontairement borné :
      // - combat sauvage uniquement ;
      // - aucune capture si la party est pleine (pas de PC/boxes ici) ;
      // - aucune capture sans Poké Ball réelle dans le bag du joueur.
      allowCapture: request is WildBattleStartRequest &&
          gameState.party.members.length < 6 &&
          _playerHasAtLeastOnePokeBall(gameState.bag),
    );
  }

  /// Sélectionne la lineup battle minimale du joueur : actif + réserves.
  ///
  /// Politique BE10 volontairement bornée :
  /// - l'actif reste soit l'index explicitement demandé, soit le premier
  ///   membre jouable ;
  /// - la réserve ne contient que les autres membres encore vivants ;
  /// - les membres déjà K.O. restent dans la save runtime, mais ne sont pas
  ///   injectés dans la lineup battle puisqu'ils ne seraient jamais
  ///   switchables honnêtement ;
  /// - l'ordre de réserve suit l'ordre de party réel, de façon stable.
  RuntimePlayerBattleLineupSelection selectPlayerBattleLineup(
    PlayerParty party, {
    int? playerPartyIndex,
  }) {
    final activeIndex = playerPartyIndex ?? selectUsablePartyMemberIndex(party);
    if (activeIndex < 0 || activeIndex >= party.members.length) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est invalide.',
        debugDetails:
            'playerPartyIndex=$activeIndex, partyLength=${party.members.length}',
      );
    }

    final activeMember = party.members[activeIndex];
    if (activeMember.isFainted) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est déjà K.O.',
        debugDetails:
            'playerPartyIndex=$activeIndex, speciesId=${activeMember.speciesId}',
      );
    }

    final reserveIndices = <int>[];
    for (var i = 0; i < party.members.length; i++) {
      if (i == activeIndex || party.members[i].isFainted) {
        continue;
      }
      reserveIndices.add(i);
    }

    return RuntimePlayerBattleLineupSelection(
      activeIndex: activeIndex,
      reserveIndices: List<int>.unmodifiable(reserveIndices),
    );
  }

  /// Retourne l'index du slot réellement utilisé pour le handoff combat.
  ///
  /// Le runtime lot 10 doit mémoriser cet index exact pour réécrire les PV du
  /// bon membre après le combat. On expose donc explicitement cette sélection
  /// au lieu de forcer [PlayableMapGame] à dupliquer la logique.
  int selectUsablePartyMemberIndex(PlayerParty party) {
    // Cette sélection reste volontairement dans le mapper :
    // - `PlayableMapGame` l'utilise déjà pour mémoriser le slot à réécrire
    //   après le combat ;
    // - elle relève d'une décision d'orchestration runtime de haut niveau,
    //   pas d'un assemblage de seed de combattant ;
    // - l'extraire dans le builder brouillerait la frontière M7 pour peu de
    //   valeur réelle dans ce repo.
    for (var i = 0; i < party.members.length; i++) {
      if (!party.members[i].isFainted) {
        return i;
      }
    }

    if (party.members.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Impossible de lancer un combat sans Pokémon dans l’équipe du joueur.',
      );
    }

    throw const RuntimeBattleSetupException(
      'Tous les Pokémon de l’équipe du joueur sont K.O.; combat impossible.',
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

/// Sélection runtime de lineup battle du joueur.
///
/// Ce petit type évite de faire circuler des tuples implicites :
/// - `activeIndex` identifie le slot réellement actif au handoff ;
/// - `reserveIndices` garde l'ordre stable des réserves injectées dans
///   `BattleSetup` ;
/// - le runtime peut ensuite réutiliser exactement cette projection pour le
///   write-back post-combat.
final class RuntimePlayerBattleLineupSelection {
  const RuntimePlayerBattleLineupSelection({
    required this.activeIndex,
    required this.reserveIndices,
  });

  final int activeIndex;
  final List<int> reserveIndices;

  List<int> get lineupPartyIndices => <int>[activeIndex, ...reserveIndices];
}

final class _RuntimeBattleEnemyLineup {
  const _RuntimeBattleEnemyLineup({
    required this.active,
    required this.reserve,
  });

  final RuntimeBattleCombatantSeed active;
  final List<RuntimeBattleCombatantSeed> reserve;
}

/// Retourne `true` si le bag runtime contient au moins une Poké Ball exploitable.
///
/// Le guard vit ici plutôt que dans `map_battle` car :
/// - le moteur battle ne doit pas dépendre du système de bag ;
/// - le runtime est déjà la frontière qui décide si `allowCapture` peut être
///   activé pour une rencontre donnée ;
/// - le lot 14 n'ouvre pas un inventaire global ni une politique de capture.
///
/// On tolère des IDs non normalisés en mémoire (`" poke-ball "`) pour rester
/// robuste face à un état runtime pas encore passé par le pipeline save/load.
bool _playerHasAtLeastOnePokeBall(Bag bag) {
  for (final entry in bag.entries) {
    if (entry.itemId.trim() == _runtimeCapturePokeBallItemId &&
        entry.categoryId.trim() == _runtimeCapturePokeBallCategoryId &&
        entry.quantity > 0) {
      return true;
    }
  }
  return false;
}
