# Phase D — Side / slot minimal report

## 1. Résumé exécutif honnête

**Verdict global**

Phase D est **réellement réussie**.

Le moteur n'est plus canoniquement structuré comme un simple quadruplet `player / playerReserve / enemy / enemyReserve`.
La topologie canonique de `BattleState` est maintenant :
- `playerSide`
- `enemySide`
- chaque side porte :
  - un `activeSlot`
  - un `active`
  - une `reserve`

Le lot apporte aussi un vrai rattachement topologique aux contracts déjà ouverts en Phase C :
- `BattleDecisionRequest` est maintenant attachée à un `side` et à un `slot`
- `BattleSwitchEvent` est maintenant attaché à un `side` et expose un `slot`
- `BattleSession` migre ses seams structurants (`createBattleSession`, `_resolveSwitchAction`, `_resolvePostTurnSwitchState`, `_resolveTurn`, `_determineOutcome`, structs privés de résolution) vers des `BattleSideState`

**Ce qui a réellement changé**

- ajout d'un contrat topologique minimal `BattleSideId` + `BattleSlotRef`
- ajout d'un vrai `BattleSideState` et d'un vrai `BattleSlotState` dans le state battle
- stockage canonique de `BattleState` migré vers `playerSide` / `enemySide`
- compatibilité bornée conservée via getters `player`, `enemy`, `playerReserve`, `enemyReserve`
- `BattleDecisionRequest` durcie avec `side`, `slot`, validations runtime, et seam de compatibilité `actor`
- `BattleSwitchEvent` durci avec `side` et `slot`
- migration interne de `BattleSession` vers des sides dans les seams topologiques critiques
- nouveaux tests de topologie + durcissement des tests requests/switches
- adaptation ciblée d'un test runtime devenu invalide parce que `BattleState` n'est plus `const`

**Ce qui n'a volontairement pas changé**

- pas de `Side` complet façon Showdown
- pas de side conditions actives
- pas de slot conditions actives
- pas de hazards
- pas de `selfSwitch`
- pas de `forceSwitch`
- pas d'event engine
- pas de queue enrichie
- pas de doubles
- pas d'abilities/items
- pas de modification runtime de prod hors nécessité stricte
- pas de modification `examples/`, `map_editor`, `map_core`

**Pourquoi c'est bien Phase D et pas E/F/H**

Le lot modifie la **topologie canonique de l'état** et le rattachement side/slot des requests et remplacements, mais n'ouvre aucun nouveau système de conditions, de scheduling ou d'événements. C'est donc un vrai lot de fondation topologique, pas une ouverture cachée de mécanique ou d'infrastructure plus large.

---

## 2. Pré-gates exécutés + résultats

### Git read-only initial

Commande : `git status --short --untracked-files=all`

```text
 M packages/map_battle/lib/map_battle.dart
 M packages/map_battle/lib/src/battle_decision.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_state.dart
 M packages/map_battle/lib/src/battle_switch.dart
 M packages/map_battle/test/battle_decision_request_test.dart
 M packages/map_battle/test/battle_switch_test.dart
?? packages/map_battle/lib/src/battle_topology.dart
?? packages/map_battle/test/battle_state_topology_test.dart
```

Commande : `git diff --stat`

```text
 packages/map_battle/lib/map_battle.dart            |   1 +
 packages/map_battle/lib/src/battle_decision.dart   |  83 ++++--
 packages/map_battle/lib/src/battle_session.dart    | 253 +++++++++---------
 packages/map_battle/lib/src/battle_state.dart      | 286 +++++++++++++++++++--
 packages/map_battle/lib/src/battle_switch.dart     |  23 +-
 .../test/battle_decision_request_test.dart         |  41 +++
 packages/map_battle/test/battle_switch_test.dart   |   9 +
 .../test/runtime_battle_outcome_apply_test.dart    |  16 +-
 8 files changed, 520 insertions(+), 192 deletions(-)
```

Commande : `git ls-files --others --exclude-standard`

```text
packages/map_battle/lib/src/battle_topology.dart
packages/map_battle/test/battle_state_topology_test.dart
```

### Interprétation honnête

Le worktree n'était pas propre au début de cette étape : il portait déjà la surface Phase D en cours de travail dans cette session. Je n'ai utilisé aucune écriture Git pour la nettoyer ni la réécrire. J'ai traité cet état comme la base réelle du lot et j'ai documenté la surface exacte touchée.

---

## 3. Méthode réelle utilisée

1. Audit réel des seams topologiques battle/runtime.
2. Design local minimal de la topologie `Side / slot`.
3. TDD : écriture d'abord des tests rouges qui exigent une topologie canonique réelle.
4. Implémentation minimale et bornée.
5. Validation locale battle/runtime.
6. Review séparée.
7. Corrections post-review.
8. Rerun complet des validations après review.
9. Rédaction du report final avec annexe intégrale.

### Skills / méthode réellement utilisés

- `using-superpowers` : pour cadrer l'usage des skills
- `brainstorming` : utilisé de façon compacte pour verrouiller le design local avant code
- `writing-plans` : utilisé comme cadre de décomposition, sans écrire de plan séparé hors scope
- `test-driven-development` : tests rouges écrits avant la migration moteur
- `subagent-driven-development` : deux audits parallèles + reviewers séparés
- `requesting-code-review` : appliqué via reviewer séparé réel
- `verification-before-completion` : reruns frais avant toute conclusion

### Plugin `game-studio`

Le plugin a été explicitement mentionné par l'utilisateur. Après audit, je n'ai pas activé de skill `game-studio` spécialisé, parce que le besoin réel était topologique/moteur et non un playtest navigateur ou une surface frontend de jeu. Le smoke produit a été rerun via les tests runtime existants, ce qui était plus pertinent et plus honnête ici.

---

## 4. Audit réel avant code

### Où vivait le problème topologique

Le problème vivait principalement dans :
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_switch.dart`

Le state restait canoniquement décrit comme :
- `player`
- `playerReserve`
- `enemy`
- `enemyReserve`

Même après BE10/BE10A et Phase C, cela restait visible dans :
- le constructeur de `BattleState`
- les structs privés de `BattleSession`
- `_resolveSwitchAction`
- `_resolvePostTurnSwitchState`
- `_determineOutcome`
- les requests encore simplement attachées à un acteur conceptuel, sans topologie side/slot explicite

### Où la vieille forme restait bloquante

Points confirmés par lecture de code :
- `BattleState` portait encore la vieille forme comme stockage, pas juste comme façade
- `BattleSession` résolvait encore ses seams critiques avec des tuples plats actif+réserve par camp
- `BattleDecisionRequest` Phase C séparait déjà les types de requests, mais sans rattachement topologique fort
- `BattleSwitchEvent` restait stringly-typed côté acteur

### Faux positifs écartés

- toucher `battle_overlay_component.dart` n'était pas nécessaire si les getters de compatibilité étaient conservés
- toucher `PlayableMapGame` n'était pas nécessaire
- toucher `runtime_battle_outcome_apply.dart` n'était pas nécessaire en prod ; seul un test runtime a dû être adapté
- ouvrir side conditions / slot conditions maintenant aurait été du creep Phase E/H
- ouvrir une queue plus riche ou un event engine aurait été hors lot

### Réponse honnête à la question “où `player / reserve / enemy / reserve` est profondément ancré ?”

Confirmé par lecture de code :
- dans le constructeur de `BattleState`
- dans les champs du state lui-même
- dans les helpers de résolution de `BattleSession`
- dans les tests qui forgent un `BattleState` direct
- secondairement dans certaines surfaces runtime de lecture, qui heureusement ont pu rester intactes via getters de compatibilité

---

## 5. Nouveau modèle retenu

### Structure exacte

Ajouts principaux :
- `BattleSideId`
- `BattleSlotRef`
- `BattleSlotState`
- `BattleSideState`

`BattleState` devient canoniquement :
- `phase`
- `playerSide`
- `enemySide`
- `field`
- `currentTurn`
- `outcome`

Compatibilité bornée conservée :
- `player`
- `playerReserve`
- `enemy`
- `enemyReserve`
- `side(BattleSideId)`

`BattleDecisionRequest` devient :
- `actor` (compat Phase C conservée)
- `side`
- `slot`
- `kind`
- `allowedChoices`

`BattleSwitchEvent` devient :
- `side`
- `actor` (compat stringly-typed conservée)
- `slot`
- reste du payload métier de switch

### Pourquoi ce design

Parce qu'il réalise un vrai progrès topologique **sans** :
- ouvrir de doubles
- ouvrir de multi-slot réel
- ajouter des types morts de conditions
- refactorer tout le runtime
- casser le golden slice

Le choix clé a été :
- **stocker canoniquement la topologie dans le moteur**
- **garder une façade de compatibilité locale** pour limiter le blast radius

### Ce que j'ai refusé

- un `Side` plus riche avec side conditions déjà actives
- un `slot` plus riche qu'un unique slot actif singles
- un système de slots décoratifs non consommés
- un remplacement de tous les labels stringly-typed dans tous les events moteur
- une migration large du runtime/UI juste “pour être propre”

---

## 6. Critique explicite du prompt

### Ce qui était juste

- le diagnostic structurel était juste : la topologie plate était bien le vrai prochain blocker
- l'interdiction d'ouvrir Phase E/F/H était très saine
- l'exigence d'un `Side` non décoratif était juste
- l'insistance sur la review séparée était utile

### Ce qui était discutable

- la demande d'un “emplacement pour slot-level state futur” pouvait pousser vers un `BattleSlotState` décoratif
- la frontière entre “vrai slot minimal utile” et “préparation abstraite inutile” n'était pas complètement triviale

### Ce qui aurait été dangereux si suivi aveuglément

- poser un `BattleSide` vide et renommer simplement des champs aurait été un faux progrès
- à l'inverse, ouvrir un vrai système multi-slot ou side conditions juste pour “donner une place future” aurait été du scope creep

### Recadrage retenu

J'ai gardé `BattleSlotState` seulement parce qu'il **porte réellement l'actif canonique aujourd'hui**. S'il n'avait pas été consommé par `BattleState` et `BattleSession`, je l'aurais refusé. C'est un vrai type vivant, pas un placeholder.

---

## 7. Périmètre inclus / exclu

### Inclus

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_topology.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_switch.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/test/battle_state_topology_test.dart`
- `packages/map_battle/test/battle_decision_request_test.dart`
- `packages/map_battle/test/battle_switch_test.dart`
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
- ce report

