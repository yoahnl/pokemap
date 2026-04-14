/// Blueprint Dart du noyau métier du battle engine.
///
/// Ce fichier n'est pas branché au runtime actuel. Il sert de base de travail
/// pour une future intégration dans `packages/map_battle`, en condensant :
/// - le plan projet local dans
///   `plan battle engine/plan-moteur-combat-projet.md`
/// - l'analyse Showdown dans
///   `plan battle engine/analyse-ultra-complete-mecaniques-combat-pokemon-showdown.md`
/// - la lecture ciblée des fichiers Showdown réellement structurants :
///   - `pokemon-showdown-master/sim/battle.ts`
///   - `pokemon-showdown-master/sim/battle-actions.ts`
///   - `pokemon-showdown-master/sim/battle-queue.ts`
///   - `pokemon-showdown-master/sim/pokemon.ts`
/// - le moteur MVP déjà présent dans `packages/map_battle`.
///
/// Intention :
/// - ne pas faire un faux port complet de Pokémon Showdown ;
/// - ne pas ouvrir une stack parallèle ;
/// - extraire la logique métier principale dans une forme Dart relisible ;
/// - préparer des types et pipelines qu'on pourra migrer plus tard dans le
///   vrai package `map_battle` sans repartir de zéro.
///
/// Choix de design :
/// - les identifiants restent majoritairement en anglais pour coller au code
///   existant dans `map_battle` et aux données locales Pokémon ;
/// - les commentaires sont en français pour capturer les invariants produits ;
/// - seuls les pivots structurels sont codés ici : setup, state, queue,
///   move pipeline, damage pipeline.
///
/// Hors scope volontaire de ce fichier :
/// - intégration runtime/Flame ;
/// - persistance save/load ;
/// - switch complet ;
/// - objets consommables ;
/// - statuts complets ;
/// - multi-combattants ;
/// - event engine riche façon Showdown.
library logique_metier_battle_engine;

enum BattleKind { wild, trainer }

enum BattlePhase { playerChoice, resolving, forcedSwitch, finished }

enum BattleRequestState { move, switchChoice, none }

enum BattleSideId { player, enemy }

enum BattleActionKind { move, switchAction, item, run, capture, residual }

enum BattleMoveCategory { physical, special, status }

enum BattleTargetKind {
  self,
  adjacentFoe,
  adjacentAlly,
  adjacentAllyOrSelf,
  any,
}

enum BattleOutcomeType { victory, defeat, runaway, captured }

/// Petit snapshot de stats utilisable par le moteur.
///
/// On sépare ce snapshot du modèle runtime complet du Pokémon pour garder un
/// contrat de combat pur. C'est le pendant simplifié de ce que Showdown garde
/// dans `pokemon.ts` entre stats de base, stats stockées et boosts.
class BattleStatsSnapshot {
  const BattleStatsSnapshot({
    required this.hp,
    required this.attack,
    required this.defense,
    required this.specialAttack,
    required this.specialDefense,
    required this.speed,
  });

  final int hp;
  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;
}

/// Contrat move enrichi.
///
/// Le moteur actuel garde surtout `id`, `name` et `power`. Le vrai gain à
/// court terme pour un moteur plus sérieux est ici : ne plus perdre la data
/// locale déjà disponible dans les catalogues projet.
class BattleMoveBlueprint {
  const BattleMoveBlueprint({
    required this.id,
    required this.name,
    required this.typeId,
    required this.category,
    required this.power,
    required this.accuracy,
    required this.maxPp,
    required this.currentPp,
    required this.priority,
    required this.target,
    this.flags = const <String>{},
    this.effectPayload = const <String, Object?>{},
  });

  final String id;
  final String name;
  final String typeId;
  final BattleMoveCategory category;
  final int power;
  final int accuracy;
  final int maxPp;
  final int currentPp;
  final int priority;
  final BattleTargetKind target;

