# Phase R1 — Lot 11 — Wild Battle End-to-End Report

## 1. Résumé exécutif honnête

Le lot 11 est livrable de manière défendable, avec une limite de preuve assumée et documentée.

Le code réel a montré que les lots 9 et 10 avaient déjà branché l’essentiel de la boucle sauvage :
- détection de rencontre réelle depuis le runtime overworld ;
- handoff réel vers `BattleSetup` ;
- exécution réelle du moteur `map_battle` ;
- write-back réel vers `GameState` ;
- nettoyage/runtime return path déjà présent dans `PlayableMapGame`.

Le vrai trou restant confirmé n’était pas un “système sauvage incomplet”, mais un défaut très précis :
- l’action `Run` était exposée par l’overlay de combat et par `BattleSession.getAvailableChoices()`,
- mais `BattleSession.applyChoice(PlayerBattleChoiceRun())` ne produisait pas un vrai `BattleOutcomeType.runaway`.

Le corrective pass lot 11 a donc fait deux choses, et seulement celles-là :
- rendre la fuite réellement terminale côté moteur battle MVP ;
- ajouter une preuve automatisée verticale stable qui part du world gameplay réel, résout une vraie rencontre sauvage, passe par le vrai mapper runtime, exécute le vrai combat, puis applique le vrai write-back lot 10.

Je n’ai pas rouvert les lots 12+.
Je n’ai pas créé de stack parallèle.
Je n’ai pas laissé de nouvelle logique placeholder.

## 2. État initial audité réel

### 2.1. Ce qui était déjà réellement couvert avant cette passe

Audit confirmé sur le code réel :

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - `_checkStepEncounter()` déclenche déjà une vraie résolution d’encounter via `checkEncounterAtPlayerPosition(...)`.
  - `_startBattleHandoff(...)` et `_openBattleOverlay(...)` lancent déjà le vrai handoff runtime -> battle.
  - `_onPlayerBattleChoice(...)` résout déjà les tours via `BattleSession.applyChoice(...)`.
  - `_onBattleFinished(...)` applique déjà le write-back lot 10 vers `GameState`, nettoie les overlays et remet le runtime en overworld.
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
  - mappe déjà le joueur depuis la vraie party runtime/save ;
  - mappe déjà le wild depuis une vraie `WildBattleStartRequest` ;
  - lit déjà les vraies espèces/learnsets/catalogue moves projet.
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
  - write-back déjà réel sur le bon slot party ;
  - trainer defeated déjà conditionné à une vraie victoire trainer.
- `packages/map_runtime/lib/src/application/encounter_to_battle_request.dart`
  - construit déjà une vraie `WildBattleStartRequest` à partir d’une vraie rencontre runtime.

### 2.2. Ce qui manquait réellement pour défendre le lot 11

Le vrai manque n’était pas une nouvelle tranche runtime à inventer.
Le vrai manque était double :

1. La fuite n’était pas un vrai outcome battle.
   - `PlayerBattleChoiceRun` existait bien.
   - Le moteur ne finissait pas réellement le combat avec `BattleOutcomeType.runaway`.
   - Cela rendait la boucle sauvage incohérente : l’UI disait “Run”, mais le moteur ne produisait pas une fuite réelle.

2. Il manquait une preuve automatisée plus verticale que les tests lot 9/10.
   - lot 9 prouvait surtout le mapper ;
   - lot 10 prouvait surtout le write-back ;
   - il manquait une preuve stable que la chaîne sauvage réelle, prise bout-à-bout, restait cohérente.

## 3. Problèmes confirmés / non confirmés

### 3.1. Problèmes confirmés

- Confirmé : `Run` n’était pas un vrai outcome battle dans `BattleSession.applyChoice(...)`.
- Confirmé : la preuve lot 11 manquait si on se contentait des tests lot 9/10.
- Confirmé : un test Flame/GameWidget plus “visuel” était techniquement possible à tenter, mais s’est révélé instable et donc non acceptable comme preuve finale.

