# Phase R1 — Lot 11 — Trainer Run Guard Mini-Fix Report

## 1. Résumé exécutif honnête

Le bug métier était réel : après le lot 11, `Run` produisait bien un vrai `BattleOutcomeType.runaway`, mais le moteur battle continuait à proposer `Run` dans tous les combats. Cela rendait possible une fuite en combat trainer, ce qui est incohérent produit et inacceptable.

Le correctif livré est strictement local à `map_battle` :
- `Run` reste disponible en combat sauvage ;
- `Run` n’est plus proposé en combat trainer ;
- un `PlayerBattleChoiceRun()` forcé sur un combat trainer est rejeté explicitement au niveau du moteur ;
- aucune fuite trainer n’est donc possible, ni via l’UI, ni via un appel direct au moteur.

Je n’ai pas rouvert les lots 12+.
Je n’ai pas touché au runtime de prod.
Je n’ai pas introduit de nouvelle architecture.

## 2. État initial audité réel

Audit du code réel confirmé :

- dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart), `BattleSession.getAvailableChoices()` ajoutait toujours `PlayerBattleChoiceRun()`, sans distinguer sauvage/trainer ;
- dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart), `BattleSession.applyChoice(PlayerBattleChoiceRun())` produisait désormais un vrai `BattleOutcomeType.runaway` ;
- aucune garde métier dans le moteur n’empêchait qu’un combat trainer termine par fuite si un call site forçait ce choix.

Le bug était donc confirmé directement au niveau de la frontière métier minimale, sans avoir besoin d’élargir au runtime.

## 3. Problème exact confirmé

Le problème exact était :

- `getAvailableChoices()` exposait `Run` en trainer battle ;
- `applyChoice(PlayerBattleChoiceRun())` produisait un outcome `runaway` même en trainer battle ;
- le moteur n’imposait donc aucune règle métier empêchant la fuite trainer.

Conséquence :
- fuite possible en combat trainer ;
- régression métier lot 11.

## 4. Cause racine

La cause racine est locale et simple :

- le lot 11 a rendu `Run` réellement terminal pour fermer la boucle sauvage ;
- mais cette évolution n’a pas été bornée par `setup.isTrainerBattle` ;
- le moteur battle est donc resté trop permissif.

Ce n’était pas un problème de runtime, d’overlay ou de host en premier lieu.
Le moteur devait rester la frontière de sécurité minimale.

## 5. Décisions retenues / rejetées

### Retenues

- Filtrer `Run` dans `getAvailableChoices()` quand `setup.isTrainerBattle == true`.
- Rejeter explicitement `PlayerBattleChoiceRun()` dans `applyChoice()` quand `setup.isTrainerBattle == true`.
- Couvrir le contrat avec des tests battle ciblés.
- Relancer une non-régression runtime sauvage pour s’assurer que la fuite sauvage reste intacte.

### Rejetées

- Ajouter un filtre seulement côté overlay/runtime.
- Convertir silencieusement `Run` trainer en autre action.
- Laisser le moteur permissif et compter sur l’UI.
- Toucher au runtime ou au host sans nécessité démontrée.
- Ouvrir les lots 12+.

## 6. Périmètre inclus / exclu

### Inclus

- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/test/battle_session_test.dart`
- `packages/map_battle/test/battle_session_flow_test.dart`
- validations battle ciblées
- non-régression runtime sauvage ciblée

### Exclu

- `map_runtime` prod
- host d’exemple
- capture / seen-caught / rewards / bag / switch
- lots 12+

## 7. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés

- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/test/battle_session_test.dart`
- `packages/map_battle/test/battle_session_flow_test.dart`

### Créés

- `reports/phase-r1-lot-11-trainer-run-guard-report.md`

### Supprimés

- aucun

## 8. Justification fichier par fichier

### `packages/map_battle/lib/src/battle_session.dart`

Fichier central du correctif.

Modifications :
- `getAvailableChoices()` n’ajoute plus `Run` en combat trainer ;
- `applyChoice()` rejette explicitement `Run` en combat trainer via `StateError`.

Pourquoi ici :
- c’est la vraie frontière métier minimale ;
- cela protège même si un call site UI/runtime se trompe ;
- cela garde le comportement sauvage intact.

### `packages/map_battle/test/battle_session_test.dart`

Ajout des preuves sur l’API visible du moteur :
- wild : `Run` est bien présent ;
- trainer : `Run` n’est plus proposé.

