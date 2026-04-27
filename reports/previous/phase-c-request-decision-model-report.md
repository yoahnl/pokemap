# Phase C — Request / Decision Model Report

## 1. Résumé exécutif honnête

Ce lot apporte un vrai progrès de fondation, pas un simple rebranding.

Ce qui a réellement changé :
- `map_battle` expose maintenant un vrai contrat explicite de décision joueur via `BattleSession.decisionRequest`.
- Le moteur distingue explicitement :
  - `BattleTurnChoiceRequest`
  - `BattleForcedReplacementRequest`
  - `BattleContinueRequest`
  - `BattleWaitRequest`
- `applyChoice()` valide désormais le choix entrant contre la request courante avant de résoudre le tour.
- `getAvailableChoices()` est conservé uniquement comme seam de compatibilité locale, dérivé de la vraie request.
- L’overlay runtime consomme désormais `decisionRequest` pour afficher le prompt de décision et pour formater les choix sans heuristiques métier cachées.

Ce qui n’a pas été changé :
- pas de vrai `Side` / `slot`
- pas de hazards / side conditions / slot conditions
- pas de `selfSwitch` / `forceSwitch`
- pas de refonte de queue d’actions
- pas d’event engine général
- pas de changement dans `map_editor`
- pas de changement dans `examples/`
- pas de changement nécessaire dans `playable_map_game.dart`

Verdict honnête :
- oui, c’est un vrai lot Phase C ;
- non, ce n’est pas encore Phase D ;
- le moteur publie enfin le type de décision attendu au lieu de demander au runtime de le deviner depuis une liste plate.

## 2. Pré-gates exécutés + résultats

Pré-gates git read-only exécutés au début :
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git ls-files --others --exclude-standard`

Résultat initial constaté :
- sortie vide sur les trois commandes ;
- interprétation honnête : worktree propre au moment du démarrage Phase C.

Pré-audit code exécuté :
- lecture de `packages/map_battle/lib/src/battle_action.dart`
- lecture de `packages/map_battle/lib/src/battle_state.dart`
- lecture de `packages/map_battle/lib/src/battle_resolution.dart`
- lecture de `packages/map_battle/lib/src/battle_session.dart`
- lecture de `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- lecture de `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- lecture des tests battle/runtime ciblés autour des choices, switches, volatiles, overlay et smoke Phase A
- recherches `rg` sur `getAvailableChoices`, `PlayerBattleChoice`, `currentTurn`, `pendingCharge`, `mustRecharge`, `timeline`, `switchEvents`

## 3. Méthode réelle utilisée

Méthode réellement suivie :
1. audit du protocole implicite battle/runtime
2. plan local borné Phase C
3. TDD ciblé sur le nouveau contrat
4. implémentation minimale du request model
5. migration overlay/runtime locale
6. validations locales ciblées
7. review séparée
8. autocritique finale

Skills/workflows réellement utilisés :
- `using-superpowers` : rappel de discipline sur le choix et l’ordre des skills
- `brainstorming` : utilisé comme garde-fou de design, sans bloquer artificiellement le lot sur une spec séparée puisque le prompt donnait déjà un cahier des charges détaillé et demandait l’exécution immédiate
- `writing-plans` : transposé ici via un plan local dans la session et `update_plan`, sans créer un document de plan séparé hors scope
- `test-driven-development` : tests rouges d’abord sur le request model et l’overlay
- `requesting-code-review` : review séparée finale via sub-agent
- `verification-before-completion` : reruns réels des analyze/tests/smoke avant conclusion
- `game-studio` : utilisé uniquement comme garde-fou de frontière runtime/overlay ; aucune dérive vers un chantier UI cosmétique

Ce que je n’ai pas fait :
- pas de faux playtest navigateur via Game Studio, car le runtime concerné est Flutter/Flame local et la vérité utile passait ici par les tests ciblés + smoke Phase A déjà canonique

## 4. Audit réel avant code

### 4.1. Où vivait le protocole implicite

Confirmé par lecture de code :
- le protocole implicite vivait d’abord dans `BattleSession.getAvailableChoices()`.
- l’ordre métier réel était :
  1. remplacement forcé si actif joueur K.O. avec réserve valide
  2. `Continue` si `mustRecharge` ou `pendingCharge`
  3. sinon menu libre `Fight + Switch + Capture + Run`
- `applyChoice()` revalidait ensuite défensivement cette même hiérarchie.

Fichiers clés :
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart`

### 4.2. Familles déjà présentes implicitement

Confirmé par lecture de code et tests :
- tour libre avec sélection de move
- switch volontaire minimal
- remplacement forcé après K.O.
- continuation forcée BE8 (`mustRecharge` / `pendingCharge`)
- absence d’un vrai request model pour représenter ces états distinctement

### 4.3. Ambiguïtés réelles avant Phase C

Confirmé par lecture de code :
- `PlayerBattleChoiceSwitch` servait à la fois pour le switch volontaire et le remplacement forcé.
- `PlayerBattleChoiceContinue` masquait deux réalités différentes : recharge et libération d’un move chargé.
- l’overlay utilisait encore des heuristiques métier :
  - `state.player.isFainted` pour décider du libellé “Switch” vs “Remplacer”
  - `volatileState.pendingCharge` / `mustRecharge` pour deviner le sens de `Continue`
- `_choiceToAction()` contenait encore un fallback mensonger pour `Fight(moveIndex)` invalide vers le slot `0`.

### 4.4. Faux positifs écartés

- `BattleTurnResult.timeline` n’était pas le sujet à refondre : la chronologie BE10A était déjà honnête.
- `PlayableMapGame` n’avait pas de logique de décision complexe à migrer : il forwarde simplement un `PlayerBattleChoice` à la session. Le vrai problème de contrat était dans `BattleSession` et l’overlay.
- un “switch request” autonome côté moteur aurait été artificiel dans l’architecture actuelle, faute de sous-menu de switch ou d’état intermédiaire honnête.

## 5. Nouveau modèle retenu

### 5.1. Structure exacte

