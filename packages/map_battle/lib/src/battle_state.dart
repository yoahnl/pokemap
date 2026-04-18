import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_topology.dart';
import 'battle_volatile.dart';
import 'battle_stats.dart';
import 'battle_typing.dart';

/// Phase du combat.
///
/// Représente l'état actuel du cycle de combat.
enum BattlePhase {
  /// En attente du choix du joueur.
  ///
  /// C'est la phase normale entre les tours.
  /// Le runtime doit appeler [BattleSession.decisionRequest] pour connaître
  /// explicitement le type de décision attendu.
  ///
  /// Compatibilité locale conservée :
  /// - [BattleSession.getAvailableChoices()] reste disponible ;
  /// - mais il devient un simple adaptateur dérivé de la vraie requête.
  playerChoice,

  /// Résolution en cours.
  ///
  /// Phase transitoire pendant laquelle le tour est en cours de résolution.
  /// Le runtime ne doit pas permettre de nouveaux choix pendant cette phase.
  resolving,

  /// Combat terminé.
  ///
  /// [BattleState.outcome] est non-null et contient le résultat final.
  /// Le runtime doit appeler `_onBattleFinished(outcome)` pour revenir à l'overworld.
  finished,
}

/// État immutable d'un combat.
///
/// Ce modèle représente l'état complet d'un combat à un instant donné.
/// Il est immutable : toutes les méthodes de modification retournent un nouvel état.
///
/// Invariants :
/// - Si [phase] == [BattlePhase.finished], alors [outcome] est non-null.
/// - Si [phase] != [BattlePhase.finished], alors [outcome] est null.
/// - [playerSide.active.currentHp] est toujours entre 0 et
///   [playerSide.active.maxHp].
/// - [enemySide.active.currentHp] est toujours entre 0 et
///   [enemySide.active.maxHp].
class BattleState {
  /// Crée un état de combat.
  ///
  /// [phase] - La phase actuelle du combat.
  ///
  /// Phase D introduit ici le vrai progrès topologique du moteur :
  /// - la forme canonique du state devient `playerSide` / `enemySide` ;
  /// - chaque side porte un slot actif et une réserve ;
  /// - on cesse donc de considérer le moteur comme un simple sac de quatre
  ///   champs plats `player / playerReserve / enemy / enemyReserve`.
  ///
  /// Compatibilité bornée conservée :
  /// - beaucoup de call sites runtime/tests lisent encore `player`, `enemy`,
  ///   `playerReserve` et `enemyReserve` ;
  /// - cette surface de lecture reste donc disponible comme façade projetée ;
  /// - mais le stockage canonique du state vit désormais dans les deux sides.
  ///
  /// Contrat d'entrée :
  /// - fournir soit `playerSide`/`enemySide` ;
  /// - soit le vieux chemin plat `player`/`playerReserve`/`enemy`/
  ///   `enemyReserve` ;
  /// - ne pas mélanger les deux pour un même côté.
  /// [field] - L'état de champ observable (weather / pseudoWeather).
  /// [currentTurn] - Le résultat du tour en cours (null si aucun tour en cours).
  /// [outcome] - Le résultat final du combat (null si combat en cours).
  BattleState({
    required this.phase,
    BattleSideState? playerSide,
    BattleCombatant? player,
    List<BattleCombatant> playerReserve = const <BattleCombatant>[],
    BattleSideState? enemySide,
    BattleCombatant? enemy,
    List<BattleCombatant> enemyReserve = const <BattleCombatant>[],
    this.field = const BattleFieldState(),
    this.currentTurn,
    this.outcome,
  })  : playerSide = _resolveBattleStateSide(
          expectedId: BattleSideId.player,
          providedSide: playerSide,
          legacyActive: player,
          legacyReserve: playerReserve,
          sideLabel: 'player',
        ),
        enemySide = _resolveBattleStateSide(
          expectedId: BattleSideId.enemy,
          providedSide: enemySide,
          legacyActive: enemy,
          legacyReserve: enemyReserve,
          sideLabel: 'enemy',
        );

  /// La phase actuelle du combat.
  final BattlePhase phase;

  /// Side joueur canonique du combat.
  final BattleSideState playerSide;

  /// Side adverse canonique du combat.
  final BattleSideState enemySide;