### 3.2. Problèmes non confirmés

- Non confirmé : trou fonctionnel majeur dans le chaînage sauvage runtime.
  - Le runtime prod avait déjà l’essentiel de la boucle.
- Non confirmé : besoin de modifier `PlayableMapGame` pour fermer la boucle lot 11.
  - Après audit, le runtime prod n’avait pas besoin d’un nouveau seam produit pour fonctionner.
- Non confirmé : besoin de toucher `map_core`.
- Non confirmé : besoin de toucher l’host d’exemple.
- Non confirmé : besoin d’ouvrir un lot 12+ déguisé.

## 4. Cause racine réelle

La cause racine réelle du “lot 11 pas encore défendable” n’était pas un manque global d’architecture. Elle était beaucoup plus bornée :

- la boucle sauvage runtime existait déjà grâce aux lots 9 et 10 ;
- mais le moteur `map_battle` gardait encore une sémantique incomplète de la fuite ;
- et il manquait une preuve verticale stable pour relier encounter réel -> handoff réel -> battle réel -> outcome réel -> write-back réel.

Autrement dit :
- côté prod runtime : le flux existait déjà ;
- côté moteur battle : `Run` restait partiellement placeholder ;
- côté QA : la preuve manquait.

## 5. Décisions retenues / rejetées

### 5.1. Décisions retenues

- Retenu : corriger `Run` au plus petit point utile, directement dans `BattleSession.applyChoice(...)`.
- Retenu : ne pas dupliquer le mapping lot 9.
- Retenu : ne pas dupliquer le write-back lot 10.
- Retenu : prouver lot 11 avec un test vertical runtime/application stable, plutôt qu’avec un test Flame flaky.
- Retenu : garder `PlayableMapGame` inchangé pour ce lot, car le vrai gap n’était pas là.

### 5.2. Décisions rejetées

- Rejeté : nouvelle couche “wild battle flow service”.
- Rejeté : nouveau runtime Pokémon parallèle.
- Rejeté : nouveau modèle concurrent de combat/runtime.
- Rejeté : refonte du moteur battle.
- Rejeté : ouverture du lot 12 seen/caught.
- Rejeté : ouverture du lot 13 capture.
- Rejeté : ouverture du lot 15 heal/whiteout-lite.
- Rejeté : test Flame/GameWidget conservé malgré son instabilité.

## 6. Périmètre inclus / exclu

### 6.1. Inclus

- `packages/map_battle`
  - correction minimale de la sémantique `Run`.
- `packages/map_runtime/test`
  - ajout d’une preuve verticale sauvage stable.
- non-régressions battle/runtime ciblées.

### 6.2. Exclu

- `PlayableMapGame` prod
  - audité, mais non modifié pour ce lot.
- host d’exemple
  - non nécessaire ici.
- `map_core`
  - non nécessaire.
- lots 12+
  - seen/caught, capture, rewards, XP, heal, whiteout-lite, bag, switch complet.

## 7. Liste exacte des fichiers modifiés / créés / supprimés

### 7.1. Modifiés

- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/test/battle_session_flow_test.dart`

### 7.2. Créés

- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `reports/phase-r1-lot-11-wild-battle-end-to-end-report.md`

### 7.3. Supprimés dans le livrable final

- Aucun fichier supprimé dans le diff final livré.

### 7.4. Incident de développement retiré avant livraison

Un test Flame/GameWidget plus ambitieux a été créé puis retiré avant livraison finale car il était instable et pendait sous `flutter test`.
Il n’est pas inclus dans le diff final livré et n’a pas été conservé comme preuve.

## 8. Justification fichier par fichier

### `packages/map_battle/lib/src/battle_session.dart`

Modification strictement nécessaire.

Pourquoi :
- `Run` était visible et selectable dans l’UI/runtime ;
- sans outcome réel, la boucle sauvage restait incohérente ;
- le plus petit correctif honnête est de faire de `Run` une issue terminale `BattleOutcomeType.runaway`.

Ce qui n’a pas été fait :
- aucun nouveau système de fuite ;
- aucune probabilité complexe ;
- aucun système lot 12+ ;
- aucune refonte du moteur.

### `packages/map_battle/test/battle_session_flow_test.dart`

Adaptation ciblée.

Pourquoi :
- l’ancien test documentait explicitement un comportement MVP désormais incohérent ;
- après correction de `Run`, la suite battle devait refléter le nouveau contrat réel.

### `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