### `packages/map_battle/test/battle_session_flow_test.dart`

Ajout de la preuve défensive :
- un `PlayerBattleChoiceRun()` forcé en trainer battle lève une erreur ;
- la session initiale n’est pas transformée en outcome `runaway`.

## 9. Commandes réellement exécutées

### Audit

```bash
git status --short
git diff --stat
sed -n '1,260p' packages/map_battle/lib/src/battle_session.dart
sed -n '1,260p' packages/map_battle/test/battle_session_flow_test.dart
sed -n '1,260p' packages/map_battle/test/battle_flow_integration_test.dart
sed -n '1,260p' packages/map_battle/test/battle_session_test.dart
rg -n "getAvailableChoices\\(|PlayerBattleChoiceRun|isRunaway" packages/map_battle/test -g'*.dart'
git diff -- packages/map_battle/lib/src/battle_session.dart packages/map_battle/test/battle_session_test.dart packages/map_battle/test/battle_session_flow_test.dart
cat packages/map_battle/lib/src/battle_session.dart
cat packages/map_battle/test/battle_session_test.dart
cat packages/map_battle/test/battle_session_flow_test.dart
```

### Format

```bash
/opt/homebrew/bin/dart format packages/map_battle/lib/src/battle_session.dart packages/map_battle/test/battle_session_test.dart packages/map_battle/test/battle_session_flow_test.dart
```

### Analyze

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
/opt/homebrew/bin/dart analyze lib/src/battle_session.dart test/battle_session_test.dart test/battle_session_flow_test.dart
```

### Tests

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
/opt/homebrew/bin/dart test test/battle_session_test.dart test/battle_session_flow_test.dart test/battle_flow_integration_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_runtime
/opt/homebrew/bin/flutter test test/wild_battle_end_to_end_flow_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart
```

## 10. Résultats réels de format / analyze / tests

### Format

Résultat réel :

```text
Formatted 3 files (0 changed) in 0.02 seconds.
```

### Analyze

Résultat réel :

```text
Analyzing battle_session.dart, battle_session_test.dart, battle_session_flow_test.dart...
No issues found!
```

### Tests `map_battle`

Résultat réel :

```text
00:00 +28: All tests passed!
```

### Non-régression runtime sauvage

Résultat réel :

```text
00:02 +10: All tests passed!
```

## 11. Incidents rencontrés

Aucun incident technique notable sur cette passe.

Le correctif est resté strictement local et n’a pas nécessité d’élargir au runtime.

## 12. État git utile

État git utile au moment du mini-fix, avant prise en compte du report lui-même :

```text
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/test/battle_session_flow_test.dart
 M packages/map_battle/test/battle_session_test.dart
```

Après création du report, un fichier untracked supplémentaire apparaît dans `reports/`.

## 13. Checklist finale

- [x] `Run` est toujours disponible en wild battle
- [x] `Run` termine toujours un wild battle avec `BattleOutcomeType.runaway`
- [x] `Run` n’est plus proposé en trainer battle
- [x] un `PlayerBattleChoiceRun()` forcé sur trainer battle ne produit jamais `runaway`
- [x] je n’ai pas cassé les tests existants utiles
- [x] je n’ai pas ouvert les lots 12+
- [x] je n’ai créé aucune stack parallèle
- [x] je n’ai fait aucune écriture git interdite
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] mon rapport final contient le contenu complet de tous les fichiers touchés

## 14. Conclusion honnête

Le bug est corrigé proprement.

Le moteur battle impose maintenant le bon contrat métier :
- sauvage : fuite autorisée et réelle ;
- trainer : fuite non proposée et refusée défensivement si forcée.

Je n’ai pas rouvert d’autre sujet.
Je me suis arrêté au bon périmètre.

## 15. Annexe — contenu complet des fichiers modifiés / créés / supprimés

Le report lui-même est exclu de sa propre annexe pour éviter la récursion infinie.

### 15.1. `packages/map_battle/lib/src/battle_session.dart`

