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

/// Changer volontairement de Pokémon actif.
///
/// BE10 ouvre enfin un vrai seam de switch singles minimal :
/// - ce choix vise un index de réserve battle courant ;
/// - il ne cible ni une party globale, ni une grille de slots ;
/// - il sert à la fois au switch volontaire et au remplacement forcé, selon
///   l'état courant de la session.
class PlayerBattleChoiceSwitch extends PlayerBattleChoice {
  /// Crée un choix de switch vers un membre de réserve.
  ///
  /// [reserveIndex] pointe dans la réserve battle courante du joueur.
  const PlayerBattleChoiceSwitch(this.reserveIndex);

  final int reserveIndex;
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

/// Continuer un tour forcé sans sélectionner un nouveau move.
///
/// BE8 l'ajoute pour éviter un nouveau mensonge de surface :
/// - un Pokémon en recharge ou avec un move chargé en attente n'a pas
///   réellement un "choix de move" libre au tour suivant ;
/// - réutiliser artificiellement `Fight(0)` ou laisser tous les boutons de
///   move actifs ferait croire à l'UI et aux tests qu'une vraie sélection est
///   encore possible ;
/// - ce petit choix explicite sert uniquement d'acquittement UI pour avancer
///   le tour forcé, sans ouvrir une taxonomie complète de commandes.
class PlayerBattleChoiceContinue extends PlayerBattleChoice {
  /// Crée un choix de continuation de tour forcé.
  const PlayerBattleChoiceContinue();
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

/// Famille ultra-bornée d'objets de soin HP supportés en BAG battle.
///
/// Lot 9-f factorise seulement ce qui devenait absurde à dupliquer :
/// - `potion`
/// - `super-potion`
/// - `hyper-potion`
///
/// Garde-fous de frontière :
/// - ce n'est pas un catalogue runtime d'objets ;
/// - ce n'est pas une taxonomie générale de medicines ;
/// - aucune autre entrée (`antidote`, `revive`, etc.)
///   n'est implicite ou "préparée".
enum BattleBagHpHealItemKind {
  potion,
  superPotion,
  hyperPotion;

  String get itemId => switch (this) {
        BattleBagHpHealItemKind.potion => 'potion',
        BattleBagHpHealItemKind.superPotion => 'super-potion',
        BattleBagHpHealItemKind.hyperPotion => 'hyper-potion',
      };

  String get label => switch (this) {
        BattleBagHpHealItemKind.potion => 'Potion',
        BattleBagHpHealItemKind.superPotion => 'Super Potion',
        BattleBagHpHealItemKind.hyperPotion => 'Hyper Potion',
      };
}

/// Utiliser un objet BAG de soin HP plat sur un membre du lineup joueur.
///
/// Cette action reste volontairement très étroite :
/// - elle couvre seulement `Potion` + `Super Potion` + `Hyper Potion` ;
/// - elle ne lit jamais le bag ;
/// - elle n'ouvre pas un système générique d'items battle ;
/// - elle existe uniquement pour rendre ces trois objets honnêtes comme vraies
///   actions de tour committées et visibles dans la timeline.
class BattleActionBagHpHealItemUse extends BattleAction {
  const BattleActionBagHpHealItemUse({
    required this.itemKind,
    required this.targetLineupIndex,
    required this.healAmount,
  }) : assert(healAmount > 0, 'HP-heal item healAmount must stay positive.');

  /// L'objet précis réellement utilisé.
  ///
  /// Le `kind` reste borné à trois cas, ce qui évite de transporter un
  /// `itemId` stringly-typed arbitraire dans le moteur.
  final BattleBagHpHealItemKind itemKind;

  /// Lineup cible côté joueur.
  ///
  /// On reste sur l'identité stable battle `lineupIndex` pour éviter
  /// tout couplage fragile à un index visuel d'overlay ou à un slot save.
  final int targetLineupIndex;

  /// Quantité de soin plate réellement portée par cette action.
  ///
  /// Le runtime décide encore si l'objet est disponible dans le bag ;
  /// le moteur ne consomme ici que l'effet déjà autorisé.
  final int healAmount;
}

/// Perdre honnêtement son tour à cause d'une recharge forcée.
///
/// BE8 préfère une action explicite plutôt que de tordre `BattleActionFight`
/// ou d'introduire un "tour vide" silencieux :
/// - cette action ne dépense pas de PP ;
/// - elle n'exécute aucun hit check ;
/// - elle rend visible le fait que le combattant a bien perdu ce tour pour
///   cause de recharge, puis nettoie l'état local.
class BattleActionRecharge extends BattleAction {
  /// Crée une action de recharge forcée.
  const BattleActionRecharge();
}

/// Changer le Pokémon actif pour un membre de réserve.
///
/// Le moteur BE10 garde ce contrat volontairement petit :
/// - `reserveIndex` référence la réserve battle courante ;
/// - le switch lui-même est résolu par `BattleSession` ;
/// - il ne transporte ni targeting riche, ni selfSwitch/forceSwitch de move.
class BattleActionSwitch extends BattleAction {
  const BattleActionSwitch({
    required this.reserveIndex,
  });

  final int reserveIndex;
}

/// Aucune action adverse pendant une étape inter-tour locale.
///
/// BE10 l'utilise uniquement pour garder une trace honnête quand le joueur
/// remplace un Pokémon K.O. entre deux tours :
/// - ce n'est pas une "attaque vide" ;
/// - ce n'est pas un nouveau système de queue ;
/// - c'est juste un marqueur explicite disant qu'aucune action adverse n'a été
///   résolue pendant cette étape de remplacement.
class BattleActionNone extends BattleAction {
  const BattleActionNone();
}