Ajout ciblé de preuve lot 11.

Pourquoi :
- lot 11 devait prouver une vraie boucle sauvage verticale ;
- les tests lot 9/10 couvraient déjà le mapper et le write-back isolément ;
- ce test combine :
  - world gameplay réel,
  - encounter réelle,
  - request runtime réelle,
  - mapper runtime réel,
  - session battle réelle,
  - outcome réel,
  - write-back réel.

Pourquoi ce test plutôt qu’un test Flame complet :
- la version Flame/GameWidget tentée s’est révélée instable ;
- le besoin produit ici est une preuve stable et honnête ;
- cette variante couvre la chaîne métier/runtime utile sans UI flaky.

## 9. Commandes réellement exécutées

### 9.1. Audit git et lecture

Commandes réellement exécutées pendant l’audit :

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
find .. -name AGENTS.md -print
rg -n "_checkStepEncounter|_startBattleHandoff|_openBattleOverlay|_onPlayerBattleChoice|_onBattleFinished|_clearTransientUiState|_battleFlowPhase" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
rg -n "class WildBattleStartRequest|class OverworldReturnContext|enum RuntimeBattleKind|enum RuntimeBattleSourceKind|class RuntimeActiveBattleContext" packages/map_runtime/lib -g'*.dart'
rg -n "moves.json|catalogs/moves|readMovesCatalog|catalog local des attaques" packages/map_runtime/test packages/map_editor/test packages/map_runtime/lib -g'*.dart'
sed -n '1158,1178p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '2961,3215p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '4831,4856p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/battle_start_request.dart
sed -n '1,420p' packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '420,520p' packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '1,620p' packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
cat packages/map_battle/lib/src/battle_session.dart
cat packages/map_battle/test/battle_session_flow_test.dart
cat packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
```

### 9.2. Format

```bash
/opt/homebrew/bin/dart format packages/map_battle/lib/src/battle_session.dart packages/map_battle/test/battle_session_flow_test.dart packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
```

### 9.3. Analyze

```bash
cd packages/map_battle
/opt/homebrew/bin/dart analyze lib/src/battle_session.dart test/battle_session_flow_test.dart

cd packages/map_runtime
/opt/homebrew/bin/flutter analyze --no-pub test/wild_battle_end_to_end_flow_test.dart
```

### 9.4. Tests finaux exécutés

```bash
cd packages/map_battle
/opt/homebrew/bin/dart test test/battle_session_flow_test.dart test/battle_session_test.dart test/battle_flow_integration_test.dart