Nouveau fichier :
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart`

Contrat retenu :
- `BattleDecisionActor`
- `BattleDecisionRequestKind`
- `BattleForcedReplacementReason`
- `BattleContinueReason`
- `BattleWaitReason`
- `BattleDecisionRequest` (sealed base)
- `BattleTurnChoiceRequest`
- `BattleForcedReplacementRequest`
- `BattleContinueRequest`
- `BattleWaitRequest`

Source de vérité moteur :
- `BattleSession.decisionRequest`

Compatibilité conservée :
- `BattleSession.getAvailableChoices()` retourne encore `decisionRequest.allowedChoices`

### 5.2. Pourquoi ce design

Confirmé par lecture de code et implémentation :
- il correspond exactement aux vraies familles de décision déjà présentes implicitement ;
- il garde `PlayerBattleChoice` comme réponse UI/runtime, donc le blast radius reste borné ;
- il ne crée pas de faux `Side`, de faux `slot`, ni de mini queue ;
- il permet au runtime/overlay de connaître explicitement le type de décision attendu ;
- il améliore la validation des choix sans ouvrir une nouvelle taxonomie d’actions battle lourde.

### 5.3. Ce que j’ai refusé

Refus explicites :
- un vrai `switch request` autonome comme nouvelle phase moteur
- un stockage du request directement dans `BattleState`
- un système générique de validations séparé du moteur
- une migration large de `PlayableMapGame`
- une introduction prématurée de `Side` / `slot`

Pourquoi :
- un `switch request` autonome aurait menti sur l’architecture actuelle, qui ne possède pas de sous-menu de switch honnête ;
- stocker le request dans `BattleState` aurait élargi inutilement le contrat immutable sur tout le repo alors que le request est encore dérivable localement et utile surtout au bord de `BattleSession` ;
- ouvrir `Side` / `slot` maintenant aurait violé la feuille de route Phase C.

## 6. Critique explicite du prompt

Ce qui était juste :
- exiger un vrai request model et pas un simple renommage cosmétique ;
- exiger la migration du runtime/overlay vers cette nouvelle source de vérité ;
- interdire d’ouvrir Phase D en douce ;
- exiger une validation plus robuste des choix.

Ce qui était discutable :
- la liste d’exemples suggérait presque un `switch request` autonome ; dans le repo réel, cela aurait été trompeur sans sous-menu de switch ou état intermédiaire honnête.

Ce qui aurait été dangereux si suivi aveuglément :
- toucher `playable_map_game.dart` “par principe” alors que la logique ambiguë vivait surtout dans `BattleSession` et `BattleOverlayComponent`.

Recadrage retenu :
- un vrai request model au bord de `BattleSession`
- un `BattleTurnChoiceRequest` qui porte explicitement moves + switchs volontaires + issues sauvages
- pas de faux type `switchRequest` autonome

## 7. Périmètre inclus / exclu

### Inclus
- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/test/battle_decision_request_test.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- ce report

### Exclu volontairement
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `examples/`
- `packages/map_editor`
- `packages/map_core`

Raison :
- non nécessaires pour faire Phase C proprement dans le repo réel.

## 8. Plan local retenu

Plan effectivement retenu :
1. confirmer le protocole implicite actuel dans `BattleSession`
2. introduire un contrat explicite au bord de `BattleSession`
3. garder `PlayerBattleChoice` comme réponse et `getAvailableChoices()` comme compat
4. brancher l’overlay sur la request, pas sur des heuristiques de KO/volatiles
5. durcir `applyChoice()` et supprimer le fallback mensonger sur `Fight(0)`
6. rerun battle/runtime/smoke

## 9. Justification fichier par fichier

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart`

Pourquoi modifié :
- nouveau contrat explicite Phase C
- cœur du request model

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`

Pourquoi modifié :
- nouvelle source de vérité `decisionRequest`
- `getAvailableChoices()` converti en adaptateur de compatibilité
- validation des choix recentrée sur la request courante
- suppression du fallback mensonger de `_choiceToAction()`

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart`

Pourquoi modifié :
- documentation alignée sur la nouvelle source de vérité

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/map_battle.dart`

Pourquoi modifié :
- export du nouveau contrat
- exemple d’usage aligné sur `decisionRequest`

### `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_decision_request_test.dart`

Pourquoi créé :
- tests rouges/verts du nouveau contrat Phase C

### `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`

Pourquoi modifié :
- l’overlay consomme maintenant explicitement la request
- prompt et libellés ne dépendent plus d’heuristiques métier cachées

### `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`

Pourquoi modifié :
- verrouille que l’overlay consomme le type de request et garde la chronologie BE10A

## 10. Classification des blockers réellement adressés

### Coverage / structure

Confirmé par lecture de code :
- ce lot n’adresse pas un blocker de couverture data ;
- il adresse un blocker de fondation léger mais réel : le request/decision model trop implicite.

### Ce qui reste structurellement hors lot

Confirmé par lecture de code, non traité :
- `Side` / `slot`
- side conditions / slot conditions
- queue d’actions enrichie
- event engine
- targeting riche

## 11. Commandes réellement exécutées

Pré-gates / audit :
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git ls-files --others --exclude-standard`
- `rg -n "getAvailableChoices|PlayerBattleChoice|BattlePhase|currentTurn|forced replacement|mustRecharge|pendingCharge|Continue|locked|wait" packages/map_battle packages/map_runtime`
- `sed -n '1,260p' packages/map_battle/lib/src/battle_action.dart`
- `sed -n '1,260p' packages/map_battle/lib/src/battle_state.dart`
- `sed -n '1,320p' packages/map_battle/lib/src/battle_resolution.dart`
- `sed -n '1,920p' packages/map_battle/lib/src/battle_session.dart`
- `sed -n '1,760p' packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `sed -n '3038,3285p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `sed -n '1,560p' packages/map_battle/test/battle_switch_test.dart`
- `sed -n '1,280p' packages/map_battle/test/battle_session_test.dart`
- `sed -n '1,280p' packages/map_runtime/test/battle_overlay_component_test.dart`
- `sed -n '1,260p' packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`