  /// État de champ observable du combat.
  ///
  /// BE9 le porte directement dans `BattleState` pour éviter un nouveau
  /// mensonge :
  /// - la météo et Trick Room modifient maintenant réellement le moteur ;
  /// - ils ne doivent donc pas vivre comme un détail caché de résolution ;
  /// - le runtime et les tests peuvent relire cet état sans introspection
  ///   privée de `BattleSession`.
  final BattleFieldState field;

  /// Le résultat du tour en cours.
  ///
  /// Null si aucun tour n'est en cours (phase [playerChoice] ou [finished]).
  final BattleTurnResult? currentTurn;

  /// Le résultat final du combat.
  ///
  /// Non-null uniquement si [phase] == [BattlePhase.finished].
  final BattleOutcome? outcome;

  /// true si le combat est terminé.
  ///
  /// Raccourci pour `phase == BattlePhase.finished`.
  bool get isFinished => phase == BattlePhase.finished;

  /// Compatibilité locale : actif joueur projeté depuis [playerSide].
  ///
  /// Ce getter reste volontairement public pour éviter qu'une migration de
  /// topologie Phase D force en douce une refonte runtime plus large.
  BattleCombatant get player => playerSide.active;

  /// Compatibilité locale : réserve joueur projetée depuis [playerSide].
  List<BattleCombatant> get playerReserve => playerSide.reserve;

  /// Compatibilité locale : actif adverse projeté depuis [enemySide].
  BattleCombatant get enemy => enemySide.active;

  /// Compatibilité locale : réserve adverse projetée depuis [enemySide].
  List<BattleCombatant> get enemyReserve => enemySide.reserve;

  /// Retourne le side demandé sans réintroduire un protocole plat.
  BattleSideState side(BattleSideId sideId) {
    return switch (sideId) {
      BattleSideId.player => playerSide,
      BattleSideId.enemy => enemySide,
    };
  }
}

/// Combattant en combat.
///
/// Représente un Pokémon avec ses PV courants.
/// Immutable : utiliser [withDamage] pour créer une copie avec des PV modifiés.
///
/// Invariants :
/// - [currentHp] est toujours entre 0 et [maxHp].
/// - [isFainted] est true si et seulement si [currentHp] <= 0.
class BattleCombatant {
  /// Crée un combattant.
  ///
  /// [speciesId] - L'identifiant de l'espèce.
  /// [level] - Le niveau.
  /// [currentHp] - Les PV courants.
  /// [maxHp] - Les PV maximum.
  /// [stats] - Snapshot résolu des stats non-HP.
  /// [typing] - Typing battle minimal si connu.
  /// [majorStatus] - Statut majeur actuellement porté si le combattant en a un.
  /// [volatileState] - Sous-état volatile local BE8 (`protect`, recharge,
  ///   charge en attente).
  /// [abilityId] - L'ability réellement résolue si le runtime la connaît.
  /// [moves] - La liste des attaques disponibles.
  const BattleCombatant({
    required this.speciesId,
    this.lineupIndex = 0,
    required this.level,
    required this.currentHp,
    required this.maxHp,
    required this.stats,
    this.typing,
    this.majorStatus,
    this.volatileState = const BattleVolatileState(),
    this.abilityId = 'unknown',
    required this.moves,
    this.statStages = const BattleStatStages(),
  });

  /// L'identifiant de l'espèce.
  final String speciesId;

  /// Identité stable de lineup pour ce combattant.
  ///
  /// Voir `BattleCombatantData.lineupIndex` :
  /// - elle ne sert pas au gameplay direct ;
  /// - elle sert à préserver une identité stable malgré les switches ;
  /// - le runtime peut ensuite écrire les bons slots de party sans reconstruire
  ///   l'historique du combat.
  final int lineupIndex;

  /// Le niveau.
  final int level;

  /// Les PV courants.
  final int currentHp;

  /// Les PV maximum.
  final int maxHp;

  /// Snapshot résolu des stats non-HP.
  ///
  /// BE2 le transporte jusqu'à l'état battle pour que :
  /// - les moves physiques opposent enfin attaque vs défense ;
  /// - les moves spéciaux opposent enfin spécial vs spécial défense ;
  /// - `speed` survive au handoff jusqu'au moteur.
  ///
  /// BE3 commence ensuite à la consommer réellement pour l'ordre d'action,
  /// sans pour autant ouvrir toute une queue générique ni un système de
  /// précision / critique / résiduels.
  final BattleStatsSnapshot stats;