```dart
import 'battle_setup.dart';
import 'battle_state.dart';
import 'battle_action.dart';
import 'battle_move.dart';
import 'battle_resolution.dart';

/// Crée une nouvelle session de combat.
///
/// [setup] - La configuration initiale du combat.
///
/// Retourne une nouvelle [BattleSession] avec l'état initial.
/// C'est le point d'entrée principal du moteur de combat.
BattleSession createBattleSession(BattleSetup setup) {
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
    moves: setup.playerPokemon.moves
        .map((m) => BattleMove(id: m.id, name: m.name, power: m.power))
        .toList(),
  );

  final enemy = BattleCombatant(
    speciesId: setup.enemyPokemon.speciesId,
    level: setup.enemyPokemon.level,
    currentHp: enemyCurrentHp,
    maxHp: setup.enemyPokemon.maxHp,
    moves: setup.enemyPokemon.moves
        .map((m) => BattleMove(id: m.id, name: m.name, power: m.power))
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
  });

  /// L'état actuel du combat.
  final BattleState state;

  /// La configuration initiale du combat.
  ///
  /// Gardée pour accéder aux métadonnées (trainerId, etc.).
  final BattleSetup setup;

  /// Récupère les choix disponibles pour le joueur.
  ///
  /// À appeler quand [state.phase] == [BattlePhase.playerChoice].
  ///
  /// Retourne une liste de choix :
  /// - [PlayerBattleChoiceFight] pour chaque attaque disponible (0-3)
  /// - [PlayerBattleChoiceRun] pour fuir, uniquement en combat sauvage
  ///
  /// Exemple d'usage :
  /// ```dart
  /// final choices = session.getAvailableChoices();
  /// // wild: [Fight(0), Fight(1), Fight(2), Fight(3), Run()]
  /// // trainer: [Fight(0), Fight(1), Fight(2), Fight(3)]
  /// ```
  List<PlayerBattleChoice> getAvailableChoices() {
    // Créer un choix Fight pour chaque attaque disponible
    final fightChoices = <PlayerBattleChoice>[];
    for (var i = 0; i < state.player.moves.length; i++) {
      fightChoices.add(PlayerBattleChoiceFight(i));
    }

    // Invariant métier important :
    // - la fuite est autorisée en sauvage pour garder une vraie boucle jouable ;
    // - la fuite n'est jamais un choix légitime en trainer battle.
    //
    // On filtre donc le choix ici pour que l'UI/runtime n'ait pas de bouton
    // Run à afficher en trainer battle.
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
    // ne doit jamais pouvoir produire un outcome "runaway".
    //
    // On rejette explicitement ce cas illégal au niveau du moteur, ce qui
    // évite de dépendre d'un filtre UI seulement.
    if (choice is PlayerBattleChoiceRun && setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceRun est interdit pendant un trainer battle.',
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
    // - aucun système lot 12+ (capture, récompenses, sac, switch) n'est ouvert ;
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
      );
    }

    // Phase 1: Convertir le choix en action
    final playerAction = _choiceToAction(choice);

    // Phase 2: Déterminer l'action de l'ennemi (IA simple)
    final enemyAction = _chooseEnemyAction();

    // Phase 3: Résoudre le tour
    final turnResult = _resolveTurn(playerAction, enemyAction);

    // Phase 4: Appliquer les dégâts et vérifier l'état
    final newPlayer = _applyDamageToCombatant(
      state.player,
      turnResult.executions.where((e) => e.target == 'player'),
    );
    final newEnemy = _applyDamageToCombatant(
      state.enemy,
      turnResult.executions.where((e) => e.target == 'enemy'),
    );

    // Phase 5: Vérifier si le combat est fini
    final outcome = _determineOutcome(newPlayer, newEnemy);

    // Phase 6: Créer le nouvel état
    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      player: newPlayer,
      enemy: newEnemy,
      currentTurn: outcome == null ? turnResult : null,
      outcome: outcome,
    );

    return BattleSession._(
      state: newState,
      setup: setup,
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
        return BattleActionFight(state.player.moves[choice.moveIndex]);
      }
      // Fallback: première attaque si index invalide
      return BattleActionFight(state.player.moves.first);
    } else if (choice is PlayerBattleChoiceRun) {
      return const BattleActionRun();
    }
    // Fallback: première attaque
    return BattleActionFight(state.player.moves.first);
  }

  /// Détermine l'action de l'ennemi (IA simple).
  ///
  /// Pour ce MVP, l'IA est très simple :
  /// - Si l'ennemi peut attaquer, il attaque avec une attaque aléatoire (déterministe : première)
  /// - L'ennemi ne fuit jamais
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleAction _chooseEnemyAction() {
    // IA simple : toujours utiliser la première attaque disponible
    // (pour le déterminisme, pas de random)
    if (state.enemy.moves.isNotEmpty && !state.enemy.isFainted) {
      return BattleActionFight(state.enemy.moves.first);
    }
    // Si aucune attaque, ne rien faire (cas edge)
    return const BattleActionRun();
  }

  /// Résout un tour de combat.
  ///
  /// [playerAction] - L'action du joueur.
  /// [enemyAction] - L'action de l'ennemi.
  ///
  /// Retourne un [BattleTurnResult] avec les exécutions.
  ///
  /// Ordre de résolution (déterministe, simple) :
  /// 1. Joueur exécute son attaque (si pas une fuite)
  /// 2. Ennemi exécute son attaque (si pas une fuite et encore en vie)
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleTurnResult _resolveTurn(
      BattleAction playerAction, BattleAction enemyAction) {
    final executions = <BattleMoveExecution>[];

    // 1. Joueur exécute son attaque
    if (playerAction is BattleActionFight && !state.enemy.isFainted) {
      final damage = playerAction.move.power;
      executions.add(BattleMoveExecution(
        attacker: 'player',
        move: playerAction.move,
        target: 'enemy',
        damage: damage,
      ));
    }

    // 2. Ennemi exécute son attaque (seulement si encore en vie après l'attaque du joueur)
    if (enemyAction is BattleActionFight) {
      // Vérifier si l'ennemi est encore en vie après l'attaque du joueur
      var enemyHpAfterPlayerAttack = state.enemy.currentHp;
      if (executions.isNotEmpty) {
        enemyHpAfterPlayerAttack -= executions.first.damage;
      }

      if (enemyHpAfterPlayerAttack > 0) {
        final damage = enemyAction.move.power;
        executions.add(BattleMoveExecution(
          attacker: 'enemy',
          move: enemyAction.move,
          target: 'player',
          damage: damage,
        ));
      }
    }

    return BattleTurnResult(
      playerAction: playerAction,
      enemyAction: enemyAction,
      executions: executions,
    );
  }

  /// Applique les dégâts à un combattant.
  ///
  /// [combatant] - Le combattant à modifier.
  /// [executions] - Les exécutions qui ciblent ce combattant.
  ///
  /// Retourne un nouveau combattant avec les PV mis à jour.
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleCombatant _applyDamageToCombatant(
    BattleCombatant combatant,
    Iterable<BattleMoveExecution> executions,
  ) {
    var newCombatant = combatant;
    for (final execution in executions) {
      newCombatant = newCombatant.withDamage(execution.damage);
    }
    return newCombatant;
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
```

### 15.2. `packages/map_battle/test/battle_session_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BattleSession', () {
    // Helper pour créer un setup de test
    BattleSetup createTestSetup({
      bool isTrainerBattle = false,
      String? trainerId,
    }) {
      return BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
            BattleMoveData(id: 'scratch', name: 'Griffe', power: 4),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: isTrainerBattle,
        trainerId: trainerId,
      );
    }

    test('createBattleSession creates session with playerChoice phase', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      expect(session.state.phase, equals(BattlePhase.playerChoice));
      expect(session.state.player.currentHp, equals(20)); // PV pleins
      expect(session.state.enemy.currentHp, equals(25)); // PV pleins
      expect(session.state.outcome, isNull);
      expect(session.state.isFinished, isFalse);
    });

    test('createBattleSession creates trainer battle with trainerId', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(setup);

      expect(session.setup.isTrainerBattle, isTrue);
      expect(session.setup.trainerId, equals('gym_leader_1'));
    });

    test('createBattleSession respects currentHp when provided by runtime', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          currentHp: 7,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          currentHp: 11,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);

      expect(session.state.player.currentHp, equals(7));
      expect(session.state.enemy.currentHp, equals(11));
    });

    test('getAvailableChoices returns fight choices + run in wild battle', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      // 2 attaques + 1 fuite
      expect(choices.length, equals(3));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices[2], isA<PlayerBattleChoiceRun>());
    });

    test('getAvailableChoices does not expose run in trainer battle', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.length, equals(2));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices.whereType<PlayerBattleChoiceRun>(), isEmpty);
    });

    test('applyChoice with fight resolves turn and damages enemy', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      // Joueur utilise la première attaque (power=5)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // L'ennemi devrait avoir pris 5 dégâts
      expect(newSession.state.enemy.currentHp, equals(20)); // 25 - 5 = 20
      expect(newSession.state.currentTurn, isNotNull);
      expect(newSession.state.currentTurn!.executions.length, greaterThan(0));
    });

    test('applyChoice with fight resolves turn and damages player', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      // Joueur utilise la première attaque
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Le joueur devrait avoir pris des dégâts de la contre-attaque (power=5)
      expect(newSession.state.player.currentHp, equals(15)); // 20 - 5 = 15
    });

    test('KO enemy results in victory', () {
      // Créer un ennemi avec peu de PV
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: const [
            BattleMoveData(id: 'mega-punch', name: 'Mega-Poing', power: 25),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // PV max = 20, donc 1 hit KO
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      // Joueur utilise Mega-Punch (power=25, one-shot)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome, isNotNull);
      expect(newSession.state.outcome!.isVictory, isTrue);
      expect(newSession.state.enemy.isFainted, isTrue);
    });

    test('KO player results in defeat', () {
      // Créer un joueur avec peu de PV face à un ennemi puissant
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 5, // Très peu de PV
          moves: const [
            BattleMoveData(id: 'growl', name: 'Rugissement', power: 0),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          moves: const [
            BattleMoveData(id: 'psychic', name: 'Psyko', power: 10),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      // Joueur utilise Growl (power=0, ne fait rien)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome, isNotNull);
      expect(newSession.state.outcome!.isDefeat, isTrue);
      expect(newSession.state.player.isFainted, isTrue);
    });

    test('trainer battle victory outcome is compatible with marking', () {
      // Créer un setup où le joueur gagne en 1 coup
      final oneHitSetup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          moves: const [
            BattleMoveData(id: 'psystrike', name: 'Frapp Psy', power: 50),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // One-shot
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(oneHitSetup);

      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome!.isVictory, isTrue);
      expect(newSession.setup.trainerId, equals('gym_leader_1'));
      // Le runtime peut maintenant marquer : 'trainer_defeated:gym_leader_1'
    });

    test('applyChoice returns new session (immutable)', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Vérifier que c'est une nouvelle instance
      expect(identical(session, newSession), isFalse);
      expect(identical(session.state, newSession.state), isFalse);
    });

    test('multiple turns until one combatant faints', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 30,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 10),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 30,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 10),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      var session = createBattleSession(setup);

      // Tour 1
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isFalse); // Les deux sont encore vivants
      expect(session.state.player.currentHp, equals(20)); // 30 - 10
      expect(session.state.enemy.currentHp, equals(20)); // 30 - 10

      // Tour 2
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isFalse);
      expect(session.state.player.currentHp, equals(10)); // 20 - 10
      expect(session.state.enemy.currentHp, equals(10)); // 20 - 10

      // Tour 3
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isTrue); // Les deux sont à 0 PV
      // Le joueur joue en premier, donc l'ennemi meurt en premier → victoire
      expect(session.state.outcome!.isVictory, isTrue);
    });
  });
}
```

### 15.3. `packages/map_battle/test/battle_session_flow_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BattleSession flow hardening', () {
    // Helper pour créer une session de test simple
    BattleSession createTestSession({
      int playerHp = 20,
      int enemyHp = 20,
      int playerMovePower = 5,
      int enemyMovePower = 5,
    }) {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: playerHp,
          moves: [
            BattleMoveData(
                id: 'tackle', name: 'Charge', power: playerMovePower),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: enemyHp,
          moves: [
            BattleMoveData(id: 'tackle', name: 'Charge', power: enemyMovePower),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      return createBattleSession(setup);
    }

    test('applyChoice processes only one choice at a time (anti-spam)', () {
      final session = createTestSession();

      // Premier choix
      final sessionAfterChoice1 =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      // La session devrait avoir évolué (PV changés, tour résolu)
      expect(sessionAfterChoice1.state.currentTurn, isNotNull);
      expect(sessionAfterChoice1.state.currentTurn!.executions.length,
          greaterThan(0));

      // Deuxième choix immédiat (simule spam)
      final sessionAfterChoice2 =
          sessionAfterChoice1.applyChoice(const PlayerBattleChoiceFight(0));

      // Le deuxième choix devrait aussi être traité normalement
      // (le vrai anti-spam est dans le runtime, pas dans la logique métier)
      expect(sessionAfterChoice2.state.currentTurn, isNotNull);
    });

    test('battle finishes after enemy faints', () {
      // Créer un ennemi avec très peu de PV
      final session = createTestSession(enemyHp: 3, playerMovePower: 10);

      // Premier choix du joueur
      final sessionAfterChoice =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      // L'ennemi devrait être K.O.
      expect(sessionAfterChoice.state.enemy.isFainted, isTrue);
      expect(sessionAfterChoice.state.isFinished, isTrue);
      expect(sessionAfterChoice.state.outcome, isNotNull);
      expect(sessionAfterChoice.state.outcome!.isVictory, isTrue);
    });

    test('battle finishes after player faints', () {
      // Créer un joueur avec très peu de PV et un ennemi puissant
      final session = createTestSession(playerHp: 3, enemyMovePower: 10);

      // Premier choix du joueur
      final sessionAfterChoice =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      // Le joueur devrait être K.O.
      expect(sessionAfterChoice.state.player.isFainted, isTrue);
      expect(sessionAfterChoice.state.isFinished, isTrue);
      expect(sessionAfterChoice.state.outcome, isNotNull);
      expect(sessionAfterChoice.state.outcome!.isDefeat, isTrue);
    });

    test('runaway choice finishes the battle immediately', () {
      final session = createTestSession(playerHp: 50);

      final sessionAfterRun =
          session.applyChoice(const PlayerBattleChoiceRun());

      expect(sessionAfterRun.state.isFinished, isTrue);
      expect(sessionAfterRun.state.outcome, isNotNull);
      expect(sessionAfterRun.state.outcome!.isRunaway, isTrue);
      expect(sessionAfterRun.state.currentTurn, isNull);
      expect(sessionAfterRun.state.player.currentHp, equals(50));
      expect(sessionAfterRun.state.enemy.currentHp, equals(20));
    });

    test('multiple turns can be played sequentially', () {
      final session = createTestSession(
          playerHp: 50, enemyHp: 50, playerMovePower: 5, enemyMovePower: 5);

      var currentSession = session;
      var turnCount = 0;

      // Jouer plusieurs tours jusqu'à la fin
      while (!currentSession.state.isFinished && turnCount < 20) {
        currentSession =
            currentSession.applyChoice(const PlayerBattleChoiceFight(0));
        turnCount++;
      }

      // Le combat devrait se terminer
      expect(currentSession.state.isFinished, isTrue);
      expect(turnCount, lessThan(20)); // Ne devrait pas prendre 20 tours
    });

    test('trainer battle setup creates correct session', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          moves: [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );

      final session = createBattleSession(setup);

      expect(session.setup.isTrainerBattle, isTrue);
      expect(session.setup.trainerId, equals('gym_leader_1'));
    });

    test('forced runaway choice is rejected in trainer battles', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );

      final session = createBattleSession(setup);

      expect(
        () => session.applyChoice(const PlayerBattleChoiceRun()),
        throwsA(isA<StateError>()),
      );
      expect(session.state.isFinished, isFalse);
      expect(session.state.outcome, isNull);
    });
  });

  group('BattleOutcome types', () {
    test('victory outcome has correct properties', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 100)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 5,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);
      final resultSession =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(resultSession.state.outcome!.isVictory, isTrue);
      expect(resultSession.state.outcome!.isDefeat, isFalse);
      expect(resultSession.state.outcome!.isRunaway, isFalse);
    });

    test('defeat outcome has correct properties', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 5,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          moves: [BattleMoveData(id: 'psychic', name: 'Psyko', power: 100)],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);
      final resultSession =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(resultSession.state.outcome!.isDefeat, isTrue);
      expect(resultSession.state.outcome!.isVictory, isFalse);
      expect(resultSession.state.outcome!.isRunaway, isFalse);
    });

    test('runaway outcome exposes a real runaway result', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 50,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);
      final resultSession = session.applyChoice(const PlayerBattleChoiceRun());

      expect(resultSession.state.isFinished, isTrue);
      expect(resultSession.state.outcome, isNotNull);
      expect(resultSession.state.outcome!.isRunaway, isTrue);
      expect(resultSession.state.outcome!.isVictory, isFalse);
      expect(resultSession.state.outcome!.isDefeat, isFalse);
      expect(resultSession.state.player.currentHp, equals(50));
      expect(resultSession.state.enemy.currentHp, equals(20));
    });
  });
}
```