TDD rouge :
- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_decision_request_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_overlay_component_test.dart`

Format :
- `cd packages/map_battle && /opt/homebrew/bin/dart format lib/map_battle.dart lib/src/battle_decision.dart lib/src/battle_session.dart lib/src/battle_state.dart test/battle_decision_request_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/dart format lib/src/presentation/flame/battle_overlay_component.dart test/battle_overlay_component_test.dart`

Validation :
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze lib/map_battle.dart lib/src/battle_decision.dart lib/src/battle_session.dart lib/src/battle_state.dart test/battle_decision_request_test.dart test/battle_session_test.dart test/battle_switch_test.dart test/battle_volatiles_test.dart test/battle_session_flow_test.dart`
- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_decision_request_test.dart test/battle_session_test.dart test/battle_switch_test.dart test/battle_volatiles_test.dart test/battle_session_flow_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/presentation/flame/battle_overlay_component.dart lib/src/presentation/flame/playable_map_game.dart test/battle_overlay_component_test.dart test/phase_a_golden_battle_slice_smoke_test.dart test/runtime_battle_setup_mapper_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_overlay_component_test.dart test/runtime_battle_setup_mapper_test.dart test/phase_a_golden_battle_slice_smoke_test.dart`

## 12. Résultats réels

### TDD rouge initial

Confirmé par exécution :
- `battle_decision_request_test.dart` cassait parce que `decisionRequest` et les nouveaux types n’existaient pas encore.
- `battle_overlay_component_test.dart` cassait parce que le helper de prompt et la source de vérité request n’existaient pas encore.

### Analyze battle

Confirmé par exécution :
- vert après suppression du helper mort `_forcedPlayerChoice`
- sortie finale : `No issues found!`

### Tests battle

Confirmé par exécution :
- vert
- suite ciblée rerunée : `battle_decision_request_test.dart`, `battle_session_test.dart`, `battle_switch_test.dart`, `battle_volatiles_test.dart`, `battle_session_flow_test.dart`

### Analyze runtime

Confirmé par exécution :
- vert
- sortie : `Analyzing 5 items... No issues found!`

### Tests runtime

Confirmé par exécution :
- vert
- suite ciblée rerunée : `battle_overlay_component_test.dart`, `runtime_battle_setup_mapper_test.dart`, `phase_a_golden_battle_slice_smoke_test.dart`

### Smoke Phase A

Confirmé par exécution :
- vert via `phase_a_golden_battle_slice_smoke_test.dart`
- pas de régression constatée du golden slice

## 13. Incidents rencontrés

- Les tout premiers appels parallèles `git status --short`, `git diff --stat`, `git ls-files --others --exclude-standard` sont revenus sans sortie ; j’ai retenu l’interprétation minimale et honnête : worktree propre au démarrage.
- Le premier lancement de la review séparée a échoué à cause de la limite de threads sub-agents ; j’ai fermé les agents d’audit terminés avant de relancer la review.
- Une régression de message d’erreur est apparue pendant les tests battle : le nouveau rejet par request type rendait le cas “move à 0 PP” moins précis. J’ai corrigé cela en gardant la validation par request tout en restaurant un message métier clair.

## 14. Décisions retenues / rejetées

### Retenues
- request model au bord de `BattleSession`
- compat locale `getAvailableChoices()`
- overlay branché sur la request
- validation des choix contre la request courante
- suppression du fallback mensonger de `_choiceToAction()`

### Rejetées
- stocker la request dans `BattleState`
- modifier `PlayableMapGame`
- créer un faux `switch request` autonome
- ouvrir Side/slot
- ouvrir une queue/action model plus riche

## 15. Retour du sub-agent d’audit/design

### Audit map_battle
- Le protocole implicite exact était bien une hiérarchie stricte dans `getAvailableChoices()`.
- Les ambiguïtés principales confirmées : surcharge sémantique de `Switch`, surcharge de `Continue`, fallback mensonger de `_choiceToAction()`.
- Recommandation principale retenue : ajouter une API de requête explicite au bord de `BattleSession` tout en gardant `PlayerBattleChoice` comme réponse.

Ce que j’ai retenu :
- cœur du diagnostic
- localisation de la vraie dette
- nécessité de supprimer le fallback `_choiceToAction()`

Ce que j’ai rejeté ou recadré :
- l’audit suggérait implicitement 3 variantes seulement ; j’ai gardé un `BattleWaitRequest` supplémentaire, car le prompt demandait aussi un état explicite “aucune décision libre attendue”, et `BattlePhase.resolving` existe déjà dans le repo.

### Audit runtime/UI
- Le runtime productif dépendait encore surtout de la liste plate dans `BattleOverlayComponent`.
- Les heuristiques confirmées : `player.isFainted` pour switch vs replacement, `pendingCharge` / `mustRecharge` pour interpréter `Continue`.
- Recommandation principale retenue : migrer l’overlay, pas `PlayableMapGame`.

Ce que j’ai retenu :
- ciblage de l’overlay comme point de migration réel
- laisser `PlayableMapGame` quasi intact
- conserver `getAvailableChoices()` comme seam temporaire de compatibilité

Ce que j’ai rejeté :
- créer un adaptateur purement runtime `BattleOverlayRequest.fromSession(session)` ; cela aurait déplacé les heuristiques au lieu de les supprimer.

## 16. Retour du reviewer séparé

Reviewer séparé : `Halley`

Synthèse réelle :
- aucun finding majeur confirmé sur le périmètre Phase C
- le reviewer confirme que :
  - `BattleSession.decisionRequest` devient bien la source de vérité ;
  - `applyChoice()` valide désormais contre le type de request ;
  - l’overlay consomme ce contrat au lieu d’inférer depuis une liste plate ;
  - aucune ouverture cachée évidente de Phase D n’est confirmée dans les fichiers revus.

Findings retenus :
- aucun finding bloquant ou important confirmé

## 17. Corrections appliquées après review

- aucune correction code supplémentaire n’a été nécessaire après la review séparée
- en conséquence, pas de rerun additionnel après review : aucune ligne de code n’a changé après ce retour

## 18. Autocritique finale

Risques restants :
- `BattleWaitRequest.resolvingTurn` reste surtout défensif dans le repo actuel, car `BattlePhase.resolving` n’est pas encore une vraie phase observable côté runtime.
- `getAvailableChoices()` est encore exposé publiquement ; même si la source de vérité a changé, il reste possible qu’un call site futur reparte sur ce seam par confort.
- le runtime ne fait encore qu’exposer la request dans l’overlay ; il n’existe pas encore de modèle de request plus profond côté host.

Limites du lot :
- pas de Side / slot
- pas de refonte du flow `PlayableMapGame`
- pas de formalisme de validation plus riche qu’un `StateError`
- pas d’API dédiée pour “sérialiser” la request vers une UI plus avancée

Ce qui bloque encore avant D/E/F :
- topologie `Side` / `slot`
- request model plus riche que le seul joueur singles local
- event/condition engine
- queue de résolution plus souple

Verdict d’autocritique :
- lot Phase C honnête et utile ;
- fondation réelle mais volontairement petite ;
- il prépare D sans ouvrir D en douce.

## 19. Contenu complet de tous les fichiers modifiés / créés / supprimés

Le report s’exclut lui-même de cette annexe pour éviter la récursion infinie.

## 20. État git final utile

### `git status --short --untracked-files=all`

```text
 M packages/map_battle/lib/map_battle.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_state.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
