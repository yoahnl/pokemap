# NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0

Rapport refait le 2026-06-12 après correction UX post-gate demandée par Karim.

## 1. Résumé exécutif

V1-112 branche le playback acteur dans la preview du Cinematic Builder : le Builder consomme `CinematicPreviewPlaybackPlan.frameAt(playbackTimeMs)`, lit `CinematicPreviewPlaybackFrame.actorPoses`, puis injecte les poses dans le modèle d'affichage acteur existant via un adaptateur editor-only.

Résultat vérifié : pendant Play, un `actorMove` direct déplace visuellement l'acteur, un `actorMove` en Trajet manuel suit les poses calculées par V1-110, Pause fige la pose courante, Stop et Reset reviennent à la pose initiale. Aucun runtime, Flame, GameState, pathfinding, collision, scrubber/seek, animation de marche ou persistance du temps n'a été ajouté.

Correction UX ajoutée après les captures utilisateur : l'inspecteur `actorMove` expose maintenant la destination comme un vrai repère final de déplacement. Le libellé technique `Picker label + id stable` a été remplacé par `Repère final du déplacement`, le choix d'un repère crée un binding `CinematicMovementTargetBindingKind.stagePoint`, et l'ajout d'un point de passage crée le `manualPath` si le chemin manuel n'existe pas encore.

## 2. Scope confirmé

Inclus :

- preview actorMove locale dans le Cinematic Builder ;
- consommation de `actorPoses` produites par V1-110 ;
- transport V1-111 conservé ;
- overlay acteur editor-only ;
- correctif UX destination/repère demandé par Karim ;
- tests widget ciblés et suite complète du builder ;
- build macOS debug.

Exclus volontairement :

- runtime, Flame, GameState, `PlayableMapGame`, `SceneRuntimeExecutor`, `CinematicRuntimeAdapter` ;
- pathfinding, collision, interpolation recalculée côté UI ;
- scrubber, seek, drag playhead, persistance de `playbackTimeMs` ;
- animation de marche, audio runtime, caméra runtime ;
- `manualPathId` côté `actorMove`, waypoints libres, coordonnées libres ;
- V1-113.

## 3. Audit initial

Prompt audité : `/Users/karim/.codex/attachments/b17f7405-5cfd-4d96-8cb2-7e6c699dfc9a/pasted-text.txt`.

Règles lues :

```text
AGENTS.md      342
agent_rules.md      107
codex_rule.md      123
MISSING codex_rules.md
```

Constats :

- V1-110 fournit déjà le read model pur `CinematicPreviewPlaybackPlan` et `CinematicPreviewPlaybackFrame`.
- V1-111 fournit déjà le transport local editor-only.
- `CinematicActorDisplayPreviewOverlay` sait afficher les acteurs mais ne devait pas devenir un moteur de playback.
- Le bug UX signalé après V1-112 venait de deux ambiguïtés :
  - `Cible` était un libellé de destination abstraite, pas un repère final compréhensible.
  - le bouton `Ajouter un repère` ignorait la sélection si aucun `manualPath` n'existait encore.

## 4. État git initial et état de reprise

État initial du lot V1-112 : arbre propre avant modification.

État de reprise avant réécriture des rapports :

```text
git branch --show-current
main

git log --oneline -n 5
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
3ed90377 fix: corrections tests et rapports v1.108

git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_112_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png
```

## 5. Sub-agents / passes séparées

- Sub-agent Audit / Architecture : PASS. Contrat V1-110 consommé, pas de recalcul UI.
- Sub-agent Implémentation : PASS. Adaptateur editor-only + propagation du modèle overlay playback.
- Sub-agent UX Correctif Karim : PASS. Destination actorMove reliée à un repère final visible ; `Cible` remplacé par `Destination` à la création UI.
- Sub-agent Tests : PASS. Tests V1-112 + régressions UX + suite complète builder.
- Sub-agent Build / Validation : PASS. `flutter build macos --debug` OK.
- Sub-agent Critique finale : PASS avec limite connue sur la précision sub-tuile de l'overlay acteur.

## 6. Fichiers modifiés et créés