  /// Espace minimal pour encoder plus tard des marqueurs sémantiques
  /// inspirés de Showdown (`protect`, `contact`, `sound`, etc.) sans
  /// imposer tout de suite un système complet de hooks.
  final Set<String> flags;

  /// Réceptacle léger pour embarquer plus tard des paramètres métier
  /// structurants (drain, recoil, statut, multi-hit, etc.).
  final Map<String, Object?> effectPayload;

  BattleMoveBlueprint copyWith({int? currentPp}) {
    return BattleMoveBlueprint(
      id: id,
      name: name,
      typeId: typeId,
      category: category,
      power: power,
      accuracy: accuracy,
      maxPp: maxPp,
      currentPp: currentPp ?? this.currentPp,
      priority: priority,
      target: target,
      flags: flags,
      effectPayload: effectPayload,
    );
  }
}

/// Snapshot d'un battler entrant en combat.
///
/// Cette structure correspond au contrat cible discuté dans les plans :
/// elle doit suffire à reconstruire l'état runtime d'un combattant sans
/// dépendre du save, du runtime Flame ou d'un accès IO.
class BattleParticipantSetup {
  const BattleParticipantSetup({
    required this.speciesId,
    required this.formId,
    required this.level,
    required this.types,
    required this.abilityId,
    required this.heldItemId,
    required this.natureId,
    required this.currentHp,
    required this.maxHp,
    required this.statsSnapshot,
    required this.statusId,
    required this.moves,
    required this.isShiny,
    required this.gender,
  });

  final String speciesId;
  final String formId;
  final int level;
  final List<String> types;
  final String abilityId;
  final String? heldItemId;
  final String natureId;
  final int currentHp;
  final int maxHp;
  final BattleStatsSnapshot statsSnapshot;
  final String? statusId;
  final List<BattleMoveBlueprint> moves;
  final bool isShiny;
  final String gender;
}

class BattleSideSetup {
  const BattleSideSetup({
    required this.sideId,
    required this.party,
    required this.activeIndex,
    this.sideConditions = const <String, Object?>{},
  });

  final BattleSideId sideId;
  final List<BattleParticipantSetup> party;
  final int activeIndex;
  final Map<String, Object?> sideConditions;
}

class BattleRulesProfile {
  const BattleRulesProfile({
    required this.id,
    this.allowRun = true,
    this.allowCapture = false,
    this.useTypeChart = false,
    this.useAccuracy = false,
    this.usePp = false,
  });

  final String id;

  /// Le guard de fuite reste un invariant métier du combat.
  final bool allowRun;

  /// Le runtime doit continuer à décider si la capture est honnête.
  /// Le moteur n'a pas à ouvrir un bag parallèle.
  final bool allowCapture;

  /// Les trois flags ci-dessous matérialisent bien ce que disent les plans :
  /// on peut enrichir le moteur par petites marches sans tout ouvrir d'un coup.
  final bool useTypeChart;
  final bool useAccuracy;
  final bool usePp;
}

class BattleSetupBlueprint {
  const BattleSetupBlueprint({
    required this.kind,
    required this.playerSide,
    required this.enemySide,
    required this.rules,
    this.trainerId,
  });

  final BattleKind kind;
  final BattleSideSetup playerSide;
  final BattleSideSetup enemySide;
  final BattleRulesProfile rules;
  final String? trainerId;

  bool get isTrainerBattle => kind == BattleKind.trainer;
}

/// État runtime d'un battler.
///
/// C'est le véritable équivalent compact de ce que Showdown porte dans
/// `pokemon.ts` : HP, statut, boosts, volatiles, item, ability et moveslots.
class BattleBattlerStateBlueprint {
  const BattleBattlerStateBlueprint({
    required this.speciesId,
    required this.formId,
    required this.level,
    required this.types,
    required this.abilityId,
    required this.heldItemId,
    required this.natureId,
    required this.currentHp,
    required this.maxHp,
    required this.stats,
    required this.statusId,
    required this.moves,
    this.boostStages = const <String, int>{},
    this.volatiles = const <String, Object?>{},
    this.isShiny = false,
    this.gender = 'unknown',
  });

