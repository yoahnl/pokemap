import 'battle_topology.dart';

/// Identifiant minimal de statut majeur réellement supporté par le moteur.
///
/// BE7 ouvre volontairement un seul sous-ensemble :
/// - `par`
/// - `brn`
/// - `psn`
/// - `tox`
///
/// Tout le reste reste explicitement hors scope :
/// - pas de `slp`
/// - pas de `frz`
/// - pas de confusion
/// - pas de système générique de volatiles.
enum BattleMajorStatusId {
  par,
  brn,
  psn,
  tox,
}

/// État minimal d'un statut majeur porté par un combattant battle.
///
/// Ce contrat reste volontairement petit :
/// - il porte seulement quel statut majeur est actif ;
/// - il ajoute un compteur toxique local pour `tox` ;
/// - il n'essaie pas d'anticiper un futur système de statuts générique.
///
/// Le compteur toxique suit une règle très simple :
/// - `tox` commence à `1` ;
/// - le résiduel de fin de tour consomme cette valeur ;
/// - si le combattant survit, on l'incrémente pour le tour suivant.
final class BattleMajorStatusState {
  const BattleMajorStatusState.par()
      : id = BattleMajorStatusId.par,
        toxicCounter = 0;

  const BattleMajorStatusState.brn()
      : id = BattleMajorStatusId.brn,
        toxicCounter = 0;

  const BattleMajorStatusState.psn()
      : id = BattleMajorStatusId.psn,
        toxicCounter = 0;

  const BattleMajorStatusState.tox({
    this.toxicCounter = 1,
  })  : assert(toxicCounter >= 1),
        id = BattleMajorStatusId.tox;

  final BattleMajorStatusId id;

  /// Compteur local du poison toxique.
  ///
  /// Pour les autres statuts, cette valeur reste à `0` et n'a aucune
  /// sémantique métier.
  final int toxicCounter;

  bool get isToxic => id == BattleMajorStatusId.tox;

  BattleMajorStatusState incrementToxicCounter() {
    if (!isToxic) {
      return this;
    }
    return BattleMajorStatusState.tox(
      toxicCounter: toxicCounter + 1,
    );
  }

  /// Réinitialise l'état local qui ne doit pas survivre à un switch-out.
  ///
  /// BE10 garde une politique très étroite :
  /// - `par`, `brn`, `psn` restent inchangés ;
  /// - `tox` reste bien `tox` ;
  /// - mais sa progression locale repart à `1` quand le Pokémon quitte puis
  ///   revient sur le terrain.
  BattleMajorStatusState resetOnSwitchOut() {
    if (!isToxic) {
      return this;
    }
    return const BattleMajorStatusState.tox();
  }
}

/// Effet battle minimal pour `applyStatus`.
///
/// Le bridge runtime -> battle traduit `PokemonMoveEffect.applyStatus` vers ce
/// contrat local seulement quand le sous-ensemble BE7 est réellement
/// exécutable. Il ne transporte pas la totalité du payload canonique :
/// - scope `target` seulement ;
/// - `chancePercent == null` pour un status garanti sur hit ;
/// - `chancePercent` entre 1 et 100 pour un status probabiliste.
final class BattleMoveMajorStatusEffect {
  const BattleMoveMajorStatusEffect({
    required this.status,
    this.chancePercent,
  }) : assert(
          chancePercent == null || (chancePercent >= 1 && chancePercent <= 100),
          'BattleMoveMajorStatusEffect chancePercent must be null or between 1 and 100.',
        );

  final BattleMajorStatusId status;
  final int? chancePercent;
}

/// Petite taxonomie des événements de statut visibles dans le résultat de tour.
///
/// BE7 ne crée pas un event bus général. On garde seulement ce qui évite une
/// mutation silencieuse :
/// - application d'un statut majeur ;
/// - blocage parce qu'un statut majeur existe déjà ;
/// - impossibilité d'agir à cause de la paralysie ;
/// - dégâts résiduels de fin de tour.
enum BattleStatusEventKind {
  applied,
  blockedExistingMajorStatus,
  preventedAction,
  residualDamage,
}

/// Trace minimale d'un événement de statut pendant un tour.
///
/// Ce contrat existe pour deux raisons :
/// - éviter que les statuts/résiduels modifient l'état sans trace ;
/// - rester assez petit pour ne pas ressembler à un journal d'événements
///   générique du moteur.
final class BattleStatusEvent {
  const BattleStatusEvent.applied({
    required this.targetSlot,
    required this.status,
    required this.sourceMoveId,
  })  : kind = BattleStatusEventKind.applied,
        damage = null,
        toxicCounter = null,
        existingStatus = null;

  const BattleStatusEvent.blockedExistingMajorStatus({
    required this.targetSlot,
    required this.status,
    required this.existingStatus,
    required this.sourceMoveId,
  })  : kind = BattleStatusEventKind.blockedExistingMajorStatus,
        damage = null,
        toxicCounter = null;

  const BattleStatusEvent.preventedAction({
    required this.targetSlot,
    required this.status,
  })  : kind = BattleStatusEventKind.preventedAction,
        sourceMoveId = null,
        damage = null,
        toxicCounter = null,
        existingStatus = null;

  const BattleStatusEvent.residualDamage({
    required this.targetSlot,
    required this.status,
    required this.damage,
    this.toxicCounter,
  })  : kind = BattleStatusEventKind.residualDamage,
        sourceMoveId = null,
        existingStatus = null;

  /// Slot ciblé par l'événement.
  ///
  /// Phase G élargit volontairement le contrat ici :
  /// - les statuts majeurs ciblent encore toujours un combattant actif ;
  /// - mais ils cessent d'être attachés à une simple chaîne `"player"` /
  ///   `"enemy"` alors que le moteur porte déjà une vraie topologie.
  final BattleSlotRef targetSlot;

  /// Side ciblé par l'événement.
  BattleSideId get targetSide => targetSlot.side;

  /// Compatibilité locale pour les surfaces encore stringly-typed.
  String get target => targetSide.actorId;

  final BattleStatusEventKind kind;
  final BattleMajorStatusId status;
  final String? sourceMoveId;
  final int? damage;
  final int? toxicCounter;
  final BattleMajorStatusId? existingStatus;
}