### Exclu volontairement

- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `examples/**`
- `packages/map_editor/**`
- `packages/map_core/**`
- toute ouverture side conditions / slot conditions / queue / event engine

### Justification

L'audit a montré que le vrai seam Phase D était battle-core. Le runtime pouvait rester stable grâce aux getters de compatibilité et au maintien de l'identité `lineupIndex`.

---

## 8. Plan local retenu

1. confirmer par audit que la topologie canonique devait vivre dans `BattleState`/`BattleSession`
2. écrire des tests rouges exigeant :
   - des sides canoniques
   - des requests side/slot
   - des switch events side/slot
3. migrer `BattleState` vers `playerSide`/`enemySide`
4. migrer les seams structurants de `BattleSession`
5. garder des getters de compatibilité pour éviter une migration runtime inutile
6. rerun battle
7. rerun runtime/smoke
8. review séparée
9. corriger les findings valides
10. rerun intégral après review

---

## 9. Justification fichier par fichier

### `packages/map_battle/lib/src/battle_topology.dart`
Ajout du vocabulaire topologique minimal : `BattleSideId`, `BattleSlotRef`.

### `packages/map_battle/lib/src/battle_state.dart`
Migration canonique du state vers `playerSide` / `enemySide`, ajout de `BattleSlotState`, `BattleSideState`, façade legacy, garde-fous runtime sur la compatibilité mixte.

### `packages/map_battle/lib/src/battle_decision.dart`
Rattachement des requests à `side` / `slot`, validations runtime, seam de compatibilité `actor` conservé.

### `packages/map_battle/lib/src/battle_switch.dart`
Rattachement des switch events à `side` et `slot`, avec getter `actor` de compatibilité.

### `packages/map_battle/lib/src/battle_session.dart`
Migration réelle des seams topologiques critiques : création de session, switch, post-turn switches, outcome, structs privés, request building.

### `packages/map_battle/lib/map_battle.dart`
Export du nouveau contrat topologique.

### `packages/map_battle/test/battle_state_topology_test.dart`
Nouveau test de contrat Phase D : topologie canonique, compat façade, garde-fous runtime.

### `packages/map_battle/test/battle_decision_request_test.dart`
Durcissement des assertions side/slot et compat `actor`.

### `packages/map_battle/test/battle_switch_test.dart`
Preuve que les switch events portent un vrai side/slot.

### `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
Adaptation ciblée d'un test runtime qui forgeait un `BattleOutcome` constant avec un `BattleState` désormais non-const.

---

## 10. Classification des blockers adressés

### Blocker structurel réellement résolu

- le moteur n'est plus canoniquement plat sur l'état des deux camps
- les requests Phase C ont maintenant un vrai rattachement topologique
- les switches/remplacements ont maintenant un vrai rattachement de side
- le state offre maintenant un lieu de vie honnête pour les futures responsabilités side-level et slot-level

### Ce qui reste hors lot

- side conditions actives
- slot conditions actives
- hazards
- `selfSwitch`
- `forceSwitch`
- event engine
- queue enrichie
- topologie multi-slot réelle
- doubles

---

## 11. Commandes réellement exécutées

### Git / audit
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git ls-files --others --exclude-standard`
- `find /Users/karim/Project/pokemonProject -name AGENTS.md -print`
- multiples `sed -n ...` sur les fichiers battle/runtime ciblés
- multiples `rg -n ...` sur les usages `state.player`, `BattleState(`, `BattleTurnResult`, etc.

### TDD / validation battle
- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_state_topology_test.dart test/battle_decision_request_test.dart test/battle_switch_test.dart`
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze`
- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_state_topology_test.dart test/battle_decision_request_test.dart test/battle_session_test.dart test/battle_switch_test.dart test/battle_session_flow_test.dart test/battle_flow_integration_test.dart test/battle_volatiles_test.dart`
- `cd packages/map_battle && /opt/homebrew/bin/dart format ...`

### Validation runtime / smoke
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/presentation/flame/battle_overlay_component.dart lib/src/application/runtime_battle_outcome_apply.dart test/battle_overlay_component_test.dart test/runtime_battle_outcome_apply_test.dart test/runtime_battle_setup_mapper_test.dart test/phase_a_golden_battle_slice_smoke_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_overlay_component_test.dart test/runtime_battle_outcome_apply_test.dart test/runtime_battle_setup_mapper_test.dart test/phase_a_golden_battle_slice_smoke_test.dart`

### Incidents de commande réellement rencontrés
- exécution initiale de `dart test` au root du repo : échec (`No pubspec.yaml file found`) ; rerun depuis `packages/map_battle`
- premier rerun runtime après migration : échec de compilation parce que deux tests forgeaient encore un `BattleOutcome` constant avec un `BattleState` devenu non-const ; corrigé puis rerun

---

## 12. Résultats réels

### Format

- `packages/map_battle`: format vert
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`: format vert

### Analyze

- `packages/map_battle`: vert
- `packages/map_runtime` ciblé: vert

### Tests battle

Commande finale rerun après review :

```text
cd packages/map_battle && /opt/homebrew/bin/dart test \
  test/battle_state_topology_test.dart \
  test/battle_decision_request_test.dart \
  test/battle_session_test.dart \
  test/battle_switch_test.dart \
  test/battle_session_flow_test.dart \
  test/battle_flow_integration_test.dart \
  test/battle_volatiles_test.dart
```

Résultat : vert, `All tests passed!`

### Tests runtime / smoke

Commande finale rerun après review :

```text
cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/battle_overlay_component_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart
```

Résultat : vert, `All tests passed!`

### Smoke produit Phase A

Le smoke Phase A a été rerun via `test/phase_a_golden_battle_slice_smoke_test.dart` dans la batterie runtime ci-dessus.
Résultat : vert.

---

## 13. Incidents rencontrés

1. **Commande au mauvais niveau de repo**
   - symptôme : `No pubspec.yaml file found`
   - cause : lancement initial de `dart test` depuis la racine
   - correction : rerun depuis `packages/map_battle`

2. **Rupture de const sur un test runtime**
   - symptôme : compilation cassée dans `runtime_battle_outcome_apply_test.dart`
   - cause : `BattleState` n'est plus const, donc deux `const BattleOutcome(...)` n'étaient plus valides
   - correction : rendre ces outcomes `final` et garder les sous-objets `const` quand c'était encore légitime

3. **Findings reviewer valides**
   - sides canoniques non validés explicitement
   - cohérence `request.side/request.slot` non forcée en runtime
   - seam de compatibilité `actor` supprimé trop brutalement
   - compatibilité mixte legacy/new sur `BattleState` protégée seulement par `assert`
   - correction : garde-fous runtime + seam `actor` réintroduit

---

## 14. Décisions retenues / rejetées

### Retenues

- `BattleState` side-based canonique
- `BattleSlotState` conservé car vivant et consommé réellement
- getters legacy conservés pour limiter le blast radius runtime
- `BattleDecisionRequest.actor` conservé comme seam de compatibilité
- validations runtime explicites sur les nouveaux invariants topologiques

### Rejetées

- réécriture du runtime de prod
- suppression brutale des getters legacy
- `BattleSideState` vide ou décoratif
- `BattleSlotState` décoratif non consommé
- extension opportuniste vers side conditions / event engine / queue

---

## 15. Retour du sub-agent d’audit/design

### `Dirac`

Apport utile :
- a confirmé que le vrai lot devait migrer `BattleState` et les seams structurants de `BattleSession`
- a conseillé de garder `BattleSetup` plat et de garder des getters legacy
- a mis en garde contre le faux progrès d'un simple wrapper sans migration interne

Retenu :
- migration réelle de `BattleSession`
- getters legacy conservés
- `BattleSetup` intact

Rejeté / nuancé :
- `Dirac` suggérait de ne pas introduire de `BattleSlotState` sauf nécessité
- j'ai choisi de le garder **parce qu'il porte réellement l'actif canonique aujourd'hui** ; ce n'est pas un placeholder mort

### `Pascal`

Apport utile :
- a confirmé que le runtime overlay et `PlayableMapGame` pouvaient rester intacts si les getters legacy restaient disponibles
- a pointé le constructeur `BattleState` comme seam fragile côté tests/runtime

Retenu :
- pas de modification runtime de prod
- compat constructor/getters maintenus

---

## 16. Retour du reviewer séparé

### `Leibniz` a remonté trois findings principaux

1. `BattleState` acceptait des sides canoniques inversés
2. `BattleDecisionRequest` ne garantissait pas la cohérence side/slot
3. la compatibilité publique `actor` avait été supprimée trop brutalement

### `Kuhn` a ajouté un finding utile

4. la compatibilité mixte `playerSide` + `player/playerReserve` ne devait pas rester protégée uniquement par `assert`

---

## 17. Corrections appliquées après review

- ajout de validations runtime pour empêcher `playerSide`/`enemySide` inversés
- ajout d'un helper `_resolveBattleStateSide(...)` pour refuser explicitement les constructions mixtes legacy/new
- réintroduction de `BattleDecisionActor` et de `BattleDecisionRequest.actor` comme seam de compatibilité borné
- conversion des validations `request.side/request.slot` en erreurs runtime explicites
- ajout de tests couvrant :
  - side inversé refusé
  - mélange inputs legacy/new refusé
  - request side/slot incohérente refusée
- rerun complet analyze/tests/smoke après ces corrections

---

## 18. Autocritique finale

### Ce lot est solide sur quoi ?

- la topologie canonique du moteur est vraiment plus honnête
- le runtime n'a pas été inutilement secoué
- la compatibilité a été bornée au lieu d'être supprimée brutalement
- les reviewers ont effectivement amélioré le lot

### Ce qui reste limité

- le moteur reste singles-only strict
- `BattleMoveExecution`, `BattleStatusEvent`, `BattleVolatileEvent`, `BattleFieldEvent` restent encore partiellement stringly-typed
- `BattleSideState` n'est pas encore le lieu de side conditions actives
- `BattleSlotState` ne porte pas encore de vrai slot-level state autre que l'actif lui-même

### Ce que cela débloque pour Phase E/F plus tard

Phase D débloque proprement :
- un lieu de vie honnête pour les futures responsabilités side-level
- un lieu de vie honnête pour les futures responsabilités slot-level
- des requests topologiquement rattachées
- des switches/remplacements topologiquement rattachés
- une base plus propre pour introduire ensuite un mini event/condition engine (Phase E) et une queue plus riche (Phase F)

Cela **ne** débloque pas automatiquement :
- side conditions riches immédiates
- hazards immédiats
- targeting riche
- doubles

---

## 19. Contenu complet de tous les fichiers touchés

Cette annexe inclut le contenu complet de tous les fichiers modifiés ou créés **sauf ce report lui-même**, exclu explicitement pour éviter une récursion infinie.


### `packages/map_battle/lib/map_battle.dart`

```dart
/// Battle engine for Pokémon-like RPG combat.
///
/// Pure Dart package, independent of Flutter/Flame.
/// Deterministic, testable, and minimal.
///
/// ## Usage
///
/// ```dart
/// // 1. Create setup
/// final setup = BattleSetup(
///   playerPokemon: BattleCombatantData(
///     speciesId: 'pikachu',
///     level: 5,
///     maxHp: 20,
///     stats: const BattleStatsSnapshot(
///       attack: 10,
///       defense: 10,
///       specialAttack: 10,
///       specialDefense: 10,
///       speed: 10,
///     ),
///     moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
///   ),
///   enemyPokemon: BattleCombatantData(
///     speciesId: 'lapras',
///     level: 5,
///     maxHp: 25,
///     stats: const BattleStatsSnapshot(
///       attack: 10,
///       defense: 10,
///       specialAttack: 10,
///       specialDefense: 10,
///       speed: 10,
///     ),
///     moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
///   ),
///   isTrainerBattle: true,
///   trainerId: 'gym_leader_1',
/// );
///
/// // 2. Create session
/// final session = createBattleSession(setup);
///
/// // 3. Read the explicit decision request
/// final request = session.decisionRequest;
/// final choices = request.allowedChoices; // compatibility helper
///
/// // 4. Apply choice
/// final newSession = session.applyChoice(PlayerBattleChoiceFight(0));
///
/// // 5. Check if finished
/// if (newSession.state.isFinished) {
///   final outcome = newSession.state.outcome!;
///   if (outcome.isVictory) {
///     // Mark trainer as defeated
///   }
/// }
/// ```
library map_battle;

export 'src/battle_setup.dart';
export 'src/battle_decision.dart';
export 'src/battle_session.dart';
export 'src/battle_state.dart';
export 'src/battle_topology.dart';
export 'src/battle_field.dart';
export 'src/battle_status.dart';
export 'src/battle_volatile.dart';
export 'src/battle_switch.dart';
export 'src/battle_stats.dart';
export 'src/battle_typing.dart';
export 'src/battle_type_chart.dart';
export 'src/battle_rng.dart';
export 'src/battle_action.dart';
export 'src/battle_move.dart';
export 'src/battle_resolution.dart';

```

### `packages/map_battle/lib/src/battle_topology.dart`

```dart
/// Identité locale des deux côtés d'un combat singles.
///
/// Phase D n'ouvre toujours pas une topologie Showdown complète :
/// - il n'existe que deux côtés ;
/// - chacun ne porte qu'un seul slot actif ;
/// - mais on arrête de faire comme si tout le moteur n'était qu'un couple
///   `player/enemy` plat sans vraie identité de side.
enum BattleSideId {
  player,
  enemy,
}

/// Petit helper de compatibilité pour les surfaces encore stringly-typed.
///
/// On le garde parce que :
/// - plusieurs traces moteur/runtime utilisent encore `"player"` / `"enemy"` ;
/// - Phase D ne doit pas élargir artificiellement le périmètre aux autres
///   contrats d'événements qui n'ont pas besoin de migrer aujourd'hui ;
/// - les nouveaux contrats topologiques peuvent néanmoins s'appuyer sur
///   [BattleSideId] sans casser toute la surface en une fois.
extension BattleSideIdActorId on BattleSideId {
  String get actorId => switch (this) {
        BattleSideId.player => 'player',
        BattleSideId.enemy => 'enemy',
      };
}

/// Référence explicite à un slot battle local.
///
/// Phase D garde ce contrat volontairement minimal :
/// - en singles, le seul slot réellement résolu aujourd'hui est le slot actif
///   `0` de chaque side ;
/// - cette référence existe pourtant déjà car les requests et les événements
///   de switch doivent maintenant se rattacher à une topologie honnête ;
/// - on n'ouvre pas pour autant une grille de slots multi-actifs.
final class BattleSlotRef {
  const BattleSlotRef({
    required this.side,
    required this.slotIndex,
  });

  const BattleSlotRef.active(this.side) : slotIndex = 0;

  final BattleSideId side;
  final int slotIndex;

  @override
  bool operator ==(Object other) {
    return other is BattleSlotRef &&
        other.side == side &&
        other.slotIndex == slotIndex;
  }

  @override
  int get hashCode => Object.hash(side, slotIndex);

  @override
  String toString() {
    return 'BattleSlotRef(side: ${side.name}, slotIndex: $slotIndex)';
  }
}

```

### `packages/map_battle/lib/src/battle_state.dart`

```dart
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
  })  : assert(
          activeSlot.side == id,
          'BattleSideState.activeSlot must belong to the same side.',
        ),
        assert(
          activeSlot.slotIndex == 0,
          'Phase D remains singles-only and only supports active slot 0.',
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

  /// Combattant actif de ce side.
  BattleCombatant get active => activeSlot.combatant;

  /// Référence canonique du slot actif.
  BattleSlotRef get activeSlotRef => activeSlot.ref;

  BattleSideState withActive(BattleCombatant updatedActive) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot.withCombatant(updatedActive),
      reserve: reserve,
    );
  }

  BattleSideState withReserve(List<BattleCombatant> updatedReserve) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot,
      reserve: updatedReserve,
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

