import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'story_flags_manager.dart';

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
/// - on ne touche ni à la capture, ni au sac, ni à la récompense ;
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
  if (outcome.isVictory && request is TrainerBattleStartRequest) {
    return storyFlagsManager.markTrainerDefeated(
      stateWithPlayerHp,
      request.trainerId,
    );
  }

  return stateWithPlayerHp;
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