  final String speciesId;
  final String formId;
  final int level;
  final List<String> types;
  final String abilityId;
  final String? heldItemId;
  final String natureId;
  final int currentHp;
  final int maxHp;
  final BattleStatsSnapshot stats;
  final String? statusId;
  final List<BattleMoveBlueprint> moves;
  final Map<String, int> boostStages;
  final Map<String, Object?> volatiles;
  final bool isShiny;
  final String gender;

  bool get isFainted => currentHp <= 0;

  BattleBattlerStateBlueprint withCurrentHp(int nextHp) {
    return BattleBattlerStateBlueprint(
      speciesId: speciesId,
      formId: formId,
      level: level,
      types: types,
      abilityId: abilityId,
      heldItemId: heldItemId,
      natureId: natureId,
      currentHp: clampInt(nextHp, 0, maxHp),
      maxHp: maxHp,
      stats: stats,
      statusId: statusId,
      moves: moves,
      boostStages: boostStages,
      volatiles: volatiles,
      isShiny: isShiny,
      gender: gender,
    );
  }

  BattleBattlerStateBlueprint consumePp(int moveIndex) {
    if (moveIndex < 0 || moveIndex >= moves.length) {
      return this;
    }
    final updatedMoves = moves.toList(growable: false);
    final move = updatedMoves[moveIndex];
    updatedMoves[moveIndex] = move.copyWith(
      currentPp: clampInt(move.currentPp - 1, 0, move.maxPp),
    );
    return BattleBattlerStateBlueprint(
      speciesId: speciesId,
      formId: formId,
      level: level,
      types: types,
      abilityId: abilityId,
      heldItemId: heldItemId,
      natureId: natureId,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      statusId: statusId,
      moves: updatedMoves,
      boostStages: boostStages,
      volatiles: volatiles,
      isShiny: isShiny,
      gender: gender,
    );
  }
}

class BattleSideStateBlueprint {
  const BattleSideStateBlueprint({
    required this.sideId,
    required this.party,
    required this.activeIndex,
    this.sideConditions = const <String, Object?>{},
    this.pendingSwitch = false,
    this.lastUsedMoveId,
  });

  final BattleSideId sideId;
  final List<BattleBattlerStateBlueprint> party;
  final int activeIndex;
  final Map<String, Object?> sideConditions;
  final bool pendingSwitch;
  final String? lastUsedMoveId;

  BattleBattlerStateBlueprint get activeBattler => party[activeIndex];

  BattleSideStateBlueprint withActiveBattler(
    BattleBattlerStateBlueprint battler, {
    String? lastUsedMoveId,
    bool? pendingSwitch,
  }) {
    final updatedParty = party.toList(growable: false);
    updatedParty[activeIndex] = battler;
    return BattleSideStateBlueprint(
      sideId: sideId,
      party: updatedParty,
      activeIndex: activeIndex,
      sideConditions: sideConditions,
      pendingSwitch: pendingSwitch ?? this.pendingSwitch,
      lastUsedMoveId: lastUsedMoveId ?? this.lastUsedMoveId,
    );
  }
}

class BattleFieldStateBlueprint {
  const BattleFieldStateBlueprint({
    this.weatherId,
    this.terrainId,
    this.pseudoWeather = const <String, Object?>{},
  });

  final String? weatherId;
  final String? terrainId;
  final Map<String, Object?> pseudoWeather;
}

class BattleQueuedActionBlueprint {
  const BattleQueuedActionBlueprint({
    required this.kind,
    required this.side,
    required this.priority,
    required this.speed,
    this.moveIndex,
    this.switchIndex,
    this.debugLabel,
  });