```

### `packages/map_battle/lib/src/battle_decision.dart`

```dart
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

```

### `packages/map_battle/lib/src/battle_switch.dart`

```dart
import 'battle_topology.dart';

/// Petite taxonomie des événements de switch/réserve visibles dans un tour.
///
/// BE10 reste volontairement très borné :
/// - pas de système de slots façon doubles ;
/// - pas de pipeline générique de selfSwitch / forceSwitch ;
/// - pas de journal universel ;
/// - seulement ce qu'il faut pour ne pas muter les actifs/réserves en silence.
enum BattleSwitchEventKind {
  switched,
  replacementRequired,
}

/// Trace minimale d'un switch ou d'un remplacement forcé.
///
/// Ce contrat sépare volontairement les événements de roster des :
/// - `BattleStatusEvent` (statuts majeurs) ;
/// - `BattleVolatileEvent` (protect/recharge/charge) ;
/// - `BattleFieldEvent` (weather/pseudoWeather).
///
/// Cela garde chaque couche lisible et évite de transformer `BattleTurnResult`
/// en sac de booléens croisés.
final class BattleSwitchEvent {
  const BattleSwitchEvent.switched({
    required this.side,
    required this.fromSpeciesId,
    required this.toSpeciesId,
    required this.wasForced,
  }) : kind = BattleSwitchEventKind.switched;

  const BattleSwitchEvent.replacementRequired({
    required this.side,
    required this.fromSpeciesId,
  })  : kind = BattleSwitchEventKind.replacementRequired,
        toSpeciesId = null,
        wasForced = true;

  /// Side concerné par le switch ou la demande de remplacement.
  final BattleSideId side;

  final BattleSwitchEventKind kind;

  /// Espèce qui quitte le terrain.
  ///
  /// Sur `replacementRequired`, c'est l'espèce K.O. que le joueur doit
  /// remplacer avant de pouvoir reprendre un tour normal.
  final String fromSpeciesId;

  /// Espèce qui entre sur le terrain quand un switch a réellement eu lieu.
  final String? toSpeciesId;

  /// `true` pour un remplacement contraint par un K.O., `false` pour un
  /// switch volontaire du joueur.
  final bool wasForced;

  /// Compatibilité locale pour les surfaces encore stringly-typed.
  ///
  /// Phase D fait migrer l'événement vers un vrai side, mais certaines traces
  /// runtime/tests lisent encore `"player"` / `"enemy"`.
  String get actor => side.actorId;

  /// Slot concerné par l'événement.
  ///
  /// En singles, tous les switches/remplacements portent encore sur le slot
  /// actif `0` du side concerné. Exposer explicitement cette référence rend la
  /// topologie réelle sans ouvrir de système multi-slot.
  BattleSlotRef get slot => BattleSlotRef.active(side);
}

