# LOT 60 — Cutscene Runtime v2 (runtime-only)

## 1. Résumé exécutif
Ce lot renforce le runtime cutscene sans toucher l’UI ni `map_editor`.  
Le `CutsceneRuntimeRunner` gère maintenant:
- dialogue bloquant (attente de fermeture réelle),
- appels de cutscenes (`callCutscene`) avec garde récursion/profondeur,
- attentes conditionnelles (`waitUntilNpcMoveCompleted`, `waitUntilFlag`, `waitUntilOutcome`, `waitUntilDialogueClosed`),
- états d’échec explicites.

Le système reste volontairement minimal et orienté exécution runtime séquentielle.

## 2. Objectif exact du lot
Passer d’un runner MVP linéaire à un runtime cutscene v2 exploitable pour la suite (future orchestration Pokemon-like), en restant strictement dans:
- `packages/map_runtime/**`
- tests runtime
- documentation technique.

## 3. Périmètre / hors périmètre
### Dans le périmètre
- Modèles de steps runtime cutscene.
- Exécution séquentielle + wait conditions + call de sous-cutscene.
- Intégration `PlayableMapGame` via callbacks runtime.
- Tests unitaires ciblés runtime.

### Hors périmètre respecté
- Aucune modification `packages/map_editor/**`.
- Aucune nouvelle UI/panneau/story navigator.
- Aucune refonte produit globale Story/Step.

## 4. Audit initial rapide
Fichiers audités en entrée:
- `packages/map_runtime/lib/src/application/cutscene_runtime_models.dart`
- `packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/application/story_flags_manager.dart`

Constat:
- La base cutscene existait, mais restait trop linéaire.
- Le mouvement PNJ scripté/pathfinding était déjà disponible et réutilisable.
- L’attente de fermeture dialogue n’était pas explicitement pilotée par le runner.
- Aucun call de sous-cutscene.
- Pas de waitUntil* sur flag/outcome/dialogue.

## 5. Choix d’architecture retenus
1. **Runner découplé de Flame conservé**: `CutsceneRuntimeRunner` reste pur orchestration, piloté par callbacks.
2. **Callbacks runtime étendus** dans `CutsceneRuntimeContext`:
   - `isDialogueOpen`
   - `resolveCutsceneById`
   - `isFlagSet`
   - `isOutcomeSet`
3. **Pile d’exécution interne** (`_CutsceneFrame`) pour `callCutscene`.
4. **Mécanisme de waits unifié** (`_PendingWait`) pour éviter les états ad hoc dispersés.
5. **Protection de robustesse**:
   - start refusé si runner occupé,
   - recursion/cycle guard,
   - max depth guard,
   - erreurs explicites pour IDs invalides et ressources introuvables.

## 6. Contrat runtime des steps v2
Ajouts/modifications dans `cutscene_runtime_models.dart`:
- `CutsceneDialogueStep.waitUntilClosed` (par défaut `true`)
- `CutsceneWaitUntilDialogueClosedStep(timeoutMs?)`
- `CutsceneWaitUntilNpcMoveCompletedStep(entityId, timeoutMs?)`
- `CutsceneWaitUntilFlagStep(flagName, expectedSet=true, timeoutMs?)`
- `CutsceneWaitUntilOutcomeStep(outcomeId, expectedSet=true, timeoutMs?)`
- `CutsceneCallStep(cutsceneId)`

### Comportement bloquant/non-bloquant
- `CutsceneDialogueStep(waitUntilClosed: true)` bloque jusqu’à fermeture réelle du dialogue.
- `CutsceneDialogueStep(waitUntilClosed: false)` avance immédiatement après lancement.
- `moveNpcTo` bloque implicitement jusqu’à `completed`/`failed`.
- `waitUntil*` bloque jusqu’à condition satisfaite (ou timeout si fourni).
- `emitOutcome` est **non terminal**: la cutscene continue.

## 7. Extraits de code clés
### 7.1 Dialogue réellement bloquant
```dart
if (!step.waitUntilClosed) {
  _advanceStepOnTopFrame();
  return;
}
_pendingWait = _PendingWait.dialogueClosed();
```

### 7.2 Call cutscene avec garde anti-récursion
```dart
for (final existing in _frames) {
  if (existing.cutscene.id == called.id) {
    _fail('Recursive cutscene call detected for "${called.id}".');
    return;
  }
}
```

