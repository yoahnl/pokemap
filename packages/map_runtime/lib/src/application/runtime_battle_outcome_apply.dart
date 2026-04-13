import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'story_flags_manager.dart';

const _runtimeCapturePokeBallItemId = 'poke-ball';
const _runtimeCapturePokeBallCategoryId = 'items';

/// Contexte runtime strictement nécessaire pour faire le write-back lot 10.
///
/// Invariant critique :
/// - [playerPartyIndex] est l'index exact du slot utilisé au moment du handoff
///   vers le combat ;
/// - il ne doit jamais être recalculé à la fin du combat ;
/// - même si le Pokémon actif finit K.O., on doit réécrire les PV sur ce slot
///   précis, pas sur "le premier Pokémon encore vivant".
///
/// Cette structure reste volontairement petite :
/// - la requête d'origine pour savoir si le combat était wild ou trainer ;
/// - l'index du slot joueur utilisé ;
/// - rien de plus.
class RuntimeActiveBattleContext {
  const RuntimeActiveBattleContext({
    required this.request,
    required this.playerPartyIndex,
  });

  final BattleStartRequest request;
  final int playerPartyIndex;
}

/// Applique le strict minimum de reprise après une vraie défaite joueur.
///
/// Pourquoi ce helper existe :
/// - le lot 10 écrit honnêtement les PV finaux du combat, y compris `0` ;
/// - le lot 15 doit éviter l'état absurde "retour overworld + toute la party K.O.
///   + aucun moyen de rejouer" ;
/// - on ne veut pourtant pas ouvrir un vrai centre Pokémon, ni un système de
///   whiteout complet, ni une logique multi-Pokémon.
///
/// Contrat volontairement petit :
/// - si au moins un Pokémon de la party est encore jouable, on ne soigne rien ;
/// - si toute la party est K.O., on relève uniquement le slot exact qui a servi
///   au combat à `1 HP` ;
/// - on garde ainsi la mémoire fidèle du write-back lot 10 sur tous les autres
///   slots, tout en garantissant qu'un prochain handoff runtime->battle restera
///   possible sans inventer un heal global.
///
/// Ce helper reste pur :
/// - il ne téléporte pas ;
/// - il ne touche ni au bag, ni aux flags trainer, ni à seen/caught ;
/// - le repositionnement runtime "whiteout-lite" reste géré par `PlayableMapGame`,
///   car lui seul connaît la carte réellement chargée et les seams de respawn.
GameState applyRuntimeDefeatRecoveryToGameState({
  required GameState gameState,
  required int playerPartyIndex,
}) {
  if (gameState.party.members.any((member) => !member.isFainted)) {
    return gameState;
  }

  final members = gameState.party.members;
  if (playerPartyIndex < 0 || playerPartyIndex >= members.length) {
    throw StateError(
      'Le whiteout-lite runtime pointe vers un slot party invalide: '
      'index=$playerPartyIndex, partyLength=${members.length}',
    );
  }

  final nextMembers = List<PlayerPokemon>.of(members, growable: false);
  final defeatedMember = nextMembers[playerPartyIndex];

  // Whiteout-lite lot 15 :
  // - on évite le softlock total après défaite ;
  // - on ne réanime qu'un seul Pokémon, sur le slot exact qui a combattu ;
  // - on ne transforme pas ce lot en heal center ou en reset complet de party.
  nextMembers[playerPartyIndex] = defeatedMember.copyWith(currentHp: 1);

  return gameState.copyWith(
    party: gameState.party.copyWith(members: nextMembers),
  );
}

/// Applique le résultat final du combat à l'état runtime.
///
/// Ce helper porte le write-back lot 10 dans un seul chemin explicite :
/// 1. écrire les PV finaux du Pokémon joueur sur le slot exact mémorisé ;
/// 2. marquer le trainer battu uniquement en cas de victoire trainer ;
/// 3. laisser intact tout ce qui appartient aux lots 11+.
///
/// Important :
/// - on ne soigne jamais implicitement le joueur ;
/// - on ne téléporte jamais ;
/// - le lot 13/14 ne gère qu'une capture sauvage minimale ;
/// - le lot 14 consomme exactement une Poké Ball au write-back runtime ;
/// - aucun bag UI, aucune récompense, aucun switch n'est ouvert ici ;
/// - on ne recalculera jamais naïvement le slot actif après le combat.
GameState applyRuntimeBattleOutcomeToGameState({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required BattleOutcome outcome,
  StoryFlagsManager storyFlagsManager = const StoryFlagsManager(),
}) {
  final stateWithPlayerHp = _writePlayerCurrentHpBackToExactPartySlot(
    gameState: gameState,
    partyIndex: context.playerPartyIndex,
    currentHp: outcome.finalState.player.currentHp,
  );

  final request = context.request;
  if (outcome.isCaptured) {
    if (request is! WildBattleStartRequest) {
      throw StateError(
        'BattleOutcomeType.captured est interdit hors combat sauvage.',
      );
    }

    // Garde-fou lot 13/14 :
    // le moteur ne doit normalement jamais proposer Capture si la party est
    // pleine ou sans Poké Ball, mais on revalide ici pour qu'un call site forcé
    // ne fasse jamais "disparaître" un Pokémon capturé faute de boîte/PC ou
    // contourne le coût réel de capture introduit par le lot 14.
    if (stateWithPlayerHp.party.members.length >= 6) {
      throw StateError(
        'Impossible d’ajouter un Pokémon capturé : la party du joueur est pleine.',
      );
    }

    final bagAfterConsumption =
        _consumeOnePokeBallOrThrow(stateWithPlayerHp.bag);
    final capturedPokemon = _buildCapturedWildPlayerPokemon(
      enemy: outcome.finalState.enemy,
    );
    final nextMembers = List<PlayerPokemon>.of(
      stateWithPlayerHp.party.members,
      growable: true,
    )..add(capturedPokemon);

    // Lot 12 garantit déjà "party -> caught -> seen". On réutilise donc cette
    // normalisation partagée au lieu d'introduire un deuxième pipeline Pokédex.
    return normalizeLoadedGameState(
      stateWithPlayerHp.copyWith(
        party: stateWithPlayerHp.party.copyWith(members: nextMembers),
        bag: bagAfterConsumption,
      ),
    );
  }

  if (outcome.isVictory && request is TrainerBattleStartRequest) {
    return storyFlagsManager.markTrainerDefeated(
      stateWithPlayerHp,
      request.trainerId,
    );
  }

  return stateWithPlayerHp;
}

