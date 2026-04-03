# LOT 63 — NPC Patrol: séparation passabilité pathfinding vs collision runtime

## 1. Résumé exécutif

Tu as bien identifié la régression: le correctif “fidelity waypoint” avait amélioré la planification mais brouillait la frontière conceptuelle entre:

- passabilité pour planifier une route;
- collision stricte au moment d’exécuter chaque step.

Correctif livré:

1. séparation explicite des responsabilités;
2. validation runtime de step avant démarrage (collision complète, sans traversée);
3. maintien du non auto-blocage pour pathfinding;
4. tests ajoutés sur joueur / NPC bloquant / obstacle / auto-collision.

---

## 2. Analyse demandée: où `_isNpcCellBlockedForScriptedMovement(...)` était utilisé

Avant ce lot, la callback (renommée ensuite) était utilisée dans `ScriptedEntityMovementController` pour:

- **planification initiale** (`moveEntityTo` -> `GridPathfinder.findPath`);
- **replan/validation dynamique** dans `_tickActiveMoves` quand le prochain node devient bloqué.

Elle n’était **pas** un vrai garde-fou dédié à la phase “démarrage réel d’un pas”.

Conséquence:

- frontière conceptuelle floue entre “can plan path” et “can execute step now”.

---

## 3. Frontière conceptuelle corrigée

## 3.1 Path planning passability

Responsabilité:

- décider si une case ancre est éligible au pathfinding;
- auto-ignore autorisé pour l’entité courante (éviter auto-collision artificielle);
- bloqueurs dynamiques (joueur) pris en compte.

Implémentation:

- `PlayableMapGame._isNpcCellBlockedForRoutePlanning(...)`
- s’appuie sur `evaluateScriptedNpcAnchorPassability(...)`
- inclut `dynamicBlockedCells: [_world.player.pos]`

## 3.2 Runtime step collision

Responsabilité:

- juste avant `startGridStep`, vérifier que le step est encore valide dans l’état courant;
- refuser explicitement si collision (joueur, NPC, obstacle, OOB, etc.).

Implémentation:

- nouveau callback `validateEntityStep` injecté au contrôleur;
- dans `PlayableMapGame`: `_validateScriptedNpcStepRuntimeCollision(...)`
- dans contrôleur: stop + `failed` si validation runtime renvoie une raison.

---

## 4. Changements techniques

## 4.1 Nouveau helper footprint-aware + bloqueurs dynamiques

Fichier:

- `packages/map_runtime/lib/src/application/scripted_npc_anchor_passability.dart`

Ajout:

- `dynamicBlockedCells` (ex: position joueur);
- validation par footprint collision réel (`resolveEntityCollisionCells`).

## 4.2 Contrôleur de déplacement: nouvelle validation de step

Fichier:

- `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart`

Ajout:

- `typedef ScriptedEntityStepValidation = String? Function(...)`
- paramètre constructeur `validateEntityStep`
- garde-fou dans `_tickActiveMoves` avant `_startEntityStep`.

## 4.3 PlayableMapGame: séparation des callbacks

Fichier:

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Modifs:

- `isCellBlocked` du contrôleur -> `_isNpcCellBlockedForRoutePlanning`
- nouveau `validateEntityStep` -> `_validateScriptedNpcStepRuntimeCollision`
- les deux utilisent le helper footprint-aware, avec blocage joueur dynamique.

## 4.4 Exports runtime

Fichier:

- `packages/map_runtime/lib/map_runtime.dart`

Ajout export:

- `ScriptedEntityStepValidation`

---

## 5. Réponse précise aux vérifications demandées

### 5.1 Waypoint top-left/centre/pieds

- Waypoint stocké/lu = **ancrage logique `MapEntity.pos` (top-left)**.
- Collision peut être offset (NPC 2x2 par défaut: 1x1 sur les pieds).

### 5.2 NPC 2x2 et cible `(26,22)`

- la cible est **gardée telle quelle** (pas de remap voisin implicite);
- passabilité est évaluée sur footprint collision réel à cet ancrage.

### 5.3 Pathfinding remplace-t-il la destination?

- non.
- destination finale reste le waypoint demandé.
- en cas d’inatteignable: échec explicite, patrouille arrêtée.

### 5.4 Route tronquée / segment partiel

- pas de fallback silencieux;
- si step impossible au runtime: statut `failed` avec raison.

### 5.5 `resolveNpcDefaultPatrolRoute(...)`

- ne transforme pas les waypoints;
- lit + construit la route runtime directe.

---

## 6. Logs temporaires de debug (ajoutés)

Présents dans:

- `npc_overworld_movement_defaults.dart`
  - lecture position initiale + waypoints bruts
  - route retenue
- `scripted_entity_movement_controller.dart`
  - requête move
  - résultat pathfinding
  - raison d’échec
- `playable_map_game.dart`
  - anchor bloqué (planning)
  - step runtime rejeté + raison

---

## 7. Tests ajoutés/renforcés

## 7.1 Nouveau test fichier

- `packages/map_runtime/test/scripted_npc_anchor_passability_test.dart`

Cas couverts:

1. NPC scripté ne peut pas traverser le joueur (`dynamicBlockedCells`);
2. NPC scripté ne peut pas traverser un autre NPC bloquant;
3. NPC 2x2 ne peut pas traverser un obstacle (collision layer);
4. auto-collision non bloquante pour sa propre position (non self-block).

## 7.2 Test contrôleur renforcé

- `packages/map_runtime/test/scripted_entity_movement_controller_test.dart`

Cas ajouté:

- patrouille stoppée explicitement si waypoint inatteignable.

---

## 8. Validations exécutées

Analyze ciblé:

```bash
cd packages/map_runtime
flutter analyze \
  lib/src/application/scripted_npc_anchor_passability.dart \
  lib/src/application/scripted_entity_movement_controller.dart \
  lib/src/presentation/flame/playable_map_game.dart \
  lib/map_runtime.dart \
  test/scripted_npc_anchor_passability_test.dart \
  test/scripted_entity_movement_controller_test.dart
```

Résultat: `No issues found`.

Tests ciblés:

```bash
cd packages/map_runtime
flutter test \
  test/scripted_entity_movement_controller_test.dart \
  test/scripted_npc_anchor_passability_test.dart \
  test/npc_overworld_movement_defaults_test.dart
```

Résultat: `All tests passed`.

---

## 9. Fichiers modifiés

- `packages/map_runtime/lib/src/application/scripted_npc_anchor_passability.dart`
- `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/test/scripted_npc_anchor_passability_test.dart`
- `packages/map_runtime/test/scripted_entity_movement_controller_test.dart`

---

## 10. Limites restantes

- Les logs debug sont volontairement verbeux (temporaires).
- Le modèle d’ancrage waypoint reste `MapEntity.pos` (top-left) — cohérent mais peut surprendre visuellement pour certains sprites/footprints.

