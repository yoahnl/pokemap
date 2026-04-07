# Fix runtime: complétion Step Studio sur fin réelle de cutscene

## 1) Bug produit observé

Dans le flux Emma (`premier_dialogue_avec_le_professeur_emma`), `step_2` était complétée dès `ScenarioRuntimeExecutionStatus.reachedEnd`, ce qui appliquait immédiatement:

- `completedStepIds += step_2`
- `worldChanges.hiddenAfterStepCompletion` pour Emma sur `Bourivka center`

Effet visible: Emma disparaissait avant la fin visuelle réelle de la mise en scène (ex: `followCharacter` encore actif).

## 2) Cause technique précise

La logique de complétion était déclenchée directement à la réception d'un résultat `reachedEnd`:

- dans `_dispatchScenarioRuntimeSource(...)`
- dans `_resumeScenarioAfterRuntimeSource(...)`

Le moteur confondait donc:

- **fin logique du graphe** (`flow reached end`)
- **fin réelle d'exécution runtime** (plus aucun effet scénarisé visible actif)

## 3) Design retenu (robuste, explicite)

Une **barrière de complétion runtime** a été ajoutée:

1. Quand un scénario atteint `reachedEnd`, on tente de compléter immédiatement.
2. Si des effets runtime pertinents sont encore actifs, on **diffère** la complétion dans une file.
3. À chaque frame overworld, on retente le flush de la file.
4. La complétion (`completedStepIds`, `completedCutsceneIds`) n'est appliquée que lorsque le runtime est stable.

Cette approche sépare explicitement:

- `flow reached end` (signal logique du graphe)
- `cutscene execution finished` (condition runtime effective)

## 4) Conditions de blocage runtime prises en compte

La complétion est retardée tant qu'au moins une condition est vraie:

- flow non overworld (`_flowPhase != overworld`)
- dialogue ouvert (`_dialogueOverlay != null`)
- runner cutscene actif (`isCutsceneRunning`)
- suivi actif (`_pendingScenarioFollowRequest != null`)
- continuations move en attente (`_pendingScenarioMoveContinuationsByEntity.isNotEmpty`)
- entrées de warp PNJ en attente (`_pendingScenarioNpcWarpEntries.isNotEmpty`)
- transition map scénarisée en attente (`_pendingScenarioTransitionMapRequest != null`)
- warp runtime en attente (`_pendingWarp != null`)
- connection runtime en attente (`_pendingConnection != null`)
- pas joueur en cours (`_player.isStepping`)

## 5) Fichiers impactés

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime_completion_gate.dart`
- `packages/map_runtime/test/scenario_runtime_completion_gate_test.dart`

## 6) Extraits importants du patch

### 6.1 File de complétion différée

```dart
final List<_PendingScenarioReachedEnd> _pendingScenarioReachedEndQueue =
    <_PendingScenarioReachedEnd>[];
String? _lastScenarioCompletionBlockReason;
```

### 6.2 Remplacement de la complétion immédiate

```dart
_handleScenarioRuntimeCompletionResult(
  result,
  origin: 'dispatch:${sourceEvent.type.name}',
);
```

et

```dart
_handleScenarioRuntimeCompletionResult(
  result,
  origin: 'continuation:$runtimeSourceId',
);
```

### 6.3 Gating explicite

```dart
String? _scenarioCompletionBlockingReason() {
  if (_flowPhase != _RuntimeFlowPhase.overworld) return 'flow_phase_${_flowPhase.name}';
  if (_dialogueOverlay != null) return 'dialogue_open';
  if (isCutsceneRunning) return 'cutscene_runner_active';
  if (_pendingScenarioFollowRequest != null) return 'follow_character_active';
  if (_pendingScenarioMoveContinuationsByEntity.isNotEmpty) return 'move_continuations_pending';
  if (_pendingScenarioNpcWarpEntries.isNotEmpty) return 'npc_warp_entries_pending';
  if (_pendingScenarioTransitionMapRequest != null) return 'transition_map_request_pending';
  if (_pendingWarp != null) return 'runtime_warp_pending';
  if (_pendingConnection != null) return 'runtime_connection_pending';
  if (_player.isStepping) return 'player_step_in_progress';
  return null;
}
```

### 6.4 Flush différé

```dart
void _processPendingScenarioReachedEndCompletions() {
  final blockingReason = _scenarioCompletionBlockingReason();
  if (blockingReason != null) return;
  final pendingItems =
      List<_PendingScenarioReachedEnd>.from(_pendingScenarioReachedEndQueue);
  _pendingScenarioReachedEndQueue.clear();
  for (final pending in pendingItems) {
    _applyScenarioReachedEndCompletion(
      scenarioId: pending.scenarioId,
      origin: 'deferred:${pending.origin}',
    );
  }
}
```

### 6.5 Intégration dans la boucle runtime

```dart
_processPendingScenarioNpcWarpEntries();
_processPendingScenarioMoveContinuations();
_processPendingScenarioFollowRequest();
_processPendingScenarioTransitionMapRequest();
_processPendingScenarioReachedEndCompletions();
```

## 7) Logs runtime ajoutés

Nouveaux logs `step_studio_trace`:

- `completion_deferred ... reason="..."`
- `completion_deferred_duplicate ...`
- `completion_gate_blocked ...`
- `completion_gate_unblocked ...`
- `completion_deferred_flush ... waitedMs=...`
- `completion_applied ... completedSteps=[...] completedCutscenes=[...]`

Ces logs permettent de vérifier précisément:

1. quand `reachedEnd` arrive,
2. pourquoi la complétion est retardée,
3. quand la barrière se débloque,
4. quand la progression est réellement écrite.

## 8) Non-régression et validation

Tests exécutés:

- `flutter test test/scenario_runtime_completion_gate_test.dart`
- `flutter test test/step_studio_completion_runtime_test.dart test/step_studio_save_reload_visibility_integration_test.dart` dans `packages/map_runtime`

Résultat: **OK**.

Points de compatibilité conservés:

- cutscenes purement dialogue: la complétion reste quasi immédiate (pas de blocage)
- cutscenes avec actions bloquantes visibles: complétion retardée jusqu'à fin réelle
- save/reload: inchangé sur le format de persistance
- règles de présence PNJ: inchangées, mais déclenchées au bon moment

## 9) Compromis

- Le gating est volontairement conservateur: il préfère retarder légèrement la complétion plutôt que masquer un PNJ trop tôt.
- Aucun contournement data n'a été ajouté: la correction est purement runtime et sémantique.

## 10) Vérification manuelle recommandée (Emma)

1. Démarrer la scène `premier_dialogue_avec_le_professeur_emma`.
2. Observer les logs `completion_deferred` puis `completion_gate_blocked` (si follow/move actif).
3. Vérifier qu'Emma reste visible pendant la mise en scène.
4. Attendre la fin réelle de la séquence.
5. Vérifier `completion_gate_unblocked` puis `completion_applied`.
6. Confirmer que la disparition d'Emma intervient après cette vraie fin runtime.
