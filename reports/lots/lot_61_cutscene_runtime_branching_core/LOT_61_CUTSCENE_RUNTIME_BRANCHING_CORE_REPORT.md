# LOT 61 — Cutscene Runtime Branching Core (runtime-only)

## 1. Résumé exécutif honnête
Ce lot ajoute le noyau de branchement runtime des cutscenes, sans UI et sans `map_editor`:
- choix joueur runtime bloquant,
- labels + goto,
- goto conditionnels (choice / flag / outcome),
- mémorisation du dernier choix,
- intégration minimale dans `PlayableMapGame` pour exposer/résoudre un choix en attente.

Le runner reste séquentiel, déterministe, et découplé de Flame.

## 2. Objectif exact du lot
Rendre les cutscenes branchables en runtime avec un modèle simple type:
- `Choice -> GotoIf* -> Label/Goto -> convergence`,
sans introduire un moteur de scripting générique.

## 3. Ce qui existait avant
Le runner v2 gérait déjà:
- dialogue (avec attente de fermeture),
- moveNpcTo + waits,
- waitUntilFlag / waitUntilOutcome / waitUntilNpcMoveCompleted,
- `emitOutcome`, `setFlag`, `clearFlag`,
- `callCutscene` avec garde récursion/profondeur.

Il manquait:
- choix joueur runtime,
- structure interne label/goto,
- branchements conditionnels simples.

## 4. Périmètre respecté
### Modifié
- `packages/map_runtime/**` (runtime + tests)

### Non touché
- `packages/map_editor/**`
- UI d’édition / story editor / step/global story

## 5. Architecture retenue
### 5.1 Modèle de step (runtime models)
Ajout de types explicites:
- `CutsceneChoiceOption`
- `CutsceneChoiceRequest`
- `CutsceneChoiceResult`
- `CutsceneChoiceStep`
- `CutsceneLabelStep`
- `CutsceneGotoStep`
- `CutsceneGotoIfChoiceStep`
- `CutsceneGotoIfFlagStep`
- `CutsceneGotoIfOutcomeStep`

`CutsceneRuntimeStatus` expose maintenant:
- `activeChoiceRequest`
- `lastChoiceResult`

### 5.2 Runner (application)
Le runner intègre:
- un stockage des résultats de choix (`_choiceResultsById`),
- un choix en attente (`_activeChoiceRequest`),
- un index des labels par frame (`labelIndexByName`),
- un compteur de transitions (`maxStepTransitions`) pour détecter des boucles infinies pratiques.

### 5.3 Host runtime (PlayableMapGame)
Ajout de hooks runtime minimaux:
- lecture du choix en attente,
- résolution programmatique du choix (index/value),
- propagation via callback `requestChoice` dans `CutsceneRuntimeContext`.

Aucune UI de choix n’a été ajoutée.

## 6. Contrat exact des nouvelles capacités
### 6.1 Choice
- `CutsceneChoiceStep` déclenche `requestChoice(...)` sur le host.
- La cutscene reste bloquée tant que le choix n’est pas résolu.
- Résolution via:
  - `resolveActiveChoiceByIndex(int)`
  - `resolveActiveChoiceByValue(String)`
- Le résultat est mémorisé:
  - dans `_choiceResultsById` (par `choiceId`)
  - dans `lastChoiceResult`.

### 6.2 Label / Goto
- `CutsceneLabelStep` est un no-op runtime.
- `CutsceneGotoStep(label)` saute vers `label`.
- Validation stricte:
  - label vide -> échec,
  - label inconnu -> échec,
  - labels dupliqués dans une cutscene -> échec au démarrage / à l’appel.

### 6.3 Goto conditionnels
- `CutsceneGotoIfChoiceStep`:
  - lit le résultat du `choiceId`,
  - saute vers label si `selectedValue == expectedValue`,
  - sinon continue.
- `CutsceneGotoIfFlagStep`:
  - teste `isFlagSet(flagName)` vs `expectedSet`.
- `CutsceneGotoIfOutcomeStep`:
  - teste `isOutcomeSet(outcomeId)` vs `expectedSet`.