  final BattleActionKind kind;
  final BattleSideId side;
  final int priority;
  final int speed;
  final int? moveIndex;
  final int? switchIndex;
  final String? debugLabel;
}

class BattleChoiceBlueprint {
  const BattleChoiceBlueprint.move({
    required this.side,
    required this.moveIndex,
  }) : kind = BattleActionKind.move,
       switchIndex = null;

  const BattleChoiceBlueprint.run({required this.side})
    : kind = BattleActionKind.run,
      moveIndex = null,
      switchIndex = null;

  const BattleChoiceBlueprint.capture({required this.side})
    : kind = BattleActionKind.capture,
      moveIndex = null,
      switchIndex = null;

  final BattleActionKind kind;
  final BattleSideId side;
  final int? moveIndex;
  final int? switchIndex;
}

class BattleOutcomeBlueprint {
  const BattleOutcomeBlueprint({required this.type, required this.finalState});

  final BattleOutcomeType type;
  final BattleStateBlueprint finalState;
}

class BattleStateBlueprint {
  const BattleStateBlueprint({
    required this.phase,
    required this.turnNumber,
    required this.rngSeed,
    required this.field,
    required this.playerSide,
    required this.enemySide,
    required this.requestState,
    this.queue = const <BattleQueuedActionBlueprint>[],
    this.log = const <String>[],
    this.outcome,
  });

  final BattlePhase phase;
  final int turnNumber;
  final int rngSeed;
  final BattleFieldStateBlueprint field;
  final BattleSideStateBlueprint playerSide;
  final BattleSideStateBlueprint enemySide;
  final BattleRequestState requestState;
  final List<BattleQueuedActionBlueprint> queue;
  final List<String> log;
  final BattleOutcomeBlueprint? outcome;

  bool get isFinished => outcome != null;

  BattleSideStateBlueprint side(BattleSideId sideId) {
    return sideId == BattleSideId.player ? playerSide : enemySide;
  }

  BattleStateBlueprint replaceSide(BattleSideStateBlueprint sideState) {
    if (sideState.sideId == BattleSideId.player) {
      return BattleStateBlueprint(
        phase: phase,
        turnNumber: turnNumber,
        rngSeed: rngSeed,
        field: field,
        playerSide: sideState,
        enemySide: enemySide,
        requestState: requestState,
        queue: queue,
        log: log,
        outcome: outcome,
      );
    }
    return BattleStateBlueprint(
      phase: phase,
      turnNumber: turnNumber,
      rngSeed: rngSeed,
      field: field,
      playerSide: playerSide,
      enemySide: sideState,
      requestState: requestState,
      queue: queue,
      log: log,
      outcome: outcome,
    );
  }

  BattleStateBlueprint withLog(String entry) {
    return BattleStateBlueprint(
      phase: phase,
      turnNumber: turnNumber,
      rngSeed: rngSeed,
      field: field,
      playerSide: playerSide,
      enemySide: enemySide,
      requestState: requestState,
      queue: queue,
      log: [...log, entry],
      outcome: outcome,
    );
  }
}

/// Contexte minimal pour la formule de dégâts progressive.
///
/// Ce contexte traduit dans un petit objet les paramètres que les deux plans
/// considèrent comme indispensables à partir du moment où le moteur sort du
/// MVP "damage = power".
class BattleDamageContext {
  const BattleDamageContext({
    required this.attackerLevel,
    required this.movePower,
    required this.category,
    required this.attackerAttack,
    required this.attackerSpecialAttack,
    required this.defenderDefense,
    required this.defenderSpecialDefense,
    required this.stabMultiplier,
    required this.typeMultiplier,
    required this.randomMultiplier,
    this.criticalMultiplier = 1.0,
    this.abilityMultiplier = 1.0,
    this.itemMultiplier = 1.0,
    this.fieldMultiplier = 1.0,
  });