Modifiés :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Créés :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_112_evidence_pack.md`

## 7. Détail par fichier

`cinematic_preview_playback_actor_overlay_adapter.dart`

- Zone : `buildCinematicPreviewPlaybackActorOverlayModel`.
- Raison : consommer `CinematicPreviewPlaybackFrame.actorPoses` sans polluer l'overlay existant.
- Impact : l'overlay acteur reste no-code et statique dans son contrat, mais sa position affichée suit la frame playback quand elle existe.

`cinematic_builder_workspace.dart`

- Zones V1-112 : import de l'adaptateur, calcul `playbackActorOverlayModel`, passage à `_PreviewSandbox`.
- Zones correctif UX : `_AddManualPathWaypointCallback`, `_addManualPathWaypoint`, `_ActorMoveControls`, `_MovementTargetPicker`.
- Impact : le playback bouge l'acteur ; le choix de destination est compréhensible ; l'ajout d'un repère manuel crée le chemin si nécessaire.

`cinematic_map_backdrop_preview_panel.dart`

- Zone : propagation optionnelle `actorPlaybackPreviewModel`.
- Impact : les chemins de rendu carte existants utilisent l'overlay playback quand il est disponible, sinon l'overlay statique.

`narrative_workspace_canvas.dart`

- Zone : `_addCinematicMovementTarget`.
- Impact : les nouvelles destinations créées depuis l'app s'appellent `Destination` au lieu de `Cible`.

`cinematic_builder_workspace_test.dart`

- Zones : tests V1-112, tests de destination actorMove, test de création automatique de `manualPath`, ajustement d'un scroll de test.
- Impact : couverture directe du symptôme signalé par Karim et non-régression du playback.

Roadmaps :

- `road_map_scenes.md`
- `road_map_scene_builder_authoring.md`

Impact : V1-112 est documenté comme terminé côté lot principal, avec prochain lot orienté V1-113.

## 8. Hunks / zones précises

Playback actor :

```diff
+import 'cinematic_preview_playback_actor_overlay_adapter.dart';
+
+    final playbackActorOverlayModel =
+        buildCinematicPreviewPlaybackActorOverlayModel(
+      displayModel: widget.actorDisplayPreviewModel,
+      playbackFrame: playbackFrame,
+    );
+
+                                  actorPlaybackPreviewModel:
+                                      playbackActorOverlayModel,
```

Manual path qui se crée au clic :

```diff
-typedef _AddManualPathWaypointCallback = Future<void> Function(
-    CinematicManualPath path, String stagePointId);
+typedef _AddManualPathWaypointCallback = Future<void> Function(
+  CinematicTimelineStep step,
+  CinematicManualPath? path,
+  String stagePointId,
+);

+      if (path == null || path.id.isEmpty) {
+        final result = addCinematicManualPathForActorMove(
+          dummyProject,
+          cinematicId: widget.asset.id,
+          actorMoveStepId: step.id,
+          waypointStagePointIds: [stagePointId],
+        );
+        await _updateCinematic(result.cinematic);
+        return;
+      }
```

Destination no-code :

```diff
-          subtitle: 'Picker label + id stable',
+          subtitle: 'Repère final du déplacement',

+          _MutedText(
+            destinationStagePoint == null
+                ? 'Choisissez un repère pour que le déplacement puisse être prévisualisé.'
+                : 'Destination actuelle : ${destinationStagePoint.label}',
+          ),
```

Label par défaut :

```diff
-        label: 'Cible',
+        label: 'Destination',
```

## 9. Contenu complet du fichier code créé

`packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart`

```dart
import 'package:map_core/map_core.dart';