?? packages/map_battle/lib/src/battle_decision.dart
?? packages/map_battle/test/battle_decision_request_test.dart
?? reports/phase-c-request-decision-model-report.md
```

### `git diff --stat -- <phase-c-files + report>`

```text
 packages/map_battle/lib/map_battle.dart            |   6 +-
 packages/map_battle/lib/src/battle_session.dart    | 286 +++++++++++++--------
 packages/map_battle/lib/src/battle_state.dart      |   8 +-
 .../flame/battle_overlay_component.dart            |  66 +++--
 .../test/battle_overlay_component_test.dart        |  87 +++++++
 5 files changed, 317 insertions(+), 136 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
packages/map_battle/lib/src/battle_decision.dart
packages/map_battle/test/battle_decision_request_test.dart
reports/phase-c-request-decision-model-report.md
```

## 21. Checklist finale

- [x] ai-je audité le repo réel avant de modifier ?
- [x] ai-je identifié où vivait le protocole implicite ?
- [x] ai-je introduit un vrai request / decision model ?
- [x] ai-je gardé le lot strictement Phase C ?
- [x] ai-je évité d’ouvrir Phase D en douce ?
- [x] ai-je migré l’overlay vers la nouvelle source de vérité ?
- [x] ai-je gardé une compat locale bornée au lieu d’un grand refactor ?
- [x] ai-je rendu la validation des choix plus explicite ?
- [x] ai-je évité toute nouvelle grosse mécanique battle ?
- [x] ai-je évité toute écriture Git interdite ?
- [x] ai-je relancé analyze/tests utiles localement ?
- [x] ai-je rerun le smoke test Phase A ?
- [x] ai-je utilisé un sub-agent d’audit/design ?
- [x] ai-je utilisé un reviewer séparé ?
- [x] ai-je intégré les remarques valides ?
- [x] ai-je signalé ce qui reste incertain ?
- [x] ai-je inclus le contenu complet de tous les fichiers touchés (hors report lui-même) ?

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/map_battle.dart`

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

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart`

```dart
import 'battle_action.dart';