  final int attackerLevel;
  final int movePower;
  final BattleMoveCategory category;
  final int attackerAttack;
  final int attackerSpecialAttack;
  final int defenderDefense;
  final int defenderSpecialDefense;
  final double stabMultiplier;
  final double typeMultiplier;
  final double randomMultiplier;
  final double criticalMultiplier;
  final double abilityMultiplier;
  final double itemMultiplier;
  final double fieldMultiplier;
}

/// Noyau de logique métier.
///
/// Correspondance approximative avec Showdown :
/// - `BattleEngineBlueprint` = petite fusion de `Battle` + `BattleActions`
/// - `buildActionQueue` = coeur simplifié de `battle-queue.ts`
/// - `executeMovePipeline` = pipeline inspiré de `runMove` / `useMove`
///
/// Le moteur actuel de `map_battle` résout tout dans `BattleSession`.
/// Ce blueprint découpe déjà les responsabilités de façon plus nette pour la
/// future migration, sans imposer tout de suite un event engine complet.
class BattleEngineBlueprint {
  const BattleEngineBlueprint();

  BattleStateBlueprint createInitialState(BattleSetupBlueprint setup) {
    return BattleStateBlueprint(
      phase: BattlePhase.playerChoice,
      turnNumber: 1,
      rngSeed: 0,
      field: const BattleFieldStateBlueprint(),
      playerSide: BattleSideStateBlueprint(
        sideId: setup.playerSide.sideId,
        party: setup.playerSide.party
            .map(toBattlerState)
            .toList(growable: false),
        activeIndex: setup.playerSide.activeIndex,
        sideConditions: setup.playerSide.sideConditions,
      ),
      enemySide: BattleSideStateBlueprint(
        sideId: setup.enemySide.sideId,
        party: setup.enemySide.party
            .map(toBattlerState)
            .toList(growable: false),
        activeIndex: setup.enemySide.activeIndex,
        sideConditions: setup.enemySide.sideConditions,
      ),
      requestState: BattleRequestState.move,
      log: <String>['battle_started:${setup.kind.name}'],
    );
  }

  /// Compile les intentions UI en actions ordonnées.
  ///
  /// Ici se trouve la frontière métier importante :
  /// - le runtime choisit quelles actions proposer ;
  /// - le moteur revalide ce qui est légal ;
  /// - l'ordonnancement reste interne au moteur.
  List<BattleQueuedActionBlueprint> buildActionQueue({
    required BattleStateBlueprint state,
    required BattleRulesProfile rules,
    required BattleChoiceBlueprint playerChoice,
    required BattleChoiceBlueprint enemyChoice,
  }) {
    final raw = <BattleQueuedActionBlueprint>[
      legalizeChoice(state: state, rules: rules, choice: playerChoice),
      legalizeChoice(state: state, rules: rules, choice: enemyChoice),
    ];
    raw.sort(compareActions);
    return raw;
  }

  BattleQueuedActionBlueprint legalizeChoice({
    required BattleStateBlueprint state,
    required BattleRulesProfile rules,
    required BattleChoiceBlueprint choice,
  }) {
    final side = state.side(choice.side);
    final battler = side.activeBattler;

    if (choice.kind == BattleActionKind.run) {
      if (!rules.allowRun) {
        throw StateError('Run interdit par les règles de combat.');
      }
      return BattleQueuedActionBlueprint(
        kind: BattleActionKind.run,
        side: choice.side,
        priority: 6,
        speed: battler.stats.speed,
        debugLabel: 'run',
      );
    }

    if (choice.kind == BattleActionKind.capture) {
      if (!rules.allowCapture) {
        throw StateError('Capture interdite par les règles de combat.');
      }
      return BattleQueuedActionBlueprint(
        kind: BattleActionKind.capture,
        side: choice.side,
        priority: 5,
        speed: battler.stats.speed,
        debugLabel: 'capture',
      );
    }

    if (choice.kind == BattleActionKind.move) {
      final moveIndex = choice.moveIndex ?? 0;
      if (moveIndex < 0 || moveIndex >= battler.moves.length) {
        throw RangeError.index(moveIndex, battler.moves, 'moveIndex');
      }
      final move = battler.moves[moveIndex];
      if (rules.usePp && move.currentPp <= 0) {
        throw StateError('Move sans PP disponible.');
      }
      return BattleQueuedActionBlueprint(
        kind: BattleActionKind.move,
        side: choice.side,
        priority: move.priority,
        speed: battler.stats.speed,
        moveIndex: moveIndex,
        debugLabel: 'move:${move.id}',
      );
    }

    throw UnimplementedError(
      'Cette blueprint ne couvre pas encore ${choice.kind.name}.',
    );
  }