  /// Typing minimal du combattant si le setup le fournit.
  ///
  /// BE5 en a besoin pour fermer le trou où `type` était encore décoratif :
  /// - STAB dépend du typing de l'attaquant ;
  /// - résistances/faiblesses/immunités dépendent du typing du défenseur.
  ///
  /// Compatibilité résiduelle assumée :
  /// - un vieux setup direct `map_battle` peut encore laisser ce champ absent ;
  /// - dans ce cas, le moteur reste neutre sur la couche type au lieu de
  ///   fabriquer un typing par défaut qui mentirait davantage.
  final BattleTypingSnapshot? typing;

  /// Statut majeur actuellement porté par ce combattant.
  ///
  /// BE7 garde cet état volontairement étroit :
  /// - `null` signifie "aucun statut majeur" ;
  /// - sinon on porte uniquement `par`, `brn`, `psn` ou `tox` ;
  /// - il n'y a toujours ni volatiles génériques, ni `slp`, ni `frz`.
  final BattleMajorStatusState? majorStatus;

  /// Sous-état volatile local strictement borné à BE8.
  ///
  /// On évite volontairement un conteneur générique :
  /// - `protectActive` pour la fenêtre de protection du tour courant ;
  /// - `mustRecharge` pour le tour perdu suivant certains moves ;
  /// - `pendingCharge` pour la deuxième moitié d'un move à charge.
  final BattleVolatileState volatileState;

  /// L'ability réellement résolue pour ce combattant.
  ///
  /// Le moteur lot 13 n'en tire toujours aucun calcul de combat. On la transporte
  /// néanmoins jusqu'à l'issue finale pour permettre au runtime de persister un
  /// Pokémon capturé à partir du vrai ennemi engagé, sans données inventées.
  final String abilityId;

  /// La liste des attaques disponibles.
  ///
  /// À partir de BE4, les moves battle transportent aussi leur PP courant :
  /// - la liste n'est donc plus seulement descriptive ;
  /// - elle porte un vrai petit état mutable-mais-immutable du point de vue
  ///   des copies de session ;
  /// - on n'ouvre toujours pas de write-back runtime des PP hors combat.
  final List<BattleMove> moves;

  /// Étages de stats actuellement appliqués à ce combattant.
  ///
  /// M8 reste volontairement borné :
  /// - on ne porte que les stats utiles au petit sous-ensemble réellement
  ///   exécutable ;
  /// - BE3 ajoute `speed` parce qu'elle devient enfin une vraie donnée moteur
  ///   pour l'ordre d'action ;
  /// - les autres mécaniques (status, weather, précision, ordre d'action
  ///   complet, etc.) restent hors scope.
  final BattleStatStages statStages;

  /// true si le combattant est K.O.
  ///
  /// Un combattant est K.O. si ses PV courants sont <= 0.
  bool get isFainted => currentHp <= 0;

  /// Crée une copie de ce combattant avec des dégâts appliqués.
  ///
  /// [damage] - La quantité de dégâts à appliquer.
  ///
  /// Les PV sont clampés entre 0 et [maxHp].
  /// Cette méthode ne modifie pas cet objet (immutable).
  BattleCombatant withDamage(int damage) {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: (currentHp - damage).clamp(0, maxHp),
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Crée une copie de ce combattant avec des PV restaurés.
  ///
  /// [healAmount] - La quantité de PV à restaurer.
  ///
  /// Les PV sont clampés entre 0 et [maxHp].
  /// Cette méthode ne modifie pas cet objet (immutable).
  BattleCombatant withHeal(int healAmount) {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: (currentHp + healAmount).clamp(0, maxHp),
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Crée une copie de ce combattant avec des changements d'étages appliqués.
  ///
  /// Les étages sont toujours clampés dans la plage canonique minimale `[-6, 6]`.
  /// M8 ne gère ici que le sous-ensemble de stats réellement exploité par le
  /// moteur battle enrichi.
  BattleCombatant withAppliedStageChanges(
    List<BattleStatStageChange> changes,
  ) {
    if (changes.isEmpty) {
      return this;
    }
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages.apply(changes),
    );
  }

  /// Crée une copie avec un slot move remplacé.
  ///
  /// BE4 évite ici une sur-architecture :
  /// - pas de nouveau sous-état `MoveState` parallèle ;
  /// - pas de map indexée future-proof ;
  /// - juste le plus petit helper honnête pour décrémenter les PP d'un slot.
  BattleCombatant withUpdatedMoveAt(int index, BattleMove updatedMove) {
    if (index < 0 || index >= moves.length) {
      throw RangeError.index(index, moves, 'index');
    }

    final updatedMoves = List<BattleMove>.of(moves);
    updatedMoves[index] = updatedMove;
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: List<BattleMove>.unmodifiable(updatedMoves),
      statStages: statStages,
    );
  }

