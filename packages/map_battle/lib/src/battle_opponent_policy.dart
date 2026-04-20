import 'battle_action.dart';
import 'battle_move.dart';
import 'battle_state.dart';

/// Seam battle-local de choix d'action adverse.
///
/// Ce contrat a été introduit au lot 3 pour sortir la sélection adverse de
/// `battle_session.dart`, puis légèrement élargi au lot 5 pour couvrir un
/// second cas très précis : le replacement adverse forcé après un K.O.
///
/// Cette extension reste volontairement bornée :
/// - elle garde la logique de difficulté hors de la session elle-même ;
/// - elle donne enfin un effet battle réel à la difficulté trainer ;
/// - mais sans ouvrir un arbitrage global entre familles d'actions, sans
///   scripts trainer/boss, sans switch volontaire intelligent et sans
///   targeting riche.
///
/// Frontières non négociables de ce seam :
/// - il ne choisit qu'entre des `BattleActionFight` déjà jugées légales ;
/// - il ne choisit un replacement qu'entre des réserves déjà jugées légales ;
/// - il ne reçoit ni `BattleSession`, ni queue, ni request, ni scheduler ;
/// - il ne gère toujours ni switch volontaire, ni `Run`, ni `Capture` ;
/// - il ne synthétise pas une nouvelle action : il doit retourner l'une des
///   options fight ou replacement qui lui sont fournies.
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

  /// Choisit le replacement adverse forcé parmi les réserves déjà légales.
  ///
  /// Lot 5 garde cette question étroite pour éviter de dériver :
  /// - la session/scheduler continuent à décider quand un remplaçant est
  ///   requis ;
  /// - la policy n'arbitre pas "fight ou switch" ;
  /// - elle choisit seulement quel Pokémon déjà remplaçable doit entrer quand
  ///   l'adversaire est obligé de remplacer un K.O.
  BattleOpponentReplacementOption chooseReplacement({
    required List<BattleOpponentReplacementOption> legalReplacementOptions,
  });

  /// Choisit éventuellement un switch volontaire adverse minimal.
  ///
  /// Le lot 6 garde ce seam volontairement borné :
  /// - la session continue à déterminer les moves fight légaux et les réserves
  ///   effectivement switchables ;
  /// - la policy ne reçoit qu'un snapshot local du combattant actif, ses
  ///   options fight et ses options de réserve ;
  /// - elle peut soit rester simple (`null` => continuer à fight), soit
  ///   retourner une des options de switch déjà légales qui lui sont fournies ;
  /// - aucun arbitrage global `Run/Capture`, aucun targeting riche, aucun
  ///   script trainer/boss n'est ouvert ici.
  ///
  /// `didEnemySwitchLastTurn` sert de garde-fou anti-thrash minimal :
  /// - il ne crée pas un état d'IA persistant ;
  /// - il permet simplement d'interdire un reswitch volontaire immédiat ;
  /// - si ce booléen vaut vrai, une policy saine doit préférer rester simple.
  BattleOpponentReplacementOption? chooseVoluntarySwitch({
    required BattleCombatant activeCombatant,
    required List<BattleActionFight> legalFightActions,
    required List<BattleOpponentReplacementOption> legalSwitchOptions,
    required bool didEnemySwitchLastTurn,
  });
}

/// Option de replacement adverse déjà jugée légale par le moteur.
///
/// Ce type reste battle-local et volontairement pauvre :
/// - le scheduler filtre les réserves déjà K.O. avant d'arriver ici ;
/// - la policy reçoit juste l'index de réserve réellement switchable et le
///   combattant correspondant ;
/// - on évite ainsi de passer la session entière, la queue ou un contexte
///   d'IA surdimensionné pour un lot 5 qui doit rester petit.
final class BattleOpponentReplacementOption {
  const BattleOpponentReplacementOption({
    required this.reserveIndex,
    required this.combatant,
  });

  final int reserveIndex;
  final BattleCombatant combatant;
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
/// - le mapping couvre maintenant `fight` et le replacement forcé ;
/// - mais il ne prépare toujours ni scripts trainer, ni switch volontaire,
///   ni targeting plus riche.
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
/// - simplement le premier move fight encore légal et le premier remplaçant
///   encore utilisable.
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

