import 'battle_action.dart';
import 'battle_move.dart';

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

/// Route une difficulté produit `1..10` vers un petit nombre de profiles.
///
/// Ce helper existe pour garder le lot 4 honnête et borné :
/// - la difficulté visible produit reste bien un entier simple ;
/// - le battle-core ne crée pas pour autant 10 IA différentes ;
/// - le runtime peut demander une policy battle-local sans réinjecter la
///   logique de difficulté dans `battle_session.dart`.
///
/// Garde-fous explicites :
/// - `null` revient au comportement historique du dépôt ;
/// - les valeurs hors plage sont clampées à `[1, 10]` au lieu d'ouvrir ici un
///   nouveau système global de validation produit ;
/// - le mapping reste fight-only et ne prépare ni scripts trainer, ni switch,
///   ni replacement, ni targeting plus riche.
BattleOpponentPolicy battleOpponentPolicyForDifficulty(int? difficulty) {
  final clampedDifficulty = difficulty == null
      ? null
      : difficulty.clamp(1, 10);
  final profile = _BattleOpponentDifficultyProfile.fromProductDifficulty(
    clampedDifficulty,
  );
  return switch (profile) {
    _BattleOpponentDifficultyProfile.basic =>
      const BattleFirstLegalOpponentPolicy(),
    _BattleOpponentDifficultyProfile.aggressive =>
      const BattleHighestPowerOpponentPolicy(),
    _BattleOpponentDifficultyProfile.calculated =>
      const BattleHighestExpectedPowerOpponentPolicy(),
  };
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

/// Policy adverse "agressive" minimaliste du lot 4.
///
/// Pourquoi elle existe :
/// - donner au routing de difficulté un vrai profil intermédiaire ;
/// - sans demander plus de contexte battle que la liste des actions fight déjà
///   légales ;
/// - sans réimplémenter un calcul de dégâts complet ou une IA contextuelle.
///
/// Invariants de périmètre :
/// - seuls les moves offensifs avec `power > 0` marquent des points ;
/// - si toutes les actions sont purement de statut, on retombe sur le premier
///   move légal pour garder un comportement stable et lisible ;
/// - aucune prise en compte du switch, du replacement, du targeting ou de
///   scripts trainer n'est introduite ici.
final class BattleHighestPowerOpponentPolicy implements BattleOpponentPolicy {
  const BattleHighestPowerOpponentPolicy();

  @override
  BattleActionFight chooseFightAction({
    required List<BattleActionFight> legalFightActions,
  }) {
    return _pickBestFightAction(
      legalFightActions: legalFightActions,
      scoreMove: _rawPowerScore,
      emptyListError:
          'BattleHighestPowerOpponentPolicy requiert au moins une action fight légale.',
    );
  }
}

/// Policy adverse "calculée" du lot 4.
///
/// Cette policy reste volontairement modeste :
/// - elle ne simule pas un tour complet ;
/// - elle ne lit pas `BattleSession` ;
/// - elle n'essaie pas d'estimer les hazards, statuts, switches ou scripts.
///
/// Elle fait uniquement mieux que le profil intermédiaire sur un point :
/// - pondérer la puissance offensive par la précision disponible ;
/// - ce qui donne un profil haut de gamme plus fiable sans prétendre devenir
///   une IA riche.
final class BattleHighestExpectedPowerOpponentPolicy
    implements BattleOpponentPolicy {
  const BattleHighestExpectedPowerOpponentPolicy();

  @override
  BattleActionFight chooseFightAction({
    required List<BattleActionFight> legalFightActions,
  }) {
    return _pickBestFightAction(
      legalFightActions: legalFightActions,
      scoreMove: _expectedPowerScore,
      emptyListError:
          'BattleHighestExpectedPowerOpponentPolicy requiert au moins une action fight légale.',
    );
  }
}

enum _BattleOpponentDifficultyProfile {
  basic,
  aggressive,
  calculated;

  static _BattleOpponentDifficultyProfile fromProductDifficulty(
    int? difficulty,
  ) {
    if (difficulty == null) {
      return _BattleOpponentDifficultyProfile.basic;
    }
    if (difficulty <= 3) {
      return _BattleOpponentDifficultyProfile.basic;
    }
    if (difficulty <= 7) {
      return _BattleOpponentDifficultyProfile.aggressive;
    }
    return _BattleOpponentDifficultyProfile.calculated;
  }
}

BattleActionFight _pickBestFightAction({
  required List<BattleActionFight> legalFightActions,
  required double Function(BattleMove move) scoreMove,
  required String emptyListError,
}) {
  if (legalFightActions.isEmpty) {
    throw StateError(emptyListError);
  }

  // Le tie-break garde volontairement l'ordre des actions fournies par la
  // session. Cela évite d'ajouter une seconde couche de pseudo-random ou de
  // hiérarchie cachée alors que le lot 4 veut seulement router vers quelques
  // profils stables et lisibles.
  var bestAction = legalFightActions.first;
  var bestScore = scoreMove(bestAction.move);
  for (final action in legalFightActions.skip(1)) {
    final actionScore = scoreMove(action.move);
    if (actionScore > bestScore) {
      bestAction = action;
      bestScore = actionScore;
    }
  }
  return bestAction;
}

double _rawPowerScore(BattleMove move) {
  if (move.resolvedCategory == BattleMoveCategory.status || move.power <= 0) {
    return 0.0;
  }
  return move.power.toDouble();
}

double _expectedPowerScore(BattleMove move) {
  final rawPower = _rawPowerScore(move);
  if (rawPower <= 0) {
    return 0.0;
  }
  final accuracyMultiplier =
      move.accuracy.isAlwaysHits ? 1.0 : move.accuracy.value / 100.0;
  return rawPower * accuracyMultiplier;
}