```

### `packages/map_battle/lib/src/battle_session.dart`

```dart
import 'battle_setup.dart';
import 'battle_decision.dart';
import 'battle_state.dart';
import 'battle_action.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_rng.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_switch.dart';
import 'battle_topology.dart';
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
    playerSide: BattleSideState.player(
      active: player,
      reserve: playerReserve,
    ),
    enemySide: BattleSideState.enemy(
      active: enemy,
      reserve: enemyReserve,
    ),
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
/// 2. [decisionRequest] expose la vraie requête de décision joueur
/// 3. [getAvailableChoices] reste disponible comme adaptateur de compatibilité
/// 4. [applyChoice] applique un choix et retourne une nouvelle session
/// 5. Répéter 2-4 jusqu'à ce que [state.isFinished] soit true
/// 6. Récupérer [state.outcome] pour le résultat final
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

  /// Requête de décision joueur explicitement exposée par le moteur.
  ///
  /// Phase C choisit ici le plus petit vrai progrès de fondation :
  /// - le moteur ne publie plus seulement une "liste plate de choix" ;
  /// - il expose désormais le type de demande courante :
  ///   tour libre, remplacement forcé, continuation forcée ou attente ;
  /// - runtime/UI peuvent donc consommer un contrat fort sans deviner le
  ///   sens du tour depuis les choix présents, le KO actif ou les volatiles.
  BattleDecisionRequest get decisionRequest => _buildDecisionRequest();

  /// Récupère les choix disponibles pour le joueur.
  ///
  /// Compatibilité locale Phase C :
  /// - cette méthode reste volontairement publique pour limiter le blast
  ///   radius immédiat ;
  /// - mais elle n'est plus la source principale de vérité ;
  /// - elle dérive désormais directement de [decisionRequest].
  ///
  List<PlayerBattleChoice> getAvailableChoices() {
    return decisionRequest.allowedChoices;
  }

  BattleDecisionRequest _buildDecisionRequest() {
    const playerSideId = BattleSideId.player;
    const playerSlot = BattleSlotRef.active(BattleSideId.player);

    if (state.phase == BattlePhase.finished) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.battleFinished,
      );
    }

    if (state.phase != BattlePhase.playerChoice) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.resolvingTurn,
      );
    }

    final replacementChoices = _availableForcedReplacementChoices();
    if (replacementChoices.isNotEmpty) {
      return BattleForcedReplacementRequest(
        side: playerSideId,
        slot: playerSlot,
        switchChoices: replacementChoices,
        reason: BattleForcedReplacementReason.activeFainted,
        faintedSpeciesId: state.player.speciesId,
      );
    }

    // Cas explicitement borné mais important :
    // - si l'actif est K.O. sans remplaçant valide et que la session n'est pas
    //   déjà terminée, on refuse d'inventer un faux tour libre ;
    // - le runtime voit alors un état "wait" bruyant au lieu d'un menu trompeur.
    if (state.player.isFainted) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.activeFaintedWithoutReplacement,
      );
    }

    final volatileState = state.player.volatileState;
    if (volatileState.pendingCharge != null) {
      return BattleContinueRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleContinueReason.pendingChargeRelease,
      );
    }
    if (volatileState.mustRecharge) {
      return BattleContinueRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleContinueReason.mustRecharge,
      );
    }

    // On construit maintenant explicitement le vrai tour libre :
    // - moves encore jouables ;
    // - switches volontaires valides ;
    // - issues sauvages éventuellement autorisées.
    final moveChoices = <PlayerBattleChoiceFight>[];
    for (var i = 0; i < state.player.moves.length; i++) {
      if (state.player.moves[i].hasUsablePp) {
        moveChoices.add(PlayerBattleChoiceFight(i));
      }
    }
    final switchChoices = _availableVoluntarySwitchChoices();
    final captureChoice = !setup.isTrainerBattle && setup.allowCapture
        ? const PlayerBattleChoiceCapture()
        : null;
    final runChoice =
        !setup.isTrainerBattle ? const PlayerBattleChoiceRun() : null;

    if (moveChoices.isEmpty &&
        switchChoices.isEmpty &&
        captureChoice == null &&
        runChoice == null) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.noLegalChoice,
      );
    }

    return BattleTurnChoiceRequest(
      side: playerSideId,
      slot: playerSlot,
      moveChoices: moveChoices,
      switchChoices: switchChoices,
      captureChoice: captureChoice,
      runChoice: runChoice,
    );
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
    final request = decisionRequest;
    if (request is BattleWaitRequest) {
      throw StateError(
        'Aucune décision joueur n’est attendue actuellement (${request.reason.name}).',
      );
    }
    if (!request.allows(choice)) {
      throw _illegalChoiceStateError(request, choice);
    }
    if (request case BattleForcedReplacementRequest()) {
      return _applyForcedPlayerReplacement(choice as PlayerBattleChoiceSwitch);
    }

    final forcedPlayerAction = switch (request) {
      BattleContinueRequest() => _resolveForcedAction(
          combatantLabel: 'player',
          combatant: state.player,
        ),
      _ => null,
    };
    if (request is BattleContinueRequest && forcedPlayerAction == null) {
      throw StateError(
        'La request ${request.kind.name} ne correspond plus à un vrai tour forcé côté moteur.',
      );
    }

    // Frontière métier défensive :
    // même si un call site contourne getAvailableChoices(), un combat trainer
    // ne doit jamais pouvoir produire ni "runaway", ni "captured".
    //
    // On rejette explicitement ce cas illégal au niveau du moteur, ce qui
    // évite de dépendre d'un filtre UI seulement.
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceRun &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceRun est interdit pendant un trainer battle.',
      );
    }
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pendant un trainer battle.',
      );
    }
    if (request is! BattleContinueRequest &&
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
    if (request is! BattleContinueRequest && choice is PlayerBattleChoiceRun) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: state.playerSide,
        enemySide: state.enemySide,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          playerSide: finalState.playerSide,
          enemySide: finalState.enemySide,
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
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: state.playerSide,
        enemySide: state.enemySide,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          playerSide: finalState.playerSide,
          enemySide: finalState.enemySide,
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
    final postTurnSwitches = _resolvePostTurnSwitchState(
      playerSide: resolvedTurn.playerSide,
      enemySide: resolvedTurn.enemySide,
    );
    final switchEvents = <BattleSwitchEvent>[
      ...resolvedTurn.turnResult.switchEvents,
      ...postTurnSwitches.switchEvents,
    ];
    final timeline = <BattleTurnEvent>[
      ...resolvedTurn.turnResult.timeline,
      ...postTurnSwitches.timeline,
    ];
    final turnResult = BattleTurnResult(
      playerAction: resolvedTurn.turnResult.playerAction,
      enemyAction: resolvedTurn.turnResult.enemyAction,
      executions: resolvedTurn.turnResult.executions,
      statusEvents: resolvedTurn.turnResult.statusEvents,
      volatileEvents: resolvedTurn.turnResult.volatileEvents,
      fieldEvents: resolvedTurn.turnResult.fieldEvents,
      switchEvents: List<BattleSwitchEvent>.unmodifiable(switchEvents),
      timeline: List<BattleTurnEvent>.unmodifiable(timeline),
    );

    // Phase 5: Vérifier si le combat est fini
    final outcome = _determineOutcome(
      postTurnSwitches.playerSide,
      postTurnSwitches.enemySide,
      resolvedTurn.field,
    );

    // Phase 6: Créer le nouvel état
    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      playerSide: postTurnSwitches.playerSide,
      enemySide: postTurnSwitches.enemySide,
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
      side: state.playerSide,
      reserveIndex: choice.reserveIndex,
      wasForced: true,
    );

    return BattleSession._(
      state: BattleState(
        phase: BattlePhase.playerChoice,
        playerSide: replacement.side,
        enemySide: state.enemySide,
        field: state.field,
        currentTurn: BattleTurnResult(
          playerAction: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          enemyAction: const BattleActionNone(),
          executions: const <BattleMoveExecution>[],
          switchEvents: <BattleSwitchEvent>[replacement.event],
          timeline: <BattleTurnEvent>[
            BattleTurnSwitchEvent(replacement.event),
          ],
        ),
        outcome: null,
      ),
      setup: setup,
      rng: rng,
    );
  }

  _ResolvedSwitchAction _resolveSwitchAction({
    required BattleSideState side,
    required int reserveIndex,
    required bool wasForced,
  }) {
    final reserve = side.reserve;
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
    updatedReserve[reserveIndex] = side.active.resetForReserveOnSwitchOut();

    return _ResolvedSwitchAction(
      side: side.withActiveAndReserve(
        active: incoming,
        reserve: List<BattleCombatant>.unmodifiable(updatedReserve),
      ),
      event: BattleSwitchEvent.switched(
        side: side.id,
        fromSpeciesId: side.active.speciesId,
        toSpeciesId: incoming.speciesId,
        wasForced: wasForced,
      ),
    );
  }

  _ResolvedPostTurnSwitchState _resolvePostTurnSwitchState({
    required BattleSideState playerSide,
    required BattleSideState enemySide,
  }) {
    var updatedPlayerSide = playerSide;
    var updatedEnemySide = enemySide;
    final switchEvents = <BattleSwitchEvent>[];
    final timeline = <BattleTurnEvent>[];

    final enemyReplacementIndex =
        _firstUsableReserveIndex(updatedEnemySide.reserve);
    if (updatedEnemySide.active.isFainted && enemyReplacementIndex != null) {
      final replacement = _resolveSwitchAction(
        side: updatedEnemySide,
        reserveIndex: enemyReplacementIndex,
        wasForced: true,
      );
      updatedEnemySide = replacement.side;
      switchEvents.add(replacement.event);
      timeline.add(BattleTurnSwitchEvent(replacement.event));
    }

    if (updatedPlayerSide.active.isFainted &&
        !updatedEnemySide.active.isFainted &&
        _firstUsableReserveIndex(updatedPlayerSide.reserve) != null) {
      final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
        side: BattleSideId.player,
        fromSpeciesId: updatedPlayerSide.active.speciesId,
      );
      switchEvents.add(replacementRequiredEvent);
      timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
    }

    return _ResolvedPostTurnSwitchState(
      playerSide: updatedPlayerSide,
      enemySide: updatedEnemySide,
      switchEvents: List<BattleSwitchEvent>.unmodifiable(switchEvents),
      timeline: List<BattleTurnEvent>.unmodifiable(timeline),
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
      throw StateError(
        'Le choix Fight(${choice.moveIndex}) vise un slot move invalide.',
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
    throw StateError(
      'Type de choix joueur non supporté par _choiceToAction: ${choice.runtimeType}.',
    );
  }

  String _describePlayerChoice(PlayerBattleChoice choice) {
    return switch (choice) {
      PlayerBattleChoiceFight(:final moveIndex) => 'Fight($moveIndex)',
      PlayerBattleChoiceSwitch(:final reserveIndex) => 'Switch($reserveIndex)',
      PlayerBattleChoiceRun() => 'Run()',
      PlayerBattleChoiceCapture() => 'Capture()',
      PlayerBattleChoiceContinue() => 'Continue()',
    };
  }

  StateError _illegalChoiceStateError(
    BattleDecisionRequest request,
    PlayerBattleChoice choice,
  ) {
    // On garde ici quelques diagnostics métier précis pour ne pas perdre en
    // lisibilité par rapport à l'ancien monde "liste plate" :
    // - un move à 0 PP doit rester identifiable comme tel ;
    // - un switch invalide ou vers une réserve K.O. mérite aussi un message
    //   ciblé ;
    // - tout le reste peut retomber sur le message générique request/kind.
    if (choice case PlayerBattleChoiceFight(:final moveIndex)) {
      if (moveIndex >= 0 && moveIndex < state.player.moves.length) {
        final move = state.player.moves[moveIndex];
        if (!move.hasUsablePp) {
          return StateError(
            'Le move "${move.name}" n’a plus de PP et ne peut pas être utilisé.',
          );
        }
      }
    }

    if (choice case PlayerBattleChoiceSwitch(:final reserveIndex)) {
      if (reserveIndex < 0 || reserveIndex >= state.playerReserve.length) {
        return StateError(
          'Le switch demandé vise un index de réserve invalide ($reserveIndex).',
        );
      }
      if (state.playerReserve[reserveIndex].isFainted) {
        return StateError(
          'Le switch demandé vise un Pokémon de réserve déjà K.O.',
        );
      }
    }

    return StateError(
      'Le choix ${_describePlayerChoice(choice)} est illégal pour la request courante ${request.kind.name}.',
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
    final timeline = <BattleTurnEvent>[];
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
            timeline.addAll(resolution.timeline);
          } else if (orderedAction.action
              case BattleActionSwitch(:final reserveIndex)) {
            final resolution = _resolveSwitchAction(
              side: BattleSideState.player(
                active: player,
                reserve: playerReserve,
              ),
              reserveIndex: reserveIndex,
              wasForced: false,
            );
            player = resolution.side.active;
            playerReserve = resolution.side.reserve;
            switchEvents.add(resolution.event);
            timeline.add(BattleTurnSwitchEvent(resolution.event));
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
            timeline.addAll(resolution.timeline);
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
            timeline.addAll(resolution.timeline);
          } else if (orderedAction.action
              case BattleActionSwitch(:final reserveIndex)) {
            final resolution = _resolveSwitchAction(
              side: BattleSideState.enemy(
                active: enemy,
                reserve: enemyReserve,
              ),
              reserveIndex: reserveIndex,
              wasForced: false,
            );
            enemy = resolution.side.active;
            enemyReserve = resolution.side.reserve;
            switchEvents.add(resolution.event);
            timeline.add(BattleTurnSwitchEvent(resolution.event));
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
            timeline.addAll(resolution.timeline);
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
    timeline.addAll(residualResolution.timeline);
    player = player.withVolatileState(
      player.volatileState.clearedEndOfTurnFlags(),
    );
    enemy = enemy.withVolatileState(
      enemy.volatileState.clearedEndOfTurnFlags(),
    );

    return _ResolvedBattleTurn(
      playerSide: BattleSideState.player(
        active: player,
        reserve: playerReserve,
      ),
      enemySide: BattleSideState.enemy(
        active: enemy,
        reserve: enemyReserve,
      ),
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
        timeline: timeline,
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
        timeline: _turnEventsFromStatus(actionGate.statusEvents),
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
        timeline: _turnEventsFromVolatile(
          <BattleVolatileEvent>[
            BattleVolatileEvent.chargeStarted(
              actor: attackerLabel,
              sourceMoveId: move.id,
              chargeStateId: move.chargeThenStrikeEffect!.chargeStateId,
            ),
          ],
        ),
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
      final missExecution = BattleMoveExecution(
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
      );
      return _ResolvedMoveExecution(
        attacker: attackerAfterPpUse,
        defender: defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: missExecution,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(volatileEvents),
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _buildMoveTimeline(
          preExecutionVolatileEvents: volatileEvents,
          execution: missExecution,
        ),
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
      final blockedExecution = BattleMoveExecution(
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
      );
      return _ResolvedMoveExecution(
        attacker: protectResolution.attacker,
        defender: protectResolution.defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: blockedExecution,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(volatileEvents),
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _buildMoveTimeline(
          preExecutionVolatileEvents: volatileEvents,
          execution: blockedExecution,
        ),
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
    final preExecutionVolatileEvents =
        List<BattleVolatileEvent>.unmodifiable(volatileEvents);
    final rechargeFollowUp = _resolveRechargeFollowUp(
      move: move,
      attackerLabel: attackerLabel,
      attacker: updatedAttacker,
      damageResult: damageResult,
    );
    volatileEvents.addAll(rechargeFollowUp.volatileEvents);

    final resolvedExecution = BattleMoveExecution(
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
    );

    return _ResolvedMoveExecution(
      attacker: rechargeFollowUp.attacker,
      defender: statusApplication.defender,
      field: fieldApplication.field,
      rng: statusApplication.nextRng,
      execution: resolvedExecution,
      statusEvents: statusApplication.statusEvents,
      volatileEvents: List<BattleVolatileEvent>.unmodifiable(volatileEvents),
      fieldEvents: fieldApplication.fieldEvents,
      timeline: _buildMoveTimeline(
        preExecutionVolatileEvents: preExecutionVolatileEvents,
        execution: resolvedExecution,
        statusEvents: statusApplication.statusEvents,
        fieldEvents: fieldApplication.fieldEvents,
        postExecutionVolatileEvents: rechargeFollowUp.volatileEvents,
      ),
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
        timeline: const <BattleTurnEvent>[],
      );
    }

    final rechargeEvents = <BattleVolatileEvent>[
      BattleVolatileEvent.rechargeTurnSpent(
        actor: combatantLabel,
      ),
    ];

    return _ResolvedRechargeAction(
      combatant: combatant.withVolatileState(
        combatant.volatileState.withMustRecharge(false),
      ),
      volatileEvents: rechargeEvents,
      timeline: _turnEventsFromVolatile(rechargeEvents),
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
      timeline: <BattleTurnEvent>[
        ..._turnEventsFromStatus(statusResidual.statusEvents),
        ..._turnEventsFromField(weatherResidual.fieldEvents),
        ..._turnEventsFromField(fieldProgression.fieldEvents),
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
    BattleSideState playerSide,
    BattleSideState enemySide,
    BattleFieldState field,
  ) {
    // Vérifier la victoire (ennemi K.O.)
    if (enemySide.active.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: playerSide,
        enemySide: enemySide,
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
    if (playerSide.active.isFainted) {
      if (_firstUsableReserveIndex(playerSide.reserve) != null) {
        return null;
      }
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: playerSide,
        enemySide: enemySide,
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

  List<BattleTurnEvent> _buildMoveTimeline({
    List<BattleVolatileEvent> preExecutionVolatileEvents =
        const <BattleVolatileEvent>[],
    BattleMoveExecution? execution,
    List<BattleStatusEvent> statusEvents = const <BattleStatusEvent>[],
    List<BattleFieldEvent> fieldEvents = const <BattleFieldEvent>[],
    List<BattleVolatileEvent> postExecutionVolatileEvents =
        const <BattleVolatileEvent>[],
  }) {
    // BE10A garde une granularité volontairement petite :
    // - on ne reconstruit plus l'ordre en UI ;
    // - on fabrique ici une chronologie ordonnée au moment où le moteur
    //   connaît réellement l'enchaînement causal ;
    // - on ne descend toutefois pas dans une micro-chronologie Showdown-like
    //   de chaque sous-étape interne.
    final timeline = <BattleTurnEvent>[
      ..._turnEventsFromVolatile(preExecutionVolatileEvents),
      if (execution != null) BattleTurnExecutionEvent(execution),
      ..._turnEventsFromStatus(statusEvents),
      ..._turnEventsFromField(fieldEvents),
      ..._turnEventsFromVolatile(postExecutionVolatileEvents),
    ];
    return List<BattleTurnEvent>.unmodifiable(timeline);
  }

  List<BattleTurnEvent> _turnEventsFromStatus(
    Iterable<BattleStatusEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnStatusEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromVolatile(
    Iterable<BattleVolatileEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnVolatileEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromField(
    Iterable<BattleFieldEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnFieldEvent.new),
    );
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
    required this.playerSide,
    required this.enemySide,
    required this.field,
    required this.rng,
    required this.turnResult,
  });

  final BattleSideState playerSide;
  final BattleSideState enemySide;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleTurnResult turnResult;
}

class _ResolvedSwitchAction {
  const _ResolvedSwitchAction({
    required this.side,
    required this.event,
  });

  final BattleSideState side;
  final BattleSwitchEvent event;
}

class _ResolvedPostTurnSwitchState {
  const _ResolvedPostTurnSwitchState({
    required this.playerSide,
    required this.enemySide,
    required this.switchEvents,
    required this.timeline,
  });

  final BattleSideState playerSide;
  final BattleSideState enemySide;
  final List<BattleSwitchEvent> switchEvents;
  final List<BattleTurnEvent> timeline;
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
    required this.timeline,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleMoveExecution? execution;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
  final List<BattleTurnEvent> timeline;
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
    required this.timeline,
  });

  final BattleCombatant combatant;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleTurnEvent> timeline;
}

class _ResolvedResidualPhase {
  const _ResolvedResidualPhase({
    required this.player,
    required this.enemy,
    required this.field,
    required this.statusEvents,
    required this.fieldEvents,
    required this.timeline,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleFieldState field;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleFieldEvent> fieldEvents;
  final List<BattleTurnEvent> timeline;
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

```

### `packages/map_battle/test/battle_state_topology_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _topologyStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

const _topologyMove = BattleMove(
  id: 'wait',
  name: 'Wait',
  power: 0,
);

BattleCombatant _combatant({
  required String speciesId,
  required int lineupIndex,
}) {
  return BattleCombatant(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    currentHp: 40,
    maxHp: 40,
    stats: _topologyStats,
    moves: const <BattleMove>[_topologyMove],
  );
}

void main() {
  group('BattleState Phase D side topology', () {
    test('legacy flat construction materializes canonical sides and slots', () {
      final state = BattleState(
        phase: BattlePhase.playerChoice,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
        ),
        playerReserve: <BattleCombatant>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
          ),
        ],
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
        ),
        enemyReserve: <BattleCombatant>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
          ),
        ],
      );

      expect(state.playerSide.id, equals(BattleSideId.player));
      expect(state.playerSide.activeSlot.ref,
          equals(const BattleSlotRef.active(BattleSideId.player)));
      expect(state.playerSide.active.speciesId, equals('lead_player'));
      expect(state.playerSide.reserve.single.speciesId, equals('bench_player'));

      expect(state.enemySide.id, equals(BattleSideId.enemy));
      expect(state.enemySide.activeSlot.ref,
          equals(const BattleSlotRef.active(BattleSideId.enemy)));
      expect(state.enemySide.active.speciesId, equals('lead_enemy'));
      expect(state.enemySide.reserve.single.speciesId, equals('bench_enemy'));

      // Compatibilité volontaire Phase D :
      // la topologie canonique change, mais le vieux chemin de lecture
      // `player/enemy/playerReserve/enemyReserve` reste encore disponible pour
      // limiter le blast radius runtime tant que Phase D ne demande pas plus.
      expect(state.player.speciesId, equals('lead_player'));
      expect(state.playerReserve.single.speciesId, equals('bench_player'));
      expect(state.enemy.speciesId, equals('lead_enemy'));
      expect(state.enemyReserve.single.speciesId, equals('bench_enemy'));
    });

    test('side-backed construction keeps the legacy getters coherent', () {
      final playerSide = BattleSideState.player(
        active: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
        ),
        reserve: <BattleCombatant>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
          ),
        ],
      );
      final enemySide = BattleSideState.enemy(
        active: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
        ),
        reserve: <BattleCombatant>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
          ),
        ],
      );

      final state = BattleState(
        phase: BattlePhase.playerChoice,
        playerSide: playerSide,
        enemySide: enemySide,
      );

      expect(state.side(BattleSideId.player), same(playerSide));
      expect(state.side(BattleSideId.enemy), same(enemySide));
      expect(state.player, same(playerSide.active));
      expect(state.playerReserve, same(playerSide.reserve));
      expect(state.enemy, same(enemySide.active));
      expect(state.enemyReserve, same(enemySide.reserve));
    });

    test('rejects swapped canonical side identities', () {
      final swappedPlayerSide = BattleSideState.enemy(
        active: _combatant(
          speciesId: 'wrong_player_side',
          lineupIndex: 0,
        ),
      );
      final enemySide = BattleSideState.enemy(
        active: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
        ),
      );

      expect(
        () => BattleState(
          phase: BattlePhase.playerChoice,
          playerSide: swappedPlayerSide,
          enemySide: enemySide,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects mixing canonical sides and legacy flat inputs', () {
      final playerSide = BattleSideState.player(
        active: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
        ),
      );

      expect(
        () => BattleState(
          phase: BattlePhase.playerChoice,
          playerSide: playerSide,
          player: _combatant(
            speciesId: 'legacy_player',
            lineupIndex: 0,
          ),
          enemy: _combatant(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

```

### `packages/map_battle/test/battle_decision_request_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

BattleMoveData _waitingMove() {
  return const BattleMoveData(
    id: 'wait',
    name: 'Wait',
    power: 0,
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.self,
    accuracy: BattleMoveAccuracy.alwaysHits(),
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleStatsSnapshot? stats,
  BattleVolatileState volatileState = const BattleVolatileState(),
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    volatileState: volatileState,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
  bool allowCapture = false,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
      allowCapture: allowCapture,
    ),
  );
}

void main() {
  group('BattleSession Phase C decision requests', () {
    test('a free turn exposes a turn choice request with moves and switches',
        () {
      final session = _session(
        allowCapture: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 40,
            ),
          ],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final request = session.decisionRequest;

      expect(request, isA<BattleTurnChoiceRequest>());
      final turnChoiceRequest = request as BattleTurnChoiceRequest;
      expect(turnChoiceRequest.actor, equals(BattleDecisionActor.player));
      expect(turnChoiceRequest.side, equals(BattleSideId.player));
      expect(
        turnChoiceRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(turnChoiceRequest.moveChoices, hasLength(1));
      expect(turnChoiceRequest.switchChoices, hasLength(1));
      expect(turnChoiceRequest.captureChoice, isA<PlayerBattleChoiceCapture>());
      expect(turnChoiceRequest.runChoice, isA<PlayerBattleChoiceRun>());
    });

    test('a fainted active with a reserve exposes a forced replacement request',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final request = session.decisionRequest;

      expect(request, isA<BattleForcedReplacementRequest>());
      final forcedReplacementRequest =
          request as BattleForcedReplacementRequest;
      expect(forcedReplacementRequest.side, equals(BattleSideId.player));
      expect(
        forcedReplacementRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(
        forcedReplacementRequest.reason,
        equals(BattleForcedReplacementReason.activeFainted),
      );
      expect(forcedReplacementRequest.switchChoices, hasLength(1));
      expect(
        forcedReplacementRequest.allowedChoices.single,
        isA<PlayerBattleChoiceSwitch>(),
      );
    });

    test('a forced recharge exposes a continue request with an explicit reason',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final request = session.decisionRequest;

      expect(request, isA<BattleContinueRequest>());
      final continueRequest = request as BattleContinueRequest;
      expect(continueRequest.side, equals(BattleSideId.player));
      expect(
        continueRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(
        continueRequest.reason,
        equals(BattleContinueReason.mustRecharge),
      );
      expect(continueRequest.allowedChoices, hasLength(1));
      expect(continueRequest.allowedChoices.single,
          isA<PlayerBattleChoiceContinue>());
    });

    test('request constructors reject mismatched side and slot attachments',
        () {
      expect(
        () => BattleContinueRequest(
          actor: BattleDecisionActor.player,
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.enemy),
          reason: BattleContinueReason.mustRecharge,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => BattleWaitRequest(
          actor: BattleDecisionActor.player,
          side: BattleSideId.player,
          slot: const BattleSlotRef(
            side: BattleSideId.player,
            slotIndex: 1,
          ),
          reason: BattleWaitReason.noLegalChoice,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('an illegal choice for the current request kind is rejected cleanly',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('forcedReplacement'),
          ),
        ),
      );
    });

    test('request transitions remain coherent across a forced continue turn',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(session.decisionRequest, isA<BattleContinueRequest>());

      final afterContinue =
          session.applyChoice(const PlayerBattleChoiceContinue());

      expect(afterContinue.decisionRequest, isA<BattleTurnChoiceRequest>());
    });

    test('a finished battle exposes an explicit wait request', () {
      final session = _session(
        player: _combatant(
          speciesId: 'player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 200,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          maxHp: 1,
          currentHp: 1,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final finishedSession =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(finishedSession.state.isFinished, isTrue);
      expect(finishedSession.decisionRequest, isA<BattleWaitRequest>());
      expect(
        (finishedSession.decisionRequest as BattleWaitRequest).reason,
        equals(BattleWaitReason.battleFinished),
      );
    });
  });
}

```

### `packages/map_battle/test/battle_switch_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

BattleMoveData _waitingMove() {
  return const BattleMoveData(
    id: 'wait',
    name: 'Wait',
    power: 0,
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.self,
    accuracy: BattleMoveAccuracy.alwaysHits(),
  );
}

BattleMoveData _tackle({
  int power = 40,
}) {
  return BattleMoveData(
    id: 'tackle',
    name: 'Tackle',
    power: power,
    type: 'normal',
    category: BattleMoveCategory.physical,
    target: BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleStatsSnapshot? stats,
  BattleMajorStatusState? majorStatus,
  BattleVolatileState volatileState = const BattleVolatileState(),
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    majorStatus: majorStatus,
    volatileState: volatileState,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
  bool allowCapture = false,
  BattleFieldState fieldState = const BattleFieldState(),
  BattleRng rng = const BattleSeededRng(),
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
      allowCapture: allowCapture,
      fieldState: fieldState,
    ),
    rng: rng,
  );
}

void main() {
  group('BattleSession BE10 switches and reserves', () {
    test('trainer enemy auto-replaces instead of ending the battle on first KO',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.isFinished, isFalse);
      expect(afterTurn.state.enemy.speciesId, equals('bench_enemy'));
      expect(
          afterTurn.state.enemyReserve.single.speciesId, equals('lead_enemy'));
      final switchEvent = afterTurn.state.currentTurn!.switchEvents.single;
      expect(switchEvent.side, equals(BattleSideId.enemy));
      expect(
        switchEvent.slot,
        equals(const BattleSlotRef.active(BattleSideId.enemy)),
      );
      expect(switchEvent.actor, equals('enemy'));
      expect(switchEvent.kind, equals(BattleSwitchEventKind.switched));
      expect(switchEvent.wasForced, isTrue);
    });

    test(
        'forced replacement choices override stale recharge/charge state on a KO active',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          volatileState: const BattleVolatileState(
            pendingCharge: BattlePendingChargeState(
              moveIndex: 0,
              moveId: 'beam',
              chargeStateId: 'charge',
            ),
          ),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'beam',
              name: 'Beam',
              power: 80,
              category: BattleMoveCategory.special,
              chargeThenStrikeEffect: BattleChargeThenStrikeEffect(
                chargeStateId: 'charge',
              ),
            ),
          ],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final choices = session.getAvailableChoices();

      expect(choices.whereType<PlayerBattleChoiceContinue>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceFight>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceSwitch>().single.reserveIndex,
          equals(0));

      final afterReplacement =
          session.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterReplacement.state.player.speciesId, equals('bench_player'));
      expect(afterReplacement.state.playerReserve.single.speciesId,
          equals('fainted_player'));
      expect(
        afterReplacement.state.playerReserve.single.volatileState.hasAny,
        isFalse,
      );
      expect(
        afterReplacement.state.currentTurn!.enemyAction,
        isA<BattleActionNone>(),
      );
      expect(
        afterReplacement.state.currentTurn!.switchEvents.single.wasForced,
        isTrue,
      );
      expect(
        afterReplacement.state.currentTurn!.switchEvents.single.side,
        equals(BattleSideId.player),
      );
    });

    test(
        'forced replacement choices expose only valid switches even when wild capture and run would normally be allowed',
        () {
      final session = _session(
        allowCapture: true,
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final choices = session.getAvailableChoices();

      expect(choices.whereType<PlayerBattleChoiceSwitch>(), hasLength(1));
      expect(choices.whereType<PlayerBattleChoiceFight>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceContinue>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceRun>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceCapture>(), isEmpty);
    });

    test('voluntary switch resolves before an opposing attack and redirects it',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 35,
          currentHp: 35,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 50,
            currentHp: 50,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          stats: _stats(speed: 100, attack: 80),
          moves: <BattleMoveData>[_tackle(power: 35)],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterTurn.state.player.speciesId, equals('bench_player'));
      expect(afterTurn.state.player.currentHp, lessThan(50));
      expect(
        afterTurn.state.playerReserve.single.speciesId,
        equals('lead_player'),
      );
      expect(
        afterTurn.state.playerReserve.single.currentHp,
        equals(35),
      );
      expect(
        afterTurn.state.currentTurn!.switchEvents.single.wasForced,
        isFalse,
      );
    });

    test('field state survives a voluntary switch turn', () {
      final session = _session(
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.rain,
            remainingTurns: 3,
          ),
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 3,
          ),
        ),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterTurn.state.player.speciesId, equals('bench_player'));
      expect(afterTurn.state.field.weather?.id, equals(BattleWeatherId.rain));
      expect(
        afterTurn.state.field.weather?.remainingTurns,
        equals(2),
      );
      expect(
        afterTurn.state.field.pseudoWeather?.id,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(
        afterTurn.state.field.pseudoWeather?.remainingTurns,
        equals(2),
      );
    });

    test(
        'switching out resets stages and volatile baggage but keeps hp, pp, and major status while tox counter restarts at 1',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 27,
          majorStatus: const BattleMajorStatusState.tox(toxicCounter: 4),
          stats: _stats(speed: 80),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'swords_dance',
              name: 'Swords Dance',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.self,
              selfStatStageChanges: <BattleStatStageChange>[
                BattleStatStageChange(stat: BattleStatId.attack, stages: 2),
              ],
            ),
            const BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 40,
              category: BattleMoveCategory.physical,
              currentPp: 7,
              pp: 35,
            ),
          ],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterBoost = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(afterBoost.state.player.statStages.attack, equals(2));

      final afterSwitchOut =
          afterBoost.applyChoice(const PlayerBattleChoiceSwitch(0));
      final benchedLead = afterSwitchOut.state.playerReserve.singleWhere(
        (combatant) => combatant.speciesId == 'lead_player',
      );
      expect(benchedLead.statStages.attack, equals(0));
      expect(
        benchedLead.currentHp,
        equals(afterBoost.state.player.currentHp),
      );
      expect(benchedLead.moves[1].currentPp, equals(7));
      expect(benchedLead.majorStatus!.id, equals(BattleMajorStatusId.tox));
      expect(benchedLead.majorStatus!.toxicCounter, equals(1));

      final afterSwitchBack =
          afterSwitchOut.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterSwitchBack.state.player.speciesId, equals('lead_player'));
      expect(afterSwitchBack.state.player.statStages.attack, equals(0));
      expect(afterSwitchBack.state.player.moves[1].currentPp, equals(7));
      expect(
        afterSwitchBack.state.currentTurn!.statusEvents
            .where(
              (event) =>
                  event.kind == BattleStatusEventKind.residualDamage &&
                  event.target == 'player',
            )
            .single
            .toxicCounter,
        equals(1),
      );
    });

    test(
        'double KO with reserves on both sides auto-replaces enemy and forces the player to switch',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.isFinished, isFalse);
      expect(afterTurn.state.player.isFainted, isTrue);
      expect(afterTurn.state.enemy.speciesId, equals('bench_enemy'));
      expect(
        afterTurn.state.currentTurn!.switchEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleSwitchEventKind>[
          BattleSwitchEventKind.switched,
          BattleSwitchEventKind.replacementRequired,
        ]),
      );
      expect(
        afterTurn.getAvailableChoices().whereType<PlayerBattleChoiceSwitch>(),
        hasLength(1),
      );
    });

    test('double KO with only an enemy reserve remains a defeat for the player',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.isFinished, isTrue);
      expect(afterTurn.state.outcome!.isDefeat, isTrue);
      expect(afterTurn.state.enemy.speciesId, equals('bench_enemy'));
    });
  });
}

