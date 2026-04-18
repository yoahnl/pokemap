import 'battle_action.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_spikes.dart';
import 'battle_stealth_rock.dart';
import 'battle_state.dart';
import 'battle_status.dart';
import 'battle_topology.dart';
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
  /// [stealthRockEvents] - Les événements Stealth Rock visibles du tour.
  /// [spikesEvents] - Les événements Spikes visibles du tour.
  /// [timeline] - La chronologie ordonnée réellement produite par le moteur.
  const BattleTurnResult({
    required this.playerAction,
    required this.enemyAction,
    required this.executions,
    this.statusEvents = const <BattleStatusEvent>[],
    this.volatileEvents = const <BattleVolatileEvent>[],
    this.fieldEvents = const <BattleFieldEvent>[],
    this.stealthRockEvents = const <BattleStealthRockEvent>[],
    this.spikesEvents = const <BattleSpikesEvent>[],
    this.switchEvents = const <BattleSwitchEvent>[],
    this.timeline = const <BattleTurnEvent>[],
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

  /// Les événements Stealth Rock visibles pendant ce tour.
  ///
  /// H1 ouvre volontairement une petite liste sœur dédiée :
  /// - Stealth Rock n'est ni un statut, ni un volatile, ni un field event ;
  /// - on refuse pourtant d'ouvrir un journal universel des side conditions ;
  /// - ce lot garde donc un contrat dédié et vivant pour une seule mécanique.
  final List<BattleStealthRockEvent> stealthRockEvents;

  /// Les événements Spikes visibles pendant ce tour.
  ///
  /// H2 suit exactement la même philosophie que H1 :
  /// - `Spikes` n'est ni un statut, ni un volatile, ni un field event ;
  /// - on refuse pourtant un journal universel de side conditions ;
  /// - ce lot porte donc son propre contrat dédié, vivant et testable.
  final List<BattleSpikesEvent> spikesEvents;

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

  /// Chronologie ordonnée du tour telle que réellement résolue par le moteur.
  ///
  /// BE10A ajoute cette source de vérité pour arrêter un nouveau mensonge :
  /// - les buckets `executions` / `statusEvents` / `volatileEvents` /
  ///   `fieldEvents` / `switchEvents` restent utiles pour les tests ciblés
  ///   et la compatibilité locale ;
  /// - mais ils ne peuvent pas, à eux seuls, exprimer l'ordre croisé entre
  ///   un switch, une exécution d'attaque, un résiduel puis un remplacement ;
  /// - le runtime/overlay ne doit donc plus reconstruire la chronologie avec
  ///   un tri heuristique de buckets.
  ///
  /// Frontière volontaire :
  /// - ce n'est pas un event bus générique ;
  /// - on transporte uniquement les six familles déjà réellement supportées ;
  /// - l'ordre est celui construit pendant la résolution réelle du tour.
  final List<BattleTurnEvent> timeline;
}

/// Entrée de chronologie ordonnée d'un tour.
///
/// Ce contrat reste strictement local à la restitution du tour :
/// - il ne remplace pas les buckets historiques ;
/// - il ne devient pas un journal universel du moteur ;
/// - il sert uniquement à conserver un ordre causal honnête entre les familles
///   d'événements déjà réellement supportées.
sealed class BattleTurnEvent {
  const BattleTurnEvent();
}

final class BattleTurnExecutionEvent extends BattleTurnEvent {
  const BattleTurnExecutionEvent(this.execution);

  final BattleMoveExecution execution;
}

final class BattleTurnStatusEvent extends BattleTurnEvent {
  const BattleTurnStatusEvent(this.event);

  final BattleStatusEvent event;
}

final class BattleTurnVolatileEvent extends BattleTurnEvent {
  const BattleTurnVolatileEvent(this.event);

  final BattleVolatileEvent event;
}

final class BattleTurnFieldEvent extends BattleTurnEvent {
  const BattleTurnFieldEvent(this.event);

  final BattleFieldEvent event;
}

final class BattleTurnStealthRockEvent extends BattleTurnEvent {
  const BattleTurnStealthRockEvent(this.event);

  final BattleStealthRockEvent event;
}

final class BattleTurnSpikesEvent extends BattleTurnEvent {
  const BattleTurnSpikesEvent(this.event);

  final BattleSpikesEvent event;
}

final class BattleTurnSwitchEvent extends BattleTurnEvent {
  const BattleTurnSwitchEvent(this.event);

  final BattleSwitchEvent event;
}

/// Exécution d'une attaque.
///
/// Représente une attaque qui a été exécutée avec ses effets.
///
/// Phase G élargit volontairement ce contrat sur un point précis :
/// - l'exécution ne doit plus être seulement observable via des chaînes
///   `"player"` / `"enemy"` / `"field"` ;
/// - le moteur a désormais une vraie topologie singles (`side` / `slot`) ;
/// - la trace de résolution doit donc porter cette topologie elle aussi.
///
/// Garde-fou de scope :
/// - on n'ouvre pas un système de targeting riche ;
/// - on ne porte toujours que le sous-ensemble réellement supporté :
///   cible combattant active ou cible field ;
/// - les getters stringly-typed restent comme seam de compatibilité local.
enum BattleMoveExecutionTargetKind {
  combatant,
  field,
  side,
}

class BattleMoveExecution {
  /// Crée une exécution d'attaque.
  ///
  /// [attackerSlot] - Le slot qui a réellement exécuté l'attaque.
  /// [move] - L'attaque utilisée.
  /// [targetKind] - La famille de cible réellement résolue.
  /// [targetSlot] - Le slot ciblé quand [targetKind] vaut `combatant`.
  /// [damage] - Les dégâts infligés.
  /// [didHit] - true si le move a réellement touché.
  /// [didCrit] - true si le move a réellement déclenché un critique.
  /// [criticalMultiplier] - Multiplicateur critique réellement appliqué.
  /// [stabMultiplier] - Multiplicateur STAB réellement consommé pour ce hit.
  /// [typeEffectivenessMultiplier] - Multiplicateur de type réellement appliqué.
  const BattleMoveExecution({
    required this.attackerSlot,
    required this.move,
    required this.targetKind,
    this.targetSlot,
    this.targetSideRef,
    required this.damage,
    required this.didHit,
    this.didCrit = false,
    this.criticalMultiplier = 1.0,
    this.stabMultiplier = 1.0,
    this.typeEffectivenessMultiplier = 1.0,
  }) : assert(
          (targetKind == BattleMoveExecutionTargetKind.combatant &&
                  targetSlot != null &&
                  targetSideRef == null) ||
              (targetKind == BattleMoveExecutionTargetKind.field &&
                  targetSlot == null &&
                  targetSideRef == null) ||
              (targetKind == BattleMoveExecutionTargetKind.side &&
                  targetSlot == null &&
                  targetSideRef != null),
          'BattleMoveExecution target payload must describe exactly one of: combatant slot, field, or side.',
        );

  /// Slot attaquant réellement résolu par le moteur.
  ///
  /// En singles Phase D/F :
  /// - il s'agit encore toujours du slot actif `0` d'un side ;
  /// - mais l'exécution arrête de mentir en faisant comme si la topologie
  ///   n'existait pas.
  final BattleSlotRef attackerSlot;

  /// Side de l'attaquant.
  BattleSideId get attackerSide => attackerSlot.side;

  /// Compatibilité locale pour les surfaces encore stringly-typed.
  ///
  /// Ce getter n'est plus la source de vérité ; il dérive désormais du slot.
  String get attacker => attackerSide.actorId;

  /// L'attaque utilisée.
  final BattleMove move;

  /// Famille de cible réellement consommée par cette exécution.
  final BattleMoveExecutionTargetKind targetKind;

  /// Slot ciblé quand l'exécution vise un combattant.
  ///
  /// Frontière volontaire :
  /// - `null` signifie uniquement "le move vise le field" ;
  /// - `null` signifie aussi "le move vise un side" ;
  /// - on ne crée ni targeting riche, ni tableau de cibles multiples.
  final BattleSlotRef? targetSlot;

  /// Side ciblé quand l'exécution vise un side plutôt qu'un combattant.
  ///
  /// H1 ouvre ce seam pour une raison précise :
  /// - Stealth Rock vise le side adverse, pas le combattant adverse ;
  /// - le move execution ne doit donc plus mentir en se faisant passer pour
  ///   un target combatant ou field ;
  /// - on n'ouvre pour autant aucun targeting riche supplémentaire.
  final BattleSideId? targetSideRef;

  /// Side ciblé quand l'exécution vise un combattant.
  BattleSideId? get targetSide => switch (targetKind) {
        BattleMoveExecutionTargetKind.combatant => targetSlot?.side,
        BattleMoveExecutionTargetKind.side => targetSideRef,
        BattleMoveExecutionTargetKind.field => null,
      };

  /// Compatibilité locale pour les surfaces encore stringly-typed.
  ///
  /// Valeurs dérivées :
  /// - `"player"` / `"enemy"` pour une cible combattant ;
  /// - `"field"` pour une cible field.
  String get target => switch (targetKind) {
        BattleMoveExecutionTargetKind.combatant => targetSlot!.side.actorId,
        BattleMoveExecutionTargetKind.side => targetSideRef!.actorId,
        BattleMoveExecutionTargetKind.field => 'field',
      };

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
