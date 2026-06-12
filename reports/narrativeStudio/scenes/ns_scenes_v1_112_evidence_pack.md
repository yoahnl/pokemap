# NS-SCENES-V1-112 — Evidence Pack

Evidence Pack refait le 2026-06-12 après correction UX post-gate demandée par Karim.

## 1. Lot

Lot : `NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0`.

Correctif intégré au même paquet de preuves : destination `actorMove` compréhensible et ajout de point de passage robuste.

Repo : `/Users/karim/Project/pokemonProject`.

Branche :

```text
main
```

## 2. Règles / audit

Règles lues avant réécriture :

- `AGENTS.md`
- `skills/README.md`
- `codex_rule.md`
- skill `verification-before-completion`

Sortie règles historique du lot :

```text
AGENTS.md      342
agent_rules.md      107
codex_rule.md      123
MISSING codex_rules.md
```

Lecture de `codex_rule.md` confirmée : les rapports doivent contenir audit initial, verdicts des passes/sub-agents, fichiers modifiés, contenu des fichiers créés, zones modifiées, commandes, résultats, état git et critique finale.

## 3. Passes / sub-agents

- Audit / Architecture : PASS. `map_core` fournit la frame playback ; l'UI ne recalcule pas les routes.
- Implémentation : PASS. L'adaptateur editor-only transforme uniquement le modèle overlay acteur.
- Tests : PASS. Tests V1-112 + régressions UX + suite complète builder.
- Build / Validation : PASS. Build macOS debug réussi.
- Critique finale : PASS avec limite sub-tuile connue.

## 4. Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 5. Fichiers créés

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart
reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_112_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png
```

Le PNG est binaire ; son contenu n'est pas reproduit, mais la preuve `ls/file/shasum` est fournie.

## 6. Contenu complet du fichier code créé

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

## 7. Zones modifiées

Playback :

```text
cinematic_builder_workspace.dart
- import cinematic_preview_playback_actor_overlay_adapter.dart
- buildCinematicPreviewPlaybackActorOverlayModel(displayModel, playbackFrame)
- actorPlaybackPreviewModel transmis au sandbox
```

Overlay backdrop :

```text
cinematic_map_backdrop_preview_panel.dart
- ajout du paramètre actorPlaybackPreviewModel
- fallback actorPlaybackPreviewModel ?? actorDisplayPreviewModel
```

Correctif Karim :

```text
cinematic_builder_workspace.dart
- _AddManualPathWaypointCallback accepte step + path nullable
- _addManualPathWaypoint crée addCinematicManualPathForActorMove si path absent
- _ActorMoveControls affiche "Repère final du déplacement"
- _ActorMoveControls permet de choisir un stage point comme destination actorMove
- _MovementTargetPicker garde le choix avancé de destination si plusieurs cibles existent
```

Libellé par défaut :

```text
narrative_workspace_canvas.dart
- addCinematicMovementTarget(... label: 'Destination')

cinematic_builder_workspace_test.dart
- harness aligné sur label: 'Destination'
```

## 8. Tests ajoutés ou modifiés

Tests ajoutés :

```text
V1-112 moves direct actorMove actor during playback and resets to start
V1-112 follows manual path actorMove poses without mutating waypoints
captures V1-112 cinematic actorMove preview playback visual gate
binds actor movement destination to a stage point from the action inspector
V1-108 — adding a waypoint creates the manual path when missing
```

Test modifié :

```text
adds edits and removes actor movement authoring block
```

Raison : le bouton de suppression est plus bas dans l'inspecteur depuis l'ajout de la destination lisible ; le test scrolle maintenant avant de cliquer.

## 9. Commandes test

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-112|binds actor movement destination|adding a waypoint creates the manual path"
```

Sortie finale exacte :

```text
00:05 +5: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie finale exacte :

```text
00:57 +216: All tests passed!
```

## 10. Commande analyse

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart
```

Sortie finale exacte :

```text
Analyzing 4 items...
37 issues found. (ran in 6.5s)
```

Verdict : PASS, exit code `0`. Les 37 issues sont des infos `prefer_const*` non fatales.

## 11. Commande build

```bash
cd packages/map_editor && flutter build macos --debug
```

Sortie finale exacte :

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

Verdict : PASS, exit code `0`.

## 12. Visual Gate

```bash
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png
```

Sortie exacte :

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
git diff --stat
```

Sortie avant réécriture finale des deux rapports :

```text
 .../cinematics/cinematic_builder_workspace.dart    | 212 ++++++-
 .../cinematic_map_backdrop_preview_panel.dart      |  41 +-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |   2 +-
 .../test/cinematic_builder_workspace_test.dart     | 700 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  18 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  21 +-
 6 files changed, 937 insertions(+), 57 deletions(-)
```

```bash
git diff --name-only
```

Sortie avant réécriture finale des deux rapports :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
```

Sortie : vide pour les deux commandes.

## 14. État git final attendu après réécriture rapports

Les rapports eux-mêmes restent non stagés et non commités, conformément à la demande actuelle qui ne demandait pas de commit.

```text
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

## 15. Verdict

`NS-SCENES-V1-112 : DONE — actorMove preview playback branché + correction UX destination/repère documentée.`

## 16. Limites honnêtes

- Les poses playback sont projetées en coordonnées entières dans l'overlay existant.
- La sauvegarde disque reste un acte global du projet ; le builder met à jour le manifeste en mémoire.
- Pas de runtime, Flame, pathfinding, collision, route libre ou V1-113.