```

### `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';

const _outcomeTestStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

void main() {
  group('applyRuntimeBattleOutcomeToGameState', () {
    test('writes back the exact party slot used for the battle handoff', () {
      const initialState = GameState(
        saveId: 'save-slot',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'slot_zero',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 40,
              knownMoveIds: <String>['a'],
              currentHp: 91,
            ),
            PlayerPokemon(
              speciesId: 'slot_one_active',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 20,
              knownMoveIds: <String>['b'],
              currentHp: 35,
            ),
            PlayerPokemon(
              speciesId: 'slot_two_stays_alive',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 22,
              knownMoveIds: <String>['c'],
              currentHp: 18,
            ),
          ],
        ),
      );

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: initialState,
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 1,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.defeat,
          playerCurrentHp: 0,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(91));
      expect(updatedState.party.members[1].currentHp, equals(0));
      expect(updatedState.party.members[2].currentHp, equals(18));
    });

    test(
        'writes back every engaged player lineup member to its exact runtime party slot after switches',
        () {
      const initialState = GameState(
        saveId: 'save-switch-lineup',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'slot_zero_bench',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 18,
              knownMoveIds: <String>['a'],
              currentHp: 44,
            ),
            PlayerPokemon(
              speciesId: 'slot_one_initial_active',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 20,
              knownMoveIds: <String>['b'],
              currentHp: 35,
            ),
            PlayerPokemon(
              speciesId: 'slot_two_unused',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 22,
              knownMoveIds: <String>['c'],
              currentHp: 18,
            ),
          ],
        ),
      );

      final outcome = BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: BattleState(
          phase: BattlePhase.finished,
          player: const BattleCombatant(
            speciesId: 'slot_zero_bench',
            lineupIndex: 1,
            level: 18,
            currentHp: 9,
            maxHp: 44,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(id: 'a', name: 'a', power: 10),
            ],
          ),
          playerReserve: const <BattleCombatant>[
            BattleCombatant(
              speciesId: 'slot_one_initial_active',
              lineupIndex: 0,
              level: 20,
              currentHp: 3,
              maxHp: 35,
              stats: _outcomeTestStats,
              moves: <BattleMove>[
                BattleMove(id: 'b', name: 'b', power: 10),
              ],
            ),
          ],
          enemy: const BattleCombatant(
            speciesId: 'enemy',
            level: 20,
            currentHp: 0,
            maxHp: 30,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(id: 'x', name: 'x', power: 10),
            ],
          ),
          currentTurn: null,
          outcome: null,
        ),
      );

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: initialState,
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 1,
          playerPartySlotIndicesByLineupIndex: const <int>[1, 0],
        ),
        outcome: outcome,
      );

      expect(updatedState.party.members[0].currentHp, equals(9));
      expect(updatedState.party.members[1].currentHp, equals(3));
      expect(updatedState.party.members[2].currentHp, equals(18));
    });

    test(
        'rejects the legacy mono-slot fallback when the final player lineup actually contains BE10 reserves',
        () {
      const initialState = GameState(
        saveId: 'save-switch-lineup-missing-mapping',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'slot_zero_bench',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 18,
              knownMoveIds: <String>['a'],
              currentHp: 44,
            ),
            PlayerPokemon(
              speciesId: 'slot_one_initial_active',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 20,
              knownMoveIds: <String>['b'],
              currentHp: 35,
            ),
          ],
        ),
      );

      final outcome = BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: BattleState(
          phase: BattlePhase.finished,
          player: const BattleCombatant(
            speciesId: 'slot_zero_bench',
            lineupIndex: 1,
            level: 18,
            currentHp: 9,
            maxHp: 44,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(id: 'a', name: 'a', power: 10),
            ],
          ),
          playerReserve: const <BattleCombatant>[
            BattleCombatant(
              speciesId: 'slot_one_initial_active',
              lineupIndex: 0,
              level: 20,
              currentHp: 3,
              maxHp: 35,
              stats: _outcomeTestStats,
              moves: <BattleMove>[
                BattleMove(id: 'b', name: 'b', power: 10),
              ],
            ),
          ],
          enemy: const BattleCombatant(
            speciesId: 'enemy',
            level: 20,
            currentHp: 0,
            maxHp: 30,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(id: 'x', name: 'x', power: 10),
            ],
          ),
          currentTurn: null,
          outcome: null,
        ),
      );

      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: initialState,
          context: RuntimeActiveBattleContext(
            request: _wildRequest(),
            playerPartyIndex: 1,
          ),
          outcome: outcome,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            contains('playerPartySlotIndicesByLineupIndex'),
          ),
        ),
      );
    });

    test('trainer victory writes player hp and marks trainer as defeated', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.victory,
          playerCurrentHp: 14,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(14));
      expect(
        updatedState.storyFlags.activeFlags,
        contains('trainer_defeated:ace_jules'),
      );
    });

    test('trainer defeat writes player hp without marking trainer defeated',
        () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.defeat,
          playerCurrentHp: 0,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(0));
      expect(
        updatedState.storyFlags.activeFlags,
        isNot(contains('trainer_defeated:ace_jules')),
      );
    });

    test('runaway writes player hp without marking trainer defeated', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.runaway,
          playerCurrentHp: 11,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(11));
      expect(
        updatedState.storyFlags.activeFlags,
        isNot(contains('trainer_defeated:ace_jules')),
      );
    });

    test('captured wild battle appends the pokemon and syncs caught/seen', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.captured,
          playerCurrentHp: 19,
          enemySpeciesId: 'wildmon',
          enemyLevel: 12,
          enemyCurrentHp: 7,
          enemyAbilityId: 'intimidate',
          enemyMoveIds: const <String>['scratch', 'leer'],
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(19));
      expect(updatedState.party.members, hasLength(3));

      final captured = updatedState.party.members.last;
      expect(captured.speciesId, equals('wildmon'));
      expect(captured.level, equals(12));
      expect(captured.abilityId, equals('intimidate'));
      expect(captured.natureId, equals('hardy'));
      expect(captured.knownMoveIds, equals(<String>['scratch', 'leer']));
      expect(captured.currentHp, equals(7));
      expect(
        updatedState.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
      );
      expect(updatedState.progression.caughtSpeciesIds, contains('wildmon'));
      expect(updatedState.progression.seenSpeciesIds, contains('wildmon'));
    });

    test('captured outcome removes the poke-ball entry when quantity reaches 0',
        () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState().copyWith(
          bag: const Bag(
            entries: <BagEntry>[
              BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
              BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
            ],
          ),
        ),
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.captured,
          playerCurrentHp: 19,
          enemySpeciesId: 'wildmon',
          enemyLevel: 12,
          enemyCurrentHp: 7,
          enemyAbilityId: 'intimidate',
          enemyMoveIds: const <String>['scratch'],
        ),
      );

      expect(
        updatedState.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
      );
    });

    test('captured outcome is rejected for trainer battles', () {
      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: _baseState(),
          context: RuntimeActiveBattleContext(
            request: _trainerRequest(trainerId: 'ace_jules'),
            playerPartyIndex: 0,
          ),
          outcome: _finishedOutcome(
            type: BattleOutcomeType.captured,
            playerCurrentHp: 19,
            enemySpeciesId: 'wildmon',
            enemyLevel: 12,
            enemyCurrentHp: 7,
            enemyAbilityId: 'intimidate',
            enemyMoveIds: const <String>['scratch'],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('captured outcome is rejected when the party is already full', () {
      final fullPartyState = _baseState().copyWith(
        party: PlayerParty(
          members: <PlayerPokemon>[
            ..._baseState().party.members,
            const PlayerPokemon(
              speciesId: 'party_2',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_3',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_4',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_5',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
          ],
        ),
      );

      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: fullPartyState,
          context: RuntimeActiveBattleContext(
            request: _wildRequest(),
            playerPartyIndex: 0,
          ),
          outcome: _finishedOutcome(
            type: BattleOutcomeType.captured,
            playerCurrentHp: 19,
            enemySpeciesId: 'wildmon',
            enemyLevel: 12,
            enemyCurrentHp: 7,
            enemyAbilityId: 'intimidate',
            enemyMoveIds: const <String>['scratch'],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('captured outcome is rejected when the bag has no poke-ball', () {
      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: _baseState().copyWith(
            bag: const Bag(
              entries: <BagEntry>[
                BagEntry(
                  itemId: 'potion',
                  categoryId: 'medicine',
                  quantity: 3,
                ),
              ],
            ),
          ),
          context: RuntimeActiveBattleContext(
            request: _wildRequest(),
            playerPartyIndex: 0,
          ),
          outcome: _finishedOutcome(
            type: BattleOutcomeType.captured,
            playerCurrentHp: 19,
            enemySpeciesId: 'wildmon',
            enemyLevel: 12,
            enemyCurrentHp: 7,
            enemyAbilityId: 'intimidate',
            enemyMoveIds: const <String>['scratch'],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('applyRuntimeDefeatRecoveryToGameState', () {
    test(
        'revives the exact battle slot to 1 HP when the whole party is KO after defeat',
        () {
      const defeatedState = GameState(
        saveId: 'whiteout-lite',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'slot_zero',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 12,
              knownMoveIds: <String>['growl'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'active_slot',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 18,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'slot_two',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 17,
              knownMoveIds: <String>['water_gun'],
              currentHp: 0,
            ),
          ],
        ),
      );

      final recoveredState = applyRuntimeDefeatRecoveryToGameState(
        gameState: defeatedState,
        playerPartyIndex: 1,
      );

      expect(recoveredState.party.members[0].currentHp, equals(0));
      expect(recoveredState.party.members[1].currentHp, equals(1));
      expect(recoveredState.party.members[2].currentHp, equals(0));
    });

    test(
        'revives the switched-in active slot instead of the original handoff slot after BE10 switches',
        () {
      const defeatedState = GameState(
        saveId: 'whiteout-lite-switched-active',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'initial_active_slot',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 12,
              knownMoveIds: <String>['growl'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'switched_in_active_slot',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 18,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'unused_slot',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 17,
              knownMoveIds: <String>['water_gun'],
              currentHp: 0,
            ),
          ],
        ),
      );

      final recoveredState = applyRuntimeDefeatRecoveryToGameState(
        gameState: defeatedState,
        playerPartyIndex: 0,
        activePlayerLineupIndex: 1,
        playerPartySlotIndicesByLineupIndex: const <int>[0, 1],
      );

      expect(recoveredState.party.members[0].currentHp, equals(0));
      expect(recoveredState.party.members[1].currentHp, equals(1));
      expect(recoveredState.party.members[2].currentHp, equals(0));
    });

    test('does not heal the party when another member is already usable', () {
      const defeatedState = GameState(
        saveId: 'whiteout-lite-benched',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'active_slot',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 18,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'bench_survivor',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 22,
              knownMoveIds: <String>['water_gun'],
              currentHp: 9,
            ),
          ],
        ),
      );

      final recoveredState = applyRuntimeDefeatRecoveryToGameState(
        gameState: defeatedState,
        playerPartyIndex: 0,
      );

      expect(recoveredState.party.members[0].currentHp, equals(0));
      expect(recoveredState.party.members[1].currentHp, equals(9));
    });
  });
}

GameState _baseState() {
  return const GameState(
    saveId: 'save-1',
    bag: Bag(
      entries: <BagEntry>[
        BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
        BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
      ],
    ),
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
        PlayerPokemon(
          speciesId: 'benchmon',
          natureId: 'hardy',
          abilityId: 'pressure',
          level: 18,
          knownMoveIds: <String>['leer'],
          currentHp: 17,
        ),
      ],
    ),
  );
}