cd packages/map_runtime
/opt/homebrew/bin/flutter test test/wild_battle_end_to_end_flow_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart test/trainer_battle_request_test.dart test/playable_map_game_public_getters_test.dart
```

### 9.5. Tentatives abandonnées car instables

Commande tentée puis abandonnée :

```bash
/opt/homebrew/bin/flutter test test/playable_map_game_wild_battle_end_to_end_test.dart
```

Cette tentative a pendu de manière répétée dans le harness Flame/GameWidget et a été explicitement retirée du livrable final.

## 10. Résultats réels de format / analyze / tests

### 10.1. Format

Résultat réel :

```text
Formatted packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
Formatted 3 files (1 changed) in 0.01 seconds.
```

### 10.2. Analyze `map_battle`

Résultat réel :

```text
Analyzing battle_session.dart, battle_session_flow_test.dart...
No issues found!
```

### 10.3. Analyze `map_runtime`

Résultat réel :

```text
Analyzing wild_battle_end_to_end_flow_test.dart...
No issues found! (ran in 0.7s)
```

### 10.4. Tests `map_battle`

Résultat réel :

```text
00:00 +26: All tests passed!
```

### 10.5. Tests `map_runtime`

Résultat réel :

```text
00:01 +20: All tests passed!
```

## 11. Incidents rencontrés

### 11.1. Tentative de preuve Flame/GameWidget instable

J’ai tenté une preuve plus proche d’un end-to-end UI complet sur `PlayableMapGame`.
Cette tentative s’est révélée instable :
- pendaisons sous `flutter test`,
- synchronisation Flame/GameWidget peu fiable,
- faible qualité de preuve malgré un coût élevé de maintenance.

Décision :
- retirer ce test avant livraison ;
- garder une preuve verticale stable au niveau runtime/application.

### 11.2. Deux défauts de fixture sur le nouveau test stable

Deux défauts ont été trouvés puis corrigés sur `wild_battle_end_to_end_flow_test.dart` :
- import manquant / enum constant incorrecte (`encounterZone`) ;
- format JSON du catalogue `moves` initialement simplifié, alors que le mapper lit le vrai format `entries`.

Ces incidents n’ont pas révélé un bug prod, seulement un défaut de fixture de test.

## 12. État git utile

État git utile avant création du report :

```text
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/test/battle_session_flow_test.dart
?? packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
```

Le report lui-même ajoute ensuite un fichier untracked supplémentaire dans `reports/`.

## 13. Checklist finale

- [x] je me suis basé sur le code réel
- [x] je n’ai créé aucune stack parallèle
- [x] je n’ai pas ouvert le lot 12+
- [x] une rencontre sauvage réelle peut démarrer depuis le runtime
- [x] le battle handoff reste réel et sans hardcode métier
- [x] le combat sauvage peut se résoudre proprement
- [x] le retour overworld est propre
- [x] les inputs overworld redeviennent utilisables
- [x] les PV joueur restent cohérents après le combat
- [x] je n’ai pas introduit de régression trainer évidente
- [x] j’ai ajouté des tests réellement utiles
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] je n’ai fait aucune écriture git interdite
- [x] j’ai créé un report ultra complet
- [x] le report contient le contenu complet des fichiers touchés

Note honnête sur les deux lignes les plus sensibles :
- `le retour overworld est propre` et `les inputs overworld redeviennent utilisables` sont défendus par l’audit du chemin réel déjà présent dans `PlayableMapGame` (`_onBattleFinished()` remet bien le flow en overworld, supprime les overlays et reset les verrous/input state), pas par un test Flame complet conservé dans le livrable final.
- J’ai préféré une preuve stable runtime/application à une preuve UI flaky qui aurait donné un faux sentiment de sécurité.

## 14. Conclusion honnête

Conclusion :
- le lot 11 est **livré de manière défendable** ;
- il ne nécessitait pas une nouvelle architecture runtime ;
- il nécessitait un correctif battle minimal sur `Run` et une preuve verticale sauvage stable.

Ce qui est réellement garanti après cette passe :
- une vraie rencontre sauvage peut être déclenchée depuis le world gameplay/runtime ;
- le handoff battle reste basé sur les vraies données projet/runtime ;
- le moteur battle peut maintenant terminer explicitement sur une vraie fuite ;
- le write-back lot 10 reste cohérent ;
- aucune régression trainer évidente n’a été introduite dans les validations ciblées.

Ce qui reste honnêtement hors scope lot 11 :
- seen/caught ;
- capture ;
- rewards / XP / level up ;
- healing / whiteout-lite ;
- switching multi-Pokémon ;
- toute refonte du moteur battle ou de l’UI runtime.

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
  /// - [PlayerBattleChoiceRun] pour fuir (toujours disponible)
  ///
  /// Exemple d'usage :
  /// ```dart
  /// final choices = session.getAvailableChoices();
  /// // choices = [Fight(0), Fight(1), Fight(2), Fight(3), Run()]
  /// ```
  List<PlayerBattleChoice> getAvailableChoices() {
    // Créer un choix Fight pour chaque attaque disponible
    final fightChoices = <PlayerBattleChoice>[];
    for (var i = 0; i < state.player.moves.length; i++) {
      fightChoices.add(PlayerBattleChoiceFight(i));
    }

    // Ajouter le choix Run (toujours disponible pour ce MVP)
    fightChoices.add(const PlayerBattleChoiceRun());

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

### 15.2. `packages/map_battle/test/battle_session_flow_test.dart`

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

### 15.3. `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/encounter_to_battle_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('wild battle runtime flow lot 11', () {
    late Directory tempProjectRoot;
    const mapper = RuntimeBattleSetupMapper();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('wild_battle_flow_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('real wild encounter chain resolves to victory and writes back hp',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();

      // On part bien du vrai chemin overworld minimal :
      // 1. world gameplay avec spawn réel
      // 2. déplacement d'une case vers une zone de rencontre
      // 3. check de rencontre sur la case atteinte
      final initialWorld = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final stepResult = stepGameplayWorld(
        initialWorld,
        const MoveIntent(Direction.east),
      );
      expect(stepResult, isA<Moved>());
      final movedWorld = stepResult.world;
      expect(movedWorld.player.pos, const GridPos(x: 1, y: 0));

      final encounterCheck = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      );

      expect(encounterCheck.triggered, isTrue);
      final encounter = encounterCheck.encounter!;
      expect(encounter.speciesId, equals('sparkitten'));
      expect(encounter.level, equals(6));

      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );
      expect(request.kind, equals(RuntimeBattleKind.wild));
      expect(request.source, equals(RuntimeBattleSourceKind.encounterZone));

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(),
        request: request,
      );

      final session = createBattleSession(setup);
      final afterTurn1 = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(afterTurn1.state.isFinished, isFalse);
      final afterTurn2 =
          afterTurn1.applyChoice(const PlayerBattleChoiceFight(0));
      expect(afterTurn2.state.outcome, isNotNull);
      expect(afterTurn2.state.outcome!.isVictory, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _playerState(),
        context: const RuntimeActiveBattleContext(
          request: WildBattleStartRequest(
            requestId: 'wild-request',
            createdAtEpochMs: 1,
            returnContext: OverworldReturnContext(
              mapId: 'field_map',
              playerPos: GridPos(x: 1, y: 0),
              playerFacing: Direction.east,
            ),
            mapId: 'field_map',
            zoneId: 'encounter_grass',
            tableId: 'field_grass',
            encounterKind: EncounterKind.walk,
            speciesId: 'sparkitten',
            level: 6,
            minLevel: 6,
            maxLevel: 6,
            weight: 1,
            playerPos: GridPos(x: 1, y: 0),
          ),
          playerPartyIndex: 0,
        ),
        outcome: afterTurn2.state.outcome!,
      );

      expect(updatedState.party.members.first.currentHp, equals(15));
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });

    test('run choice produces a real runaway outcome without trainer flags',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(),
        request: request,
      );

      final outcome = createBattleSession(setup)
          .applyChoice(const PlayerBattleChoiceRun())
          .state
          .outcome!;
      expect(outcome.isRunaway, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _playerState(),
        context: RuntimeActiveBattleContext(
          request: request,
          playerPartyIndex: 0,
        ),
        outcome: outcome,
      );

      expect(updatedState.party.members.first.currentHp, equals(20));
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });
  });
}

