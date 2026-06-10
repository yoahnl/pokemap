# NS-SCENES-V1-104 — Evidence Pack

## 1. Audit Initial & Architecture (Sub-agent Audit)

Avant d'exécuter le lot, l'existant a été audité afin de s'assurer de la continuité avec V1-103 et de la conformité avec les règles du dépôt :
- **Fichiers ciblés** : 
  - `packages/map_core/lib/src/models/cinematic_asset.dart` (Enum)
  - `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart` (Authoring pure operations et transition de cibles)
  - `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart` (Résolution de position)
  - `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart` (Formatage de label timeline)
  - `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart` (Diagnostics statiques)
  - `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` (UI Sidebar picker & toggle option)
  - `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart` (Traduction des diagnostics)
- **Contrats et frontières** : Aucun fichier sous `map_runtime`, `map_gameplay` ou `map_battle` n'a été modifié. Aucune modification du runtime Flame ou du playback n'a été introduite.
- **Risques principaux** : Risque d'identifiants source zombies lors des transitions de types de cibles (par exemple en passant de `stagePoint` vers `abstractPoint`). Ce risque est neutralisé via des tests de transition directe et l'instanciation immuable des modèles de target binding.

---

## 2. Diffs & Zones Modifiées (Sub-agent Implémentation)

### packages/map_core/lib/src/models/cinematic_asset.dart
```diff
@@ -44,6 +44,7 @@ enum CinematicMovementTargetBindingKind {
   abstractPoint,
   mapEntity,
   mapEvent,
+  stagePoint,
 }
```

### packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
```diff
@@ -2236,7 +2236,8 @@ bool _movementTargetBindingRequiresSource(
   CinematicMovementTargetBinding binding,
 ) {
   return binding.kind == CinematicMovementTargetBindingKind.mapEntity ||
-      binding.kind == CinematicMovementTargetBindingKind.mapEvent;
+      binding.kind == CinematicMovementTargetBindingKind.mapEvent ||
+      binding.kind == CinematicMovementTargetBindingKind.stagePoint;
 }
```

### packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart
```diff
@@ -754,6 +755,7 @@ CinematicActorPreviewPosition _positionFromMovementTarget({
   required String? targetId,
   required Set<String> movementTargetIds,
   required Map<String, CinematicMovementTargetBinding> movementTargetBindings,
+  required List<CinematicStagePoint> stagePoints,
   required MapData? mapData,
   required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
 }) {
@@ -811,7 +813,44 @@ CinematicActorPreviewPosition _positionFromMovementTarget({
     );
   }
   final sourceId = binding.sourceId?.trim();
-  if (sourceId == null || sourceId.isEmpty || mapData == null) {
+  if (sourceId == null || sourceId.isEmpty) {
+    diagnostics.add(
+      CinematicActorDisplayPreviewDiagnostic(
+        code: CinematicActorDisplayPreviewDiagnosticCode
+            .actorDisplayMissingMovementTarget,
+        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
+        message: 'La cible de placement n a pas de source de map valide.',
+        actorId: actorId,
+        sourceId: normalizedTargetId,
+      ),
+    );
+    return CinematicActorPreviewPosition(
+      status: CinematicActorPreviewPositionStatus.missingSource,
+      sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
+      sourceId: normalizedTargetId,
+    );
+  }
+  if (binding.kind == CinematicMovementTargetBindingKind.stagePoint) {
+    final pos = _positionFromStagePoint(
+      actorId: actorId,
+      stagePointId: sourceId,
+      stagePoints: stagePoints,
+      mapData: mapData,
+      diagnostics: diagnostics,
+    );
+    return CinematicActorPreviewPosition(
+      status: pos.status,
+      sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
+      sourceId: normalizedTargetId,
+      x: pos.x,
+      y: pos.y,
+    );
+  }
+  if (mapData == null) {
```

### packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
```diff
@@ -98,10 +98,40 @@ CinematicTimelineLaneReadModel buildCinematicTimelineLaneReadModel(
     for (final actor in cinematic.requiredActors)
       actor.actorId: actor.label ?? actor.actorId,
   };
-  final targetLabels = <String, String>{
-    for (final target in cinematic.movementTargets)
-      target.targetId: target.label,
-  };
+  final targetLabels = <String, String>{};
+  for (final target in cinematic.movementTargets) {
+    var label = target.label;
+    final stageContext = cinematic.stageContext;
+    if (stageContext != null) {
+      CinematicMovementTargetBinding? binding;
+      for (final b in stageContext.movementTargetBindings) {
+        if (b.targetId == target.targetId) {
+          binding = b;
+          break;
+        }
+      }
+      if (binding != null) {
+        if (binding.kind == CinematicMovementTargetBindingKind.stagePoint) {
+          final sourceId = binding.sourceId;
+          CinematicStagePoint? point;
+          if (sourceId != null) {
+            for (final p in stageContext.stagePoints) {
+              if (p.id == sourceId) {
+                point = p;
+                break;
+              }
+            }
+          }
+          if (point != null) {
+            label = point.label;
+          } else {
+            label = '[Point de scène manquant]';
+          }
+        }
+      }
+    }
+    targetLabels[target.targetId] = label;
+  }
```

### packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
```diff
@@ -60,6 +60,9 @@ enum CinematicDiagnosticCode {
   actorInitialPlacementStagePointMissing,
   actorInitialPlacementStagePointWithoutStageMap,
   actorInitialPlacementStagePointOutOfMap,
+  movementTargetBindingStagePointMissing,
+  movementTargetBindingStagePointWithoutStageMap,
+  movementTargetBindingStagePointOutOfMap,
 }
```

---

## 3. Commandes lancées & Preuves d'exécution (Sub-agent Validation)

### Tests Unitaires Core (`map_core`)
```bash
cd packages/map_core && dart test
```
**Résultat** :
`All tests passed! (2458 tests)`

### Tests Workspace Widget (`map_editor`)
```bash
cd packages/map_editor && flutter test test/cinematic_builder_workspace_test.dart
```
**Résultat** :
`All tests passed! (202 tests)`

### Analyses Statiques
```bash
cd packages/map_core && dart analyze
```
**Résultat** : `No issues found!`

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart test/cinematic_builder_workspace_test.dart
```
**Résultat** : Aucune erreur bloquante. Seuls 27 warnings et infos pré-existants de syntaxe / const.

### Preuve de la Visual Gate
La Visual Gate a été capturée avec succès sous `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.png` via l'exécution de la commande de screenshot golden :
```bash
flutter test --update-goldens --dart-define=NS_SCENES_V1_104_CAPTURE_ACTOR_MOVE_TARGET_STAGE_POINT=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-104 actorMove target from stage point visual gate'
```

Vérification de l'intégrité de l'image de preuve :
```bash
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.png
# -rw-r--r--@ 1 karim  staff   304K Jun  9 00:50 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.png

file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.png
# reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.png
# ffbd6fe9f0ffdf231656f0acffb2007dbae69529449827e43838bf5896087049  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.png
```

---

## 4. État Git (Sub-agent Critique)

### État Git Initial
Le dépôt local contenait les modifications fonctionnelles du lot V1-104 en cours, avec tous les fichiers produit du package `map_core` et `map_editor` modifiés, sans fichiers générés superflus ni code de runtime.

### État Git Final
```text
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
 M packages/map_core/lib/src/models/cinematic_asset.dart
 M packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart
 M packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_diagnostics_test.dart
 M packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_104_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.png
```

---

## 5. Auto-critique & Qualité (Sub-agent Critique)

- **Force de l'implémentation** : L'intégration s'est faite de manière totalement propre sans forcer l'usage de codes ou widgets ad-hoc. L'utilisation du catalogue de sources `CinematicStageMapSourceCatalog` et le recyclage du helper `_positionFromStagePoint` ont permis d'éviter toute duplication de logique.
- **Diagnostics visuels** : La liaison de la cible de mouvement `Centre scène` sur le Stage Point valide `Point 2` a correctement résolu le diagnostic bloquant de liaison manquante hérité de V1-103.
- **Risques restants** : Aucun risque technique immédiat. Le scope est hermétiquement borné au builder de cinématiques en mode sandbox.

### Table de Quality Gate

| Règle / Critère | Statut (PASS/FAIL) | Preuve / Rationale |
|---|---|---|
| Non-modification du code runtime/Flame/gameplay | **PASS** | Les packages `map_runtime`, `map_gameplay`, `map_battle` sont restés intacts. |
| Préservation de l'immutabilité et rétrocompatibilité | **PASS** | `stagePoints` et `movementTargetBindings` sont décodés avec compatibilité descendante. |
| Aucune commande Git d'écriture | **PASS** | Seuls des `git diff`, `git status` et `ls/file/shasum` ont été exécutés en lecture seule. |
| Diagnostics de cohérence robustes | **PASS** | Les diagnostics `missing`, `without map` et `out of bounds` sont implémentés et testés. |
| Nettoyage de l'identifiant zombie | **PASS** | Les tests unitaires valident le reset de `sourceId` lors de transitions de cibles. |
| Golden de non-régression valide | **PASS** | Screenshot de Visual Gate à 1663x926 pixels généré avec succès. |

---

## 6. Prochaines Étapes Proposées (sans les implémenter)

`NS-SCENES-V1-105 — Cinematic Manual Path Authoring Prep Contract` : Cadrer le contrat de modélisation pour les chemins de déplacement manuels composés de multiples points et les outils d'édition graphique associés.