BattleOutcome _finishedOutcome({
  required BattleOutcomeType type,
  required int playerCurrentHp,
  String enemySpeciesId = 'aquafi',
  int enemyLevel = 18,
  int enemyCurrentHp = 0,
  String enemyAbilityId = 'torrent',
  List<String> enemyMoveIds = const <String>['water_gun'],
}) {
  final finalState = BattleState(
    phase: BattlePhase.finished,
    player: BattleCombatant(
      speciesId: 'sproutle',
      level: 12,
      currentHp: playerCurrentHp,
      maxHp: 32,
      stats: _outcomeTestStats,
      moves: const <BattleMove>[
        BattleMove(id: 'growl', name: 'Growl', power: 0),
      ],
    ),
    enemy: BattleCombatant(
      speciesId: enemySpeciesId,
      level: enemyLevel,
      currentHp: enemyCurrentHp,
      maxHp: 35,
      stats: _outcomeTestStats,
      abilityId: enemyAbilityId,
      moves: enemyMoveIds
          .map(
            (moveId) => BattleMove(
              id: moveId,
              name: moveId,
              power: 10,
            ),
          )
          .toList(growable: false),
    ),
    currentTurn: null,
    outcome: null,
  );

  return BattleOutcome(
    type: type,
    finalState: finalState,
  );
}