  /// Crée une copie avec un statut majeur mis à jour.
  ///
  /// Ce helper garde la transition d'état locale et lisible :
  /// - pas de builder parallèle de combattant ;
  /// - pas de mutation silencieuse d'un objet immutable ;
  /// - juste la plus petite brique utile pour `applyStatus`, la paralysie et
  ///   les résiduels de fin de tour.
  BattleCombatant withMajorStatus(BattleMajorStatusState? updatedStatus) {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: updatedStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Crée une copie avec un sous-état volatile mis à jour.
  ///
  /// BE8 garde cette transition locale et lisible :
  /// - pas de mutation silencieuse ;
  /// - pas de builder parallèle ;
  /// - juste le plus petit helper immutable utile pour `Protect`, la recharge
  ///   et les moves à charge.
  BattleCombatant withVolatileState(BattleVolatileState updatedVolatileState) {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: updatedVolatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Prépare ce combattant à retourner en réserve après un switch.
  ///
  /// Politique BE10 explicitement bornée :
  /// - on conserve les PV courants ;
  /// - on conserve les PP courants ;
  /// - on conserve le statut majeur ;
  /// - mais on nettoie tout ce qui n'a de sens que "sur le terrain" :
  ///   stages, protect, recharge, charge en attente ;
  /// - `tox` garde le statut majeur, mais son compteur local repart à `1`
  ///   pour éviter que le switch rende BE7 mensonger.
  BattleCombatant resetForReserveOnSwitchOut() {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus?.resetOnSwitchOut(),
      volatileState: volatileState.clearedOnSwitchOut(),
      abilityId: abilityId,
      moves: moves,
      statStages: const BattleStatStages(),
    );
  }
}

/// Slot battle local réellement utilisé par le moteur singles.
///
/// Phase D refuse ici le faux type décoratif :
/// - ce slot n'est pas un placeholder vide ;
/// - il porte réellement le combattant actif du side ;
/// - les requests et événements peuvent donc enfin se rattacher à un slot
///   concret sans ouvrir une topologie multi-actifs ou doubles.
final class BattleSlotState {
  BattleSlotState({
    required this.side,
    required this.slotIndex,
    required this.combatant,
  });

  BattleSlotState.active({
    required BattleSideId side,
    required BattleCombatant combatant,
  }) : this(
          side: side,
          slotIndex: 0,
          combatant: combatant,
        );

  final BattleSideId side;
  final int slotIndex;
  final BattleCombatant combatant;

  /// Référence stable vers ce slot pour les requests et traces topologiques.
  BattleSlotRef get ref => BattleSlotRef(
        side: side,
        slotIndex: slotIndex,
      );

  /// Retourne une copie du slot avec un autre combattant.
  ///
  /// Le slot reste le même :
  /// - même side ;
  /// - même index ;
  /// - seule l'occupation change lors d'un switch ou d'une résolution de tour.
  BattleSlotState withCombatant(BattleCombatant updatedCombatant) {
    return BattleSlotState(
      side: side,
      slotIndex: slotIndex,
      combatant: updatedCombatant,
    );
  }
}

/// État local d'un side singles.
///
/// Ce type est volontairement petit mais réel :
/// - un side a maintenant une identité explicite ;
/// - il porte un vrai slot actif ;
/// - il porte une réserve ordonnée ;
/// - il devient le lieu honnête des futures responsabilités side-level, sans
///   ouvrir dès maintenant side conditions/hazards/doubles.
final class BattleSideState {
  BattleSideState({
    required this.id,
    required this.activeSlot,
    this.reserve = const <BattleCombatant>[],
    this.hasStealthRock = false,
    this.spikesLayers = 0,
  })  : assert(
          activeSlot.side == id,
          'BattleSideState.activeSlot must belong to the same side.',
        ),
        assert(
          activeSlot.slotIndex == 0,
          'Phase D remains singles-only and only supports active slot 0.',
        ),
        assert(
          spikesLayers >= 0 && spikesLayers <= 3,
          'H2 Spikes remains a strict 0..3 layered slice.',
        );