### 7.3 Wait conditionnel sur flag/outcome
```dart
final isSet = _context.isFlagSet(pending.flagName!);
if (isSet == pending.expectedSet) {
  _pendingWait = null;
  _advanceStepOnTopFrame();
}
```

### 7.4 Intégration PlayableMapGame (callbacks runtime)
```dart
isDialogueOpen: () => _dialogueOverlay != null,
resolveCutsceneById: _findRuntimeCutsceneById,
isFlagSet: (flagName) => _storyFlags.isSet(_gameState, flagName),
isOutcomeSet: (outcomeId) =>
    _storyFlags.isSet(_gameState, scenarioOutcomeFlagName(outcomeId)),
```

## 8. Fichiers modifiés
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/application/cutscene_runtime_models.dart`
- `packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/cutscene_runtime_runner_test.dart`

## 9. Fichiers créés
- `reports/lots/lot_60_cutscene_runtime_v2/LOT_60_CUTSCENE_RUNTIME_V2_REPORT.md`

## 10. Validations exécutées (réelles)
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
flutter analyze packages/map_runtime/lib/src/application/cutscene_runtime_models.dart \
  packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart \
  packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart \
  packages/map_runtime/test/cutscene_runtime_runner_test.dart \
  packages/map_runtime/test/playable_map_game_public_getters_test.dart
```
Résultat final: **No issues found**.

Note: une passe intermédiaire avait des infos lint `prefer_initializing_formals`, corrigées ensuite.

### Tests ciblés
Tentative initiale (depuis root monorepo) :
```bash
flutter test packages/map_runtime/test/cutscene_runtime_runner_test.dart
```
Résultat: échec (pas de `pubspec.yaml` à la racine du monorepo).

Commandes exécutées dans `packages/map_runtime` :
```bash
flutter test test/cutscene_runtime_runner_test.dart
flutter test test/playable_map_game_public_getters_test.dart
flutter test test/scripted_entity_movement_controller_test.dart
```
Résultat: **3/3 OK**.

## 11. Couverture de tests ajoutée/renforcée
`cutscene_runtime_runner_test.dart` couvre:
- dialogue bloquant jusqu’à fermeture,
- `moveNpcTo` + attente de completion réelle,
- `emitOutcome` puis continuation,
- `callCutscene` parent->enfant->reprise parent,
- garde récursion infinie,
- `waitUntilFlag`,
- `waitUntilOutcome`,
- `waitUntilNpcMoveCompleted`,
- start refusé si runner déjà occupé,
- failure cutscene appelée introuvable,
- failure dialogue non ouvrable.

## 12. Ce qui fonctionne maintenant
- Une cutscene peut bloquer sur un dialogue jusqu’à fermeture réelle.
- Une cutscene peut appeler une autre cutscene.
- Le runner gère des attentes runtime utiles (temps, mouvement, flags, outcomes).
- `PlayableMapGame` expose et alimente correctement ce runtime via callbacks.
- Les outcomes restent non terminaux (la scène continue si prévue).

## 13. Limites restantes (honnêtes)
- Pas de contrôle de flux avancé type labels/goto/choice dans ce lot.
- Pas de timeout global de cutscene (seulement timeout optionnel par wait step).
- Pas de cancellation/interruption explicite publique du runner.
- Pas d’UI d’édition (volontairement hors périmètre).

## 14. Ce qui n’a pas été fait volontairement
- Aucun changement `map_editor`.
- Aucune nouvelle UX/panneau/scenario navigator.
- Aucune refonte Global Story/Step.
- Aucun bridge UI/authoring supplémentaire.

## 15. Prochaines étapes recommandées
1. Ajouter API d’interruption/cancel cutscene côté runner + `PlayableMapGame`.
2. Ajouter step `waitUntilDialogueOpened` (si besoin de synchronisation fine).
3. Ajouter diagnostics runtime d’exécution (timeline simple) pour debug.
4. Préparer le mapping futur Step -> CutsceneById côté orchestration gameplay.

## 16. État git final exact (au moment du rapport)
`git status --short`
```text
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/cutscene_runtime_models.dart
 M packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/cutscene_runtime_runner_test.dart
?? reports/lots/lot_60_cutscene_runtime_v2/LOT_60_CUTSCENE_RUNTIME_V2_REPORT.md
```
