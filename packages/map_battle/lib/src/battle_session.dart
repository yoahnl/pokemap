import 'battle_setup.dart';
import 'battle_state.dart';
import 'battle_action.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_rng.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_switch.dart';
import 'battle_volatile.dart';
import 'battle_stats.dart';
import 'battle_type_chart.dart';

const double _criticalHitMultiplier = 1.5;
const int _supportedWeatherDurationTurns = 5;
const int _supportedPseudoWeatherDurationTurns = 5;
const Set<String> _sandstormResidualImmuneTypes = <String>{
  'ground',
  'rock',
  'steel',
};

/// Crée une nouvelle session de combat.
///
/// [setup] - La configuration initiale du combat.
/// [rng] - Le seam RNG minimal utilisé par le hit pipeline.
///
/// Retourne une nouvelle [BattleSession] avec l'état initial.
/// C'est le point d'entrée principal du moteur de combat.
BattleSession createBattleSession(
  BattleSetup setup, {
  BattleRng rng = const BattleSeededRng(),
}) {
  final player = _buildBattleCombatantFromData(setup.playerPokemon);
  final enemy = _buildBattleCombatantFromData(setup.enemyPokemon);
  final playerReserve = setup.playerReservePokemon
      .map(_buildBattleCombatantFromData)
      .toList(growable: false);
  final enemyReserve = setup.enemyReservePokemon
      .map(_buildBattleCombatantFromData)
      .toList(growable: false);

  // Créer l'état initial
  final initialState = BattleState(
    phase: BattlePhase.playerChoice,
    player: player,
    playerReserve: playerReserve,
    enemy: enemy,
    enemyReserve: enemyReserve,
    field: setup.fieldState,
    currentTurn: null,
    outcome: null,
  );

  return BattleSession._(
    state: initialState,
    setup: setup,
    rng: rng,
  );
}

int _clampHp({
  required int? currentHp,
  required int maxHp,
}) {
  final value = currentHp ?? maxHp;
  if (value < 0) {
    return 0;
  }
  if (value > maxHp) {
    return maxHp;
  }
  return value;
}

BattleCombatant _buildBattleCombatantFromData(
  BattleCombatantData data,
) {
  // On convertit tout le petit contrat battle d'un même bloc pour garantir
  // qu'aucune dimension déjà jugée honnête n'est reperdue lors du passage
  // setup -> state, y compris maintenant l'identité de lineup BE10.
  return BattleCombatant(
    speciesId: data.speciesId,
    lineupIndex: data.lineupIndex,
    level: data.level,
    currentHp: _clampHp(
      currentHp: data.currentHp,
      maxHp: data.maxHp,
    ),
    maxHp: data.maxHp,
    stats: data.stats,
    typing: data.typing,
    majorStatus: data.majorStatus,
    volatileState: data.volatileState,
    abilityId: data.abilityId,
    moves: data.moves
        .map(
          (m) => BattleMove(
            id: m.id,
            name: m.name,
            power: m.power,
            type: m.type,
            category: m.category,
            target: m.target,
            accuracy: m.accuracy,
            pp: m.pp,
            currentPp: m.currentPp,
            priority: m.priority,
            critRatio: m.critRatio,
            majorStatusEffect: m.majorStatusEffect,
            selfVolatileStatus: m.selfVolatileStatus,
            weatherEffect: m.weatherEffect,
            pseudoWeatherEffect: m.pseudoWeatherEffect,
            breaksProtect: m.breaksProtect,
            requiresRecharge: m.requiresRecharge,
            chargeThenStrikeEffect: m.chargeThenStrikeEffect,
            selfStatStageChanges: m.selfStatStageChanges,
            targetStatStageChanges: m.targetStatStageChanges,
          ),
        )
        .toList(growable: false),
  );
}

/// Session de combat.
///
/// Encapsule l'état d'un combat et fournit les méthodes pour interagir avec.
/// Immutable : toutes les méthodes retournent une nouvelle session.
///
/// Cycle de vie :
/// 1. [createBattleSession] crée la session
/// 2. [getAvailableChoices] récupère les choix disponibles
/// 3. [applyChoice] applique un choix et retourne une nouvelle session
/// 4. Répéter 2-3 jusqu'à ce que [state.isFinished] soit true
/// 5. Récupérer [state.outcome] pour le résultat final
class BattleSession {
  /// Crée une session de combat.
  ///
  /// Constructeur privé. Utiliser [createBattleSession] à la place.
  const BattleSession._({
    required this.state,
    required this.setup,
    required this.rng,
  });

  /// L'état actuel du combat.
  final BattleState state;

  /// La configuration initiale du combat.
  ///
  /// Gardée pour accéder aux métadonnées (trainerId, etc.).
  final BattleSetup setup;

  /// RNG minimal du moteur battle.
  ///
  /// BE4 choisit de le garder sur la session plutôt que dans `BattleState` :
  /// - l'état observable du combat reste centré sur les combattants / outcomes ;
  /// - le RNG reste un détail de résolution, pas une donnée UI/runtime ;
  /// - mais il reste explicitement injectable et immutable.
  final BattleRng rng;

  /// Récupère les choix disponibles pour le joueur.
  ///
  /// À appeler quand [state.phase] == [BattlePhase.playerChoice].
  ///
  /// Retourne une liste de choix :
  /// - [PlayerBattleChoiceFight] pour chaque attaque disponible (0-3)
  /// - [PlayerBattleChoiceSwitch] pour chaque réserve encore vivante quand un
  ///   switch volontaire ou un remplacement forcé est honnêtement possible
  /// - [PlayerBattleChoiceCapture] pour capturer, uniquement en sauvage quand
  ///   le runtime a explicitement autorisé cette issue
  /// - [PlayerBattleChoiceRun] pour fuir, uniquement en combat sauvage
  ///
  /// Exemple d'usage :
  /// ```dart
  /// final choices = session.getAvailableChoices();
  /// // wild: [Fight(0), Fight(1), Fight(2), Fight(3), Capture(), Run()]
  /// // trainer: [Fight(0), Fight(1), Fight(2), Fight(3)]
  /// ```
  List<PlayerBattleChoice> getAvailableChoices() {
    final replacementChoices = _availableForcedReplacementChoices();
    if (replacementChoices.isNotEmpty) {
      return replacementChoices;
    }

    final forcedChoice = _forcedPlayerChoice();
    if (forcedChoice != null) {
      return <PlayerBattleChoice>[forcedChoice];
    }

    // BE4 arrête ici un autre mensonge discret :
    // - un move à 0 PP ne doit plus apparaître comme un choix valide ;
    // - on conserve néanmoins l'index réel du slot pour que l'UI/runtime
    //   continue à référencer le vrai move dans la liste du combattant ;
    // - on n'ouvre toujours pas Struggle, donc un Pokémon peut n'avoir aucun
    //   choix `Fight` restant.
    final fightChoices = <PlayerBattleChoice>[];
    for (var i = 0; i < state.player.moves.length; i++) {
      if (state.player.moves[i].hasUsablePp) {
        fightChoices.add(PlayerBattleChoiceFight(i));
      }
    }

    // BE10 ajoute un seam de switch volontaire minimal sans ouvrir de système
    // de party complet :
    // - le joueur peut dépenser son tour pour envoyer un membre de réserve ;
    // - seuls les membres de réserve encore vivants sont proposés ;
    // - les membres K.O. restent éventuellement stockés pour le write-back,
    //   mais ne doivent jamais apparaître comme choix jouable.
    fightChoices.addAll(_availableVoluntarySwitchChoices());

    // Invariants métier lots 11 + 13 :
    // - la fuite est autorisée en sauvage pour garder une vraie boucle jouable ;
    // - la capture n'est autorisée qu'en sauvage ;
    // - la capture n'est proposée que si le runtime a validé qu'elle pourra
    //   être écrite honnêtement (party avec place, pas de trainer battle) ;
    // - trainer battle : ni Run ni Capture ne doivent apparaître.
    if (!setup.isTrainerBattle && setup.allowCapture) {
      fightChoices.add(const PlayerBattleChoiceCapture());
    }

    // On filtre donc Run ici pour que l'UI/runtime n'ait pas de bouton
    // de fuite à afficher en trainer battle.
    if (!setup.isTrainerBattle) {
      fightChoices.add(const PlayerBattleChoiceRun());
    }

    return fightChoices;
  }

  PlayerBattleChoice? _forcedPlayerChoice() {
    if (state.player.isFainted) {
      return null;
    }

    final volatileState = state.player.volatileState;
    if (!volatileState.mustRecharge && volatileState.pendingCharge == null) {
      return null;
    }

    // BE8 choisit ici la plus petite surface publique honnête :
    // - le joueur ne re-sélectionne pas un move librement pendant une
    //   recharge ou la libération d'un move déjà chargé ;
    // - on expose donc un simple "continuer" au lieu de maquiller ce tour
    //   forcé avec un faux bouton de move.
    return const PlayerBattleChoiceContinue();
  }

  List<PlayerBattleChoiceSwitch> _availableForcedReplacementChoices() {
    if (!state.player.isFainted) {
      return const <PlayerBattleChoiceSwitch>[];
    }

    return _selectableReserveIndices(state.playerReserve)
        .map(PlayerBattleChoiceSwitch.new)
        .toList(growable: false);
  }

  List<PlayerBattleChoiceSwitch> _availableVoluntarySwitchChoices() {
    if (state.player.isFainted) {
      return const <PlayerBattleChoiceSwitch>[];
    }

    return _selectableReserveIndices(state.playerReserve)
        .map(PlayerBattleChoiceSwitch.new)
        .toList(growable: false);
  }

  List<int> _selectableReserveIndices(List<BattleCombatant> reserve) {
    final indices = <int>[];
    for (var i = 0; i < reserve.length; i++) {
      if (!reserve[i].isFainted) {
        indices.add(i);
      }
    }
    return List<int>.unmodifiable(indices);
  }