const _capturedPokemonDefaultNatureId = 'hardy';
const _capturedPokemonFallbackAbilityId = 'unknown';

/// Construit le Pokémon réellement ajouté à la party après une capture sauvage.
///
/// Le lot 13 reste volontairement minimal :
/// - l'espèce, le niveau, l'ability et les moves viennent du vrai combattant
///   sauvage réellement engagé dans le moteur battle ;
/// - la nature reste un fallback MVP déterministe (`hardy`) faute de véritable
///   génération runtime existante ;
/// - on ne tente pas d'inventer ivs/evs/status/shiny/held item au-delà des
///   defaults du modèle `PlayerPokemon`.
///
/// Invariant important :
/// - une capture réussie ne doit jamais produire un Pokémon owned déjà K.O. ;
/// - si un call site forge un outcome capturé incohérent avec `enemyHp <= 0`,
///   on clamp donc les PV du Pokémon capturé à 1 minimum.
PlayerPokemon _buildCapturedWildPlayerPokemon({
  required BattleCombatant enemy,
}) {
  final normalizedAbilityId = enemy.abilityId.trim().isEmpty
      ? _capturedPokemonFallbackAbilityId
      : enemy.abilityId.trim();
  final normalizedMoveIds = enemy.moves
      .map((move) => move.id.trim())
      .where((moveId) => moveId.isNotEmpty)
      .toSet()
      .toList(growable: false);

  return PlayerPokemon(
    speciesId: enemy.speciesId.trim(),
    natureId: _capturedPokemonDefaultNatureId,
    abilityId: normalizedAbilityId,
    level: enemy.level,
    knownMoveIds: normalizedMoveIds,
    currentHp: enemy.currentHp <= 0 ? 1 : enemy.currentHp,
  );
}

/// Consomme exactement une Poké Ball du bag runtime.
///
/// Pourquoi le coût est appliqué ici :
/// - le moteur battle n'a pas à connaître le bag réel du joueur ;
/// - la capture n'est "réelle" qu'au moment où le runtime accepte d'écrire le
///   résultat dans le `GameState` ;
/// - cela donne une frontière de sécurité unique contre les appels forcés :
///   si aucun `poke-ball` n'existe, le write-back échoue explicitement.
///
/// Le lot 14 reste volontairement minimal :
/// - une seule ressource est concernée (`poke-ball` / `items`) ;
/// - aucune UI d'inventaire n'est ouverte ;
/// - aucun autre item n'est touché ;
/// - aucune entrée à quantité 0 ne doit survivre, car `BagEntry` l'interdit.
Bag _consumeOnePokeBallOrThrow(Bag bag) {
  final nextEntries = <BagEntry>[];
  var didConsumePokeBall = false;

  for (final entry in bag.entries) {
    final isCaptureBall =
        entry.itemId.trim() == _runtimeCapturePokeBallItemId &&
            entry.categoryId.trim() == _runtimeCapturePokeBallCategoryId;
    if (!isCaptureBall || didConsumePokeBall) {
      nextEntries.add(entry);
      continue;
    }

    didConsumePokeBall = true;
    final nextQuantity = entry.quantity - 1;
    if (nextQuantity > 0) {
      nextEntries.add(
        entry.copyWith(quantity: nextQuantity),
      );
    }
  }

  if (!didConsumePokeBall) {
    throw StateError(
      'Impossible d’appliquer BattleOutcomeType.captured sans Poké Ball dans le bag du joueur.',
    );
  }

  return Bag(entries: nextEntries).normalized();
}

/// Réécrit les PV du combattant joueur dans la vraie party runtime.
///
/// Ce helper encode la règle produit la plus importante du lot 10 :
/// l'écriture se fait sur [partyIndex], qui correspond au slot réellement
/// utilisé pendant le handoff lot 9.
///
/// On ne tente surtout pas de retrouver "le Pokémon actif" à partir de l'état
/// post-combat, car ce recalcul pourrait pointer vers un autre membre si le
/// combattant actif vient de tomber à 0 HP.
GameState _writePlayerCurrentHpBackToExactPartySlot({
  required GameState gameState,
  required int partyIndex,
  required int currentHp,
}) {
  final members = gameState.party.members;
  if (partyIndex < 0 || partyIndex >= members.length) {
    throw StateError(
      'RuntimeActiveBattleContext pointe vers un slot party invalide: '
      'index=$partyIndex, partyLength=${members.length}',
    );
  }

  final nextMembers = List<PlayerPokemon>.of(members, growable: false);
  final currentMember = nextMembers[partyIndex];
  nextMembers[partyIndex] = currentMember.copyWith(
    currentHp: currentHp < 0 ? 0 : currentHp,
  );

  return gameState.copyWith(
    party: gameState.party.copyWith(members: nextMembers),
  );
}