  /// Compare deux actions dans l'esprit de `battle-queue.ts`.
  ///
  /// Ordre retenu :
  /// - priorité la plus haute d'abord ;
  /// - puis vitesse la plus haute ;
  /// - puis joueur avant ennemi pour garder un tie-break déterministe local.
  static int compareActions(
    BattleQueuedActionBlueprint a,
    BattleQueuedActionBlueprint b,
  ) {
    final priority = b.priority.compareTo(a.priority);
    if (priority != 0) {
      return priority;
    }
    final speed = b.speed.compareTo(a.speed);
    if (speed != 0) {
      return speed;
    }
    return a.side.index.compareTo(b.side.index);
  }

  /// Pipeline d'un tour complet.
  ///
  /// Ce n'est pas un port complet du moteur actuel : c'est le squelette que
  /// les deux documents recommandent.
  ///
  /// Étapes :
  /// 1. compiler les choix ;
  /// 2. exécuter les actions dans l'ordre ;
  /// 3. appliquer les résiduels plus tard ;
  /// 4. fermer le tour ou produire un outcome.
  BattleStateBlueprint executeTurn({
    required BattleStateBlueprint state,
    required BattleRulesProfile rules,
    required BattleChoiceBlueprint playerChoice,
    required BattleChoiceBlueprint enemyChoice,
  }) {
    var workingState = BattleStateBlueprint(
      phase: BattlePhase.resolving,
      turnNumber: state.turnNumber,
      rngSeed: state.rngSeed,
      field: state.field,
      playerSide: state.playerSide,
      enemySide: state.enemySide,
      requestState: BattleRequestState.none,
      queue: const <BattleQueuedActionBlueprint>[],
      log: state.log,
      outcome: state.outcome,
    );

    final queue = buildActionQueue(
      state: state,
      rules: rules,
      playerChoice: playerChoice,
      enemyChoice: enemyChoice,
    );
    workingState = BattleStateBlueprint(
      phase: workingState.phase,
      turnNumber: workingState.turnNumber,
      rngSeed: workingState.rngSeed,
      field: workingState.field,
      playerSide: workingState.playerSide,
      enemySide: workingState.enemySide,
      requestState: workingState.requestState,
      queue: queue,
      log: workingState.log,
      outcome: workingState.outcome,
    );

    for (final action in queue) {
      if (workingState.isFinished) {
        break;
      }
      if (action.kind == BattleActionKind.run) {
        final outcome = BattleOutcomeBlueprint(
          type: BattleOutcomeType.runaway,
          finalState: workingState,
        );
        workingState = BattleStateBlueprint(
          phase: BattlePhase.finished,
          turnNumber: workingState.turnNumber,
          rngSeed: workingState.rngSeed,
          field: workingState.field,
          playerSide: workingState.playerSide,
          enemySide: workingState.enemySide,
          requestState: BattleRequestState.none,
          queue: const <BattleQueuedActionBlueprint>[],
          log: [...workingState.log, 'runaway:${action.side.name}'],
          outcome: outcome,
        );
        continue;
      }
      if (action.kind == BattleActionKind.capture) {
        final outcome = BattleOutcomeBlueprint(
          type: BattleOutcomeType.captured,
          finalState: workingState,
        );
        workingState = BattleStateBlueprint(
          phase: BattlePhase.finished,
          turnNumber: workingState.turnNumber,
          rngSeed: workingState.rngSeed,
          field: workingState.field,
          playerSide: workingState.playerSide,
          enemySide: workingState.enemySide,
          requestState: BattleRequestState.none,
          queue: const <BattleQueuedActionBlueprint>[],
          log: [...workingState.log, 'captured:${action.side.name}'],
          outcome: outcome,
        );
        continue;
      }
      if (action.kind == BattleActionKind.move) {
        workingState = executeMovePipeline(
          state: workingState,
          rules: rules,
          action: action,
        );
      }
    }

    if (workingState.isFinished) {
      return workingState;
    }

    final playerFainted = workingState.playerSide.activeBattler.isFainted;
    final enemyFainted = workingState.enemySide.activeBattler.isFainted;
    if (enemyFainted) {
      final outcome = BattleOutcomeBlueprint(
        type: BattleOutcomeType.victory,
        finalState: workingState,
      );
      return BattleStateBlueprint(
        phase: BattlePhase.finished,
        turnNumber: workingState.turnNumber,
        rngSeed: workingState.rngSeed,
        field: workingState.field,
        playerSide: workingState.playerSide,
        enemySide: workingState.enemySide,
        requestState: BattleRequestState.none,
        queue: const <BattleQueuedActionBlueprint>[],
        log: [...workingState.log, 'outcome:victory'],
        outcome: outcome,
      );
    }
    if (playerFainted) {
      final outcome = BattleOutcomeBlueprint(
        type: BattleOutcomeType.defeat,
        finalState: workingState,
      );
      return BattleStateBlueprint(
        phase: BattlePhase.finished,
        turnNumber: workingState.turnNumber,
        rngSeed: workingState.rngSeed,
        field: workingState.field,
        playerSide: workingState.playerSide,
        enemySide: workingState.enemySide,
        requestState: BattleRequestState.none,
        queue: const <BattleQueuedActionBlueprint>[],
        log: [...workingState.log, 'outcome:defeat'],
        outcome: outcome,
      );
    }

    return BattleStateBlueprint(
      phase: BattlePhase.playerChoice,
      turnNumber: workingState.turnNumber + 1,
      rngSeed: workingState.rngSeed + 1,
      field: workingState.field,
      playerSide: workingState.playerSide,
      enemySide: workingState.enemySide,
      requestState: BattleRequestState.move,
      queue: const <BattleQueuedActionBlueprint>[],
      log: [...workingState.log, 'turn_closed'],
      outcome: null,
    );
  }

