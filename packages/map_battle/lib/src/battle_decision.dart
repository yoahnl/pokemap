import 'battle_action.dart';
import 'battle_topology.dart';

/// Compatibilité locale avec le contrat Phase C.
///
/// Phase D rattache désormais chaque request à un vrai side et à un vrai slot,
/// mais le paquet exportait déjà un petit `actor` public. On garde donc ce
/// seam pour éviter une rupture API plus large que le lot :
/// - il reste strictement limité au joueur humain ;
/// - il ne remplace pas `side`, qui devient la vraie donnée topologique ;
/// - il pourra être supprimé explicitement plus tard si une migration publique
///   complète est décidée.
enum BattleDecisionActor {
  player,
}

/// Famille métier de la requête de décision courante.
///
/// Ce champ sert à éviter un nouveau mensonge de contrat :
/// - auparavant, runtime/UI devaient déduire le "type de tour" en inspectant
///   une liste plate de `PlayerBattleChoice` ;
/// - maintenant, le moteur expose explicitement si le joueur est sur un tour
///   libre, un remplacement forcé, une continuation forcée, ou aucun tour
///   jouable.
enum BattleDecisionRequestKind {
  turnChoice,
  forcedReplacement,
  forcedContinue,
  wait,
}

/// Cause métier d'un remplacement forcé.
///
/// Phase C n'ouvre qu'un seul cas honnête déjà réellement supporté :
/// l'actif joueur est K.O. et doit être remplacé.
enum BattleForcedReplacementReason {
  activeFainted,
}

/// Cause métier d'un tour forcé "continuer".
///
/// Phase C sépare enfin explicitement les deux sous-cas BE8 qui étaient
/// auparavant cachés derrière `PlayerBattleChoiceContinue`.
enum BattleContinueReason {
  mustRecharge,
  pendingChargeRelease,
}

/// Cause métier d'un état où aucune décision libre n'est attendue.
///
/// On garde ce contrat volontairement petit :
/// - fin de combat ;
/// - phase transitoire de résolution ;
/// - état incohérent mais explicite où aucun choix honnête n'existe.
enum BattleWaitReason {
  battleFinished,
  resolvingTurn,
  activeFaintedWithoutReplacement,
  noLegalChoice,
}

/// Requête de décision joueur exposée par le moteur battle.
///
/// Frontière volontaire Phase C :
/// - ce contrat ne remplace pas `PlayerBattleChoice`, qui reste la réponse
///   envoyée par l'UI/runtime au moteur ;
/// - il remplace en revanche la vieille "liste plate" comme source principale
///   de vérité pour savoir quel genre de décision est attendu ;
/// - il n'ouvre pas encore un vrai request model Showdown-like multi-side.
sealed class BattleDecisionRequest {
  BattleDecisionRequest({
    this.actor = BattleDecisionActor.player,
    required this.side,
    required this.slot,
    required this.kind,
  }) {
    if (actor != BattleDecisionActor.player) {
      throw ArgumentError(
        'Phase D only exposes player-facing decision requests.',
      );
    }
    if (side != BattleSideId.player) {
      throw ArgumentError(
        'Phase D only exposes player-facing decision requests.',
      );
    }
    if (slot.side != side) {
      throw ArgumentError(
        'BattleDecisionRequest.slot must belong to the same side.',
      );
    }
    if (slot.slotIndex != 0) {
      throw ArgumentError(
        'Phase D remains singles-only and only supports slot 0 requests.',
      );
    }
  }

  /// Compatibilité publique Phase C conservée.
  final BattleDecisionActor actor;

  /// Le side qui doit répondre à cette requête.
  ///
  /// Phase D cesse ici de faire comme si la requête appartenait seulement à un
  /// acteur stringly-typed ou implicite :
  /// - la décision est désormais rattachée à un vrai côté du combat ;
  /// - on reste strictement en singles, donc seul le joueur répond encore ;
  /// - mais le contrat arrête d'être topologiquement plat.
  final BattleSideId side;