/// Acteur concerné par une requête de décision.
///
/// Phase C reste volontairement strictement singles :
/// - seul le joueur humain reçoit aujourd'hui une vraie requête de décision ;
/// - l'ennemi reste piloté localement par le moteur ;
/// - introduire cet enum maintenant garde toutefois le contrat explicite
///   sans ouvrir de vraie topologie `Side`/`slot`.
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
  const BattleDecisionRequest({
    required this.actor,
    required this.kind,
  });

  /// L'acteur qui doit répondre à cette requête.
  final BattleDecisionActor actor;

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
    required super.actor,
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
    required super.actor,
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
  const BattleContinueRequest({
    required super.actor,
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
  const BattleWaitRequest({
    required super.actor,
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

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`

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
    if (state.phase == BattlePhase.finished) {
      return const BattleWaitRequest(
        actor: BattleDecisionActor.player,
        reason: BattleWaitReason.battleFinished,
      );
    }

    if (state.phase != BattlePhase.playerChoice) {
      return const BattleWaitRequest(
        actor: BattleDecisionActor.player,
        reason: BattleWaitReason.resolvingTurn,
      );
    }

    final replacementChoices = _availableForcedReplacementChoices();
    if (replacementChoices.isNotEmpty) {
      return BattleForcedReplacementRequest(
        actor: BattleDecisionActor.player,
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
      return const BattleWaitRequest(
        actor: BattleDecisionActor.player,
        reason: BattleWaitReason.activeFaintedWithoutReplacement,
      );
    }

    final volatileState = state.player.volatileState;
    if (volatileState.pendingCharge != null) {
      return const BattleContinueRequest(
        actor: BattleDecisionActor.player,
        reason: BattleContinueReason.pendingChargeRelease,
      );
    }
    if (volatileState.mustRecharge) {
      return const BattleContinueRequest(
        actor: BattleDecisionActor.player,
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
      return const BattleWaitRequest(
        actor: BattleDecisionActor.player,
        reason: BattleWaitReason.noLegalChoice,
      );
    }

    return BattleTurnChoiceRequest(
      actor: BattleDecisionActor.player,
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
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture) {
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
    final timeline = <BattleTurnEvent>[];

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
      timeline.add(BattleTurnSwitchEvent(replacement.event));
    }

    if (updatedPlayer.isFainted &&
        !updatedEnemy.isFainted &&
        _firstUsableReserveIndex(updatedPlayerReserve) != null) {
      final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
        actor: 'player',
        fromSpeciesId: updatedPlayer.speciesId,
      );
      switchEvents.add(replacementRequiredEvent);
      timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
    }

    return _ResolvedPostTurnSwitchState(
      player: updatedPlayer,
      playerReserve: updatedPlayerReserve,
      enemy: updatedEnemy,
      enemyReserve: updatedEnemyReserve,
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
              actor: 'player',
              active: player,
              reserve: playerReserve,
              reserveIndex: reserveIndex,
              wasForced: false,
            );
            player = resolution.active;
            playerReserve = resolution.reserve;
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
              actor: 'enemy',
              active: enemy,
              reserve: enemyReserve,
              reserveIndex: reserveIndex,
              wasForced: false,
            );
            enemy = resolution.active;
            enemyReserve = resolution.reserve;
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
    required this.timeline,
  });

  final BattleCombatant player;
  final List<BattleCombatant> playerReserve;
  final BattleCombatant enemy;
  final List<BattleCombatant> enemyReserve;
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

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart`

```dart
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
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
/// - [player.currentHp] est toujours entre 0 et [player.maxHp].
/// - [enemy.currentHp] est toujours entre 0 et [enemy.maxHp].
class BattleState {
  /// Crée un état de combat.
  ///
  /// [phase] - La phase actuelle du combat.
  /// [player] - Le combattant joueur.
  /// [enemy] - Le combattant adverse.
  /// [field] - L'état de champ observable (weather / pseudoWeather).
  /// [currentTurn] - Le résultat du tour en cours (null si aucun tour en cours).
  /// [outcome] - Le résultat final du combat (null si combat en cours).
  const BattleState({
    required this.phase,
    required this.player,
    this.playerReserve = const <BattleCombatant>[],
    required this.enemy,
    this.enemyReserve = const <BattleCombatant>[],
    this.field = const BattleFieldState(),
    this.currentTurn,
    this.outcome,
  });

  /// La phase actuelle du combat.
  final BattlePhase phase;

  /// Le combattant joueur.
  final BattleCombatant player;

  /// Réserve battle locale du joueur.
  ///
  /// BE10 garde ici un modèle très petit :
  /// - un seul actif ;
  /// - zéro ou plusieurs réserves ;
  /// - chaque membre reste un vrai `BattleCombatant`, donc avec ses PV,
  ///   moves/PP, statut majeur et typing déjà résolus.
  final List<BattleCombatant> playerReserve;

  /// Le combattant adverse.
  final BattleCombatant enemy;

  /// Réserve battle locale de l'adversaire.
  final List<BattleCombatant> enemyReserve;

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

### `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_decision_request_test.dart`

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
      expect(
        continueRequest.reason,
        equals(BattleContinueReason.mustRecharge),
      );
      expect(continueRequest.allowedChoices, hasLength(1));
      expect(continueRequest.allowedChoices.single,
          isA<PlayerBattleChoiceContinue>());
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

### `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`

```dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

/// Retourne le prompt de décision à afficher pour la requête courante.
///
/// Phase C utilise cette petite fonction pure pour une raison concrète :
/// - l'overlay doit désormais afficher le *type* de requête demandé par le
///   moteur, pas déduire ce type depuis une liste plate de choix ;
/// - garder ce formatage dans un helper pur permet aussi de le verrouiller en
///   test sans devoir piloter tout le composant Flame ;
/// - on reste très loin d'un système de présentation générique.
String buildBattleDecisionPromptForOverlay(BattleDecisionRequest request) {
  return switch (request) {
    BattleTurnChoiceRequest() => 'Que doit faire le joueur ?',
    BattleForcedReplacementRequest() =>
      'Le joueur doit remplacer son Pokémon K.O.',
    BattleContinueRequest() => 'Le joueur doit continuer un tour forcé',
    BattleWaitRequest(:final reason) => switch (reason) {
        BattleWaitReason.battleFinished => 'Combat terminé',
        BattleWaitReason.resolvingTurn => 'Résolution du tour en cours',
        BattleWaitReason.activeFaintedWithoutReplacement =>
          'Aucun remplaçant disponible',
        BattleWaitReason.noLegalChoice => 'Aucune décision légale disponible',
      },
  };
}

/// Construit les lignes de restitution d'un tour pour l'overlay runtime.
///
/// BE10A centralise ici la restitution textuelle pour une raison précise :
/// - l'overlay ne doit plus réinventer l'ordre du tour en triant des buckets ;
/// - la vraie source de vérité est désormais `BattleTurnResult.timeline` ;
/// - cette fonction garde donc la surface runtime alignée sur la chronologie
///   réellement produite par le moteur battle.
///
/// Garde-fou volontaire :
/// - si un `BattleTurnResult` porte encore des buckets non vides sans
///   chronologie ordonnée, on échoue explicitement ;
/// - mieux vaut un seam bruyant qu'une UI qui raconte un ordre faux.
List<String> buildBattleTurnLinesForOverlay(BattleTurnResult turnResult) {
  if (turnResult.timeline.isEmpty &&
      (turnResult.executions.isNotEmpty ||
          turnResult.statusEvents.isNotEmpty ||
          turnResult.volatileEvents.isNotEmpty ||
          turnResult.fieldEvents.isNotEmpty ||
          turnResult.switchEvents.isNotEmpty)) {
    throw StateError(
      'BattleTurnResult.timeline est requis pour afficher honnêtement la chronologie du tour dans l’overlay runtime.',
    );
  }

  final lines = <String>[];
  for (final event in turnResult.timeline) {
    switch (event) {
      case BattleTurnExecutionEvent(:final execution):
        final attacker = _overlayCombatantLabel(execution.attacker);
        lines.add(
          '$attacker utilise ${execution.move.name} → ${execution.damage} dégâts',
        );
      case BattleTurnStatusEvent(:final event):
        lines.add(_formatOverlayStatusEvent(event));
      case BattleTurnVolatileEvent(:final event):
        lines.add(_formatOverlayVolatileEvent(event));
      case BattleTurnFieldEvent(:final event):
        lines.add(_formatOverlayFieldEvent(event));
      case BattleTurnSwitchEvent(:final event):
        lines.add(_formatOverlaySwitchEvent(event));
    }
  }

  return List<String>.unmodifiable(lines);
}

String _formatOverlaySwitchEvent(BattleSwitchEvent event) {
  final actor = _overlayCombatantLabel(event.actor);
  return switch (event.kind) {
    BattleSwitchEventKind.switched => event.wasForced
        ? '$actor remplace ${event.fromSpeciesId} par ${event.toSpeciesId}'
        : '$actor switch de ${event.fromSpeciesId} vers ${event.toSpeciesId}',
    BattleSwitchEventKind.replacementRequired =>
      '$actor doit remplacer ${event.fromSpeciesId} K.O.',
  };
}

String _formatOverlayStatusEvent(BattleStatusEvent event) {
  final actor = _overlayCombatantLabel(event.target);
  final status = event.status.name.toUpperCase();
  return switch (event.kind) {
    BattleStatusEventKind.applied =>
      '$actor reçoit le statut $status (${event.sourceMoveId})',
    BattleStatusEventKind.blockedExistingMajorStatus =>
      '$actor garde déjà ${event.existingStatus!.name.toUpperCase()} '
          'et ignore $status',
    BattleStatusEventKind.preventedAction =>
      '$actor ne peut pas agir à cause de $status',
    BattleStatusEventKind.residualDamage =>
      '$actor subit ${event.damage} dégâts résiduels ($status'
          '${event.toxicCounter == null ? '' : ', compteur ${event.toxicCounter}'}'
          ')',
  };
}

String _formatOverlayVolatileEvent(BattleVolatileEvent event) {
  final actor = _overlayCombatantLabel(event.actor);
  final target =
      event.target == null ? null : _overlayCombatantLabel(event.target!);

  return switch (event.kind) {
    BattleVolatileEventKind.protectActivated => '$actor active Protect',
    BattleVolatileEventKind.protectBlocked =>
      '${target ?? 'La cible'} bloque l’attaque avec Protect',
    BattleVolatileEventKind.protectBroken =>
      '$actor perce Protect sur ${target ?? 'la cible'}',
    BattleVolatileEventKind.rechargeRequired =>
      '$actor doit recharger au tour suivant',
    BattleVolatileEventKind.rechargeTurnSpent =>
      '$actor passe son tour pour recharger',
    BattleVolatileEventKind.chargeStarted =>
      '$actor commence à charger ${event.sourceMoveId ?? 'son attaque'}',
    BattleVolatileEventKind.chargeReleased =>
      '$actor libère ${event.sourceMoveId ?? 'son attaque chargée'}',
  };
}

String _formatOverlayFieldEvent(BattleFieldEvent event) {
  return switch (event.kind) {
    BattleFieldEventKind.weatherSet =>
      'Le champ passe à ${_overlayWeatherLabel(event.weather!)}',
    BattleFieldEventKind.weatherResidualDamage =>
      '${_overlayCombatantLabel(event.target!)} subit ${event.damage} dégâts de ${_overlayWeatherLabel(event.weather!)}',
    BattleFieldEventKind.weatherExpired =>
      '${_overlayWeatherLabel(event.weather!)} prend fin',
    BattleFieldEventKind.pseudoWeatherSet =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} devient actif',
    BattleFieldEventKind.pseudoWeatherCleared =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} est dissipé',
    BattleFieldEventKind.pseudoWeatherExpired =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} prend fin',
  };
}

String _overlayCombatantLabel(String combatantId) {
  return combatantId == 'player' ? 'Joueur' : 'Ennemi';
}

String _overlayWeatherLabel(BattleWeatherId weather) {
  return switch (weather) {
    BattleWeatherId.rain => 'la pluie',
    BattleWeatherId.sandstorm => 'la tempête de sable',
  };
}

String _overlayPseudoWeatherLabel(BattlePseudoWeatherId pseudoWeather) {
  return switch (pseudoWeather) {
    BattlePseudoWeatherId.trickRoom => 'Trick Room',
  };
}

/// Composant UI d'overlay de combat.
///
/// Affiche l'état courant du combat et permet au joueur de choisir une action.
/// Ne contient AUCUNE logique métier de combat — pure UI.
///
/// La logique métier est dans `map_battle` (BattleSession).
/// Ce composant se contente de :
/// - Afficher les PV des combattants
/// - Afficher les choix disponibles
/// - Notifier le runtime du choix du joueur via [onPlayerChoice]
///
/// **Interaction** : L'utilisateur peut cliquer sur un choix pour le sélectionner.
/// Le clic appelle [onPlayerChoice] avec le choix correspondant.
///
/// **IMPORTANT** : Ce composant stocke une référence mutable vers la session
/// courante. Quand le runtime appelle [updateState()], la session interne
/// est mise à jour pour refléter le nouvel état. Toutes les méthodes d'affichage
/// lisent [session] qui est donc toujours à jour.
class BattleOverlayComponent extends PositionComponent with TapCallbacks {
  /// Crée un overlay de combat.
  ///
  /// [session] - La session de combat courante (état + API).
  /// [viewportSize] - La taille de la viewport pour centrer le panneau.
  /// [onPlayerChoice] - Callback appelé quand le joueur fait un choix.
  BattleOverlayComponent({
    required BattleSession session,
    required Vector2 viewportSize,
    required this.onPlayerChoice,
  })  : _session = session,
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 97,
        );

  /// La session de combat courante.
  ///
  /// **Mutable** : mise à jour par [updateState()] pour refléter le nouvel état.
  /// Toutes les méthodes d'affichage lisent cette propriété, donc l'UI est
  /// toujours synchronisée avec l'état réel du combat.
  BattleSession _session;

  /// Callback appelé quand le joueur fait un choix.
  ///
  /// Le runtime doit appeler `session.applyChoice(choice)` pour appliquer le choix.
  final void Function(PlayerBattleChoice choice) onPlayerChoice;

  /// Référence vers le panneau principal (pour mise à jour dynamique).
  PositionComponent? _panel;

  /// Composants de texte pour les PV (pour mise à jour dynamique).
  TextComponent? _playerHpText;
  TextComponent? _enemyHpText;
  TextComponent? _choicesTitleText;

  /// Composant de texte pour afficher le résultat du tour en cours.
  ///
  /// Affiche les attaques du joueur et de l'ennemi, ainsi que les dégâts.
  TextComponent? _turnResultText;

  /// Composants de choix (pour mise à jour dynamique).
  /// Chaque composant est associé à un index de choix.
  final List<_ChoiceComponent> _choiceComponents = [];

  /// Index du choix actuellement sélectionné.
  ///
  /// Utilisé pour la navigation clavier (↑/↓) et pour afficher visuellement
  /// le choix sélectionné avec un style différent.
  ///
  /// Invariant : `_selectedIndex` est toujours entre 0 et `_choiceComponents.length - 1`.
  int _selectedIndex = 0;

  /// Composant de surbrillance pour le choix sélectionné.
  ///
  /// Affiché derrière le choix sélectionné pour le mettre en évidence visuellement.
  RectangleComponent? _selectionHighlight;

  @override
  Future<void> onLoad() async {
    // Fond sombre
    final bg = RectangleComponent(
      size: size.clone(),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xF20B1020),
      priority: 0,
    );
    add(bg);

    // Panneau principal
    final panelWidth = (size.x - 80).clamp(240.0, 760.0);
    final panelHeight = (size.y - 120).clamp(220.0, 520.0);
    _panel = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      position: Vector2((size.x - panelWidth) / 2, (size.y - panelHeight) / 2),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xE81A223B),
      priority: 1,
    );
    add(_panel!);

    // Bordure du panneau
    final panelBorder = RectangleComponent(
      size: _panel!.size.clone(),
      anchor: Anchor.topLeft,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x66FFFFFF),
      priority: 2,
    );
    _panel!.add(panelBorder);

    // Titre
    final title = TextComponent(
      text: _getTitleForSession(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF5F5F5),
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 3,
    );
    _panel!.add(title);

    // PV du joueur
    _playerHpText = TextComponent(
      text: _getPlayerHpText(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 72),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_playerHpText!);

    // PV de l'ennemi
    _enemyHpText = TextComponent(
      text: _getEnemyHpText(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 100),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_enemyHpText!);

    // Titre des choix
    _choicesTitleText = TextComponent(
      text: buildBattleDecisionPromptForOverlay(_session.decisionRequest),
      anchor: Anchor.topLeft,
      position: Vector2(22, 150),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFC4CCDA),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_choicesTitleText!);

    // Choix disponibles
    _renderChoices();

    // Astuce
    final hint = TextComponent(
      text: 'Utilisez les flèches ↑/↓ et E pour choisir',
      anchor: Anchor.bottomLeft,
      position: Vector2(22, panelHeight - 18),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFC4CCDA),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(hint);
  }

  /// Met à jour l'affichage avec un nouvel état de session.
  ///
  /// [newSession] - La nouvelle session avec l'état mis à jour.
  ///
  /// **IMPORTANT** : Cette méthode met à jour [_session] pour que toutes les
  /// méthodes d'affichage (_getChoiceText, etc.) lisent le bon état.
  ///
  /// Cette méthode gère aussi la cohérence de la sélection :
  /// - Si le combat est fini, la sélection est désactivée
  /// - Si la sélection est hors bornes (moins de choix), elle est clampée
  /// - Si un tour est en cours, affiche le résultat du tour (attaques + dégâts)
  void updateState(BattleSession newSession) {
    // Mettre à jour la session interne — CRITIQUE pour la cohérence
    _session = newSession;

    // Mettre à jour les PV
    _playerHpText?.text = _getPlayerHpText();
    _enemyHpText?.text = _getEnemyHpText();
    _choicesTitleText?.text =
        buildBattleDecisionPromptForOverlay(newSession.decisionRequest);

    // Afficher le résultat du tour si disponible
    _updateTurnResult();

    // Si le combat est fini, afficher le résultat
    if (newSession.state.isFinished) {
      _showOutcome(newSession.state.outcome!);
    } else {
      // Combat toujours en cours — maintenir la sélection cohérente
      // Clamper l'index si le nombre de choix a changé
      final choices = newSession.decisionRequest.allowedChoices;
      if (_selectedIndex >= choices.length) {
        _selectedIndex = choices.length - 1;
      }
      if (_selectedIndex < 0) {
        _selectedIndex = 0;
      }
      // Re-render pour mettre à jour les choix et la surbrillance
      _renderChoices();
    }
  }

  /// Met à jour l'affichage du résultat du tour en cours.
  ///
  /// Affiche les attaques du joueur et de l'ennemi, ainsi que les dégâts infligés.
  void _updateTurnResult() {
    // Supprimer l'ancien texte de résultat du tour
    _turnResultText?.removeFromParent();
    _turnResultText = null;

    final turnResult = _session.state.currentTurn;
    if (turnResult == null) {
      return;
    }

    final lines = buildBattleTurnLinesForOverlay(turnResult);

    if (lines.isEmpty) {
      return;
    }

    // Afficher le résultat du tour
    _turnResultText = TextComponent(
      text: lines.join('\n'),
      anchor: Anchor.topCenter,
      position: Vector2(_panel!.size.x / 2, 130),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_turnResultText!);
  }

  /// Affiche le résultat final du combat.
  void _showOutcome(BattleOutcome outcome) {
    final outcomeText = switch (outcome.type) {
      BattleOutcomeType.victory => 'Victoire !',
      BattleOutcomeType.defeat => 'Défaite...',
      BattleOutcomeType.runaway => 'Fuite réussie !',
      BattleOutcomeType.captured => 'Capture réussie !',
    };

    final outcomeComponent = TextComponent(
      text: outcomeText,
      anchor: Anchor.topCenter,
      position: Vector2(_panel!.size.x / 2, _panel!.size.y / 2 + 50),
      textRenderer: TextPaint(
        style: TextStyle(
          color: outcome.isVictory || outcome.isCaptured
              ? const Color(0xFF4CAF50)
              : const Color(0xFFF44336),
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 10,
    );
    _panel!.add(outcomeComponent);
  }

  /// Affiche les choix disponibles.
  ///
  /// Cette méthode :
  /// 1. Récupère les choix disponibles depuis [_session]
  /// 2. Crée un composant visuel pour chaque choix
  /// 3. Ajoute un composant de surbrillance pour le choix sélectionné
  /// 4. Met à jour [_selectionHighlight] pour le rendu visuel
  void _renderChoices() {
    // Lit [_session] qui est toujours à jour grâce à updateState()
    final request = _session.decisionRequest;
    final choices = request.allowedChoices;
    var y = 190.0;

    // Nettoyer les anciens composants de choix
    for (final component in _choiceComponents) {
      component.removeFromParent();
    }
    _choiceComponents.clear();

    // Nettoyer l'ancienne surbrillance
    _selectionHighlight?.removeFromParent();
    _selectionHighlight = null;

    for (var i = 0; i < choices.length; i++) {
      final choice = choices[i];
      final text = _getChoiceText(request, choice);
      final choiceComponent = _ChoiceComponent(
        choice: choice,
        text: text,
        position: Vector2(22, y),
      );
      _choiceComponents.add(choiceComponent);
      _panel!.add(choiceComponent);

      // Créer la surbrillance pour le choix sélectionné
      if (i == _selectedIndex) {
        _selectionHighlight = RectangleComponent(
          size: Vector2(280, 28),
          position: Vector2(24, y + 2),
          anchor: Anchor.topLeft,
          paint: Paint()
            ..color = const Color(0x40FFFFFF) // Blanc semi-transparent
            ..style = PaintingStyle.fill,
          priority: 2,
        );
        _panel!.add(_selectionHighlight!);
      }

      y += 32;
    }
  }

  /// Retourne le texte à afficher pour un choix.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getChoiceText(
    BattleDecisionRequest request,
    PlayerBattleChoice choice,
  ) {
    if (choice is PlayerBattleChoiceFight) {
      // Lit les moves depuis _session.state.player.moves — toujours à jour
      final move = _session.state.player.moves[choice.moveIndex];
      return '⚔ ${move.name} (Puissance: ${move.power})';
    } else if (choice is PlayerBattleChoiceSwitch) {
      final reserve = _session.state.playerReserve[choice.reserveIndex];
      final isForcedReplacement = request is BattleForcedReplacementRequest;
      final actionLabel = isForcedReplacement ? 'Remplacer par' : 'Switch vers';
      return '↔ $actionLabel ${reserve.speciesId} '
          '(${reserve.currentHp}/${reserve.maxHp} PV)';
    } else if (choice is PlayerBattleChoiceContinue) {
      // Phase C cesse ici d'inférer le sens du tour forcé depuis l'état
      // volatile brut : la vraie source de vérité est désormais la requête.
      if (request case BattleContinueRequest(:final reason)) {
        if (reason == BattleContinueReason.pendingChargeRelease) {
          return 'Continuer (libérer la charge)';
        }
        if (reason == BattleContinueReason.mustRecharge) {
          return 'Continuer (recharge)';
        }
      }
      return 'Continuer';
    } else if (choice is PlayerBattleChoiceCapture) {
      return 'Capturer';
    } else if (choice is PlayerBattleChoiceRun) {
      return '🏃 Fuir';
    }
    return '???';
  }

  /// Retourne le titre pour la session.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getTitleForSession() {
    if (_session.setup.isTrainerBattle) {
      return 'Combat Dresseur';
    }
    return 'Combat Sauvage';
  }

  /// Retourne le texte des PV du joueur.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getPlayerHpText() {
    return 'Joueur (${_session.state.player.speciesId}): '
        '${_session.state.player.currentHp}/${_session.state.player.maxHp} PV';
  }

  /// Retourne le texte des PV de l'ennemi.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getEnemyHpText() {
    return 'Ennemi (${_session.state.enemy.speciesId}): '
        '${_session.state.enemy.currentHp}/${_session.state.enemy.maxHp} PV';
  }

  /// Déplace la sélection vers le haut (choix précédent).
  ///
  /// Si la sélection est déjà au premier choix, reste au premier choix (pas de wrap).
  /// Met à jour visuellement la surbrillance.
  ///
  /// Retourne true si la sélection a changé, false sinon.
  bool moveSelectionUp() {
    if (_selectedIndex > 0) {
      _selectedIndex--;
      debugPrint('[battle-overlay] moveSelectionUp: new index=$_selectedIndex');
      _renderChoices(); // Re-render pour mettre à jour la surbrillance
      return true;
    }
    debugPrint(
        '[battle-overlay] moveSelectionUp: already at first choice (index=$_selectedIndex)');
    return false;
  }

  /// Déplace la sélection vers le bas (choix suivant).
  ///
  /// Si la sélection est déjà au dernier choix, reste au dernier choix (pas de wrap).
  /// Met à jour visuellement la surbrillance.
  ///
  /// Retourne true si la sélection a changé, false sinon.
  bool moveSelectionDown() {
    if (_selectedIndex < _choiceComponents.length - 1) {
      _selectedIndex++;
      debugPrint(
          '[battle-overlay] moveSelectionDown: new index=$_selectedIndex');
      _renderChoices(); // Re-render pour mettre à jour la surbrillance
      return true;
    }
    debugPrint(
        '[battle-overlay] moveSelectionDown: already at last choice (index=$_selectedIndex, max=${_choiceComponents.length - 1})');
    return false;
  }

  /// Retourne le choix actuellement sélectionné.
  ///
  /// Retourne null si aucun choix n'est disponible.
  PlayerBattleChoice? getSelectedChoice() {
    if (_choiceComponents.isEmpty ||
        _selectedIndex < 0 ||
        _selectedIndex >= _choiceComponents.length) {
      return null;
    }
    return _choiceComponents[_selectedIndex].choice;
  }

  /// Valide le choix actuellement sélectionné.
  ///
  /// Appelle [onPlayerChoice] avec le choix sélectionné.
  ///
  /// Retourne true si un choix a été validé, false si aucun choix n'est disponible.
  bool validateSelectedChoice() {
    final selectedChoice = getSelectedChoice();
    if (selectedChoice != null) {
      debugPrint(
          '[battle-overlay] validateSelectedChoice: choice=$selectedChoice');
      onPlayerChoice(selectedChoice);
      return true;
    }
    debugPrint('[battle-overlay] validateSelectedChoice: no choice selected');
    return false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Vérifier si un choix a été cliqué
    final tapPos = event.localPosition;
    for (var i = 0; i < _choiceComponents.length; i++) {
      final choiceComponent = _choiceComponents[i];
      if (choiceComponent.containsPoint(tapPos)) {
        // Mettre à jour la sélection visuelle
        _selectedIndex = i;
        _renderChoices();

        // Choix cliqué — notifier le runtime
        onPlayerChoice(choiceComponent.choice);
        return;
      }
    }
  }
}

