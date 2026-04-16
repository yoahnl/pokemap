import 'battle_action.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_state.dart';
import 'battle_status.dart';
import 'battle_switch.dart';
import 'battle_volatile.dart';

/// Résultat d'un tour de combat.
///
/// Contient les actions jouées et leurs exécutions.
/// Utilisé pour afficher le déroulement du tour au joueur.
class BattleTurnResult {
  /// Crée un résultat de tour.
  ///
  /// [playerAction] - L'action jouée par le joueur.
  /// [enemyAction] - L'action jouée par l'ennemi.
  /// [executions] - La liste des exécutions d'attaques (dans l'ordre).
  /// [statusEvents] - Les événements de statut/résiduel visibles du tour.
  /// [volatileEvents] - Les événements volatiles BE8 visibles du tour.
  /// [fieldEvents] - Les événements de champ BE9 visibles du tour.
  const BattleTurnResult({
    required this.playerAction,
    required this.enemyAction,
    required this.executions,
    this.statusEvents = const <BattleStatusEvent>[],
    this.volatileEvents = const <BattleVolatileEvent>[],
    this.fieldEvents = const <BattleFieldEvent>[],
    this.switchEvents = const <BattleSwitchEvent>[],
  });

  /// L'action jouée par le joueur.
  final BattleAction playerAction;

  /// L'action jouée par l'ennemi.
  final BattleAction enemyAction;

  /// La liste des exécutions d'attaques.
  ///
  /// Ordonnées selon l'ordre de résolution (déterministe).
  /// Depuis BE3 :
  /// - priorité décroissante ;
  /// - puis vitesse effective décroissante ;
  /// - puis tie-break déterministe explicite.
  final List<BattleMoveExecution> executions;

  /// Les événements de statut visibles pendant ce tour.
  ///
  /// BE7 ajoute cette trace minimale pour ne plus mentir sur deux axes :
  /// - l'application d'un statut majeur ne doit pas être une mutation muette ;
  /// - les résiduels de fin de tour ne doivent pas retirer des PV sans trace.
  final List<BattleStatusEvent> statusEvents;

  /// Les événements volatiles visibles pendant ce tour.
  ///
  /// BE8 les sépare volontairement de `statusEvents` :
  /// - `Protect`, la recharge et la charge sur deux tours n'ont pas la même
  ///   sémantique que les statuts majeurs ;
  /// - les entasser dans `BattleMoveExecution` ferait grossir ce contrat avec
  ///   des booléens croisés peu lisibles ;
  /// - une petite liste sœur garde la trace honnête sans créer un event bus.
  final List<BattleVolatileEvent> volatileEvents;

  /// Les événements de champ visibles pendant ce tour.
  ///
  /// BE9 les sépare volontairement du reste :
  /// - la météo et Trick Room sont désormais de vrais états moteur ;
  /// - les entasser dans `statusEvents` ou `volatileEvents` brouillerait les
  ///   invariants métier de chaque couche ;
  /// - une petite troisième liste suffit à garder le champ observable sans
  ///   ouvrir un journal universel.
  final List<BattleFieldEvent> fieldEvents;

  /// Les événements de switch / remplacement visibles pendant ce tour.
  ///
  /// BE10 les sépare volontairement du reste :
  /// - un switch n'est ni un statut majeur, ni un volatile BE8, ni un
  ///   événement de champ ;
  /// - le runtime/UI a besoin de distinguer un remplacement forcé d'une simple
  ///   exécution de move ;
  /// - cette petite liste sœur suffit à garder l'état observable sans ouvrir
  ///   de journal universel.
  final List<BattleSwitchEvent> switchEvents;
}

/// Exécution d'une attaque.
///
/// Représente une attaque qui a été exécutée avec ses effets.
class BattleMoveExecution {
  /// Crée une exécution d'attaque.
  ///
  /// [attacker] - L'identifiant de l'attaquant ("player" ou "enemy").
  /// [move] - L'attaque utilisée.
  /// [target] - L'identifiant de la cible ("player" ou "enemy").
  /// [damage] - Les dégâts infligés.
  /// [didHit] - true si le move a réellement touché.
  /// [didCrit] - true si le move a réellement déclenché un critique.
  /// [criticalMultiplier] - Multiplicateur critique réellement appliqué.
  /// [stabMultiplier] - Multiplicateur STAB réellement consommé pour ce hit.
  /// [typeEffectivenessMultiplier] - Multiplicateur de type réellement appliqué.
  const BattleMoveExecution({
    required this.attacker,
    required this.move,
    required this.target,
    required this.damage,
    required this.didHit,
    this.didCrit = false,
    this.criticalMultiplier = 1.0,
    this.stabMultiplier = 1.0,
    this.typeEffectivenessMultiplier = 1.0,
  });

  /// L'identifiant de l'attaquant.
  ///
  /// Valeurs possibles : "player" ou "enemy".
  final String attacker;

