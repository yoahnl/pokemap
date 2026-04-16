import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'story_flags_manager.dart';

const _runtimeCapturePokeBallItemId = 'poke-ball';
const _runtimeCapturePokeBallCategoryId = 'items';

/// Contexte runtime strictement nécessaire pour faire le write-back post-combat.
///
/// Invariant critique :
/// - [playerPartyIndex] est l'index exact du slot utilisé au moment du handoff
///   vers le combat ;
/// - il reste utile pour la compatibilité historique mono-slot et pour le
///   whiteout-lite ;
/// - BE10 ajoute en plus [playerPartySlotIndicesByLineupIndex] pour couvrir
///   honnêtement les combats où plusieurs membres sont réellement engagés.
///
/// Cette structure reste volontairement petite :
/// - la requête d'origine pour savoir si le combat était wild ou trainer ;
/// - l'index du slot joueur initial ;
/// - le mapping lineup battle -> slots runtime quand BE10 l'exige ;
/// - rien de plus.
class RuntimeActiveBattleContext {
  const RuntimeActiveBattleContext({
    required this.request,
    required this.playerPartyIndex,
    this.playerPartySlotIndicesByLineupIndex = const <int>[],
  });

  final BattleStartRequest request;
  final int playerPartyIndex;

  /// Mapping stable lineup battle joueur -> slots de party runtime.
  ///
  /// BE10 ajoute ce seam parce que le joueur peut désormais switcher pendant
  /// le combat :
  /// - `playerPartyIndex` seul ne suffit plus pour réécrire honnêtement les
  ///   PV de plusieurs membres engagés ;
  /// - le runtime mémorise donc l'ordre exact actif + réserves injecté dans
  ///   `BattleSetup` ;
  /// - `map_battle` garde ensuite une identité de lineup stable malgré les
  ///   switches, et le write-back peut retrouver les bons slots sans rejouer
  ///   l'historique du combat.
  ///
  /// Compatibilité volontaire :
  /// - l'ancien chemin mono-slot peut laisser cette liste vide ;
  /// - dans ce cas, le write-back retombe honnêtement sur le seul
  ///   `playerPartyIndex`.
  final List<int> playerPartySlotIndicesByLineupIndex;
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
  int? activePlayerLineupIndex,
  List<int> playerPartySlotIndicesByLineupIndex = const <int>[],
}) {
  if (gameState.party.members.any((member) => !member.isFainted)) {
    return gameState;
  }

  final members = gameState.party.members;
  final revivePartySlotIndex = _resolveDefeatRecoveryPartySlotIndex(
    partyLength: members.length,
    playerPartyIndex: playerPartyIndex,
    activePlayerLineupIndex: activePlayerLineupIndex,
    playerPartySlotIndicesByLineupIndex: playerPartySlotIndicesByLineupIndex,
  );

  if (revivePartySlotIndex < 0 || revivePartySlotIndex >= members.length) {
    throw StateError(
      'Le whiteout-lite runtime pointe vers un slot party invalide: '
      'index=$revivePartySlotIndex, partyLength=${members.length}',
    );
  }

  final nextMembers = List<PlayerPokemon>.of(members, growable: false);
  final defeatedMember = nextMembers[revivePartySlotIndex];

  // Whiteout-lite lot 15 :
  // - on évite le softlock total après défaite ;
  // - on ne réanime qu'un seul Pokémon, sur le slot exact qui était encore
  //   actif au moment de la défaite ;
  // - BE10 impose ce détail : après un switch, l'ancien slot initial ne doit
  //   plus être "magiquement" réanimé à la place du vrai Pokémon tombé ;
  // - on ne transforme pas ce lot en heal center ou en reset complet de party.
  nextMembers[revivePartySlotIndex] = defeatedMember.copyWith(currentHp: 1);

  return gameState.copyWith(
    party: gameState.party.copyWith(members: nextMembers),
  );
}