  BattleSideState.player({
    required BattleCombatant active,
    List<BattleCombatant> reserve = const <BattleCombatant>[],
  }) : this(
          id: BattleSideId.player,
          activeSlot: BattleSlotState.active(
            side: BattleSideId.player,
            combatant: active,
          ),
          reserve: reserve,
        );

  BattleSideState.enemy({
    required BattleCombatant active,
    List<BattleCombatant> reserve = const <BattleCombatant>[],
  }) : this(
          id: BattleSideId.enemy,
          activeSlot: BattleSlotState.active(
            side: BattleSideId.enemy,
            combatant: active,
          ),
          reserve: reserve,
        );

  final BattleSideId id;
  final BattleSlotState activeSlot;

  /// Réserve ordonnée locale de ce side.
  ///
  /// Invariant métier conservé :
  /// - chaque membre engagé dans le combat reste présent exactement une fois ;
  /// - le slot actif ne vit pas aussi dans la réserve ;
  /// - l'ordre de réserve reste stable tant qu'un switch ne l'altère pas.
  final List<BattleCombatant> reserve;

  /// H1 ouvre le plus petit vrai état side-level vivant : Stealth Rock.
  ///
  /// Garde-fou de périmètre :
  /// - pas de conteneur générique de hazards ;
  /// - pas de liste de side conditions ;
  /// - pas de "pour plus tard" ;
  /// - juste la vérité minimale nécessaire à cette mécanique.
  final bool hasStealthRock;

  /// H2 ouvre exactement un second état side-level vivant : `Spikes`.
  ///
  /// Garde-fous de portée :
  /// - pas de conteneur générique de side conditions ;
  /// - pas de map d'hazards ;
  /// - pas de framework de couches arbitraires ;
  /// - seulement un compteur borné 0..3, parce que c'est la vérité métier
  ///   immédiatement consommée par ce lot et rien d'autre.
  final int spikesLayers;

  /// Combattant actif de ce side.
  BattleCombatant get active => activeSlot.combatant;

  /// Référence canonique du slot actif.
  BattleSlotRef get activeSlotRef => activeSlot.ref;

  BattleSideState withActive(BattleCombatant updatedActive) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot.withCombatant(updatedActive),
      reserve: reserve,
      hasStealthRock: hasStealthRock,
      spikesLayers: spikesLayers,
    );
  }

  BattleSideState withReserve(List<BattleCombatant> updatedReserve) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot,
      reserve: updatedReserve,
      hasStealthRock: hasStealthRock,
      spikesLayers: spikesLayers,
    );
  }

  BattleSideState withActiveAndReserve({
    required BattleCombatant active,
    required List<BattleCombatant> reserve,
  }) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot.withCombatant(active),
      reserve: reserve,
      hasStealthRock: hasStealthRock,
      spikesLayers: spikesLayers,
    );
  }

  BattleSideState withStealthRock(bool value) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot,
      reserve: reserve,
      hasStealthRock: value,
      spikesLayers: spikesLayers,
    );
  }

  BattleSideState withSpikesLayers(int value) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot,
      reserve: reserve,
      hasStealthRock: hasStealthRock,
      spikesLayers: value,
    );
  }
}