  @override
  BattleOpponentReplacementOption chooseReplacement({
    required List<BattleOpponentReplacementOption> legalReplacementOptions,
  }) {
    if (legalReplacementOptions.isEmpty) {
      throw StateError(
        'BattleFirstLegalOpponentPolicy requiert au moins une option de replacement légale.',
      );
    }
    return legalReplacementOptions.first;
  }

  @override
  BattleOpponentReplacementOption? chooseVoluntarySwitch({
    required BattleCombatant activeCombatant,
    required List<BattleActionFight> legalFightActions,
    required List<BattleOpponentReplacementOption> legalSwitchOptions,
    required bool didEnemySwitchLastTurn,
  }) {
    return null;
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
/// - lot 5 lui ajoute un replacement forcé du même esprit :
///   choisir le remplaçant avec la pression offensive brute la plus forte ;
/// - aucune prise en compte du switch volontaire, du targeting ou de scripts
///   trainer n'est introduite ici.
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

  @override
  BattleOpponentReplacementOption chooseReplacement({
    required List<BattleOpponentReplacementOption> legalReplacementOptions,
  }) {
    return _pickBestReplacementOption(
      legalReplacementOptions: legalReplacementOptions,
      scoreCombatant: _rawReplacementScore,
      emptyListError:
          'BattleHighestPowerOpponentPolicy requiert au moins une option de replacement légale.',
    );
  }

  @override
  BattleOpponentReplacementOption? chooseVoluntarySwitch({
    required BattleCombatant activeCombatant,
    required List<BattleActionFight> legalFightActions,
    required List<BattleOpponentReplacementOption> legalSwitchOptions,
    required bool didEnemySwitchLastTurn,
  }) {
    return _chooseMinimalVoluntarySwitch(
      activeCombatant: activeCombatant,
      legalFightActions: legalFightActions,
      legalSwitchOptions: legalSwitchOptions,
      didEnemySwitchLastTurn: didEnemySwitchLastTurn,
      activeFightScore: _bestFightActionScore(
        legalFightActions: legalFightActions,
        moveScore: _rawPowerScore,
      ),
      switchOptionScore: _rawReplacementScore,
      clearGainThreshold: 60.0,
      lowPressureThreshold: 0.0,
      lowHpThreshold: 0.0,
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
/// - et, au lot 5, préférer lors d'un replacement forcé un attaquant qui
///   reste à la fois menaçant, rapide et encore suffisamment sain ;
/// - ce qui donne un profil haut de gamme un peu plus dangereux sans
///   prétendre devenir une IA riche.
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

  @override
  BattleOpponentReplacementOption chooseReplacement({
    required List<BattleOpponentReplacementOption> legalReplacementOptions,
  }) {
    return _pickBestReplacementOption(
      legalReplacementOptions: legalReplacementOptions,
      scoreCombatant: _calculatedReplacementScore,
      emptyListError:
          'BattleHighestExpectedPowerOpponentPolicy requiert au moins une option de replacement légale.',
    );
  }

  @override
  BattleOpponentReplacementOption? chooseVoluntarySwitch({
    required BattleCombatant activeCombatant,
    required List<BattleActionFight> legalFightActions,
    required List<BattleOpponentReplacementOption> legalSwitchOptions,
    required bool didEnemySwitchLastTurn,
  }) {
    final activeFightScore = _bestFightActionScore(
      legalFightActions: legalFightActions,
      moveScore: _expectedPowerScore,
    );
    return _chooseMinimalVoluntarySwitch(
      activeCombatant: activeCombatant,
      legalFightActions: legalFightActions,
      legalSwitchOptions: legalSwitchOptions,
      didEnemySwitchLastTurn: didEnemySwitchLastTurn,
      activeFightScore: activeFightScore,
      switchOptionScore: _calculatedReplacementScore,
      clearGainThreshold: 25.0,
      lowPressureThreshold: 20.0,
      lowHpThreshold: 0.25,
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

double _bestFightActionScore({
  required List<BattleActionFight> legalFightActions,
  required double Function(BattleMove move) moveScore,
}) {
  var bestScore = 0.0;
  for (final action in legalFightActions) {
    final candidateScore = moveScore(action.move);
    if (candidateScore > bestScore) {
      bestScore = candidateScore;
    }
  }
  return bestScore;
}

BattleOpponentReplacementOption _pickBestReplacementOption({
  required List<BattleOpponentReplacementOption> legalReplacementOptions,
  required double Function(BattleCombatant combatant) scoreCombatant,
  required String emptyListError,
}) {
  if (legalReplacementOptions.isEmpty) {
    throw StateError(emptyListError);
  }

  var bestOption = legalReplacementOptions.first;
  var bestScore = scoreCombatant(bestOption.combatant);
  for (final option in legalReplacementOptions.skip(1)) {
    final optionScore = scoreCombatant(option.combatant);
    if (optionScore > bestScore) {
      bestOption = option;
      bestScore = optionScore;
    }
  }
  return bestOption;
}

double _rawReplacementScore(BattleCombatant combatant) {
  return _bestDamagingMoveScore(
    combatant: combatant,
    moveScore: _rawPowerScore,
  );
}

double _calculatedReplacementScore(BattleCombatant combatant) {
  final expectedDamagePressure = _bestDamagingMoveScore(
    combatant: combatant,
    moveScore: _expectedPowerScore,
  );
  if (expectedDamagePressure <= 0) {
    return 0.0;
  }

  // Lot 5 reste volontairement petit :
  // - pas de lookahead multi-tour ;
  // - pas de type pressure complète ;
  // - pas de simulation de dégâts ;
  // - juste un léger lift crédible pour départager deux remplaçants déjà
  //   offensifs selon leur vitesse et leur marge de survie immédiate.
  final hpRatio =
      combatant.maxHp <= 0 ? 0.0 : combatant.currentHp / combatant.maxHp;
  final speedPressure = combatant.stats.speed * 0.35;
  final healthPressure = hpRatio * 40.0;
  return expectedDamagePressure + speedPressure + healthPressure;
}

BattleOpponentReplacementOption? _chooseMinimalVoluntarySwitch({
  required BattleCombatant activeCombatant,
  required List<BattleActionFight> legalFightActions,
  required List<BattleOpponentReplacementOption> legalSwitchOptions,
  required bool didEnemySwitchLastTurn,
  required double activeFightScore,
  required double Function(BattleCombatant combatant) switchOptionScore,
  required double clearGainThreshold,
  required double lowPressureThreshold,
  required double lowHpThreshold,
}) {
  if (didEnemySwitchLastTurn ||
      legalFightActions.isEmpty ||
      legalSwitchOptions.isEmpty) {
    return null;
  }

  final hpRatio = activeCombatant.maxHp <= 0
      ? 0.0
      : activeCombatant.currentHp / activeCombatant.maxHp;
  final activeIsLowPressure = activeFightScore <= lowPressureThreshold;
  final activeIsLowHp = lowHpThreshold > 0.0 && hpRatio <= lowHpThreshold;
  if (!activeIsLowPressure && !activeIsLowHp) {
    return null;
  }

  final activeStayScore = activeFightScore +
      (activeCombatant.stats.speed * 0.35) +
      (hpRatio * 40.0);

  BattleOpponentReplacementOption? bestOption;
  var bestOptionScore = 0.0;
  for (final option in legalSwitchOptions) {
    final optionScore = switchOptionScore(option.combatant);
    if (optionScore > bestOptionScore || bestOption == null) {
      bestOption = option;
      bestOptionScore = optionScore;
    }
  }

  if (bestOption == null || bestOptionScore <= 0.0) {
    return null;
  }
  if (bestOptionScore - activeStayScore < clearGainThreshold) {
    return null;
  }
  return bestOption;
}

double _bestDamagingMoveScore({
  required BattleCombatant combatant,
  required double Function(BattleMove move) moveScore,
}) {
  var bestScore = 0.0;
  for (final move in combatant.moves) {
    if (!move.hasUsablePp) {
      continue;
    }
    final candidateScore = moveScore(move);
    if (candidateScore > bestScore) {
      bestScore = candidateScore;
    }
  }
  return bestScore;
}