WildBattleStartRequest _wildRequest() {
  return const WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: 'wildmon',
    level: 12,
    minLevel: 12,
    maxLevel: 12,
    weight: 30,
    playerPos: GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest({required String trainerId}) {
  return TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: trainerId,
    npcEntityId: 'npc_ace',
    mapId: 'field_map',
    playerPos: const GridPos(x: 1, y: 1),
  );
}

```

---

## 20. État git final utile

Commande : `git status --short --untracked-files=all`

```text
 M packages/map_battle/lib/map_battle.dart
 M packages/map_battle/lib/src/battle_decision.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_state.dart
 M packages/map_battle/lib/src/battle_switch.dart
 M packages/map_battle/test/battle_decision_request_test.dart
 M packages/map_battle/test/battle_switch_test.dart
 M packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
?? packages/map_battle/lib/src/battle_topology.dart
?? packages/map_battle/test/battle_state_topology_test.dart
?? reports/phase-d-side-slot-minimal-report.md
```

Commande : `git diff --stat`

```text
 packages/map_battle/lib/map_battle.dart            |   1 +
 packages/map_battle/lib/src/battle_decision.dart   |  83 ++++--
 packages/map_battle/lib/src/battle_session.dart    | 253 +++++++++---------
 packages/map_battle/lib/src/battle_state.dart      | 286 +++++++++++++++++++--
 packages/map_battle/lib/src/battle_switch.dart     |  23 +-
 .../test/battle_decision_request_test.dart         |  41 +++
 packages/map_battle/test/battle_switch_test.dart   |   9 +
 .../test/runtime_battle_outcome_apply_test.dart    |  16 +-
 8 files changed, 520 insertions(+), 192 deletions(-)