  /// Le slot concerné par cette requête.
  ///
  /// Frontière volontaire :
  /// - Phase D n'ouvre pas une grille riche de slots ;
  /// - mais la requête s'attache désormais explicitement au slot actif qui
  ///   attend une réponse, au lieu de laisser le runtime le deviner.
  final BattleSlotRef slot;

  /// Le type métier de la requête courante.
  final BattleDecisionRequestKind kind;

  /// Les choix explicitement autorisés pour cette requête.
  ///
  /// Cette vue plate reste utile comme seam de compatibilité locale :
  /// - certains call sites/tests peuvent encore itérer sur une liste ;
  /// - la vraie source de vérité n'est plus cette forme, mais la requête
  ///   typée qui lui donne son sens ;
  /// - le moteur continue donc à fournir les deux, avec la requête comme
  ///   contrat principal.
  List<PlayerBattleChoice> get allowedChoices;

  /// true si cette requête attend réellement un choix du joueur.
  bool get expectsInput => allowedChoices.isNotEmpty;

  /// Vérifie si [choice] fait partie des réponses légales à cette requête.
  ///
  /// On évite volontairement de dépendre d'une égalité structurelle globale
  /// sur `PlayerBattleChoice` :
  /// - les choix actuels sont de petits payloads UI, pas des value-objects
  ///   riches déjà normalisés ;
  /// - ce helper local suffit pour la validation Phase C ;
  /// - il garde la migration bornée sans refactorer tout le contrat existant.
  bool allows(PlayerBattleChoice choice) {
    for (final allowedChoice in allowedChoices) {
      if (_samePlayerBattleChoice(allowedChoice, choice)) {
        return true;
      }
    }
    return false;
  }
}

/// Requête de tour libre.
///
/// C'est le vrai "tour normal" du moteur singles local :
/// - le joueur peut choisir un move disponible ;
/// - il peut aussi switcher volontairement si une réserve valide existe ;
/// - en sauvage, `Capture`/`Run` peuvent aussi apparaître.
///
/// Important :
/// - on ne crée PAS ici un faux `switchRequest` séparé ;
/// - le moteur local n'a pas de sous-menu de switch ni d'état intermédiaire
///   honnête pour ça ;
/// - le type explicite ici est donc "tour libre", avec ses familles de choix.
final class BattleTurnChoiceRequest extends BattleDecisionRequest {
  BattleTurnChoiceRequest({
    super.actor = BattleDecisionActor.player,
    required super.side,
    required super.slot,
    required List<PlayerBattleChoiceFight> moveChoices,
    List<PlayerBattleChoiceSwitch> switchChoices =
        const <PlayerBattleChoiceSwitch>[],
    this.captureChoice,
    this.runChoice,
  })  : moveChoices = List<PlayerBattleChoiceFight>.unmodifiable(moveChoices),
        switchChoices =
            List<PlayerBattleChoiceSwitch>.unmodifiable(switchChoices),
        super(kind: BattleDecisionRequestKind.turnChoice);

  /// Les choix de move actuellement légaux.
  final List<PlayerBattleChoiceFight> moveChoices;

  /// Les choix de switch volontaire actuellement légaux.
  final List<PlayerBattleChoiceSwitch> switchChoices;

  /// Le choix de capture si ce combat sauvage l'autorise honnêtement.
  final PlayerBattleChoiceCapture? captureChoice;

  /// Le choix de fuite si ce combat l'autorise honnêtement.
  final PlayerBattleChoiceRun? runChoice;

  @override
  List<PlayerBattleChoice> get allowedChoices =>
      List<PlayerBattleChoice>.unmodifiable(
        <PlayerBattleChoice>[
          ...moveChoices,
          ...switchChoices,
          if (captureChoice != null) captureChoice!,
          if (runChoice != null) runChoice!,
        ],
      );
}

