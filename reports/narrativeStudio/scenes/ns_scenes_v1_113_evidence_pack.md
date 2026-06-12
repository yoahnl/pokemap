# NS-SCENES-V1-113 — Evidence Pack

## Lot

```text
NS-SCENES-V1-113 — Cinematic Actor Playback Smooth Motion / Sub-tile Overlay Polish V0
```

## Gate 0 complet

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
<vide>
<vide>
<vide>
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
3ed90377 fix: corrections tests et rapports v1.108
4670f42c update selbrume
caaa7f65 feat: cinematic manual path drawing UI et rapports v1.108
b54e1cd3 docs: ajout rapports v1.107 bis (nettoyage JSON et hardening)
ecb0d64b feat: cinematic manual path core model et tests
```

## Regles lues

```text
AGENTS.md : present
agent_rules.md : present
codex_rule.md : present
codex_rules.md : absent
```

`codex_rule.md` impose audit initial, passes type sub-agents, tests, build, et rapport detaille. Les passes sont documentees dans le rapport principal.

## Fichiers lus

```text
reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_110_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_111_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_112_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
packages/map_core/test/cinematic_actor_display_preview_model_test.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart
```

## Fichiers modifies

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Fichiers crees

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png
reports/narrativeStudio/scenes/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_113_evidence_pack.md
```

Le screenshot est binaire ; sa preuve complete est fournie par `ls`, `file` et `shasum`.

## Hunks pertinents

Adaptateur playback :

```diff
+final class CinematicActorPlaybackOverlayPose {
+  const CinematicActorPlaybackOverlayPose({
+    required this.actorId,
+    required this.x,
+    required this.y,
+  });
+
+  final String actorId;
+  final double x;
+  final double y;
+}
+
+final class CinematicActorPlaybackOverlayModel {
+  CinematicActorPlaybackOverlayModel({
+    required this.displayModel,
+    required Map<String, CinematicActorPlaybackOverlayPose> poseOverrides,
+  }) : poseOverrides =
+            Map<String, CinematicActorPlaybackOverlayPose>.unmodifiable(
+          poseOverrides,
+        );
+}
```

Suppression de l'ancien snapping :

```diff
-        position: CinematicActorPreviewPosition(
-          status: CinematicActorPreviewPositionStatus.resolved,
-          sourceKind: actor.position.sourceKind,
-          x: pose.x!.round(),
-          y: pose.y!.round(),
-          sourceId: actor.position.sourceId,
-          sourceLabel: actor.position.sourceLabel,
-        ),
+        position: actor.position,
```

Overlay acteur :

```diff
+  Offset _anchorForActor(
+    CinematicMapBackdropViewportTransform transform,
+    CinematicActorDisplayPreviewActor actor,
+  ) {
+    final override = playbackPoseOverrides[actor.actorId];
+    if (override != null) {
+      return transform.tileToPreview(override.x, override.y);
+    }
+    return transform.tileCenterBottom(
+      tileX: actor.position.x ?? 0,
+      tileY: actor.position.y ?? 0,
+    );
+  }
```

Workspace :

```diff
+    final isPlaybackOverlayActive =
+        _isPlaybackPlaying || playbackTimeMs > 0;
+    final playbackActorOverlayModel =
+        isPlaybackOverlayActive
+            ? buildCinematicPreviewPlaybackActorOverlayModel(
+                displayModel: widget.actorDisplayPreviewModel,
+                playbackFrame: playbackFrame,
+              )
+            : null;
```

## Preuve que l'ancien round() des poses playback a disparu

Commande :

```bash
rg -n "pose\\.x!\\.round|pose\\.y!\\.round|pose\\.x\\.round|pose\\.y\\.round|pose\\.x!\\.toInt|pose\\.y!\\.toInt|pose\\.x\\.toInt|pose\\.y\\.toInt|pose\\.x!\\.floor|pose\\.y!\\.floor|pose\\.x!\\.ceil|pose\\.y!\\.ceil" packages/map_editor/lib/src/ui/canvas/cinematics || true
```

Sortie :

```text
<vide>
```

## Preuve que l'UI consomme encore actorPoses

Hunk :

```dart
final pose = playbackFrame.actorPoseById(actor.actorId);
if (pose == null) {
  actors.add(actor);
  continue;
}
if (pose.hasPosition) {
  poseOverrides[actor.actorId] = CinematicActorPlaybackOverlayPose(
    actorId: actor.actorId,
    x: pose.x!,
    y: pose.y!,
  );
}
```

## Preuve que l'UI ne recalcule pas l'interpolation actorMove

Commande :

```bash
rg -n "lerp|lerpDouble|sqrt|hypot|RouteSegment|manualPath.*segment|segment.*manualPath|waypoint.*distance|distance.*waypoint" packages/map_editor/lib/src/ui/canvas/cinematics || true
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart:297:    final distance = math.sqrt(dx * dx + dy * dy);
```

Justification : cette occurrence est dans `_ManualPathLinePainter`, uniquement pour dessiner une ligne pointillee entre points deja calcules. Elle ne lit pas `actorPoses`, ne produit pas de pose acteur et ne recalcule pas actorMove.

## Tests core cibles

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Sortie :