  /// L'attaque utilisée.
  final BattleMove move;

  /// L'identifiant de la cible.
  ///
  /// Valeurs possibles : "player", "enemy" ou "field" pour un move qui agit
  /// sur le champ plutôt que sur un combattant.
  final String target;

  /// Les dégâts infligés.
  ///
  /// Après M8 puis BE4 :
  /// - un move de statut touché peut infliger `0` dégât ;
  /// - un move qui miss inflige aussi `0` dégât ;
  /// - un move de dégâts standards part toujours de `move.power` ;
  /// - des multiplicateurs simples issus des étages de stats peuvent modifier
  ///   ce montant ;
  /// - BE5 y ajoute STAB et efficacité de type ;
  /// - on reste néanmoins très loin d'une formule Pokémon complète.
  final int damage;

  /// true si le move a réellement touché.
  ///
  /// BE4 l'ajoute pour arrêter un autre mensonge silencieux :
  /// - `damage == 0` ne distingue pas un miss d'un move de statut ;
  /// - la trace d'exécution doit donc porter explicitement le hit/miss ;
  /// - on évite ainsi de forcer l'UI/runtime à deviner l'issue depuis un
  ///   contrat trop pauvre.
  final bool didHit;

  /// true si le move a réellement déclenché un critique.
  ///
  /// BE6 ajoute ce flag pour éviter une nouvelle perte de vérité :
  /// - un critique ne doit pas être deviné indirectement depuis les dégâts ;
  /// - le runtime/UI doit pouvoir distinguer un simple hit d'un vrai crit ;
  /// - un miss, une immunité ou un move de statut gardent toujours `false`.
  final bool didCrit;

  /// Multiplicateur critique réellement appliqué à ce move.
  ///
  /// Valeurs attendues dans BE6 :
  /// - `1.5` sur un critique déclenché ;
  /// - `1.0` sinon.
  ///
  /// Ce champ reste volontairement petit :
  /// - il documente l'effet réellement appliqué ;
  /// - il n'ouvre pas un système complet de règles avancées de critique.
  final double criticalMultiplier;

  /// Multiplicateur STAB réellement appliqué à ce move.
  ///
  /// Valeurs attendues dans BE5 :
  /// - `1.5` si l'attaquant partage le type du move ;
  /// - `1.0` sinon ;
  /// - `1.0` aussi sur les vieux call sites battle qui n'ont pas de typing.
  final double stabMultiplier;

  /// Multiplicateur d'efficacité de type réellement appliqué.
  ///
  /// Valeurs typiques BE5 :
  /// - `2.0`, `4.0` pour les faiblesses ;
  /// - `0.5`, `0.25` pour les résistances ;
  /// - `0.0` pour une immunité ;
  /// - `1.0` pour un cas neutre ou pour un vieux setup battle sans typing.
  ///
  /// Important :
  /// - `didHit == true` et `typeEffectivenessMultiplier == 0.0` signifient
  ///   "le move a bien passé le hit check, mais la cible y est immunisée" ;
  /// - cela évite de confondre immunité, miss et move de statut.
  final double typeEffectivenessMultiplier;
}

/// Type de résultat final d'un combat.
enum BattleOutcomeType {
  /// Le joueur a gagné (ennemi K.O.).
  victory,

  /// Le joueur a perdu (joueur K.O.).
  defeat,

  /// Le joueur a fui avec succès.
  runaway,

  /// Le joueur a capturé avec succès un Pokémon sauvage.
  ///
  /// Le lot 13 garde ce contrat volontairement petit :
  /// - l'issue termine immédiatement le combat ;
  /// - elle ne porte pas de formule de capture canonique ;
  /// - le runtime se charge ensuite d'écrire réellement le Pokémon capturé
  ///   dans la party/save du joueur.
  captured,
}

/// Résultat final d'un combat.
///
/// Contient le type de résultat et l'état final du combat.
/// Utilisé par le runtime pour déterminer les actions post-combat
/// (marquage trainer defeated, retour overworld, etc.).
class BattleOutcome {
  /// Crée un résultat de combat.
  ///
  /// [type] - Le type de résultat (victoire, défaite, fuite).
  /// [finalState] - L'état final du combat.
  const BattleOutcome({required this.type, required this.finalState});

  /// Le type de résultat.
  final BattleOutcomeType type;

  /// L'état final du combat.
  final BattleState finalState;

  /// true si le joueur a gagné.
  bool get isVictory => type == BattleOutcomeType.victory;

  /// true si le joueur a perdu.
  bool get isDefeat => type == BattleOutcomeType.defeat;

  /// true si le joueur a fui.
  bool get isRunaway => type == BattleOutcomeType.runaway;

  /// true si le joueur a capturé le Pokémon sauvage.
  bool get isCaptured => type == BattleOutcomeType.captured;
}
