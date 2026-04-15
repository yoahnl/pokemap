import 'battle_move.dart';

/// Choix disponible pour le joueur.
///
/// Représente une décision que le joueur peut prendre pendant son tour.
/// Ce modèle est utilisé par l'UI pour afficher les options disponibles.
sealed class PlayerBattleChoice {
  /// Constructeur constant pour les sous-classes.
  const PlayerBattleChoice();
}

/// Utiliser une attaque.
///
/// Le joueur choisit d'utiliser une de ses 4 attaques.
/// [moveIndex] est l'index dans la liste des attaques du Pokémon (0-3).
class PlayerBattleChoiceFight extends PlayerBattleChoice {
  /// Crée un choix d'attaque.
  ///
  /// [moveIndex] - L'index de l'attaque dans la liste (0-3).
  const PlayerBattleChoiceFight(this.moveIndex);

  /// L'index de l'attaque dans la liste des attaques du Pokémon.
  final int moveIndex;
}

/// Fuir le combat.
///
/// Le joueur choisit de tenter de fuir.
/// Pour ce MVP, la fuite est toujours réussie (simplification).
class PlayerBattleChoiceRun extends PlayerBattleChoice {
  /// Crée un choix de fuite.
  const PlayerBattleChoiceRun();
}

/// Capturer le Pokémon adverse.
///
/// Le lot 13 reste volontairement minimal :
/// - cette action n'est légitime qu'en combat sauvage ;
/// - elle ne modélise ni sac, ni consommation d'objet, ni formule canonique ;
/// - elle sert uniquement à produire un outcome explicite que le runtime
///   pourra écrire honnêtement dans la vraie party du joueur.
class PlayerBattleChoiceCapture extends PlayerBattleChoice {
  /// Crée un choix de capture.
  const PlayerBattleChoiceCapture();
}

/// Action résolue (interne au moteur de combat).
///
/// Contrairement à [PlayerBattleChoice] qui est un choix UI,
/// [BattleAction] représente l'action après résolution (attaque sélectionnée, etc.).
sealed class BattleAction {
  /// Constructeur constant pour les sous-classes.
  const BattleAction();
}

/// Utiliser une attaque (action résolue).
///
/// Contient l'attaque réelle à exécuter, pas juste l'index.
class BattleActionFight extends BattleAction {
  /// Crée une action d'attaque.
  ///
  /// [move] - L'attaque à exécuter.
  /// [moveIndex] - L'index du slot move dans le combattant.
  ///
  /// BE4 ajoute cet index pour une raison très concrète :
  /// - les PP vivent désormais dans l'état battle ;
  /// - le moteur doit savoir quel slot décrémenter honnêtement ;
  /// - transporter seulement l'objet `BattleMove` ne suffit plus.
  ///
  /// Ce n'est pas l'ouverture d'un système de queue plus riche :
  /// - on garde seulement la donnée minimale nécessaire au hit pipeline.
  const BattleActionFight(
    this.move, {
    required this.moveIndex,
  });

  /// L'attaque à exécuter.
  final BattleMove move;

  /// Le slot du move sur le combattant.
  final int moveIndex;
}

/// Fuir (action résolue).
///
/// Représente une tentative de fuite résolue.
class BattleActionRun extends BattleAction {
  /// Crée une action de fuite.
  const BattleActionRun();
}