  /// Pipeline principal d'exécution d'un move.
  ///
  /// Ordre volontairement calqué sur les deux plans :
  /// 1. vérifier si l'utilisateur peut agir ;
  /// 2. consommer le PP si le profil l'exige ;
  /// 3. résoudre immunité / précision ;
  /// 4. calculer et appliquer les dégâts ;
  /// 5. enregistrer les traces de résolution.
  BattleStateBlueprint executeMovePipeline({
    required BattleStateBlueprint state,
    required BattleRulesProfile rules,
    required BattleQueuedActionBlueprint action,
  }) {
    final actingSide = state.side(action.side);
    final defendingSide = state.side(
      action.side == BattleSideId.player
          ? BattleSideId.enemy
          : BattleSideId.player,
    );
    var attacker = actingSide.activeBattler;
    var defender = defendingSide.activeBattler;
    final moveIndex = action.moveIndex ?? 0;
    final move = attacker.moves[moveIndex];

    // On garde la barrière "can act" très explicite. C'est ici qu'on branchera
    // plus tard paralysie, sommeil, gel, recharge, lock, etc.
    if (attacker.isFainted) {
      return state.withLog('move_skipped:fainted:${attacker.speciesId}');
    }

    if (rules.usePp) {
      attacker = attacker.consumePp(moveIndex);
    }

    // Showdown sépare fortement target resolution, immunité, accuracy,
    // protection puis application du hit. On garde la même ossature.
    if (rules.useAccuracy && move.accuracy < 100) {
      final deterministicRoll = (state.turnNumber * 17 + state.rngSeed) % 100;
      if (deterministicRoll >= move.accuracy) {
        final updatedActingSide = actingSide.withActiveBattler(
          attacker,
          lastUsedMoveId: move.id,
        );
        return state
            .replaceSide(updatedActingSide)
            .withLog('move_missed:${move.id}:${action.side.name}');
      }
    }

    final damage = calculateDamage(
      BattleDamageContext(
        attackerLevel: attacker.level,
        movePower: move.power,
        category: move.category,
        attackerAttack: attacker.stats.attack,
        attackerSpecialAttack: attacker.stats.specialAttack,
        defenderDefense: defender.stats.defense,
        defenderSpecialDefense: defender.stats.specialDefense,
        stabMultiplier: attacker.types.contains(move.typeId) ? 1.5 : 1.0,
        typeMultiplier: rules.useTypeChart ? 1.0 : 1.0,
        randomMultiplier: 0.925,
      ),
    );

    defender = defender.withCurrentHp(defender.currentHp - damage);

    final updatedActingSide = actingSide.withActiveBattler(
      attacker,
      lastUsedMoveId: move.id,
    );
    final updatedDefendingSide = defendingSide.withActiveBattler(defender);

    return state
        .replaceSide(updatedActingSide)
        .replaceSide(updatedDefendingSide)
        .withLog('move_hit:${move.id}:${damage}');
  }