/// Builds the actor display model used by the preview overlay during local
/// editor playback.
///
/// V1-112 deliberately keeps movement calculation in `map_core`: this adapter
/// only reads `CinematicPreviewPlaybackFrame.actorPoses` and copies those
/// positions into the existing actor display model consumed by the overlay.
CinematicActorDisplayPreviewModel?
    buildCinematicPreviewPlaybackActorOverlayModel({
  required CinematicActorDisplayPreviewModel? displayModel,
  required CinematicPreviewPlaybackFrame? playbackFrame,
}) {
  if (displayModel == null || playbackFrame == null) {
    return displayModel;
  }

  final actors = <CinematicActorDisplayPreviewActor>[];
  for (final actor in displayModel.actors) {
    final pose = playbackFrame.actorPoseById(actor.actorId);
    if (pose == null || !pose.hasPosition) {
      actors.add(actor);
      continue;
    }

    // The existing actor overlay is tile-anchored and consumes integer display
    // positions. We still consume the playback pose as the source of truth, but
    // project it into the current overlay contract instead of introducing a
    // second renderer in this lot.
    actors.add(
      CinematicActorDisplayPreviewActor(
        actorId: actor.actorId,
        label: actor.label,
        role: actor.role,
        bindingStatus: actor.bindingStatus,
        bindingKind: actor.bindingKind,
        bindingSourceId: actor.bindingSourceId,
        bindingSourceLabel: actor.bindingSourceLabel,
        position: CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: actor.position.sourceKind,
          x: pose.x!.round(),
          y: pose.y!.round(),
          sourceId: actor.position.sourceId,
          sourceLabel: actor.position.sourceLabel,
        ),
        appearance: actor.appearance,
        direction: pose.facing == CinematicActorPreviewDirection.unknown
            ? actor.direction
            : pose.facing,
        directionSource: pose.facing == CinematicActorPreviewDirection.unknown
            ? actor.directionSource
            : CinematicActorPreviewDirectionSource.actorFace,
        renderHint: actor.renderHint,
        diagnostics: actor.diagnostics,
      ),
    );
  }

  return CinematicActorDisplayPreviewModel(
    status: displayModel.status,
    summary: displayModel.summary,
    actors: actors,
    diagnostics: displayModel.diagnostics,
  );
}
```

Le PNG Visual Gate est binaire ; il est prouvé par `ls`, `file` et `shasum` dans l'Evidence Pack.

## 10. Tests créés / modifiés

Ajoutés :

- `V1-112 moves direct actorMove actor during playback and resets to start`
- `V1-112 follows manual path actorMove poses without mutating waypoints`
- `captures V1-112 cinematic actorMove preview playback visual gate`
- `binds actor movement destination to a stage point from the action inspector`
- `V1-108 — adding a waypoint creates the manual path when missing`

Modifié :

- `enables actor movement only after actor and target exist` attend désormais `Destination` au lieu de `Cible`.
- `adds edits and removes actor movement authoring block` scrolle jusqu'au bouton de suppression, car l'inspecteur actorMove contient plus d'informations utiles.

## 11. Commandes et résultats

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-112|binds actor movement destination|adding a waypoint creates the manual path"
```

```text
00:05 +5: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

```text
00:57 +216: All tests passed!
```

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart
```

```text
Analyzing 4 items...
37 issues found. (ran in 6.5s)
```

Résultat : exit code `0`. Les 37 entrées sont des infos `prefer_const*` non fatales.

```bash
cd packages/map_editor && flutter build macos --debug
```

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 12. Visual Gate

```bash
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png
```

```text
-rw-r--r--  1 karim  staff   223K Jun 12 19:36 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
a53f2d0e5d4538afa8c5fbcffdab7ae481dd90f191c64c4290c0b78dd31baa4d  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png
```

## 13. Git / anti-scope

```bash
git diff --check
```

Sortie : vide, exit code `0`.

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
```

Sortie : vide pour les deux commandes.

## 14. Limites conservées

- L'overlay acteur existant consomme encore des coordonnées entières de tuiles. La frame playback reste la source de vérité, mais V1-112 projette par arrondi dans le contrat existant.
- Le bouton de sauvegarde global du projet reste responsable de l'écriture disque. Le builder applique bien les changements au `ProjectManifest` en mémoire.
- La correction ne crée pas de système multi-acteurs, ni d'éditeur de route libre, ni de coordonnées libres.
- Les infos `prefer_const*` de l'analyse restent hors scope.

## 15. Auto-critique finale

Points solides :

- V1-112 consomme bien `actorPoses` au lieu de recalculer l'actorMove dans l'UI.
- Le symptôme utilisateur `Cible` abstraite est corrigé dans l'inspecteur.
- Le clic sur `Ajouter un repère` ne peut plus être ignoré faute de `manualPath`.
- La suite complète du builder et le build macOS debug passent.

Risques restants :

- Le rendu acteur reste tile-rounded ; un lot futur devra décider si l'overlay doit supporter des positions sub-tuile.
- Le flux de sauvegarde disque peut encore sembler implicite si l'utilisateur ne remarque pas le statut projet modifié.

## 16. Prochaine étape proposée

Continuer avec `NS-SCENES-V1-113` uniquement après commit du lot actuel, ou prévoir un micro-lot UX pour clarifier visuellement le statut “modifié en mémoire / sauvegarder le projet”.