BattleSideState _resolveBattleStateSide({
  required BattleSideId expectedId,
  required BattleSideState? providedSide,
  required BattleCombatant? legacyActive,
  required List<BattleCombatant> legacyReserve,
  required String sideLabel,
}) {
  // Phase D choisit ici un garde-fou runtime, pas seulement un assert debug :
  // - la migration introduit deux façons de construire `BattleState` ;
  // - mélanger la nouvelle forme side-based et l'ancien chemin plat serait
  //   sinon silencieusement ambigu en release ;
  // - on préfère donc échouer explicitement plutôt que de "deviner" quelle
  //   représentation l'appelant voulait vraiment utiliser.
  if (providedSide != null &&
      (legacyActive != null || legacyReserve.isNotEmpty)) {
    throw ArgumentError(
      'BattleState.$sideLabel must be built either from $sideLabel'
      'Side or from the legacy $sideLabel/$sideLabel'
      'Reserve inputs, not both.',
    );
  }

  if (providedSide != null) {
    if (providedSide.id != expectedId) {
      throw ArgumentError(
        'BattleState.$sideLabel must carry BattleSideId.${expectedId.name}.',
      );
    }
    return providedSide;
  }

  if (legacyActive == null) {
    throw ArgumentError(
      'BattleState.$sideLabel requires either ${sideLabel}Side or '
      '$sideLabel.',
    );
  }

  return switch (expectedId) {
    BattleSideId.player => BattleSideState.player(
        active: legacyActive,
        reserve: legacyReserve,
      ),
    BattleSideId.enemy => BattleSideState.enemy(
        active: legacyActive,
        reserve: legacyReserve,
      ),
  };
}

/// Étages de stats utilisables par le moteur battle MVP enrichi.
///
/// On évite volontairement une structure générique "Map<Stat, int>" :
/// - le moteur n'a besoin que d'un petit sous-ensemble ;
/// - cette forme garde des accès simples et des invariants lisibles ;
/// - elle évite d'ouvrir de faux besoins "future-proof" trop tôt.
class BattleStatStages {
  const BattleStatStages({
    this.attack = 0,
    this.defense = 0,
    this.specialAttack = 0,
    this.specialDefense = 0,
    this.speed = 0,
  });

  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;

  /// Retourne une copie avec les changements demandés appliqués.
  BattleStatStages apply(List<BattleStatStageChange> changes) {
    var updated = this;
    for (final change in changes) {
      updated = updated._applyOne(change);
    }
    return updated;
  }

  BattleStatStages _applyOne(BattleStatStageChange change) {
    switch (change.stat) {
      case BattleStatId.attack:
        return BattleStatStages(
          attack: _clampStage(attack + change.stages),
          defense: defense,
          specialAttack: specialAttack,
          specialDefense: specialDefense,
          speed: speed,
        );
      case BattleStatId.defense:
        return BattleStatStages(
          attack: attack,
          defense: _clampStage(defense + change.stages),
          specialAttack: specialAttack,
          specialDefense: specialDefense,
          speed: speed,
        );
      case BattleStatId.specialAttack:
        return BattleStatStages(
          attack: attack,
          defense: defense,
          specialAttack: _clampStage(specialAttack + change.stages),
          specialDefense: specialDefense,
          speed: speed,
        );
      case BattleStatId.specialDefense:
        return BattleStatStages(
          attack: attack,
          defense: defense,
          specialAttack: specialAttack,
          specialDefense: _clampStage(specialDefense + change.stages),
          speed: speed,
        );
      case BattleStatId.speed:
        return BattleStatStages(
          attack: attack,
          defense: defense,
          specialAttack: specialAttack,
          specialDefense: specialDefense,
          speed: _clampStage(speed + change.stages),
        );
    }
  }

  /// Retourne le multiplicateur utilisé par le calcul de dégâts MVP enrichi.
  ///
  /// On reprend la table canonique simplifiée des stages Pokémon :
  /// - stage 0 => 1.0
  /// - stage +1 => 1.5
  /// - stage +2 => 2.0
  /// - stage -1 => 2/3
  /// etc.
  ///
  /// Cela suffit pour rendre les boosts/débuffs battle réellement visibles,
  /// sans ouvrir les vraies stats détaillées du moteur complet.
  double multiplierFor(BattleStatId stat) {
    final stage = switch (stat) {
      BattleStatId.attack => attack,
      BattleStatId.defense => defense,
      BattleStatId.specialAttack => specialAttack,
      BattleStatId.specialDefense => specialDefense,
      BattleStatId.speed => speed,
    };
    if (stage >= 0) {
      return (2 + stage) / 2;
    }
    return 2 / (2 - stage);
  }

  int _clampStage(int value) => value.clamp(-6, 6);
}