  /// Formule de dégâts progressive minimale.
  ///
  /// Cette fonction ne prétend pas reproduire tout Showdown.
  /// Elle fixe simplement la marche suivante par rapport au MVP actuel :
  /// sortir du simple `damage = move.power`.
  int calculateDamage(BattleDamageContext ctx) {
    final levelFactor = ((2 * ctx.attackerLevel) / 5).floor() + 2;
    final attackStat = ctx.category == BattleMoveCategory.physical
        ? ctx.attackerAttack
        : ctx.attackerSpecialAttack;
    final defenseStat = ctx.category == BattleMoveCategory.physical
        ? ctx.defenderDefense
        : ctx.defenderSpecialDefense;

    final safeDefense = defenseStat <= 0 ? 1 : defenseStat;
    final baseDamage =
        ((((levelFactor * ctx.movePower * attackStat) / safeDefense).floor()) /
                50)
            .floor() +
        2;

    final modifier =
        ctx.stabMultiplier *
        ctx.typeMultiplier *
        ctx.criticalMultiplier *
        ctx.randomMultiplier *
        ctx.abilityMultiplier *
        ctx.itemMultiplier *
        ctx.fieldMultiplier;

    var finalDamage = (baseDamage * modifier).floor();
    if (ctx.typeMultiplier > 0 && finalDamage < 1) {
      finalDamage = 1;
    }
    return finalDamage;
  }
}

BattleBattlerStateBlueprint toBattlerState(BattleParticipantSetup setup) {
  return BattleBattlerStateBlueprint(
    speciesId: setup.speciesId,
    formId: setup.formId,
    level: setup.level,
    types: setup.types,
    abilityId: setup.abilityId,
    heldItemId: setup.heldItemId,
    natureId: setup.natureId,
    currentHp: clampInt(setup.currentHp, 0, setup.maxHp),
    maxHp: setup.maxHp,
    stats: setup.statsSnapshot,
    statusId: setup.statusId,
    moves: setup.moves,
    isShiny: setup.isShiny,
    gender: setup.gender,
  );
}

int clampInt(int value, int min, int max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}
