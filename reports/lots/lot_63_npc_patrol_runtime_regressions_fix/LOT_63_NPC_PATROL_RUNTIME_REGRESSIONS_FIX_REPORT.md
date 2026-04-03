# LOT 63 — Correctif runtime régressions patrouille NPC (collision / eau / interaction)

## 1. Résumé exécutif honnête

Trois régressions runtime ont été corrigées côté `map_runtime`:

1. **Traversée joueur/NPC**: le commit de position canonique NPC était trop tôt (au démarrage du pas), ce qui désynchronisait visuel vs collision/interactions.
2. **NPC walk sur eau**: la validation de passabilité scriptée ne tenait compte que des collisions dures, pas des surfaces interdites (`waterRequiresSurf`).
3. **Interaction dialogue cassée après déplacement**: même cause racine que (1), la position utilisée par `entityAt(...)` pouvait diverger de la position visuelle pendant un pas.

Le correctif principal a été de **séparer explicitement**:

- passabilité de **planification** (pathfinding),
- validation de **pas runtime** (au moment du step),
- mise à jour de la **position canonique** du monde (collision/interactions), désormais committée en fin de pas.

---

## 2. Audit précis des causes racines

### A. Pourquoi le PNJ traversait encore

Cause racine:

- le contrôleur scripté commitait la position runtime (`_onEntityPositionCommitted`) **au démarrage** de chaque step, pas à la fin.
- Résultat: le monde logique libérait immédiatement l’ancienne case alors que le sprite était encore visuellement dessus.
- Effet observable: traversées visuelles (joueur/NPC/NPC) et collision perçue incohérente.

Fichiers concernés:

- `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

### B. Pourquoi le PNJ allait sur l’eau

Cause racine:

- `evaluateScriptedNpcAnchorPassability(...)` utilisait `world.isBlocked(...)` (collision dure) mais pas `movementBlockReasonAt(...)`.
- Donc les cellules eau non marquées en collision dure restaient passables pour un NPC en mode marche.

Fichier concerné:

- `packages/map_runtime/lib/src/application/scripted_npc_anchor_passability.dart`

### C. Pourquoi l’interaction dialogue était cassée après déplacement

Cause racine:

- l’interaction utilise `stepGameplayWorld(..., InteractIntent())` puis `world.entityAt(celluleDevantJoueur)`.
- `entityAt` lit la **source canonique** (`GameplayWorldState`) et non la position visuelle Flame.
- avec commit anticipé au démarrage du pas, la position canonique pouvait être en avance sur le rendu.
- Effet: PNJ visible à un endroit, interactable à un autre (ou plus difficilement interactable).

Fichiers concernés:

- `packages/map_gameplay/lib/src/gameplay_step.dart` (lecture interaction)
- `packages/map_gameplay/lib/src/gameplay_world_state.dart` (source canonique)
- `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart` (timing du commit)

---

## 3. Frontière conceptuelle corrigée

### Avant (incorrect)

- même notion de “passabilité” utilisée de fait pour plusieurs responsabilités;
- commit canonique au mauvais moment (start step);
- surfaces runtime (eau) non intégrées à la validation NPC walk.

### Après (correct)

1. **Planification de route**
   - Utilise le callback `isCellBlocked` + auto-ignore de l’entité courante.
   - Sert à construire un chemin possible.

2. **Validation runtime d’un step**
   - Utilise `validateEntityStep` juste avant lancement effectif du pas.
   - Revalide collisions dynamiques et passabilité au moment réel du move.

3. **Position canonique interaction/collision**
   - Commit différé en fin de pas (quand l’animation est terminée).
   - Maintient l’alignement visuel ↔ gameplay (`entityAt`, collisions, interactions).

---

## 4. Implémentation détaillée

## 4.1 `scripted_npc_anchor_passability.dart`

### Changement

- Ajout du paramètre:
  - `MovementMode movementMode = MovementMode.walk`
- Validation par cellule via:
  - `world.movementBlockReasonAt(...)`
  - au lieu de `world.isBlocked(...)` seul

### Effet

- Les surfaces eau nécessitant surf sont maintenant bloquantes pour NPC walk.
- Les raisons d’échec sont explicites dans `reason` (`waterRequiresSurf`, `solid`, etc.).

---

## 4.2 `playable_map_game.dart`

### Changements

- `_isNpcCellBlockedForRoutePlanning(...)`
  - utilise `movementMode: MovementMode.walk`
  - injecte des bloqueurs dynamiques via `_scriptedNpcDynamicBlockedCells()`
- `_validateScriptedNpcStepRuntimeCollision(...)`
  - même logique, mais pour validation runtime d’un pas concret
- Ajout:
  - `_scriptedNpcDynamicBlockedCells()`
  - `_renderedPlayerFootGridCell()`

### Décision importante

Les bloqueurs dynamiques incluent:

1. `world.player.pos` (canonique),
2. cellule visuelle actuelle des pieds du joueur (pendant interpolation).

But: éviter les traversées visuelles quand le joueur est en transition de pas.

---

## 4.3 `scripted_entity_movement_controller.dart`

### Changement structurel clé

Le commit canonique via `_onEntityPositionCommitted(...)` est maintenant **différé**:

- à start step:
  - on met à jour `_trackedPositions` (progression interne route),
  - on stocke `pendingRuntimeCommit`,
- au tick suivant quand `isEntityStepping == false`:
  - on applique le commit canonique.

### Effet

- collisions/interactions restent alignées avec ce que le joueur voit;
- plus de libération prématurée de cellule;
- meilleure cohérence pour `InteractIntent`.

---

## 4.4 Tests

### `scripted_npc_anchor_passability_test.dart`

Ajouts/renforcements:

- blocage sur cellule joueur dynamique;
- blocage sur autre NPC bloquant;
- blocage obstacle avec NPC 2x2;
- out-of-bounds explicite;
- **nouveau**: self-occupancy ignorée (pas d’auto-blocage);
- **nouveau**: NPC walk bloqué sur eau (`waterRequiresSurf`).

### `scripted_entity_movement_controller_test.dart`

- ajusté au nouveau contrat de commit différé.
- conserve la couverture:
  - déplacement ponctuel,
  - patrouille loop/non-loop,
  - pause,
  - override scripté puis reprise patrouille,
  - arrêt explicite si waypoint inatteignable.

### `scripted_npc_runtime_interaction_test.dart` (nouveau)

- vérifie qu’un NPC déplacé dans la source canonique reste interactable sur sa nouvelle position;
- vérifie que l’ancienne position n’est plus interactable;
- dialogue toujours présent après déplacement.

---

## 5. Fichiers modifiés

- `packages/map_runtime/lib/src/application/scripted_npc_anchor_passability.dart`
- `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/scripted_entity_movement_controller_test.dart`
- `packages/map_runtime/test/scripted_npc_anchor_passability_test.dart`

## 6. Fichiers créés

- `packages/map_runtime/test/scripted_npc_runtime_interaction_test.dart`
- `reports/lots/lot_63_npc_patrol_runtime_regressions_fix/LOT_63_NPC_PATROL_RUNTIME_REGRESSIONS_FIX_REPORT.md`

---

## 7. Extraits de code clés

### A. Validation surface + collision (passability helper)

```dart
final movementBlockReason = world.movementBlockReasonAt(
  x: cell.x,
  y: cell.y,
  movementMode: movementMode,
);
if (movementBlockReason != null) {
  return ScriptedNpcAnchorPassabilityResult(
    passable: false,
    reason:
      'Blocked collision cell (...) reason=${movementBlockReason.name}.',
    evaluatedCollisionCells: collisionCells,
  );
}
```

### B. Commit canonique différé

```dart
if (task.pendingRuntimeCommit != null) {
  _onEntityPositionCommitted(entityId, task.pendingRuntimeCommit!);
  task.pendingRuntimeCommit = null;
}
...
_trackedPositions[entityId] = next;
task.pendingRuntimeCommit = next;
```

### C. Bloqueurs dynamiques joueur (canonique + visuel)

```dart
Iterable<GridPos> _scriptedNpcDynamicBlockedCells() sync* {
  yield _world.player.pos;
  final rendered = _renderedPlayerFootGridCell();
  if (rendered != null && rendered != _world.player.pos) {
    yield rendered;
  }
}
```

---

## 8. Validations exécutées

Commandes réellement lancées:

1. `dart format` sur fichiers modifiés runtime/tests
2. `flutter analyze` ciblé:
   - `scripted_npc_anchor_passability.dart`
   - `scripted_entity_movement_controller.dart`
   - `playable_map_game.dart`
   - tests runtime touchés
3. `flutter test` ciblé:
   - `test/scripted_entity_movement_controller_test.dart`
   - `test/scripted_npc_anchor_passability_test.dart`
   - `test/scripted_npc_runtime_interaction_test.dart`

Résultats:

- `flutter analyze` ciblé: **OK, 0 issue**
- `flutter test` ciblé: **OK, all tests passed**

---

## 9. Ce qui n’a pas été fait volontairement

- Pas de changement UI / `map_editor`.
- Pas de refonte narrative/story.
- Pas d’extension du système de movement modes NPC (on reste sur `walk` pour ce lot).
- Pas de changement sur Global Story / Step / Cutscene authoring.

---

## 10. Limites restantes (honnêtes)

- Le blocage dynamique joueur utilise une approximation robuste (cellule canonique + cellule visuelle des pieds), pas un volume multi-cellules complet.
- Le runtime reste mono-état simple pour ce MVP; pas de système avancé de réservation temporelle multi-acteurs.
- Les logs de debug ajoutés restent orientés diagnostic runtime (`[npc_patrol]`), à alléger plus tard si besoin.

---

## 11. Prochaines étapes recommandées

1. Ajouter un test d’intégration plus large `PlayableMapGame` simulant déplacement simultané joueur+NPC.
2. Centraliser la notion de “footprint dynamique joueur” si un mode futur impose un footprint > 1x1.
3. Exposer un diagnostic runtime optionnel (dev-only) pour visualiser cellule canonique vs cellule visuelle.

---

## 12. État git final exact

`git status --short` après ce lot:

```text
 M packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart
 M packages/map_runtime/lib/src/application/scripted_npc_anchor_passability.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/scripted_entity_movement_controller_test.dart
 M packages/map_runtime/test/scripted_npc_anchor_passability_test.dart
?? packages/map_runtime/test/scripted_npc_runtime_interaction_test.dart
?? reports/lots/lot_63_npc_patrol_runtime_regressions_fix/
```

