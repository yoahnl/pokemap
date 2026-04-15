import 'battle_setup.dart';
import 'battle_state.dart';
import 'battle_action.dart';
import 'battle_move.dart';
import 'battle_rng.dart';
import 'battle_resolution.dart';
import 'battle_stats.dart';

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
  // Le runtime peut maintenant fournir les PV courants réels du Pokémon actif.
  // On garde néanmoins un fallback explicite sur les PV max pour préserver les
  // anciens call sites/tests qui n'avaient pas besoin de cet état.
  final playerCurrentHp = _clampHp(
    currentHp: setup.playerPokemon.currentHp,
    maxHp: setup.playerPokemon.maxHp,
  );
  final enemyCurrentHp = _clampHp(
    currentHp: setup.enemyPokemon.currentHp,
    maxHp: setup.enemyPokemon.maxHp,
  );

  // Convertir les données de setup en combattants
  final player = BattleCombatant(
    speciesId: setup.playerPokemon.speciesId,
    level: setup.playerPokemon.level,
    currentHp: playerCurrentHp,
    maxHp: setup.playerPokemon.maxHp,
    stats: setup.playerPokemon.stats,
    abilityId: setup.playerPokemon.abilityId,
    // Le contrat battle enrichi doit survivre jusqu'à l'état de session :
    // - `type` et `target` restent surtout descriptifs à ce stade ;
    // - `priority` est déjà consommée depuis BE3 ;
    // - `accuracy` et `currentPp` deviennent réellement actives en BE4.
    moves: setup.playerPokemon.moves
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
            selfStatStageChanges: m.selfStatStageChanges,
            targetStatStageChanges: m.targetStatStageChanges,
          ),
        )
        .toList(),
  );

  final enemy = BattleCombatant(
    speciesId: setup.enemyPokemon.speciesId,
    level: setup.enemyPokemon.level,
    currentHp: enemyCurrentHp,
    maxHp: setup.enemyPokemon.maxHp,
    stats: setup.enemyPokemon.stats,
    abilityId: setup.enemyPokemon.abilityId,
    // Même règle pour l'adversaire : on ne reperd aucune dimension déjà jugée
    // honnête dans le contrat battle minimal.
    moves: setup.enemyPokemon.moves
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
            selfStatStageChanges: m.selfStatStageChanges,
            targetStatStageChanges: m.targetStatStageChanges,
          ),
        )
        .toList(),
  );

  // Créer l'état initial
  final initialState = BattleState(
    phase: BattlePhase.playerChoice,
    player: player,
    enemy: enemy,
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
    // Frontière métier défensive :
    // même si un call site contourne getAvailableChoices(), un combat trainer
    // ne doit jamais pouvoir produire ni "runaway", ni "captured".
    //
    // On rejette explicitement ce cas illégal au niveau du moteur, ce qui
    // évite de dépendre d'un filtre UI seulement.
    if (choice is PlayerBattleChoiceRun && setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceRun est interdit pendant un trainer battle.',
      );
    }
    if (choice is PlayerBattleChoiceCapture && setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pendant un trainer battle.',
      );
    }
    if (choice is PlayerBattleChoiceCapture && !setup.allowCapture) {
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
    if (choice is PlayerBattleChoiceRun) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: state.player,
        enemy: state.enemy,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          player: finalState.player,
          enemy: finalState.enemy,
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
    if (choice is PlayerBattleChoiceCapture) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: state.player,
        enemy: state.enemy,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          player: finalState.player,
          enemy: finalState.enemy,
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
    final playerAction = _choiceToAction(choice);

    // Phase 2: Déterminer l'action de l'ennemi (IA simple)
    final enemyAction = _chooseEnemyAction();

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
    // - pas de système de switch / residual / before-turn hooks ;
    // - juste le plus petit mécanisme honnête pour les deux actions de ce tour.
    final resolvedTurn = _resolveTurn(playerAction, enemyAction);

    // Phase 4: Récupérer l'état résultant après dégâts + éventuels boosts.
    final newPlayer = resolvedTurn.player;
    final newEnemy = resolvedTurn.enemy;

    // Phase 5: Vérifier si le combat est fini
    final outcome = _determineOutcome(newPlayer, newEnemy);

    // Phase 6: Créer le nouvel état
    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      player: newPlayer,
      enemy: newEnemy,
      currentTurn: outcome == null ? resolvedTurn.turnResult : null,
      outcome: outcome,
    );

    return BattleSession._(
      state: newState,
      setup: setup,
      rng: resolvedTurn.rng,
    );
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
    } else if (choice is PlayerBattleChoiceRun) {
      return const BattleActionRun();
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
  /// 4. `Run`/`Capture` restent hors pseudo-queue générique.
  ///
  /// Cette méthode est interne au moteur de combat.
  _ResolvedBattleTurn _resolveTurn(
      BattleAction playerAction, BattleAction enemyAction) {
    final executions = <BattleMoveExecution>[];
    var player = state.player;
    var enemy = state.enemy;
    var turnRng = rng;
    final orderedActions = _resolveTurnOrder(
      playerAction: playerAction,
      enemyAction: enemyAction,
      player: player,
      enemy: enemy,
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
              targetLabel: 'enemy',
              rng: turnRng,
            );
            player = resolution.attacker;
            enemy = resolution.defender;
            turnRng = resolution.rng;
            executions.add(resolution.execution);
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
              targetLabel: 'player',
              rng: turnRng,
            );
            enemy = resolution.attacker;
            player = resolution.defender;
            turnRng = resolution.rng;
            executions.add(resolution.execution);
          }
      }
    }

    return _ResolvedBattleTurn(
      player: player,
      enemy: enemy,
      rng: turnRng,
      turnResult: BattleTurnResult(
        playerAction: playerAction,
        enemyAction: enemyAction,
        executions: executions,
      ),
    );
  }

  List<_OrderedBattleAction> _resolveTurnOrder({
    required BattleAction playerAction,
    required BattleAction enemyAction,
    required BattleCombatant player,
    required BattleCombatant enemy,
  }) {
    // BE3 refuse d'introduire une fausse queue générique.
    //
    // Le moteur actuel n'a besoin que d'un ordre honnête pour deux actions :
    // - si ce sont deux `Fight`, on compare priorité puis vitesse effective ;
    // - sinon, on conserve l'ordre historique minimal, car les autres actions
    //   restent déjà gérées explicitement ailleurs (`Run`/`Capture`) ou ne
    //   sont pas de vrais chemins gameplay du moteur MVP.
    if (playerAction is! BattleActionFight ||
        enemyAction is! BattleActionFight) {
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

    final playerPriority = playerAction.move.priority;
    final enemyPriority = enemyAction.move.priority;
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
    if (playerSpeed != enemySpeed) {
      return playerSpeed > enemySpeed
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

  /// Résout une exécution unique de move.
  ///
  /// M8 puis BE4 gardent ici un contrat volontairement petit et honnête :
  /// - dégâts standards via `power` ;
  /// - influence de `modifyStats` uniquement sur atk/def/spa/spd ;
  /// - moves de statut => dégâts 0 ;
  /// - hit check minimal et PP réels ;
  /// - les changements de stats sont appliqués immédiatement après un hit.
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
    required String targetLabel,
    required BattleRng rng,
  }) {
    if (!move.hasUsablePp) {
      throw StateError(
        'Le move "${move.name}" n’a plus de PP et ne peut pas être résolu honnêtement.',
      );
    }

    // BE4 introduit ici le plus petit hit pipeline honnête :
    // 1. on valide que le move est encore utilisable ;
    // 2. on consomme 1 PP immédiatement sur la tentative ;
    // 3. on résout ensuite le hit check ;
    // 4. un miss n'applique ni dégâts ni stage changes ;
    // 5. un hit suit le chemin déjà supporté.
    final attackerAfterPpUse = attacker.withUpdatedMoveAt(
      moveIndex,
      move.withConsumedPp(),
    );
    final hitCheck = _resolveHitCheck(
      move: move,
      rng: rng,
    );

    if (!hitCheck.didHit) {
      return _ResolvedMoveExecution(
        attacker: attackerAfterPpUse,
        defender: defender,
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
        ),
      );
    }

    final damage = _computeMoveDamage(
      move: move,
      attacker: attackerAfterPpUse,
      defender: defender,
    );

    final updatedAttacker =
        attackerAfterPpUse.withAppliedStageChanges(move.selfStatStageChanges);
    final updatedDefender = defender
        .withDamage(damage)
        .withAppliedStageChanges(move.targetStatStageChanges);

    return _ResolvedMoveExecution(
      attacker: updatedAttacker,
      defender: updatedDefender,
      rng: hitCheck.nextRng,
      execution: BattleMoveExecution(
        attacker: attackerLabel,
        move: updatedAttacker.moves[moveIndex],
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
        damage: damage,
        didHit: true,
      ),
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
  /// - pas de type chart ;
  /// - pas de critiques ;
  /// - pas d'accuracy/evasion stages ;
  /// - le hit check BE4 vit en amont, avant d'entrer dans cette formule.
  int _computeMoveDamage({
    required BattleMove move,
    required BattleCombatant attacker,
    required BattleCombatant defender,
  }) {
    if (move.resolvedCategory == BattleMoveCategory.status || move.power <= 0) {
      return 0;
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
    final scaledDamage =
        ((((levelFactor * safePower * effectiveAttack) ~/ effectiveDefense) ~/
                    50) +
                2)
            .toInt();
    return scaledDamage < 1 ? 1 : scaledDamage;
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
    // - aucun RNG, aucune nature, aucun weather, aucun trick room.
    return _resolveEffectiveStat(
      baseStat: combatant.stats.speed,
      multiplier: combatant.statStages.multiplierFor(BattleStatId.speed),
    );
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
  /// Règles :
  /// - Si enemy.isFainted → victoire
  /// - Si player.isFainted → défaite
  /// - Sinon → combat continue (null)
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleOutcome? _determineOutcome(
      BattleCombatant player, BattleCombatant enemy) {
    // Vérifier la victoire (ennemi K.O.)
    if (enemy.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: player,
        enemy: enemy,
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
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: player,
        enemy: enemy,
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
    required this.enemy,
    required this.rng,
    required this.turnResult,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleRng rng;
  final BattleTurnResult turnResult;
}

class _ResolvedMoveExecution {
  const _ResolvedMoveExecution({
    required this.attacker,
    required this.defender,
    required this.rng,
    required this.execution,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final BattleRng rng;
  final BattleMoveExecution execution;
}

class _ResolvedHitCheck {
  const _ResolvedHitCheck({
    required this.didHit,
    required this.nextRng,
  });

  final bool didHit;
  final BattleRng nextRng;
}