/// Requête de remplacement forcé.
///
/// Phase C sépare enfin cette demande métier du simple `Switch` volontaire :
/// - la réponse reste bien `PlayerBattleChoiceSwitch` ;
/// - mais l'UI/runtime n'a plus à deviner si le switch est libre ou imposé ;
/// - le moteur peut aussi expliquer pourquoi ce remplacement est requis.
final class BattleForcedReplacementRequest extends BattleDecisionRequest {
  BattleForcedReplacementRequest({
    super.actor = BattleDecisionActor.player,
    required super.side,
    required super.slot,
    required List<PlayerBattleChoiceSwitch> switchChoices,
    required this.reason,
    required this.faintedSpeciesId,
  })  : switchChoices =
            List<PlayerBattleChoiceSwitch>.unmodifiable(switchChoices),
        super(kind: BattleDecisionRequestKind.forcedReplacement);

  /// Les seuls switches encore légaux pour sortir du K.O.
  final List<PlayerBattleChoiceSwitch> switchChoices;

  /// La cause métier du remplacement forcé.
  final BattleForcedReplacementReason reason;

  /// L'espèce actuellement K.O. qui doit être remplacée.
  final String faintedSpeciesId;

  @override
  List<PlayerBattleChoice> get allowedChoices => switchChoices;
}

/// Requête de continuation forcée.
///
/// Phase C l'isole pour arrêter de cacher la contrainte dans `volatileState`
/// côté runtime/overlay :
/// - la réponse reste `PlayerBattleChoiceContinue()` ;
/// - mais le moteur explique désormais si le joueur recharge ou libère une
///   attaque déjà chargée ;
/// - le runtime n'a plus besoin d'inférer ce sens depuis l'état volatile brut.
final class BattleContinueRequest extends BattleDecisionRequest {
  BattleContinueRequest({
    super.actor = BattleDecisionActor.player,
    required super.side,
    required super.slot,
    required this.reason,
  }) : super(kind: BattleDecisionRequestKind.forcedContinue);

  final BattleContinueReason reason;

  @override
  List<PlayerBattleChoice> get allowedChoices =>
      const <PlayerBattleChoice>[PlayerBattleChoiceContinue()];
}

/// Requête "aucune décision honnête n'est attendue".
///
/// Ce n'est PAS un nouveau système de lock générique :
/// - on documente juste explicitement qu'aucun input joueur légitime n'est
///   attendu dans cet état ;
/// - cela évite que le runtime/overlay invente un menu vide ou un faux type
///   de tour à partir d'une simple absence de choix.
final class BattleWaitRequest extends BattleDecisionRequest {
  BattleWaitRequest({
    super.actor = BattleDecisionActor.player,
    required super.side,
    required super.slot,
    required this.reason,
  }) : super(kind: BattleDecisionRequestKind.wait);

  final BattleWaitReason reason;

  @override
  List<PlayerBattleChoice> get allowedChoices => const <PlayerBattleChoice>[];
}

bool _samePlayerBattleChoice(
  PlayerBattleChoice left,
  PlayerBattleChoice right,
) {
  return switch ((left, right)) {
    (
      PlayerBattleChoiceFight(:final moveIndex),
      PlayerBattleChoiceFight(moveIndex: final otherMoveIndex),
    ) =>
      moveIndex == otherMoveIndex,
    (
      PlayerBattleChoiceSwitch(:final reserveIndex),
      PlayerBattleChoiceSwitch(reserveIndex: final otherReserveIndex),
    ) =>
      reserveIndex == otherReserveIndex,
    (PlayerBattleChoiceRun(), PlayerBattleChoiceRun()) => true,
    (PlayerBattleChoiceCapture(), PlayerBattleChoiceCapture()) => true,
    (PlayerBattleChoiceContinue(), PlayerBattleChoiceContinue()) => true,
    _ => false,
  };
}