  BattleAction? _resolveForcedAction({
    required String combatantLabel,
    required BattleCombatant combatant,
  }) {
    if (combatant.isFainted) {
      return null;
    }

    final volatileState = combatant.volatileState;
    final pendingCharge = volatileState.pendingCharge;
    if (pendingCharge != null) {
      if (pendingCharge.moveIndex < 0 ||
          pendingCharge.moveIndex >= combatant.moves.length) {
        throw StateError(
          'Le combattant $combatantLabel porte un move chargé invalide (index ${pendingCharge.moveIndex}).',
        );
      }

      final chargedMove = combatant.moves[pendingCharge.moveIndex];
      if (chargedMove.id != pendingCharge.moveId ||
          chargedMove.chargeThenStrikeEffect == null) {
        throw StateError(
          'Le combattant $combatantLabel porte un état de charge incohérent pour le move ${pendingCharge.moveId}.',
        );
      }

      return BattleActionFight(
        chargedMove,
        moveIndex: pendingCharge.moveIndex,
      );
    }

    if (volatileState.mustRecharge) {
      return const BattleActionRecharge();
    }

    return null;
  }

  /// Applique un choix du joueur et retourne une NOUVELLE session.
  ///
  /// [choice] - Le choix fait par le joueur.
  ///
  /// Cette méthode est immutable : elle ne modifie pas [this],
  /// mais retourne une nouvelle [BattleSession] avec l'état mis à jour.
  ///
  /// Comportement :
  /// 1. Convertit le [PlayerBattleChoice] en [BattleAction]
  /// 2. Détermine l'action de l'ennemi (IA simple)
  /// 3. Résout le tour (ordre d'exécution, dégâts, etc.)
  /// 4. Vérifie si un combattant est K.O.
  /// 5. Si combat fini, crée [BattleOutcome]
  /// 6. Retourne la nouvelle session
  ///
  /// Depuis BE4, la résolution d'un move n'est plus "toujours hit" :
  /// - la tentative peut consommer 1 PP puis rater ;
  /// - ce miss n'annule ni l'ordre du tour ni la consommation ;
  /// - seuls les effets réellement supportés sont alors appliqués sur hit.
  ///
  /// Exemple d'usage :
  /// ```dart
  /// final newSession = session.applyChoice(PlayerBattleChoiceFight(0));
  /// if (newSession.state.isFinished) {
  ///   final outcome = newSession.state.outcome!;
  ///   // outcome.isVictory, outcome.isDefeat, etc.
  /// }
  /// ```
  BattleSession applyChoice(PlayerBattleChoice choice) {
    final forcedReplacementChoices = _availableForcedReplacementChoices();
    if (forcedReplacementChoices.isNotEmpty) {
      if (choice is! PlayerBattleChoiceSwitch) {
        throw StateError(
          'Le joueur doit d’abord remplacer son Pokémon K.O. avec un choix de switch valide.',
        );
      }
      return _applyForcedPlayerReplacement(choice);
    }

    final forcedPlayerAction = _resolveForcedAction(
      combatantLabel: 'player',
      combatant: state.player,
    );
    if (forcedPlayerAction != null && choice is! PlayerBattleChoiceContinue) {
      throw StateError(
        'Ce tour joueur est forcé; il faut l’acquitter avec PlayerBattleChoiceContinue.',
      );
    }
    if (forcedPlayerAction == null && choice is PlayerBattleChoiceContinue) {
      throw StateError(
        'PlayerBattleChoiceContinue est réservé aux tours forcés BE8.',
      );
    }

    // Frontière métier défensive :
    // même si un call site contourne getAvailableChoices(), un combat trainer
    // ne doit jamais pouvoir produire ni "runaway", ni "captured".
    //
    // On rejette explicitement ce cas illégal au niveau du moteur, ce qui
    // évite de dépendre d'un filtre UI seulement.
    if (forcedPlayerAction == null &&
        choice is PlayerBattleChoiceRun &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceRun est interdit pendant un trainer battle.',
      );
    }
    if (forcedPlayerAction == null &&
        choice is PlayerBattleChoiceCapture &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pendant un trainer battle.',
      );
    }
    if (forcedPlayerAction == null &&
        choice is PlayerBattleChoiceCapture &&
        !setup.allowCapture) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pour ce combat.',
      );
    }

    // Lot 11 verrouille une boucle sauvage jouable de bout en bout.
    //
    // L'overlay runtime expose déjà explicitement l'action "Run". Si on la
    // laissait se comporter comme un tour vide sans issue finale, on garderait
    // une incohérence produit : la fuite semblerait disponible, mais ne
    // sortirait jamais réellement du combat.
    //
    // On choisit ici le comportement le plus petit et le plus honnête pour le
    // moteur MVP actuel :
    // - la fuite réussit immédiatement ;
    // - aucun dégât supplémentaire n'est appliqué ;
    // - aucun système lot 14+ (récompenses, sac, switch, XP, etc.) n'est ouvert ;
    // - le runtime lot 10 peut réutiliser directement cet outcome pour son
    //   write-back et son retour overworld.
    if (forcedPlayerAction == null && choice is PlayerBattleChoiceRun) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: state.player,
        playerReserve: state.playerReserve,
        enemy: state.enemy,
        enemyReserve: state.enemyReserve,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          player: finalState.player,
          playerReserve: finalState.playerReserve,
          enemy: finalState.enemy,
          enemyReserve: finalState.enemyReserve,
          field: finalState.field,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.runaway,
            finalState: finalState,
          ),
        ),
        setup: setup,
        rng: rng,
      );
    }

    // Lot 13 choisit le plus petit contrat de capture honnête :
    // - pas de formule canonique de Poké Ball ;
    // - pas de consommation d'objet ;
    // - la capture réussit immédiatement quand elle est proposée ;
    // - le runtime reste responsable du vrai write-back dans la party/save.
    //
    // On garde l'ennemi inchangé dans le finalState : il représente le Pokémon
    // effectivement capturé, avec ses moves/niveau/ability réellement engagés.
    if (forcedPlayerAction == null && choice is PlayerBattleChoiceCapture) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: state.player,
        playerReserve: state.playerReserve,
        enemy: state.enemy,
        enemyReserve: state.enemyReserve,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          player: finalState.player,
          playerReserve: finalState.playerReserve,
          enemy: finalState.enemy,
          enemyReserve: finalState.enemyReserve,
          field: finalState.field,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.captured,
            finalState: finalState,
          ),
        ),
        setup: setup,
        rng: rng,
      );
    }

    // Phase 1: Convertir le choix en action
    final playerAction = forcedPlayerAction ?? _choiceToAction(choice);

    // Phase 2: Déterminer l'action de l'ennemi (IA simple)
    final enemyAction = _resolveForcedAction(
          combatantLabel: 'enemy',
          combatant: state.enemy,
        ) ??
        _chooseEnemyAction();

    // Phase 3: Résoudre le tour.
    //
    // BE3 corrige ici une ancienne approximation mensongère :
    // - on ne résout plus "joueur puis ennemi quoi qu'il arrive" ;
    // - on calcule un ordre minimal honnête une seule fois au début du tour ;
    // - priorité d'abord, puis vitesse effective, puis tie-break déterministe ;
    // - aucun recalcul rétroactif si un move modifie la vitesse pendant ce tour.
    //
    // Frontière volontairement stricte :
    // - pas de queue générique façon Showdown ;
    // - pas de PRNG ;
    // - pas de système générique de switch / hooks / réserves façon Showdown ;
    // - BE10 ajoute seulement le plus petit switch singles nécessaire :
    //   actif + réserve, switch volontaire joueur, remplacement après K.O. ;
    // - BE7 ajoute seulement un résiduel de fin de tour local pour les
    //   statuts majeurs supportés ;
    // - juste le plus petit mécanisme honnête pour les deux actions de ce
    //   tour et leur clôture immédiate.
    final resolvedTurn = _resolveTurn(playerAction, enemyAction);

    // Phase 4: Récupérer l'état résultant après dégâts + éventuels boosts.
    final newPlayer = resolvedTurn.player;
    final newPlayerReserve = resolvedTurn.playerReserve;
    final newEnemy = resolvedTurn.enemy;
    final newEnemyReserve = resolvedTurn.enemyReserve;
    final postTurnSwitches = _resolvePostTurnSwitchState(
      player: newPlayer,
      playerReserve: newPlayerReserve,
      enemy: newEnemy,
      enemyReserve: newEnemyReserve,
    );
    final switchEvents = <BattleSwitchEvent>[
      ...resolvedTurn.turnResult.switchEvents,
      ...postTurnSwitches.switchEvents,
    ];
    final turnResult = BattleTurnResult(
      playerAction: resolvedTurn.turnResult.playerAction,
      enemyAction: resolvedTurn.turnResult.enemyAction,
      executions: resolvedTurn.turnResult.executions,
      statusEvents: resolvedTurn.turnResult.statusEvents,
      volatileEvents: resolvedTurn.turnResult.volatileEvents,
      fieldEvents: resolvedTurn.turnResult.fieldEvents,
      switchEvents: List<BattleSwitchEvent>.unmodifiable(switchEvents),
    );

    // Phase 5: Vérifier si le combat est fini
    final outcome = _determineOutcome(
      postTurnSwitches.player,
      postTurnSwitches.playerReserve,
      postTurnSwitches.enemy,
      postTurnSwitches.enemyReserve,
      resolvedTurn.field,
    );

    // Phase 6: Créer le nouvel état
    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      player: postTurnSwitches.player,
      playerReserve: postTurnSwitches.playerReserve,
      enemy: postTurnSwitches.enemy,
      enemyReserve: postTurnSwitches.enemyReserve,
      field: resolvedTurn.field,
      // On conserve maintenant la trace du dernier tour même s'il termine le
      // combat :
      // - sinon un K.O. au résiduel, une paralysie bloquante ou une
      //   application de statut terminale redeviendraient invisibles ;
      // - `Run` et `Capture` gardent toujours `currentTurn == null`, car ils ne
      //   passent pas par `_resolveTurn`.
      currentTurn: turnResult,
      outcome: outcome,
    );

    return BattleSession._(
      state: newState,
      setup: setup,
      rng: resolvedTurn.rng,
    );
  }

  BattleSession _applyForcedPlayerReplacement(PlayerBattleChoiceSwitch choice) {
    final replacement = _resolveSwitchAction(
      actor: 'player',
      active: state.player,
      reserve: state.playerReserve,
      reserveIndex: choice.reserveIndex,
      wasForced: true,
    );

    return BattleSession._(
      state: BattleState(
        phase: BattlePhase.playerChoice,
        player: replacement.active,
        playerReserve: replacement.reserve,
        enemy: state.enemy,
        enemyReserve: state.enemyReserve,
        field: state.field,
        currentTurn: BattleTurnResult(
          playerAction: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          enemyAction: const BattleActionNone(),
          executions: const <BattleMoveExecution>[],
          switchEvents: <BattleSwitchEvent>[replacement.event],
        ),
        outcome: null,
      ),
      setup: setup,
      rng: rng,
    );
  }

  _ResolvedSwitchAction _resolveSwitchAction({
    required String actor,
    required BattleCombatant active,
    required List<BattleCombatant> reserve,
    required int reserveIndex,
    required bool wasForced,
  }) {
    if (reserveIndex < 0 || reserveIndex >= reserve.length) {
      throw RangeError.index(reserveIndex, reserve, 'reserveIndex');
    }

    final incoming = reserve[reserveIndex];
    if (incoming.isFainted) {
      throw StateError(
        'Le switch demandé vise un Pokémon de réserve déjà K.O.',
      );
    }

    // BE10 choisit de conserver une réserve de taille stable :
    // - le membre entrant quitte la réserve ;
    // - l'actif sortant y retourne au même emplacement après reset ;
    // - chaque participant battle reste donc présent exactement une fois,
    //   ce qui simplifie le write-back runtime final.
    final updatedReserve = List<BattleCombatant>.of(reserve);
    updatedReserve[reserveIndex] = active.resetForReserveOnSwitchOut();

    return _ResolvedSwitchAction(
      active: incoming,
      reserve: List<BattleCombatant>.unmodifiable(updatedReserve),
      event: BattleSwitchEvent.switched(
        actor: actor,
        fromSpeciesId: active.speciesId,
        toSpeciesId: incoming.speciesId,
        wasForced: wasForced,
      ),
    );
  }

  _ResolvedPostTurnSwitchState _resolvePostTurnSwitchState({
    required BattleCombatant player,
    required List<BattleCombatant> playerReserve,
    required BattleCombatant enemy,
    required List<BattleCombatant> enemyReserve,
  }) {
    var updatedPlayer = player;
    var updatedPlayerReserve = playerReserve;
    var updatedEnemy = enemy;
    var updatedEnemyReserve = enemyReserve;
    final switchEvents = <BattleSwitchEvent>[];

    final enemyReplacementIndex = _firstUsableReserveIndex(updatedEnemyReserve);
    if (updatedEnemy.isFainted && enemyReplacementIndex != null) {
      final replacement = _resolveSwitchAction(
        actor: 'enemy',
        active: updatedEnemy,
        reserve: updatedEnemyReserve,
        reserveIndex: enemyReplacementIndex,
        wasForced: true,
      );
      updatedEnemy = replacement.active;
      updatedEnemyReserve = replacement.reserve;
      switchEvents.add(replacement.event);
    }

    if (updatedPlayer.isFainted &&
        !updatedEnemy.isFainted &&
        _firstUsableReserveIndex(updatedPlayerReserve) != null) {
      switchEvents.add(
        BattleSwitchEvent.replacementRequired(
          actor: 'player',
          fromSpeciesId: updatedPlayer.speciesId,
        ),
      );
    }

    return _ResolvedPostTurnSwitchState(
      player: updatedPlayer,
      playerReserve: updatedPlayerReserve,
      enemy: updatedEnemy,
      enemyReserve: updatedEnemyReserve,
      switchEvents: List<BattleSwitchEvent>.unmodifiable(switchEvents),
    );
  }

  int? _firstUsableReserveIndex(List<BattleCombatant> reserve) {
    for (var i = 0; i < reserve.length; i++) {
      if (!reserve[i].isFainted) {
        return i;
      }
    }
    return null;
  }

  /// Convertit un [PlayerBattleChoice] en [BattleAction].
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleAction _choiceToAction(PlayerBattleChoice choice) {
    if (choice is PlayerBattleChoiceFight) {
      // Vérifier que l'index est valide
      if (choice.moveIndex >= 0 &&
          choice.moveIndex < state.player.moves.length) {
        final move = state.player.moves[choice.moveIndex];
        if (!move.hasUsablePp) {
          throw StateError(
            'Le move "${move.name}" n’a plus de PP et ne peut pas être utilisé.',
          );
        }
        return BattleActionFight(
          move,
          moveIndex: choice.moveIndex,
        );
      }
      // Fallback: première attaque si index invalide
      final fallbackMove = state.player.moves.first;
      if (!fallbackMove.hasUsablePp) {
        throw StateError(
          'Aucun fallback honnête possible : le move par défaut n’a plus de PP.',
        );
      }
      return BattleActionFight(
        fallbackMove,
        moveIndex: 0,
      );
    } else if (choice is PlayerBattleChoiceSwitch) {
      if (choice.reserveIndex < 0 ||
          choice.reserveIndex >= state.playerReserve.length) {
        throw StateError(
          'Le switch demandé vise un index de réserve invalide (${choice.reserveIndex}).',
        );
      }
      if (state.playerReserve[choice.reserveIndex].isFainted) {
        throw StateError(
          'Le switch demandé vise un Pokémon de réserve déjà K.O.',
        );
      }
      return BattleActionSwitch(
        reserveIndex: choice.reserveIndex,
      );
    } else if (choice is PlayerBattleChoiceRun) {
      return const BattleActionRun();
    } else if (choice is PlayerBattleChoiceContinue) {
      throw StateError(
        'PlayerBattleChoiceContinue ne doit jamais atteindre _choiceToAction sans action forcée résolue en amont.',
      );
    }
    // Fallback: première attaque
    final fallbackMove = state.player.moves.first;
    if (!fallbackMove.hasUsablePp) {
      throw StateError(
        'Aucun fallback honnête possible : le move par défaut n’a plus de PP.',
      );
    }
    return BattleActionFight(
      fallbackMove,
      moveIndex: 0,
    );
  }

  /// Détermine l'action de l'ennemi (IA simple).
  ///
  /// Pour ce MVP, l'IA est très simple :
  /// - Si l'ennemi peut attaquer, il attaque avec une attaque aléatoire (déterministe : première)
  /// - L'ennemi ne fuit jamais
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleAction _chooseEnemyAction() {
    // IA simple : toujours utiliser la première attaque encore utilisable.
    //
    // BE4 ne réintroduit pas un comportement mensonger "le move part quand
    // même sans PP" et n'ouvre pas non plus Struggle :
    // - si aucun move n'a de PP, on échoue explicitement ;
    // - cela garde la dette visible au lieu de la maquiller.
    if (state.enemy.moves.isNotEmpty && !state.enemy.isFainted) {
      for (var i = 0; i < state.enemy.moves.length; i++) {
        if (state.enemy.moves[i].hasUsablePp) {
          return BattleActionFight(
            state.enemy.moves[i],
            moveIndex: i,
          );
        }
      }
      throw StateError(
        'Le combattant adverse n’a plus aucun move utilisable et Struggle est hors scope.',
      );
    }
    // Si aucune attaque, ne rien faire (cas edge)
    return const BattleActionRun();
  }

  /// Résout un tour de combat.
  ///
  /// [playerAction] - L'action du joueur.
  /// [enemyAction] - L'action de l'ennemi.
  ///
  /// Retourne l'état résolu du tour :
  /// - les exécutions à afficher ;
  /// - l'état joueur après dégâts / boosts ;
  /// - l'état ennemi après dégâts / boosts.
  ///
  /// Ordre de résolution BE3 :
  /// 1. on capture l'ordre une seule fois au début du tour ;
  /// 2. pour deux `Fight`, on compare :
  ///    - priorité décroissante ;
  ///    - vitesse effective décroissante ;
  ///    - tie-break déterministe explicite : joueur avant ennemi ;
  /// 3. une action de vitesse du premier acteur n'altère donc jamais
  ///    rétroactivement l'ordre du même tour ;
  /// 4. `Run`/`Capture` restent hors pseudo-queue générique ;
  /// 5. BE7 ajoute ensuite seulement une petite phase de résiduel de fin de
  ///    tour pour les statuts majeurs supportés, sans ouvrir un système de
  ///    hooks générique.
  ///
  /// Cette méthode est interne au moteur de combat.
  _ResolvedBattleTurn _resolveTurn(
      BattleAction playerAction, BattleAction enemyAction) {
    final executions = <BattleMoveExecution>[];
    final statusEvents = <BattleStatusEvent>[];
    final volatileEvents = <BattleVolatileEvent>[];
    final fieldEvents = <BattleFieldEvent>[];
    final switchEvents = <BattleSwitchEvent>[];
    var player = state.player;
    var playerReserve = state.playerReserve;
    var enemy = state.enemy;
    var enemyReserve = state.enemyReserve;
    var field = state.field;
    var turnRng = rng;
    final orderedActions = _resolveTurnOrder(
      playerAction: playerAction,
      enemyAction: enemyAction,
      player: player,
      enemy: enemy,
      field: field,
    );

    for (final orderedAction in orderedActions) {
      switch (orderedAction.actor) {
        case _BattleActor.player:
          if (orderedAction.action
              case BattleActionFight(:final move, :final moveIndex)) {
            if (player.isFainted || enemy.isFainted) {
              continue;
            }
            final resolution = _resolveMoveExecution(
              attackerLabel: 'player',
              move: move,
              moveIndex: moveIndex,
              attacker: player,
              defender: enemy,
              field: field,
              targetLabel: 'enemy',
              rng: turnRng,
            );
            player = resolution.attacker;
            enemy = resolution.defender;
            field = resolution.field;
            turnRng = resolution.rng;
            if (resolution.execution != null) {
              executions.add(resolution.execution!);
            }
            statusEvents.addAll(resolution.statusEvents);
            volatileEvents.addAll(resolution.volatileEvents);
            fieldEvents.addAll(resolution.fieldEvents);
          } else if (orderedAction.action
              case BattleActionSwitch(:final reserveIndex)) {
            final resolution = _resolveSwitchAction(
              actor: 'player',
              active: player,
              reserve: playerReserve,
              reserveIndex: reserveIndex,
              wasForced: false,
            );
            player = resolution.active;
            playerReserve = resolution.reserve;
            switchEvents.add(resolution.event);
          } else if (orderedAction.action is BattleActionRecharge) {
            if (player.isFainted || enemy.isFainted) {
              continue;
            }
            final resolution = _resolveRechargeAction(
              combatantLabel: 'player',
              combatant: player,
            );
            player = resolution.combatant;
            volatileEvents.addAll(resolution.volatileEvents);
          }
        case _BattleActor.enemy:
          if (orderedAction.action
              case BattleActionFight(:final move, :final moveIndex)) {
            if (enemy.isFainted || player.isFainted) {
              continue;
            }
            final resolution = _resolveMoveExecution(
              attackerLabel: 'enemy',
              move: move,
              moveIndex: moveIndex,
              attacker: enemy,
              defender: player,
              field: field,
              targetLabel: 'player',
              rng: turnRng,
            );
            enemy = resolution.attacker;
            player = resolution.defender;
            field = resolution.field;
            turnRng = resolution.rng;
            if (resolution.execution != null) {
              executions.add(resolution.execution!);
            }
            statusEvents.addAll(resolution.statusEvents);
            volatileEvents.addAll(resolution.volatileEvents);
            fieldEvents.addAll(resolution.fieldEvents);
          } else if (orderedAction.action
              case BattleActionSwitch(:final reserveIndex)) {
            final resolution = _resolveSwitchAction(
              actor: 'enemy',
              active: enemy,
              reserve: enemyReserve,
              reserveIndex: reserveIndex,
              wasForced: false,
            );
            enemy = resolution.active;
            enemyReserve = resolution.reserve;
            switchEvents.add(resolution.event);
          } else if (orderedAction.action is BattleActionRecharge) {
            if (enemy.isFainted || player.isFainted) {
              continue;
            }
            final resolution = _resolveRechargeAction(
              combatantLabel: 'enemy',
              combatant: enemy,
            );
            enemy = resolution.combatant;
            volatileEvents.addAll(resolution.volatileEvents);
          }
      }
    }

    final residualResolution = _resolveEndOfTurnPhase(
      player: player,
      enemy: enemy,
      field: field,
    );
    player = residualResolution.player;
    enemy = residualResolution.enemy;
    field = residualResolution.field;
    statusEvents.addAll(residualResolution.statusEvents);
    fieldEvents.addAll(residualResolution.fieldEvents);
    player = player.withVolatileState(
      player.volatileState.clearedEndOfTurnFlags(),
    );
    enemy = enemy.withVolatileState(
      enemy.volatileState.clearedEndOfTurnFlags(),
    );

    return _ResolvedBattleTurn(
      player: player,
      playerReserve: playerReserve,
      enemy: enemy,
      enemyReserve: enemyReserve,
      field: field,
      rng: turnRng,
      turnResult: BattleTurnResult(
        playerAction: playerAction,
        enemyAction: enemyAction,
        executions: executions,
        statusEvents: statusEvents,
        volatileEvents: volatileEvents,
        fieldEvents: fieldEvents,
        switchEvents: switchEvents,
      ),
    );
  }

  List<_OrderedBattleAction> _resolveTurnOrder({
    required BattleAction playerAction,
    required BattleAction enemyAction,
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    // BE3 refuse d'introduire une fausse queue générique.
    //
    // Le moteur actuel n'a besoin que d'un ordre honnête pour deux actions :
    // - si ce sont deux `Fight`, on compare priorité puis vitesse effective ;
    // - sinon, on conserve l'ordre historique minimal, car les autres actions
    //   restent déjà gérées explicitement ailleurs (`Run`/`Capture`) ou ne
    //   sont pas de vrais chemins gameplay du moteur MVP.
    if (!_supportsOrderedResolution(playerAction) ||
        !_supportsOrderedResolution(enemyAction)) {
      return <_OrderedBattleAction>[
        _OrderedBattleAction(
          actor: _BattleActor.player,
          action: playerAction,
        ),
        _OrderedBattleAction(
          actor: _BattleActor.enemy,
          action: enemyAction,
        ),
      ];
    }

    final playerPriority = _priorityForResolvedAction(playerAction);
    final enemyPriority = _priorityForResolvedAction(enemyAction);
    if (playerPriority != enemyPriority) {
      return playerPriority > enemyPriority
          ? <_OrderedBattleAction>[
              _OrderedBattleAction(
                actor: _BattleActor.player,
                action: playerAction,
              ),
              _OrderedBattleAction(
                actor: _BattleActor.enemy,
                action: enemyAction,
              ),
            ]
          : <_OrderedBattleAction>[
              _OrderedBattleAction(
                actor: _BattleActor.enemy,
                action: enemyAction,
              ),
              _OrderedBattleAction(
                actor: _BattleActor.player,
                action: playerAction,
              ),
            ];
    }

    final playerSpeed = _resolveEffectiveSpeed(player);
    final enemySpeed = _resolveEffectiveSpeed(enemy);
    final trickRoomActive =
        field.isPseudoWeatherActive(BattlePseudoWeatherId.trickRoom);
    if (playerSpeed != enemySpeed) {
      final playerActsFirst =
          trickRoomActive ? playerSpeed < enemySpeed : playerSpeed > enemySpeed;
      return playerActsFirst
          ? <_OrderedBattleAction>[
              _OrderedBattleAction(
                actor: _BattleActor.player,
                action: playerAction,
              ),
              _OrderedBattleAction(
                actor: _BattleActor.enemy,
                action: enemyAction,
              ),
            ]
          : <_OrderedBattleAction>[
              _OrderedBattleAction(
                actor: _BattleActor.enemy,
                action: enemyAction,
              ),
              _OrderedBattleAction(
                actor: _BattleActor.player,
                action: playerAction,
              ),
            ];
    }

    // Tie-break volontairement déterministe et documenté :
    // - pas de PRNG pour résoudre les égalités d'ordre ;
    // - BE4 introduit bien un seam RNG pour le hit pipeline, mais pas pour ce
    //   tie-break ;
    // - pas de Fischer-Yates façon Showdown ;
    // - Trick Room n'inverse pas ce tie-break : seul l'ordre de vitesse est
    //   renversé ;
    // - on choisit "joueur avant ennemi" parce que c'est stable, testable,
    //   et cohérent avec l'historique du moteur jusqu'ici.
    return <_OrderedBattleAction>[
      _OrderedBattleAction(
        actor: _BattleActor.player,
        action: playerAction,
      ),
      _OrderedBattleAction(
        actor: _BattleActor.enemy,
        action: enemyAction,
      ),
    ];
  }

  bool _supportsOrderedResolution(BattleAction action) {
    return action is BattleActionFight ||
        action is BattleActionRecharge ||
        action is BattleActionSwitch;
  }

  int _priorityForResolvedAction(BattleAction action) {
    return switch (action) {
      // Politique BE10 explicitement simplifiée :
      // - un switch volontaire singles résout avant un `Fight` standard ;
      // - on n'ouvre pas pour autant une vraie taxonomie Showdown de priorités
      //   de switch, selfSwitch, forceSwitch, etc. ;
      // - cette constante locale suffit au sous-ensemble honnête du lot.
      BattleActionSwitch() => 6,
      BattleActionFight(:final move) => move.priority,
      BattleActionRecharge() => 0,
      _ => 0,
    };
  }

  /// Résout une exécution unique de move.
  ///
  /// M8 puis BE4 gardent ici un contrat volontairement petit et honnête :
  /// - dégâts standards via `power` ;
  /// - influence de `modifyStats` uniquement sur atk/def/spa/spd ;
  /// - moves de statut => dégâts 0 ;
  /// - hit check minimal et PP réels ;
  /// - BE6 ajoute un crit minimal réel pour les hits offensifs non immunisés ;
  /// - les changements de stats sont appliqués immédiatement après un hit ;
  /// - BE7 ajoute ensuite un petit sous-ensemble `applyStatus` et un blocage
  ///   d'action par paralysie, sans ouvrir un système de statuts complet.
  ///
  /// Cette application immédiate reste importante :
  /// - un `growl` du joueur peut déjà réduire une contre-attaque physique
  ///   ennemie plus tard dans le même tour s'il touche ;
  /// - mais un changement de `speed` ne réordonne jamais rétroactivement un
  ///   tour déjà ordonné au début de `_resolveTurn`.
  _ResolvedMoveExecution _resolveMoveExecution({
    required String attackerLabel,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleFieldState field,
    required String targetLabel,
    required BattleRng rng,
  }) {
    final pendingCharge = attacker.volatileState.pendingCharge;
    final isChargeRelease = pendingCharge != null &&
        pendingCharge.moveIndex == moveIndex &&
        pendingCharge.moveId == move.id;

    if (!isChargeRelease && !move.hasUsablePp) {
      throw StateError(
        'Le move "${move.name}" n’a plus de PP et ne peut pas être résolu honnêtement.',
      );
    }

    // Ordre de résolution BE8, volontairement borné et documenté :
    // 1. si le move est la libération d'une charge déjà stockée, on réutilise
    //    ce move sans repayer les PP et on nettoie immédiatement l'état de
    //    charge ;
    // 2. sinon, on suit BE4 : tentative => consommation de PP ;
    // 3. blocage d'action par paralysie si applicable ;
    // 4. si le move est un chargeThenStrike en premier tour, on entre en
    //    charge et on s'arrête là ;
    // 5. hit check ;
    // 6. application éventuelle de `protect` sur le lanceur, puis interception
    //    par une protection adverse déjà active ;
    // 7. dégâts / statuts / BE5 / BE6 / BE7 ;
    // 8. éventuelle recharge forcée si le move le demande.
    final attackerAfterChargeClear = isChargeRelease
        ? attacker.withVolatileState(
            attacker.volatileState.withPendingCharge(null),
          )
        : attacker;
    final attackerAfterPpUse = isChargeRelease
        ? attackerAfterChargeClear
        : attackerAfterChargeClear.withUpdatedMoveAt(
            moveIndex,
            move.withConsumedPp(),
          );
    final actionGate = _resolveMajorStatusActionGate(
      combatantLabel: attackerLabel,
      combatant: attackerAfterPpUse,
      rng: rng,
    );

    if (!actionGate.canAct) {
      return _ResolvedMoveExecution(
        attacker: attackerAfterPpUse,
        defender: defender,
        field: field,
        rng: actionGate.nextRng,
        execution: null,
        statusEvents: actionGate.statusEvents,
        volatileEvents: const <BattleVolatileEvent>[],
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    if (!isChargeRelease && move.chargeThenStrikeEffect != null) {
      final chargingAttacker = attackerAfterPpUse.withVolatileState(
        attackerAfterPpUse.volatileState.withPendingCharge(
          BattlePendingChargeState(
            moveIndex: moveIndex,
            moveId: move.id,
            chargeStateId: move.chargeThenStrikeEffect!.chargeStateId,
          ),
        ),
      );

      return _ResolvedMoveExecution(
        attacker: chargingAttacker,
        defender: defender,
        field: field,
        rng: actionGate.nextRng,
        execution: null,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: <BattleVolatileEvent>[
          BattleVolatileEvent.chargeStarted(
            actor: attackerLabel,
            sourceMoveId: move.id,
            chargeStateId: move.chargeThenStrikeEffect!.chargeStateId,
          ),
        ],
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final volatileEvents = <BattleVolatileEvent>[
      if (isChargeRelease)
        BattleVolatileEvent.chargeReleased(
          actor: attackerLabel,
          sourceMoveId: move.id,
          chargeStateId: pendingCharge.chargeStateId,
        ),
    ];

    final hitCheck = _resolveHitCheck(
      move: move,
      rng: actionGate.nextRng,
    );

    if (!hitCheck.didHit) {
      return _ResolvedMoveExecution(
        attacker: attackerAfterPpUse,
        defender: defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: BattleMoveExecution(
          attacker: attackerLabel,
          move: attackerAfterPpUse.moves[moveIndex],
          target: _resolveExecutionTargetLabel(
            move: move,
            attackerLabel: attackerLabel,
            opponentLabel: targetLabel,
          ),
          damage: 0,
          didHit: false,
          didCrit: false,
          criticalMultiplier: 1.0,
        ),
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(volatileEvents),
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final protectResolution = _resolveProtectInteractions(
      move: move,
      attackerLabel: attackerLabel,
      targetLabel: targetLabel,
      attacker: attackerAfterPpUse,
      defender: defender,
    );
    volatileEvents.addAll(protectResolution.volatileEvents);

    if (protectResolution.blockedByProtect) {
      return _ResolvedMoveExecution(
        attacker: protectResolution.attacker,
        defender: protectResolution.defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: BattleMoveExecution(
          attacker: attackerLabel,
          move: protectResolution.attacker.moves[moveIndex],
          target: _resolveExecutionTargetLabel(
            move: move,
            attackerLabel: attackerLabel,
            opponentLabel: targetLabel,
          ),
          damage: 0,
          didHit: true,
          didCrit: false,
          criticalMultiplier: 1.0,
        ),
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(volatileEvents),
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final damageResult = _computeMoveDamage(
      move: move,
      attacker: protectResolution.attacker,
      defender: protectResolution.defender,
      field: field,
      rng: hitCheck.nextRng,
    );

    // BE5 donne à l'immunité une sémantique simple et honnête pour le petit
    // sous-ensemble moteur actuellement supporté :
    // - le move a bien été tenté et a passé le hit check ;
    // - mais il n'a "aucun effet" sur la cible si le typing annule le hit ;
    // - on n'applique donc ni dégâts ni stage changes à partir d'un hit
    //   immunisé, ce qui évite des demi-effets mensongers.
    final updatedAttacker = damageResult.wasImmune
        ? protectResolution.attacker
        : protectResolution.attacker
            .withAppliedStageChanges(move.selfStatStageChanges);
    final defenderAfterHit = damageResult.wasImmune
        ? protectResolution.defender
        : protectResolution.defender
            .withDamage(damageResult.damage)
            .withAppliedStageChanges(move.targetStatStageChanges);
    final statusApplication = _resolveMajorStatusApplication(
      move: move,
      targetLabel: targetLabel,
      defender: defenderAfterHit,
      damageResult: damageResult,
      rng: damageResult.nextRng,
    );
    final fieldApplication = _resolveFieldApplication(
      move: move,
      field: field,
    );
    final rechargeFollowUp = _resolveRechargeFollowUp(
      move: move,
      attackerLabel: attackerLabel,
      attacker: updatedAttacker,
      damageResult: damageResult,
    );
    volatileEvents.addAll(rechargeFollowUp.volatileEvents);

    return _ResolvedMoveExecution(
      attacker: rechargeFollowUp.attacker,
      defender: statusApplication.defender,
      field: fieldApplication.field,
      rng: statusApplication.nextRng,
      execution: BattleMoveExecution(
        attacker: attackerLabel,
        move: rechargeFollowUp.attacker.moves[moveIndex],
        // BE1 ne laisse plus `target` se reperdre au moment de la trace
        // d'exécution :
        // - un move `self` doit apparaître comme ciblant le lanceur ;
        // - un move `opponent` garde la cible adverse résolue du tour ;
        // - `unspecified` reste le fallback de compatibilité des anciens call
        //   sites qui construisaient des moves battle pauvres à la main.
        target: _resolveExecutionTargetLabel(
          move: move,
          attackerLabel: attackerLabel,
          opponentLabel: targetLabel,
        ),
        damage: damageResult.damage,
        didHit: true,
        didCrit: damageResult.didCrit,
        criticalMultiplier: damageResult.criticalMultiplier,
        stabMultiplier: damageResult.stabMultiplier,
        typeEffectivenessMultiplier: damageResult.typeEffectivenessMultiplier,
      ),
      statusEvents: statusApplication.statusEvents,
      volatileEvents: List<BattleVolatileEvent>.unmodifiable(volatileEvents),
      fieldEvents: fieldApplication.fieldEvents,
    );
  }

  _ResolvedProtectInteractions _resolveProtectInteractions({
    required BattleMove move,
    required String attackerLabel,
    required String targetLabel,
    required BattleCombatant attacker,
    required BattleCombatant defender,
  }) {
    var updatedAttacker = attacker;
    var updatedDefender = defender;
    final volatileEvents = <BattleVolatileEvent>[];

    if (move.selfVolatileStatus == BattleVolatileStatusId.protect) {
      updatedAttacker = updatedAttacker.withVolatileState(
        updatedAttacker.volatileState.withProtectActive(true),
      );
      volatileEvents.add(
        BattleVolatileEvent.protectActivated(
          actor: attackerLabel,
          sourceMoveId: move.id,
        ),
      );
    }

    if (move.target != BattleMoveTarget.opponent ||
        !updatedDefender.volatileState.protectActive) {
      return _ResolvedProtectInteractions(
        attacker: updatedAttacker,
        defender: updatedDefender,
        blockedByProtect: false,
        volatileEvents: volatileEvents,
      );
    }

    if (move.breaksProtect) {
      updatedDefender = updatedDefender.withVolatileState(
        updatedDefender.volatileState.withProtectActive(false),
      );
      volatileEvents.add(
        BattleVolatileEvent.protectBroken(
          actor: attackerLabel,
          target: targetLabel,
          sourceMoveId: move.id,
        ),
      );
      return _ResolvedProtectInteractions(
        attacker: updatedAttacker,
        defender: updatedDefender,
        blockedByProtect: false,
        volatileEvents: volatileEvents,
      );
    }

    volatileEvents.add(
      BattleVolatileEvent.protectBlocked(
        actor: attackerLabel,
        target: targetLabel,
        sourceMoveId: move.id,
      ),
    );
    return _ResolvedProtectInteractions(
      attacker: updatedAttacker,
      defender: updatedDefender,
      blockedByProtect: true,
      volatileEvents: volatileEvents,
    );
  }

  _ResolvedRechargeFollowUp _resolveRechargeFollowUp({
    required BattleMove move,
    required String attackerLabel,
    required BattleCombatant attacker,
    required _ResolvedDamage damageResult,
  }) {
    // BE8 borne `requireRecharge` au sous-ensemble local réellement défendable :
    // - le move doit avoir atteint la phase "dégâts calculés" ;
    // - un miss ou un blocage par Protect sort déjà plus haut ;
    // - une immunité complète ne déclenche pas ce verrou, car aucun effet
    //   offensif réel n'a finalement été produit ;
    // - on ne prétend toujours pas reproduire tous les cas spéciaux Pokémon.
    if (!move.requiresRecharge ||
        move.resolvedCategory == BattleMoveCategory.status ||
        damageResult.wasImmune) {
      return _ResolvedRechargeFollowUp(
        attacker: attacker,
        volatileEvents: const <BattleVolatileEvent>[],
      );
    }

    return _ResolvedRechargeFollowUp(
      attacker: attacker.withVolatileState(
        attacker.volatileState.withMustRecharge(true),
      ),
      volatileEvents: <BattleVolatileEvent>[
        BattleVolatileEvent.rechargeRequired(
          actor: attackerLabel,
          sourceMoveId: move.id,
        ),
      ],
    );
  }

  _ResolvedRechargeAction _resolveRechargeAction({
    required String combatantLabel,
    required BattleCombatant combatant,
  }) {
    if (!combatant.volatileState.mustRecharge) {
      return _ResolvedRechargeAction(
        combatant: combatant,
        volatileEvents: const <BattleVolatileEvent>[],
      );
    }

    return _ResolvedRechargeAction(
      combatant: combatant.withVolatileState(
        combatant.volatileState.withMustRecharge(false),
      ),
      volatileEvents: <BattleVolatileEvent>[
        BattleVolatileEvent.rechargeTurnSpent(
          actor: combatantLabel,
        ),
      ],
    );
  }

  _ResolvedFieldApplication _resolveFieldApplication({
    required BattleMove move,
    required BattleFieldState field,
  }) {
    // BE9 garde un contrat de champ petit et explicite :
    // - un move ne pose au maximum qu'une météo OU un pseudoWeather ;
    // - aucune pile générique d'effets de champ ;
    // - aucune side/slot condition cachée derrière ce helper.
    if (move.weatherEffect == null && move.pseudoWeatherEffect == null) {
      return _ResolvedFieldApplication(
        field: field,
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    var updatedField = field;
    final fieldEvents = <BattleFieldEvent>[];

    if (move.weatherEffect case final weather?) {
      updatedField = updatedField.withWeather(
        BattleWeatherState(
          id: weather,
          remainingTurns: _supportedWeatherDurationTurns,
        ),
      );
      fieldEvents.add(
        BattleFieldEvent.weatherSet(
          weather: weather,
          sourceMoveId: move.id,
        ),
      );
    }

    if (move.pseudoWeatherEffect case final pseudoWeather?) {
      // Recadrage volontaire :
      // - BE9 ne crée pas un "room system" générique ;
      // - mais Trick Room réutilisé pendant qu'il est déjà actif doit rester
      //   honnête pour le sous-ensemble local ;
      // - on choisit donc un toggle simple : pose si absent, retrait si déjà
      //   actif, sans rouvrir d'autre mécanique de restart.
      if (updatedField.pseudoWeather?.id == pseudoWeather) {
        updatedField = updatedField.withPseudoWeather(null);
        fieldEvents.add(
          BattleFieldEvent.pseudoWeatherCleared(
            pseudoWeather: pseudoWeather,
            sourceMoveId: move.id,
          ),
        );
      } else {
        updatedField = updatedField.withPseudoWeather(
          BattlePseudoWeatherState(
            id: pseudoWeather,
            remainingTurns: _supportedPseudoWeatherDurationTurns,
          ),
        );
        fieldEvents.add(
          BattleFieldEvent.pseudoWeatherSet(
            pseudoWeather: pseudoWeather,
            sourceMoveId: move.id,
          ),
        );
      }
    }

    return _ResolvedFieldApplication(
      field: updatedField,
      fieldEvents: List<BattleFieldEvent>.unmodifiable(fieldEvents),
    );
  }

  _ResolvedActionGate _resolveMajorStatusActionGate({
    required String combatantLabel,
    required BattleCombatant combatant,
    required BattleRng rng,
  }) {
    final status = combatant.majorStatus;
    if (status?.id != BattleMajorStatusId.par) {
      return _ResolvedActionGate(
        canAct: true,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    // BE7 ouvre ici la plus petite sémantique honnête de paralysie :
    // - le move a déjà consommé 1 PP, car la tentative a bien eu lieu ;
    // - on bloque ensuite l'action avec une chance fixe de 25% ;
    // - on ne touche ni à l'ordre BE3 déjà figé, ni au hit check BE4.
    final roll = rng.nextChance(
      numerator: 1,
      denominator: 4,
    );
    if (!roll.didOccur) {
      return _ResolvedActionGate(
        canAct: true,
        nextRng: roll.next,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    return _ResolvedActionGate(
      canAct: false,
      nextRng: roll.next,
      statusEvents: <BattleStatusEvent>[
        BattleStatusEvent.preventedAction(
          target: combatantLabel,
          status: BattleMajorStatusId.par,
        ),
      ],
    );
  }

  _ResolvedStatusApplication _resolveMajorStatusApplication({
    required BattleMove move,
    required String targetLabel,
    required BattleCombatant defender,
    required _ResolvedDamage damageResult,
    required BattleRng rng,
  }) {
    final effect = move.majorStatusEffect;
    if (effect == null) {
      return _ResolvedStatusApplication(
        defender: defender,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    // BE7 ne crée pas encore de couche complète d'immunité de statut.
    // En revanche, pour un move qui inflige aussi des dégâts, on refuse
    // d'appliquer un statut si le hit a été entièrement annulé par une
    // immunité de type déjà supportée par BE5.
    if (damageResult.wasImmune &&
        move.resolvedCategory != BattleMoveCategory.status) {
      return _ResolvedStatusApplication(
        defender: defender,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    if (defender.majorStatus != null) {
      return _ResolvedStatusApplication(
        defender: defender,
        nextRng: rng,
        statusEvents: <BattleStatusEvent>[
          BattleStatusEvent.blockedExistingMajorStatus(
            target: targetLabel,
            status: effect.status,
            existingStatus: defender.majorStatus!.id,
            sourceMoveId: move.id,
          ),
        ],
      );
    }

    if (effect.chancePercent case final chance?) {
      final chanceRoll = rng.nextChance(
        numerator: chance,
        denominator: 100,
      );
      if (!chanceRoll.didOccur) {
        return _ResolvedStatusApplication(
          defender: defender,
          nextRng: chanceRoll.next,
          statusEvents: const <BattleStatusEvent>[],
        );
      }

      return _ResolvedStatusApplication(
        defender: defender.withMajorStatus(_majorStatusStateFor(effect.status)),
        nextRng: chanceRoll.next,
        statusEvents: <BattleStatusEvent>[
          BattleStatusEvent.applied(
            target: targetLabel,
            status: effect.status,
            sourceMoveId: move.id,
          ),
        ],
      );
    }

    return _ResolvedStatusApplication(
      defender: defender.withMajorStatus(_majorStatusStateFor(effect.status)),
      nextRng: rng,
      statusEvents: <BattleStatusEvent>[
        BattleStatusEvent.applied(
          target: targetLabel,
          status: effect.status,
          sourceMoveId: move.id,
        ),
      ],
    );
  }

  _ResolvedResidualPhase _resolveEndOfTurnPhase({
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    // BE9 restructure explicitement la fin de tour, sans créer un système
    // général de hooks :
    // 1. résiduels de statuts majeurs déjà ouverts en BE7 ;
    // 2. résiduels météo supportés en BE9 ;
    // 3. décrémentation puis expiration du champ ;
    // 4. l'outcome final est ensuite déterminé plus haut, à partir de l'état
    //    réellement obtenu après ces effets.
    final statusResidual = _applyEndOfTurnMajorStatusResiduals(
      player: player,
      enemy: enemy,
    );
    final weatherResidual = _applyEndOfTurnWeatherResiduals(
      player: statusResidual.player,
      enemy: statusResidual.enemy,
      field: field,
    );
    final fieldProgression =
        _advanceFieldStateAtEndOfTurn(weatherResidual.field);

    return _ResolvedResidualPhase(
      player: weatherResidual.player,
      enemy: weatherResidual.enemy,
      field: fieldProgression.field,
      statusEvents: statusResidual.statusEvents,
      fieldEvents: <BattleFieldEvent>[
        ...weatherResidual.fieldEvents,
        ...fieldProgression.fieldEvents,
      ],
    );
  }

  _ResolvedMajorStatusResiduals _applyEndOfTurnMajorStatusResiduals({
    required BattleCombatant player,
    required BattleCombatant enemy,
  }) {
    // BE7 reste volontairement local :
    // - pas de "hook system" de fin de tour ;
    // - pas de queue de résiduels générique ;
    // - juste la plus petite phase explicite pour les statuts majeurs
    //   supportés, après les actions et avant l'outcome final.
    final playerResidual = !player.isFainted
        ? _applyEndOfTurnResidualForCombatant(
            combatant: player,
            combatantLabel: 'player',
          )
        : const _ResolvedSingleResidual(
            combatant: null,
            statusEvents: <BattleStatusEvent>[],
          );
    final enemyResidual = !enemy.isFainted
        ? _applyEndOfTurnResidualForCombatant(
            combatant: enemy,
            combatantLabel: 'enemy',
          )
        : const _ResolvedSingleResidual(
            combatant: null,
            statusEvents: <BattleStatusEvent>[],
          );

    return _ResolvedMajorStatusResiduals(
      player: playerResidual.combatant ?? player,
      enemy: enemyResidual.combatant ?? enemy,
      statusEvents: <BattleStatusEvent>[
        ...playerResidual.statusEvents,
        ...enemyResidual.statusEvents,
      ],
    );
  }

  _ResolvedSingleResidual _applyEndOfTurnResidualForCombatant({
    required BattleCombatant combatant,
    required String combatantLabel,
  }) {
    final status = combatant.majorStatus;
    if (status == null || combatant.isFainted) {
      return _ResolvedSingleResidual(
        combatant: combatant,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    final residualDamage = switch (status.id) {
      BattleMajorStatusId.par => 0,
      BattleMajorStatusId.brn => _fractionalResidual(
          maxHp: combatant.maxHp,
          numerator: 1,
          denominator: 16,
        ),
      BattleMajorStatusId.psn => _fractionalResidual(
          maxHp: combatant.maxHp,
          numerator: 1,
          denominator: 8,
        ),
      BattleMajorStatusId.tox => _fractionalResidual(
          maxHp: combatant.maxHp,
          numerator: status.toxicCounter,
          denominator: 16,
        ),
    };

    if (residualDamage <= 0) {
      return _ResolvedSingleResidual(
        combatant: combatant,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    final damagedCombatant = combatant.withDamage(residualDamage);
    final nextCombatant =
        status.id == BattleMajorStatusId.tox && !damagedCombatant.isFainted
            ? damagedCombatant.withMajorStatus(status.incrementToxicCounter())
            : damagedCombatant;

    return _ResolvedSingleResidual(
      combatant: nextCombatant,
      statusEvents: <BattleStatusEvent>[
        BattleStatusEvent.residualDamage(
          target: combatantLabel,
          status: status.id,
          damage: residualDamage,
          toxicCounter:
              status.id == BattleMajorStatusId.tox ? status.toxicCounter : null,
        ),
      ],
    );
  }

  _ResolvedWeatherResiduals _applyEndOfTurnWeatherResiduals({
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    final weather = field.weather;
    if (weather == null || weather.id != BattleWeatherId.sandstorm) {
      return _ResolvedWeatherResiduals(
        player: player,
        enemy: enemy,
        field: field,
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final playerResidual = _applySandstormResidual(
      combatant: player,
      combatantLabel: 'player',
    );
    final enemyResidual = _applySandstormResidual(
      combatant: enemy,
      combatantLabel: 'enemy',
    );

    return _ResolvedWeatherResiduals(
      player: playerResidual.combatant,
      enemy: enemyResidual.combatant,
      field: field,
      fieldEvents: <BattleFieldEvent>[
        ...playerResidual.fieldEvents,
        ...enemyResidual.fieldEvents,
      ],
    );
  }

  _ResolvedSandstormResidual _applySandstormResidual({
    required BattleCombatant combatant,
    required String combatantLabel,
  }) {
    if (combatant.isFainted || _isImmuneToSandstormResidual(combatant)) {
      return _ResolvedSandstormResidual(
        combatant: combatant,
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final damage = _fractionalResidual(
      maxHp: combatant.maxHp,
      numerator: 1,
      denominator: 16,
    );
    final damagedCombatant = combatant.withDamage(damage);

    return _ResolvedSandstormResidual(
      combatant: damagedCombatant,
      fieldEvents: <BattleFieldEvent>[
        BattleFieldEvent.weatherResidualDamage(
          weather: BattleWeatherId.sandstorm,
          target: combatantLabel,
          damage: damage,
        ),
      ],
    );
  }

  bool _isImmuneToSandstormResidual(BattleCombatant combatant) {
    final typing = combatant.typing;
    if (typing == null) {
      return false;
    }
    return _sandstormResidualImmuneTypes.contains(typing.primaryType) ||
        (typing.secondaryType != null &&
            _sandstormResidualImmuneTypes.contains(typing.secondaryType));
  }

  _ResolvedFieldProgression _advanceFieldStateAtEndOfTurn(
      BattleFieldState field) {
    var updatedField = field;
    final fieldEvents = <BattleFieldEvent>[];

    if (field.weather case final weather?) {
      if (weather.remainingTurns <= 1) {
        updatedField = updatedField.withWeather(null);
        fieldEvents.add(
          BattleFieldEvent.weatherExpired(
            weather: weather.id,
          ),
        );
      } else {
        updatedField = updatedField.withWeather(weather.decrement());
      }
    }

    if (field.pseudoWeather case final pseudoWeather?) {
      if (pseudoWeather.remainingTurns <= 1) {
        updatedField = updatedField.withPseudoWeather(null);
        fieldEvents.add(
          BattleFieldEvent.pseudoWeatherExpired(
            pseudoWeather: pseudoWeather.id,
          ),
        );
      } else {
        updatedField =
            updatedField.withPseudoWeather(pseudoWeather.decrement());
      }
    }

    return _ResolvedFieldProgression(
      field: updatedField,
      fieldEvents: List<BattleFieldEvent>.unmodifiable(fieldEvents),
    );
  }

  _ResolvedHitCheck _resolveHitCheck({
    required BattleMove move,
    required BattleRng rng,
  }) {
    if (move.accuracy.isAlwaysHits || move.accuracy.value >= 100) {
      // Recadrage volontaire de BE4 :
      // - `alwaysHits` doit évidemment bypasser le hit check ;
      // - dans le moteur actuel, `percent(100)` est également déterministe,
      //   car nous n'avons encore ni accuracy stages, ni evasion, ni autres
      //   modificateurs de précision ;
      // - consommer du RNG sur 100% n'apporterait donc aucune vérité
      //   supplémentaire et compliquerait artificiellement les tests.
      return _ResolvedHitCheck(
        didHit: true,
        nextRng: rng,
      );
    }

    final roll = rng.nextPercentRoll();
    return _ResolvedHitCheck(
      didHit: roll.value <= move.accuracy.value,
      nextRng: roll.next,
    );
  }

  String _resolveExecutionTargetLabel({
    required BattleMove move,
    required String attackerLabel,
    required String opponentLabel,
  }) {
    return switch (move.target) {
      BattleMoveTarget.self => attackerLabel,
      BattleMoveTarget.field => 'field',
      BattleMoveTarget.opponent ||
      BattleMoveTarget.unspecified =>
        opponentLabel,
    };
  }

  /// Calcule les dégâts standards du moteur battle MVP enrichi.
  ///
  /// BE2 ne bascule toujours pas vers une formule Pokémon complète. Le but est
  /// maintenant plus honnête que l'ancien simple `damage = power` :
  /// - les dégâts standards reposent enfin sur un vrai snapshot de stats ;
  /// - les moves physiques utilisent `attack` vs `defense` ;
  /// - les moves spéciaux utilisent `specialAttack` vs `specialDefense` ;
  /// - les stages continuent à s'appliquer, mais sur ces vraies bases ;
  /// - `speed` influence désormais l'ordre d'action dans BE3, mais reste sans
  ///   rôle direct dans les dégâts.
  ///
  /// Frontière explicitement conservée :
  /// - pas d'accuracy/evasion stages ;
  /// - pas de règles Pokémon avancées de critique ;
  /// - le hit check BE4 vit en amont, avant d'entrer dans cette formule ;
  /// - BE6 ajoute seulement :
  ///   - une vraie chance de critique minimale ;
  ///   - un multiplicateur critique fixe ;
  ///   - aucune interaction avancée avec stages / items / abilities.
  _ResolvedDamage _computeMoveDamage({
    required BattleMove move,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleFieldState field,
    required BattleRng rng,
  }) {
    if (move.resolvedCategory == BattleMoveCategory.status || move.power <= 0) {
      return _ResolvedDamage(
        damage: 0,
        didCrit: false,
        criticalMultiplier: 1.0,
        stabMultiplier: 1.0,
        typeEffectivenessMultiplier: 1.0,
        nextRng: rng,
      );
    }

    final offensiveStatId = switch (move.resolvedCategory) {
      BattleMoveCategory.physical => BattleStatId.attack,
      BattleMoveCategory.special => BattleStatId.specialAttack,
      BattleMoveCategory.status => BattleStatId.attack,
    };
    final defensiveStatId = switch (move.resolvedCategory) {
      BattleMoveCategory.physical => BattleStatId.defense,
      BattleMoveCategory.special => BattleStatId.specialDefense,
      BattleMoveCategory.status => BattleStatId.defense,
    };

    // Ordre de calcul volontairement documenté :
    // 1. on part du snapshot de stats résolu par le runtime ;
    // 2. on applique les stages côté attaquant et défenseur ;
    // 3. on utilise ensuite une formule entière simple, Pokémon-like ;
    // 4. on garde enfin un minimum de 1 dégât pour tout move non-status
    //    ayant passé le bridge BE1.
    final effectiveAttack = _resolveEffectiveStat(
      baseStat: _statValueFor(attacker.stats, offensiveStatId),
      multiplier: attacker.statStages.multiplierFor(offensiveStatId),
    );
    final effectiveDefense = _resolveEffectiveStat(
      baseStat: _statValueFor(defender.stats, defensiveStatId),
      multiplier: defender.statStages.multiplierFor(defensiveStatId),
    );
    final safePower = move.power < 0 ? 0 : move.power;
    final levelFactor = ((2 * attacker.level) ~/ 5) + 2;
    final baseDamage =
        ((((levelFactor * safePower * effectiveAttack) ~/ effectiveDefense) ~/
                    50) +
                2)
            .toInt();

    // BE5 ajoute ici la plus petite consommation honnête du type :
    // - STAB simple à 1.5 ;
    // - type chart standard ;
    // - immunité à 0 ;
    // - double type multiplicatif ;
    // - toujours aucune abilities, aucun item, aucune Tera ;
    // - BE9 n'ajoute ensuite qu'un unique modificateur météo local :
    //   la pluie pour Eau/Feu.
    final stabMultiplier = BattleTypeChart.resolveStabMultiplier(
      moveType: move.type,
      attackerTyping: attacker.typing,
    );
    final typeEffectivenessMultiplier =
        BattleTypeChart.resolveEffectivenessMultiplier(
      moveType: move.type,
      defenderTyping: defender.typing,
    );

    if (typeEffectivenessMultiplier == 0.0) {
      return _ResolvedDamage(
        damage: 0,
        didCrit: false,
        criticalMultiplier: 1.0,
        stabMultiplier: stabMultiplier,
        typeEffectivenessMultiplier: typeEffectivenessMultiplier,
        nextRng: rng,
      );
    }

    // BE6 garde ici un ordre de résolution petit mais honnête :
    // 1. le hit check a déjà eu lieu en amont ;
    // 2. on vérifie ensuite l'immunité via le type chart ;
    // 3. seulement pour un hit offensif non immunisé, on résout un crit ;
    // 4. puis on applique STAB / efficacité de type et le clamp final.
    //
    // Ce choix évite de "dépenser" un tirage de crit sur un move qui n'aurait
    // de toute façon aucun effet. Pour le sous-ensemble actuel, c'est plus
    // honnête et reste mathématiquement neutre sur le résultat observable.
    final criticalHit = _resolveCriticalHit(
      move: move,
      rng: rng,
    );

    // Ordre de multiplication BE6 :
    // 1. baseDamage déterministe BE2 ;
    // 2. critique minimal BE6 ;
    // 3. malus de brûlure sur les moves physiques dans BE7 ;
    // 4. STAB ;
    // 5. effectiveness / résistance ;
    // 6. météo BE9 réellement supportée ;
    // 7. clamp minimum 1 si le move a touché et n'est pas immunisé.
    //
    // On reste volontairement dans un modèle simple à base de doubles +
    // `floor` plutôt que de singer tous les paliers internes de Showdown.
    final burnMultiplier =
        attacker.majorStatus?.id == BattleMajorStatusId.brn &&
                move.resolvedCategory == BattleMoveCategory.physical
            ? 0.5
            : 1.0;
    final weatherMultiplier = _resolveWeatherDamageMultiplier(
      move: move,
      field: field,
    );
    final scaledDamage = (baseDamage *
            criticalHit.multiplier *
            burnMultiplier *
            stabMultiplier *
            typeEffectivenessMultiplier *
            weatherMultiplier)
        .floor();
    final finalDamage = scaledDamage < 1 ? 1 : scaledDamage;

    return _ResolvedDamage(
      damage: finalDamage,
      didCrit: criticalHit.didCrit,
      criticalMultiplier: criticalHit.multiplier,
      stabMultiplier: stabMultiplier,
      typeEffectivenessMultiplier: typeEffectivenessMultiplier,
      nextRng: criticalHit.nextRng,
    );
  }

  double _resolveWeatherDamageMultiplier({
    required BattleMove move,
    required BattleFieldState field,
  }) {
    final weather = field.weather;
    if (weather == null || weather.id != BattleWeatherId.rain) {
      return 1.0;
    }

    return switch (move.type) {
      'water' => 1.5,
      'fire' => 0.5,
      _ => 1.0,
    };
  }

  _ResolvedCriticalHit _resolveCriticalHit({
    required BattleMove move,
    required BattleRng rng,
  }) {
    final chance = _critChanceForRatio(move.critRatio);
    if (chance.didOccurWithoutRng) {
      return _ResolvedCriticalHit(
        didCrit: true,
        multiplier: _criticalHitMultiplier,
        nextRng: rng,
      );
    }

    final roll = rng.nextChance(
      numerator: chance.numerator,
      denominator: chance.denominator,
    );
    return _ResolvedCriticalHit(
      didCrit: roll.didOccur,
      multiplier: roll.didOccur ? _criticalHitMultiplier : 1.0,
      nextRng: roll.next,
    );
  }

  _CritChance _critChanceForRatio(int critRatio) {
    // Table BE6 volontairement explicite :
    // - on suit une lecture moderne Pokémon-like des stages de crit ;
    // - `1` reste le ratio neutre du canonique projet ;
    // - on ne prétend pas ouvrir Focus Energy, Lucky Chant ou d'autres
    //   modificateurs indirects.
    //
    // Mini-fix BE6 puis BE6-mini-fix-2 :
    // - la première version neutralisait silencieusement `critRatio <= 0`
    //   dans la branche "ratio neutre" ;
    // - cela laissait une donnée battle invalide devenir "à peu près valide" ;
    // - le contrat public est désormais mieux verrouillé en amont, donc cette
    //   garde sert surtout de défense en profondeur pour un état incohérent
    //   qui réapparaîtrait à l'intérieur même de `map_battle` ;
    // - on préfère maintenant un `StateError` explicite, parce qu'à ce stade
    //   il s'agit d'un état battle incohérent, pas d'une simple option métier.
    if (critRatio < 1) {
      throw StateError(
        'Battle critical ratio must be >= 1; got $critRatio.',
      );
    }
    return switch (critRatio) {
      1 => const _CritChance(numerator: 1, denominator: 24),
      2 => const _CritChance(numerator: 1, denominator: 8),
      3 => const _CritChance(numerator: 1, denominator: 2),
      _ => const _CritChance.always(),
    };
  }

  int _statValueFor(BattleStatsSnapshot snapshot, BattleStatId stat) {
    return switch (stat) {
      BattleStatId.attack => snapshot.attack,
      BattleStatId.defense => snapshot.defense,
      BattleStatId.specialAttack => snapshot.specialAttack,
      BattleStatId.specialDefense => snapshot.specialDefense,
      BattleStatId.speed => snapshot.speed,
    };
  }

  int _resolveEffectiveSpeed(BattleCombatant combatant) {
    // L'ordre BE3 repose sur une vitesse effective déterministe :
    // - snapshot de speed résolu par le runtime ;
    // - multiplicateur de stages battle déjà présent ;
    // - BE7 y ajoute ensuite le malus simple de paralysie ;
    // - aucun RNG, aucune nature, aucun weather ;
    // - Trick Room BE9 n'altère pas cette valeur : il inverse ensuite la
    //   comparaison des deux vitesses au niveau du scheduler.
    final stagedSpeed = _resolveEffectiveStat(
      baseStat: combatant.stats.speed,
      multiplier: combatant.statStages.multiplierFor(BattleStatId.speed),
    );
    if (combatant.majorStatus?.id != BattleMajorStatusId.par) {
      return stagedSpeed;
    }

    final slowedSpeed = (stagedSpeed * 0.5).floor();
    return slowedSpeed < 1 ? 1 : slowedSpeed;
  }

  BattleMajorStatusState _majorStatusStateFor(BattleMajorStatusId status) {
    return switch (status) {
      BattleMajorStatusId.par => const BattleMajorStatusState.par(),
      BattleMajorStatusId.brn => const BattleMajorStatusState.brn(),
      BattleMajorStatusId.psn => const BattleMajorStatusState.psn(),
      BattleMajorStatusId.tox => const BattleMajorStatusState.tox(),
    };
  }

  int _fractionalResidual({
    required int maxHp,
    required int numerator,
    required int denominator,
  }) {
    final raw = (maxHp * numerator) ~/ denominator;
    return raw < 1 ? 1 : raw;
  }

  int _resolveEffectiveStat({
    required int baseStat,
    required double multiplier,
  }) {
    // BE2 garde ici une règle simple et déterministe :
    // - pas de fraction stockée ;
    // - pas de rounding ambigu ;
    // - on applique les stages par multiplication, puis `floor` ;
    // - on clamp enfin au minimum 1 pour ne jamais diviser par 0 ni produire
    //   une stat offensive/défensive absurde.
    final resolved = (baseStat * multiplier).floor();
    return resolved < 1 ? 1 : resolved;
  }

  /// Détermine le résultat final du combat.
  ///
  /// [player] - L'état final du joueur.
  /// [enemy] - L'état final de l'ennemi.
  ///
  /// Retourne null si le combat continue, ou un [BattleOutcome] si fini.
  ///
  /// Politique BE10, volontairement petite et explicite :
  /// - les remplacements automatiques honnêtes ont déjà été tentés avant
  ///   d'entrer ici ;
  /// - si l'ennemi actif est encore K.O. à ce stade, il n'a plus de réserve
  ///   valide et le joueur gagne ;
  /// - sinon, si le joueur actif est encore K.O. mais qu'une réserve valide
  ///   existe encore, le combat continue pour laisser place au switch forcé ;
  /// - sinon, si le joueur actif est encore K.O., il n'a plus de réserve
  ///   valide et le joueur perd ;
  /// - sinon le combat continue ;
  /// - en cas de double K.O. sans réserve des deux côtés, on conserve donc la
  ///   politique historique "enemy d'abord", ce qui produit une victoire.
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleOutcome? _determineOutcome(
    BattleCombatant player,
    List<BattleCombatant> playerReserve,
    BattleCombatant enemy,
    List<BattleCombatant> enemyReserve,
    BattleFieldState field,
  ) {
    // Vérifier la victoire (ennemi K.O.)
    if (enemy.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: player,
        playerReserve: playerReserve,
        enemy: enemy,
        enemyReserve: enemyReserve,
        field: field,
        currentTurn: null,
        outcome: null, // Sera set dans le BattleOutcome
      );
      return BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: finalState,
      );
    }

    // Vérifier la défaite (joueur K.O.)
    if (player.isFainted) {
      if (_firstUsableReserveIndex(playerReserve) != null) {
        return null;
      }
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: player,
        playerReserve: playerReserve,
        enemy: enemy,
        enemyReserve: enemyReserve,
        field: field,
        currentTurn: null,
        outcome: null,
      );
      return BattleOutcome(
        type: BattleOutcomeType.defeat,
        finalState: finalState,
      );
    }

    // Combat continue
    return null;
  }
}

enum _BattleActor {
  player,
  enemy,
}

class _OrderedBattleAction {
  const _OrderedBattleAction({
    required this.actor,
    required this.action,
  });

  final _BattleActor actor;
  final BattleAction action;
}

class _ResolvedBattleTurn {
  const _ResolvedBattleTurn({
    required this.player,
    required this.playerReserve,
    required this.enemy,
    required this.enemyReserve,
    required this.field,
    required this.rng,
    required this.turnResult,
  });

  final BattleCombatant player;
  final List<BattleCombatant> playerReserve;
  final BattleCombatant enemy;
  final List<BattleCombatant> enemyReserve;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleTurnResult turnResult;
}

class _ResolvedSwitchAction {
  const _ResolvedSwitchAction({
    required this.active,
    required this.reserve,
    required this.event,
  });

  final BattleCombatant active;
  final List<BattleCombatant> reserve;
  final BattleSwitchEvent event;
}

class _ResolvedPostTurnSwitchState {
  const _ResolvedPostTurnSwitchState({
    required this.player,
    required this.playerReserve,
    required this.enemy,
    required this.enemyReserve,
    required this.switchEvents,
  });

  final BattleCombatant player;
  final List<BattleCombatant> playerReserve;
  final BattleCombatant enemy;
  final List<BattleCombatant> enemyReserve;
  final List<BattleSwitchEvent> switchEvents;
}

class _ResolvedMoveExecution {
  const _ResolvedMoveExecution({
    required this.attacker,
    required this.defender,
    required this.field,
    required this.rng,
    required this.execution,
    required this.statusEvents,
    required this.volatileEvents,
    required this.fieldEvents,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleMoveExecution? execution;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedHitCheck {
  const _ResolvedHitCheck({
    required this.didHit,
    required this.nextRng,
  });

  final bool didHit;
  final BattleRng nextRng;
}

class _ResolvedActionGate {
  const _ResolvedActionGate({
    required this.canAct,
    required this.nextRng,
    required this.statusEvents,
  });

  final bool canAct;
  final BattleRng nextRng;
  final List<BattleStatusEvent> statusEvents;
}

class _ResolvedDamage {
  const _ResolvedDamage({
    required this.damage,
    required this.didCrit,
    required this.criticalMultiplier,
    required this.stabMultiplier,
    required this.typeEffectivenessMultiplier,
    required this.nextRng,
  });

  final int damage;
  final bool didCrit;
  final double criticalMultiplier;
  final double stabMultiplier;
  final double typeEffectivenessMultiplier;
  final BattleRng nextRng;

  bool get wasImmune => typeEffectivenessMultiplier == 0.0;
}

class _ResolvedCriticalHit {
  const _ResolvedCriticalHit({
    required this.didCrit,
    required this.multiplier,
    required this.nextRng,
  });

  final bool didCrit;
  final double multiplier;
  final BattleRng nextRng;
}

class _ResolvedStatusApplication {
  const _ResolvedStatusApplication({
    required this.defender,
    required this.nextRng,
    required this.statusEvents,
  });

  final BattleCombatant defender;
  final BattleRng nextRng;
  final List<BattleStatusEvent> statusEvents;
}

class _ResolvedProtectInteractions {
  const _ResolvedProtectInteractions({
    required this.attacker,
    required this.defender,
    required this.blockedByProtect,
    required this.volatileEvents,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final bool blockedByProtect;
  final List<BattleVolatileEvent> volatileEvents;
}

class _ResolvedRechargeFollowUp {
  const _ResolvedRechargeFollowUp({
    required this.attacker,
    required this.volatileEvents,
  });

  final BattleCombatant attacker;
  final List<BattleVolatileEvent> volatileEvents;
}

class _ResolvedRechargeAction {
  const _ResolvedRechargeAction({
    required this.combatant,
    required this.volatileEvents,
  });

  final BattleCombatant combatant;
  final List<BattleVolatileEvent> volatileEvents;
}

class _ResolvedResidualPhase {
  const _ResolvedResidualPhase({
    required this.player,
    required this.enemy,
    required this.field,
    required this.statusEvents,
    required this.fieldEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleFieldState field;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedMajorStatusResiduals {
  const _ResolvedMajorStatusResiduals({
    required this.player,
    required this.enemy,
    required this.statusEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final List<BattleStatusEvent> statusEvents;
}

class _ResolvedWeatherResiduals {
  const _ResolvedWeatherResiduals({
    required this.player,
    required this.enemy,
    required this.field,
    required this.fieldEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedSandstormResidual {
  const _ResolvedSandstormResidual({
    required this.combatant,
    required this.fieldEvents,
  });

  final BattleCombatant combatant;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedFieldProgression {
  const _ResolvedFieldProgression({
    required this.field,
    required this.fieldEvents,
  });

  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedFieldApplication {
  const _ResolvedFieldApplication({
    required this.field,
    required this.fieldEvents,
  });

  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedSingleResidual {
  const _ResolvedSingleResidual({
    required this.combatant,
    required this.statusEvents,
  });

  final BattleCombatant? combatant;
  final List<BattleStatusEvent> statusEvents;
}

class _CritChance {
  const _CritChance({
    required this.numerator,
    required this.denominator,
  }) : didOccurWithoutRng = false;

  const _CritChance.always()
      : numerator = 1,
        denominator = 1,
        didOccurWithoutRng = true;

  final int numerator;
  final int denominator;
  final bool didOccurWithoutRng;
}