int _resolveDefeatRecoveryPartySlotIndex({
  required int partyLength,
  required int playerPartyIndex,
  required int? activePlayerLineupIndex,
  required List<int> playerPartySlotIndicesByLineupIndex,
}) {
  // Compatibilité volontaire :
  // - les anciens call sites mono-slot ne connaissent que playerPartyIndex ;
  // - BE10 ajoute un mapping lineup -> slots runtime pour éviter de réanimer
  //   le mauvais membre après un switch ;
  // - on ne force donc le nouveau chemin que quand les deux informations
  //   modernes sont réellement disponibles.
  if (playerPartySlotIndicesByLineupIndex.isEmpty ||
      activePlayerLineupIndex == null) {
    return playerPartyIndex;
  }

  if (activePlayerLineupIndex < 0 ||
      activePlayerLineupIndex >= playerPartySlotIndicesByLineupIndex.length) {
    throw StateError(
      'Le whiteout-lite runtime a reçu un lineupIndex joueur invalide: '
      'lineupIndex=$activePlayerLineupIndex, '
      'lineupLength=${playerPartySlotIndicesByLineupIndex.length}',
    );
  }

  final mappedPartyIndex =
      playerPartySlotIndicesByLineupIndex[activePlayerLineupIndex];
  if (mappedPartyIndex < 0 || mappedPartyIndex >= partyLength) {
    throw StateError(
      'Le whiteout-lite runtime a reçu un mapping lineup->party invalide: '
      'lineupIndex=$activePlayerLineupIndex, '
      'partyIndex=$mappedPartyIndex, partyLength=$partyLength',
    );
  }

  return mappedPartyIndex;
}

/// Applique le résultat final du combat à l'état runtime.
///
/// Ce helper porte le write-back lot 10 dans un seul chemin explicite :
/// 1. écrire les PV finaux du lineup joueur sur les slots exacts mémorisés ;
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
  final stateWithPlayerHp = _writePlayerBattleLineupBackToPartySlots(
    gameState: gameState,
    context: context,
    finalState: outcome.finalState,
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

/// Réécrit les PV des combattants joueur réellement engagés dans la vraie party.
///
/// BE10 remplace l'ancien write-back mono-slot par une projection minimale
/// mais honnête du lineup battle joueur :
/// - l'actif final et les réserves finales portent tous un `lineupIndex`
///   battle stable ;
/// - le contexte runtime connaît la correspondance lineup -> slots de party ;
/// - on réécrit donc chaque membre réellement engagé sur le bon slot save,
///   sans recalculer l'historique des switches.
///
/// Frontière volontairement bornée :
/// - on n'écrit encore que les PV, car le runtime hors combat ne possède pas
///   encore de write-back honnête des PP courants ni des statuts majeurs ;
/// - les membres de party non engagés dans ce combat restent inchangés.
GameState _writePlayerBattleLineupBackToPartySlots({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required BattleState finalState,
}) {
  final lineupToParty = context.playerPartySlotIndicesByLineupIndex.isEmpty
      ? <int>[context.playerPartyIndex]
      : context.playerPartySlotIndicesByLineupIndex;
  final playerLineup = <BattleCombatant>[
    finalState.player,
    ...finalState.playerReserve,
  ];

  if (playerLineup.length != lineupToParty.length) {
    throw StateError(
      'Le write-back runtime ne peut pas réconcilier une lineup battle et un mapping de party de tailles différentes: '
      'lineupLength=${playerLineup.length}, partyMappingLength=${lineupToParty.length}',
    );
  }

  final members = gameState.party.members;
  final nextMembers = List<PlayerPokemon>.of(members, growable: false);
  final seenLineupIndices = <int>{};

  for (final combatant in playerLineup) {
    final lineupIndex = combatant.lineupIndex;
    if (lineupIndex < 0 || lineupIndex >= lineupToParty.length) {
      throw StateError(
        'Le write-back runtime pointe vers un lineupIndex battle invalide: '
        'lineupIndex=$lineupIndex, mappingLength=${lineupToParty.length}',
      );
    }
    if (!seenLineupIndices.add(lineupIndex)) {
      throw StateError(
        'Le write-back runtime a rencontré deux combattants avec le même lineupIndex=$lineupIndex.',
      );
    }

    final partyIndex = lineupToParty[lineupIndex];
    if (partyIndex < 0 || partyIndex >= members.length) {
      throw StateError(
        'RuntimeActiveBattleContext pointe vers un slot party invalide: '
        'index=$partyIndex, partyLength=${members.length}',
      );
    }

    final currentMember = nextMembers[partyIndex];
    nextMembers[partyIndex] = currentMember.copyWith(
      currentHp: combatant.currentHp < 0 ? 0 : combatant.currentHp,
    );
  }

  return gameState.copyWith(
    party: gameState.party.copyWith(members: nextMembers),
  );
}