```

Commande : `git ls-files --others --exclude-standard`

```text
packages/map_battle/lib/src/battle_topology.dart
packages/map_battle/test/battle_state_topology_test.dart
reports/phase-d-side-slot-minimal-report.md
```

---

## 21. Checklist finale

- [x] ai-je audité le repo réel avant de modifier ?
- [x] ai-je identifié où la topologie plate restait vraiment bloquante ?
- [x] ai-je choisi un design unique et l’ai-je réellement implémenté ?
- [x] le moteur n’est-il plus seulement structuré autour de `player/reserve/enemy/reserve` ?
- [x] existe-t-il une vraie topologie `Side` locale utile ?
- [x] existe-t-il une vraie notion de slot minimal utile ?
- [x] les requests Phase C restent-elles cohérentes ?
- [x] les switches/remplacements restent-ils honnêtes ?
- [x] ai-je évité d’ouvrir Phase E/F/H en douce ?
- [x] ai-je évité de toucher `examples/`, `map_editor`, `map_core` ?
- [x] ai-je relancé analyze/tests/validations utiles localement ?
- [x] ai-je rerun après correction post-review ?
- [x] ai-je utilisé un sub-agent d’audit/design ?
- [x] ai-je utilisé un reviewer séparé ?
- [x] ai-je intégré les remarques valides du reviewer ?
- [x] ai-je inclus le contenu complet de tous les fichiers touchés (hors report lui-même) ?
- [x] ai-je explicitement signalé ce qui reste incertain ?
- [x] ai-je évité toute écriture Git interdite ?

---

## Décision finale

**Phase D réussie.**

Ce lot débloque proprement la suite en donnant enfin au moteur :
- une topologie singles honnête par side
- un slot actif explicite
- des requests et remplacements attachés à cette topologie

Cela prépare **réellement** Phase E/F, sans les ouvrir en douce.