```text
00:00 +12: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

Sortie :

```text
00:00 +27: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
```

Sortie :

```text
00:00 +4: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

## Tests editor cibles

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-113"
```

Sortie :

```text
00:05 +5: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie :

```text
00:33 +221: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

Sortie :

```text
00:06 +26: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_actor_sprite_preview_renderer_test.dart
```

Sortie :

```text
WARNING: Actor "Professor" (id: actor_prof) has a sprite source rect out of bounds. Source rect: x=1600, y=1600, width=16, height=16. Tileset image size: 256x256.
00:02 +21: All tests passed!
```

## Visual Gate generation

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_113_CAPTURE_CINEMATIC_ACTOR_PLAYBACK_SMOOTH_MOTION_SUBTILE=true test/cinematic_builder_workspace_test.dart --name "captures V1-113"
```

Sortie :

```text
00:04 +1: All tests passed!
```

## Analyse statique editor ciblee

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart test/cinematic_builder_workspace_test.dart test/cinematic_actor_sprite_preview_renderer_test.dart
```

Sortie :

```text
Analyzing 6 items...

   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1449:9 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1450:18 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1458:9 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1467:9 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:2943:19 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:2980:23 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:2991:23 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:2999:23 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3007:23 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3015:23 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3023:23 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:5141:13 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:5200:11 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:12047:26 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_actor_sprite_preview_renderer_test.dart:74:26 • prefer_const_constructors
   info • Use 'const' literals as arguments to constructors of '@immutable' classes. Try adding 'const' before the literal • test/cinematic_actor_sprite_preview_renderer_test.dart:75:17 • prefer_const_literals_to_create_immutables
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:12227:38 • prefer_const_constructors
   info • Use 'const' literals as arguments to constructors of '@immutable' classes. Try adding 'const' before the literal • test/cinematic_builder_workspace_test.dart:12228:17 • prefer_const_literals_to_create_immutables
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:12229:11 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:13516:36 • prefer_const_constructors
   info • Use 'const' literals as arguments to constructors of '@immutable' classes. Try adding 'const' before the literal • test/cinematic_builder_workspace_test.dart:13517:15 • prefer_const_literals_to_create_immutables
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:13518:9 • prefer_const_constructors

77 issues found. (ran in 3.8s)
```

Note : la commande retourne un code `0` avec `--no-fatal-infos`. La liste ci-dessus reproduit le signal utile et les bornes de la sortie ; toutes les issues sont des infos non fatales.

## Build macOS debug

Commande :

```bash
cd packages/map_editor && flutter build macos --debug
```

Sortie :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Visual Gate ls/file/shasum

Commandes :

```bash
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png
```

Sortie :

```text
-rw-r--r--  1 karim  staff   222K Jun 12 23:10 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
e80b175ab26559c5890db444e68ab3b5676eb304720d2c9cdcdb3a531ee27f15  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png
```

## Checks anti-scope obligatoires

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
```

Sortie :

```text
<vide>
```

Commande :

```bash
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
```

Sortie :

```text
<vide>
```

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_114*' -print
```

Sortie :

```text
<vide>
```

Commande :

```bash
rg -n "Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|Flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|pathfinding|collision|walkCycle|walkingAnimation|walking frame|walk frame|manualPathId|Scrubber|Seek|scrubber|seek|V1-114" packages/map_editor/lib/src/ui/canvas/cinematics || true
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart:12:/// NOTE: This overlay is purely editor-only. Playback interpolation, pathfinding, and actual
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:360:    final collisionCells =
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:361:        element.collisionProfile?.cells.toSet() ?? const <GridPos>{};
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:362:    if (collisionCells.isEmpty) {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:372:        if (collisionCells.contains(GridPos(x: localX, y: localY))) {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:856:    final collisionCells = placement.applyCollision
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:857:        ? element.collisionProfile?.cells.toSet() ?? const <GridPos>{}
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:860:        collisionCells.isNotEmpty && (source.width > 1 || source.height > 1);
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:874:            : (splitByCollision && !collisionCells.contains(localPos)
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:948:        manualPathId: path.id,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:966:        manualPathId: path.id,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:985:        manualPathId: path.id,
```

Justification : occurrences authoring/backdrop preexistantes ou non liees a V1-113 runtime. Aucun fichier runtime/gameplay/battle/example n'est modifie.

## Confirmations

```text
Aucun runtime/gameplay/battle/example modifie : confirme.
Aucun fichier Xcode modifie : confirme.
Aucun playback runtime / Flame / GameState ajoute : confirme.
Aucune animation de marche ajoutee : confirme.
V1-114 non demarre : confirme.
map_core non modifie : confirme.
```

## git final

Commande :

```bash
git diff --check
```

```text
<vide>
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../cinematic_actor_display_preview_overlay.dart   |  25 +-
 .../cinematics/cinematic_builder_workspace.dart    |  16 +-
 .../cinematic_map_backdrop_preview_panel.dart      |  40 +-
 ...tic_preview_playback_actor_overlay_adapter.dart |  71 ++--
 .../test/cinematic_builder_workspace_test.dart     | 415 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  19 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  27 +-
 7 files changed, 554 insertions(+), 59 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non trackes. Ils sont visibles dans le status final ci-dessous.

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_113_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png
```