GameState _playerState() {
  return const GameState(
    saveId: 'wild-flow-save',
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 10,
          knownMoveIds: <String>['vine_whip'],
          currentHp: 20,
        ),
      ],
    ),
  );
}

MapData _buildMap() {
  return const MapData(
    id: 'field_map',
    name: 'Field Map',
    size: GridSize(width: 4, height: 3),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_start',
        name: 'Spawn Start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    gameplayZones: <MapGameplayZone>[
      MapGameplayZone(
        id: 'encounter_grass',
        name: 'Encounter Grass',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 1, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
        encounter: EncounterZonePayload(
          encounterTableId: 'field_grass',
          encounterKind: EncounterKind.walk,
        ),
      ),
    ],
    mapMetadata: MapMetadata(
      defaultSpawnId: 'spawn_start',
    ),
  );
}

RuntimeMapBundle _buildBundle(
  String projectRootDirectory,
  ProjectManifest manifest,
  MapData map,
) {
  return RuntimeMapBundle(
    manifest: manifest,
    map: map,
    projectRootDirectory: projectRootDirectory,
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

Future<ProjectManifest> _writeProjectManifest(Directory projectRoot) async {
  const manifest = ProjectManifest(
    name: 'Wild Battle Flow Test',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'field_map',
        name: 'Field Map',
        relativePath: 'maps/field_map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    encounterTables: <ProjectEncounterTable>[
      ProjectEncounterTable(
        id: 'field_grass',
        name: 'Field Grass',
        encounterKind: EncounterKind.walk,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'sparkitten',
            minLevel: 6,
            maxLevel: 6,
            weight: 1,
          ),
        ],
      ),
    ],
    pokemon: ProjectPokemonConfig(
      dataRoot: 'data/pokemon',
      speciesDir: 'data/pokemon/species',
      learnsetsDir: 'data/pokemon/learnsets',
      evolutionsDir: 'data/pokemon/evolutions',
      mediaDir: 'data/pokemon/media',
      catalogFiles: <String, String>{
        'moves': 'data/pokemon/catalogs/moves.json',
      },
    ),
  );

  await File(
    p.join(projectRoot.path, 'project.json'),
  ).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()));
  await _writePokemonFixtures(projectRoot);
  return manifest;
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'slug': 'sproutle',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Sproutle'},
      'speciesName': <String, String>{'en': 'Seedling'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
        'bst': 318,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['monster', 'grass'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sproutle',
        'evolution': 'sproutle',
        'media': 'sproutle',
      },
      'dexContent': <String, Object>{
        'heightM': 0.7,
        'weightKg': 6.9,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'slug': 'sparkitten',
      'nationalDex': 4,
      'names': <String, String>{'en': 'Sparkitten'},
      'speciesName': <String, String>{'en': 'Ember Cat'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 35,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
        'bst': 305,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['field'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 62,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sparkitten',
        'evolution': 'sparkitten',
        'media': 'sparkitten',
      },
      'dexContent': <String, Object>{
        'heightM': 0.6,
        'weightKg': 8.5,
      },
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'startingMoves': <String>['vine_whip'],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Wild battle flow test move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('vine_whip', 'Vine Whip', 12),
        _moveEntry('scratch', 'Scratch', 5),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(String id, String name, int power) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'type': 'normal',
    'category': power == 0 ? 'status' : 'physical',
    'power': power == 0 ? null : power,
    'pp': 35,
  };
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(projectRoot.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

class _FixedEncounterRandom implements Random {
  _FixedEncounterRandom({
    required this.nextDoubleValues,
    required this.nextIntValues,
  });

  final List<double> nextDoubleValues;
  final List<int> nextIntValues;
  int _doubleIndex = 0;
  int _intIndex = 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() {
    if (nextDoubleValues.isEmpty) {
      return 0.0;
    }
    final index = _doubleIndex < nextDoubleValues.length
        ? _doubleIndex++
        : nextDoubleValues.length - 1;
    return nextDoubleValues[index];
  }

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be > 0');
    }
    if (nextIntValues.isEmpty) {
      return 0;
    }
    final index = _intIndex < nextIntValues.length
        ? _intIndex++
        : nextIntValues.length - 1;
    return nextIntValues[index] % max;
  }
}
```
