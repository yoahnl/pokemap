import 'battle_action.dart';

/// Seam battle-local de choix d'action adverse.
///
/// Ce contrat existe pour une raison volontairement étroite dans le lot 3 :
/// - sortir la sélection du move adverse de `battle_session.dart` ;
/// - empêcher le futur lot difficulté de réinjecter cette logique au milieu de
///   la session ;
/// - mais sans ouvrir dès maintenant un framework d'IA, des profils multiples,
///   du switch intelligent ou du targeting riche.
///
/// Frontières non négociables de ce seam :
/// - il ne choisit qu'entre des `BattleActionFight` déjà jugées légales ;
/// - il ne reçoit ni `BattleSession`, ni queue, ni request, ni scheduler ;
/// - il ne gère ni switch, ni replacement, ni `Run`, ni `Capture` ;
/// - il ne synthétise pas une nouvelle action : il doit retourner l'une des
///   actions fight fournies.
abstract interface class BattleOpponentPolicy {
  /// Choisit l'action fight adverse à jouer parmi les options déjà légales.
  ///
  /// Le contrat reste volontairement petit :
  /// - la session battle continue à décider quels moves sont encore utilisables
  ///   et à gérer les dead-ends explicites ;
  /// - la policy ne fait qu'arbitrer entre ces actions fight déjà prêtes ;
  /// - cela garde ce seam strictement dans le lot 3 au lieu de glisser vers
  ///   un mini-système d'IA générique.
  BattleActionFight chooseFightAction({
    required List<BattleActionFight> legalFightActions,
  });
}

/// Policy adverse par défaut du dépôt.
///
/// Le lot 3 garde volontairement un comportement équivalent à l'existant :
/// - aucune difficulté ;
/// - aucune heuristique de puissance, type ou statut ;
/// - aucune variabilité pseudo-aléatoire ;
/// - simplement le premier move fight encore légal.
///
/// Ce nom explicite évite deux mensonges :
/// - appeler cette classe `DefaultBattleOpponentPolicy` ferait masquer le fait
///   que son comportement réel est "premier move légal" ;
/// - appeler cela "IA" ferait croire à un système plus riche qu'il ne l'est.
final class BattleFirstLegalOpponentPolicy implements BattleOpponentPolicy {
  const BattleFirstLegalOpponentPolicy();

  @override
  BattleActionFight chooseFightAction({
    required List<BattleActionFight> legalFightActions,
  }) {
    if (legalFightActions.isEmpty) {
      throw StateError(
        'BattleFirstLegalOpponentPolicy requiert au moins une action fight légale.',
      );
    }
    return legalFightActions.first;
  }
}