## 7. Fichiers modifiés
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/application/cutscene_runtime_models.dart`
- `packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/cutscene_runtime_runner_test.dart`
- `packages/map_runtime/test/playable_map_game_public_getters_test.dart`

## 8. Fichiers créés
- `reports/lots/lot_61_cutscene_runtime_branching_core/LOT_61_CUTSCENE_RUNTIME_BRANCHING_CORE_REPORT.md`

## 9. Extraits de code importants
### 9.1 Step Choice + attente
```dart
if (step is CutsceneChoiceStep) {
  _runChoiceStep(step);
  return;
}
...
if (_activeChoiceRequest != null) {
  return;
}
```

### 9.2 Résolution de choix
```dart
bool resolveActiveChoiceByIndex(int selectedIndex) { ... }
bool resolveActiveChoiceByValue(String selectedValue) { ... }
```

### 9.3 Jump label déterministe
```dart
final targetStepIndex = top.labelIndexByName[normalized];
if (targetStepIndex == null) {
  _fail('Goto target ... not found ...');
  return;
}
top.stepIndex = targetStepIndex + 1;
```

### 9.4 Branchement conditionnel par choix
```dart
final result = _choiceResultsById[choiceId];
if (result == null) {
  _fail('GotoIfChoice cannot find choice result ...');
  return;
}
if (result.selectedValue == expected) {
  _jumpToLabelOnTopFrame(step.label);
} else {
  _advanceStepOnTopFrame();
}
```

### 9.5 Hook runtime host (sans UI)
```dart
requestChoice: (request) {
  _pendingCutsceneChoiceRequest = request;
  return true;
},
```

## 10. Tests ajoutés/renforcés
`cutscene_runtime_runner_test.dart` couvre:
- dialogue bloquant,
- moveNpcTo bloquant,
- choice bloquant + mémoire du résultat,
- goto + convergence,
- erreur label inconnu,
- erreur labels dupliqués,
- gotoIfChoice,
- gotoIfFlag,
- gotoIfOutcome,
- compatibilité callCutscene avec labels/goto dans l’enfant,
- récursion callCutscene,
- waits existants (flag/outcome/npc),
- start refusé si runner occupé,
- erreurs dialogue/cutscene introuvables.

`playable_map_game_public_getters_test.dart` couvre en plus:
- getters/méthodes choice publiques safe avant `onLoad`.

## 11. Validations réellement exécutées
### Format
```bash
dart format packages/map_runtime/lib/map_runtime.dart \
  packages/map_runtime/lib/src/application/cutscene_runtime_models.dart \
  packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart \
  packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart \
  packages/map_runtime/test/cutscene_runtime_runner_test.dart \
  packages/map_runtime/test/playable_map_game_public_getters_test.dart
```
Résultat: OK.

### Analyze ciblé
```bash
flutter analyze \
  packages/map_runtime/lib/src/application/cutscene_runtime_models.dart \
  packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart \
  packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart \
  packages/map_runtime/test/cutscene_runtime_runner_test.dart \
  packages/map_runtime/test/playable_map_game_public_getters_test.dart
```
Résultat: **No issues found**.

### Tests ciblés (dans `packages/map_runtime`)
```bash
flutter test test/cutscene_runtime_runner_test.dart
flutter test test/playable_map_game_public_getters_test.dart
flutter test test/scripted_entity_movement_controller_test.dart
```
Résultat: **3/3 OK**.

## 12. Limites restantes
- Pas de UI de choix (volontairement hors périmètre).
- Pas de système de choix multi-étapes avancé (timers, defaults, cancel).
- Pas de `goto` basé sur expression complexe (uniquement conditionnels ciblés).
- Le runner ne fait pas de “smart healing” des scripts; il fail explicitement sur données invalides.

## 13. Ce qui n’a pas été fait volontairement
- Aucune modif `map_editor`.
- Aucune modif story/step/global flow côté auteur.
- Aucune surcouche produit/UI.
- Aucun DSL custom.

## 14. Prochaines étapes recommandées
1. Brancher une vraie UI runtime de choix (overlay) sur `pendingCutsceneChoiceRequest`.
2. Ajouter un step optionnel “default timeout choice -> auto-select”.
3. Ajouter un test d’intégration runtime “starter_selection” bout-en-bout dans `PlayableMapGame`.

## 15. État git final exact
`git status --short`
```text
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/cutscene_runtime_models.dart
 M packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/cutscene_runtime_runner_test.dart
 M packages/map_runtime/test/playable_map_game_public_getters_test.dart
```
