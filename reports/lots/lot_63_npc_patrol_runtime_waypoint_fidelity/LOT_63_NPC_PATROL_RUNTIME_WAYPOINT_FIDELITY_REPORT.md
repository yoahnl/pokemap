# LOT 63 — Runtime NPC Patrol: waypoint fidelity (analyse + correctif)

## 1. Résumé exécutif

Le JSON map était correct (waypoints persistés), mais la patrouille runtime n’était pas fidèle pour certains NPC (notamment `size=2x2`).

Cause racine identifiée:

- le pathfinding validait les cases avec un test mono-cellule (`world.isBlocked(x,y)`) basé implicitement sur l’ancrage `MapEntity.pos`;
- pour un NPC `2x2`, la collision réelle par défaut est `1x1` sur les “pieds” (offset), pas sur le coin haut-gauche;
- l’entité pouvait donc s’auto-bloquer pendant le pathfinding (cellule de collision actuelle), ce qui produisait des trajectoires aberrantes (dérive latérale).

Correctif appliqué:

- validation de passabilité basée sur le **footprint collision réel** de l’entité candidate;
- auto-collision correctement ignorée (uniquement pour l’entité courante);
- arrêt explicite de patrouille en cas de waypoint inatteignable (pas de fallback implicite);
- logs temporaires détaillés sur toute la chaîne (lecture waypoints, cible visée, pathfinding, échecs).

---

## 2. Diagnostic précis de la chaîne runtime (demandé)

## 2.1 Lecture des waypoints JSON

Point de lecture:

- `resolveNpcDefaultPatrolRoute(MapEntity entity)` dans `npc_overworld_movement_defaults.dart`

Constat:

- les waypoints sont lus tels quels depuis `entity.npc.movement.waypoints`;
- aucune transformation de coordonnées n’est appliquée.

## 2.2 Conversion en route runtime

Point de conversion:

- `resolveNpcDefaultPatrolRoute` -> `ScriptedEntityPatrolRoute`

Constat:

- la route runtime reprend exactement la liste ordonnée des waypoints;
- pas de remap “proche atteignable”.

## 2.3 Pathfinding utilisé

Point d’exécution:

- `ScriptedEntityMovementController.moveEntityTo()`
- `GridPathfinder.findPath(...)`

Constat avant fix:

- `isPassable` délégué à callback mono-cellule, insuffisant pour footprint réel NPC.

## 2.4 Validation des cases cibles

Avant fix:

- validation `world.isBlocked(x,y)` sur un seul `(x,y)`.

Après fix:

- validation sur toutes les cellules de collision de la position candidate (helper dédié).

## 2.5 Gestion des entités 2x2

Point clé:

- `resolveEntityCollisionCells(entity)` (map_core) applique:
  - collision NPC par défaut `1x1`
  - offset bas (pieds), pas forcément le coin haut-gauche visuel.

Impact:

- pour un NPC `2x2`, l’ancrage logique et la cellule collision visible peuvent diverger.

## 2.6 Ancrage exact de la position

Ancrage runtime conservé:

- `MapEntity.pos` (coin haut-gauche logique).

Important:

- ce n’est pas le “centre” ni la case des pieds.
- l’impression visuelle de décalage (ex: `(26,13)` alors que `pos=(26,12)`) vient du footprint collision/visual, pas d’un remap waypoint.

## 2.7 Position logique vs rendue

Le rendu actor suit le `GridPos` logique, mais la collision gameplay peut être évaluée sur une cellule offset.
Le correctif aligne le pathfinding sur cette réalité collision.

## 2.8 Fallback implicite

Avant:

- pas de remap explicite, mais la patrouille pouvait retenter silencieusement des cibles impossibles.

Après:

- si waypoint inatteignable: arrêt explicite de la patrouille + log raison.

---

## 3. Correctifs implémentés

## 3.1 Nouveau helper de passabilité footprint-aware

Nouveau fichier:

- `packages/map_runtime/lib/src/application/scripted_npc_anchor_passability.dart`

Ajout:

- `evaluateScriptedNpcAnchorPassability(...)`
- évalue toutes les cellules collision de la position candidate;
- gère:
  - entité inconnue,
  - out-of-bounds footprint,
  - collision monde,
  - auto-ignore de l’entité en cours.

## 3.2 Callback runtime de blocage corrigé

Fichier:

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Modif:

- `_isNpcCellBlockedForScriptedMovement(...)` utilise maintenant le helper footprint-aware.

Effet:

- fin de l’auto-collision artificielle sur NPC 2x2;
- passabilité cohérente avec la collision réelle.

## 3.3 Patrouille stricte en cas d’échec waypoint

Fichier:

- `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart`

Modif:

- dans `_tickPatrols`, si `moveEntityTo(...)` retourne `failed`:
  - suppression de la patrouille de l’entité,
  - log explicite.

Contrat:

- **waypoint exact ou échec explicite**;
- pas de fallback silencieux.

## 3.4 Logs de debug temporaires

Ajout de logs dans:

- `npc_overworld_movement_defaults.dart`
  - lecture initiale (entity pos/size, waypoints bruts)
  - route retenue
- `scripted_entity_movement_controller.dart`
  - request move (from -> to)
  - résultat pathfinding (nodes/steps)
  - raisons d’échec
  - arrêt explicite de patrouille
- `playable_map_game.dart`
  - anchor bloqué + footprint collision évalué + raison

---

## 4. Tests ajoutés/renforcés

## 4.1 Nouveau test footprint passability

Nouveau fichier:

- `packages/map_runtime/test/scripted_npc_anchor_passability_test.dart`

Couvre:

- NPC 1x1: reachable vs blocked;
- NPC 2x2: validation sur footprint collision réel;
- footprint out-of-bounds: échec explicite.

## 4.2 Test patrouille stricte

Fichier modifié:

- `packages/map_runtime/test/scripted_entity_movement_controller_test.dart`

Ajout:

- `patrol stops explicitly when next waypoint is unreachable`

---

## 5. Fichiers modifiés

- `packages/map_runtime/lib/src/application/scripted_npc_anchor_passability.dart` (créé)
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart`
- `packages/map_runtime/lib/src/application/npc_overworld_movement_defaults.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/test/scripted_npc_anchor_passability_test.dart` (créé)
- `packages/map_runtime/test/scripted_entity_movement_controller_test.dart`

---

## 6. Validations exécutées

Format:

```bash
dart format \
  packages/map_runtime/lib/src/application/scripted_npc_anchor_passability.dart \
  packages/map_runtime/lib/src/application/npc_overworld_movement_defaults.dart \
  packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart \
  packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart \
  packages/map_runtime/lib/map_runtime.dart \
  packages/map_runtime/test/scripted_npc_anchor_passability_test.dart \
  packages/map_runtime/test/scripted_entity_movement_controller_test.dart
```

Analyze ciblé:

```bash
cd packages/map_runtime
flutter analyze \
  lib/src/application/scripted_npc_anchor_passability.dart \
  lib/src/application/npc_overworld_movement_defaults.dart \
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

## 7. Limites restantes (honnêtes)

- logs de debug ajoutés sont verbeux (volontairement temporaires pour diagnostic);
- le lot ne change pas la sémantique d’ancrage `MapEntity.pos` (top-left);
- pas de conversion automatique de waypoints entre “position visuelle” et “pieds collision” (hors scope demandé).

---

## 8. Réponse explicite à la déviation observée

Pourquoi JSON correct mais mouvement incohérent:

1. Waypoints étaient bien persistés et lus;
2. la validation pathfinding utilisait une vérification mono-case;
3. pour NPC `2x2`, collision réelle décalée (footprint 1x1 offset);
4. le moteur pouvait s’auto-bloquer au lieu de suivre la descente attendue.

Ce qui corrige la déviation:

- passabilité footprint-aware + auto-ignore propre;
- arrêt strict sur waypoint invalide/inatteignable;
- logs explicites sur chaque étape (lecture, cible, path, échec).