/// Composant de choix avec référence au choix associé.
///
/// Permet de détecter les clics sur un choix spécifique et de notifier
/// le runtime via [onPlayerChoice].
class _ChoiceComponent extends PositionComponent {
  _ChoiceComponent({
    required this.choice,
    required String text,
    required Vector2 position,
  }) : super(
          size: Vector2(300, 32),
          position: position,
          anchor: Anchor.topLeft,
        ) {
    // Ajouter le texte du choix
    add(TextComponent(
      text: text,
      anchor: Anchor.topLeft,
      position: Vector2.zero(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    ));
  }

  /// Le choix associé à ce composant.
  final PlayerBattleChoice choice;

  /// Vérifie si un point est dans les bounds de ce composant.
  @override
  bool containsPoint(Vector2 point) {
    return point.x >= position.x &&
        point.x <= position.x + size.x &&
        point.y >= position.y &&
        point.y <= position.y + size.y;
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

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
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
    ),
  );
}

void main() {
  group('BattleOverlayComponent Phase C decision prompts', () {
    test('uses the request type instead of a flat choice list heuristic', () {
      final freeTurnSession = _session(
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

      expect(
        buildBattleDecisionPromptForOverlay(freeTurnSession.decisionRequest),
        equals('Que doit faire le joueur ?'),
      );

      final forcedReplacementSession = _session(
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
        buildBattleDecisionPromptForOverlay(
          forcedReplacementSession.decisionRequest,
        ),
        equals('Le joueur doit remplacer son Pokémon K.O.'),
      );

      final continueSession = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(continueSession.decisionRequest),
        equals('Le joueur doit continuer un tour forcé'),
      );
    });
  });

  group('BattleOverlayComponent BE10A chronology', () {
    test('renders a voluntary switch before the later enemy attack', () {
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
      final lines =
          buildBattleTurnLinesForOverlay(afterTurn.state.currentTurn!);

      final switchIndex =
          lines.indexWhere((line) => line.contains('Joueur switch de'));
      final attackIndex =
          lines.indexWhere((line) => line.contains('Ennemi utilise Tackle'));

      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(attackIndex, greaterThanOrEqualTo(0));
      expect(switchIndex, lessThan(attackIndex));
    });

    test('rejects bucket-only turn results because chronology would be false',
        () {
      const bucketOnlyTurn = BattleTurnResult(
        playerAction: BattleActionNone(),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attacker: 'enemy',
            move: BattleMove(id: 'tackle', name: 'Tackle', power: 40),
            target: 'player',
            damage: 12,
            didHit: true,
          ),
        ],
      );

      expect(
        () => buildBattleTurnLinesForOverlay(bucketOnlyTurn),
        throwsA(isA<StateError>()),
      );
    });

    test(
        'renders end-of-turn residuals before forced replacement markers after a double KO',
        () {
      final session = _session(
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
        isTrainerBattle: true,
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final lines =
          buildBattleTurnLinesForOverlay(afterTurn.state.currentTurn!);

      final residualIndex = lines.indexWhere(
        (line) => line.contains('dégâts résiduels (PSN)'),
      );
      final enemyReplacementIndex = lines.indexWhere(
        (line) => line.contains('Ennemi remplace lead_enemy par bench_enemy'),
      );
      final playerReplacementIndex = lines.indexWhere(
        (line) => line.contains('Joueur doit remplacer lead_player K.O.'),
      );

      expect(residualIndex, greaterThanOrEqualTo(0));
      expect(enemyReplacementIndex, greaterThan(residualIndex));
      expect(playerReplacementIndex, greaterThan(enemyReplacementIndex));
    });
  });
}

```
